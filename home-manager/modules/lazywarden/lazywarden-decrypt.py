#!/usr/bin/env python3
"""
Decrypt a Lazywarden backup.

Usage:
    lazywarden-decrypt backup.zip --output ~/Secure/lazywarden-restore
"""

import argparse
import base64
import json
import os
import shutil
import sys
from getpass import getpass
from pathlib import Path

import pyzipper
from argon2.low_level import Type, hash_secret_raw
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes


def derive_key(password: str, salt: bytes) -> bytes:
    """Derive the AES-256 key using Lazywarden's Argon2 parameters."""
    return hash_secret_raw(
        password.encode(),
        salt,
        time_cost=3,
        memory_cost=65536,
        parallelism=1,
        hash_len=32,
        type=Type.I,
    )


def decrypt_blob(blob: bytes, encryption_password: str) -> bytes:
    """Decrypt a Lazywarden AES-CFB JSON blob."""
    data = base64.urlsafe_b64decode(blob)
    if len(data) < 33:
        raise ValueError("encrypted blob is too short")

    salt = data[:16]
    iv = data[16:32]
    ciphertext = data[32:]

    key = derive_key(encryption_password, salt)
    cipher = Cipher(algorithms.AES(key), modes.CFB(iv), backend=default_backend())
    decryptor = cipher.decryptor()
    return decryptor.update(ciphertext) + decryptor.finalize()


def ensure_private_directory(path: Path) -> None:
    path.mkdir(mode=0o700, parents=True, exist_ok=True)
    path.chmod(0o700)


def safe_extract_zip(zip_file: pyzipper.AESZipFile, destination: Path, password: bytes) -> list[Path]:
    """Extract zip members while preventing path traversal."""
    extracted = []
    destination_root = destination.resolve()

    for member in zip_file.infolist():
        target = (destination / member.filename).resolve()
        if destination_root != target and destination_root not in target.parents:
            raise ValueError(f"refusing unsafe zip member path: {member.filename}")

        if member.is_dir():
            ensure_private_directory(target)
            continue

        ensure_private_directory(target.parent)
        with zip_file.open(member, pwd=password) as source, open(target, "wb") as dest:
            shutil.copyfileobj(source, dest)
        target.chmod(0o600)
        extracted.append(target)

    return extracted


def find_single_file(directory: Path, pattern: str, description: str) -> Path | None:
    matches = sorted(directory.glob(pattern))
    if len(matches) > 1:
        names = ", ".join(path.name for path in matches)
        raise ValueError(f"found multiple {description} files: {names}")
    return matches[0] if matches else None


def decrypt_backup_json(output_dir: Path, encryption_password: str, cleanup: bool) -> Path:
    encrypted_json = find_single_file(output_dir, "*.json", "encrypted JSON")
    if encrypted_json is None:
        raise FileNotFoundError("no JSON file found in extracted backup")

    plaintext = decrypt_blob(encrypted_json.read_bytes(), encryption_password)
    data = json.loads(plaintext)

    decrypted_json = output_dir / f"{encrypted_json.stem}_decrypted.json"
    with open(decrypted_json, "w", encoding="utf-8") as file:
        json.dump(data, file, indent=2, sort_keys=True)
        file.write("\n")
    decrypted_json.chmod(0o600)

    if cleanup:
        encrypted_json.unlink()

    return decrypted_json


def extract_attachments(output_dir: Path, cleanup: bool) -> Path | None:
    attachments_zip = find_single_file(output_dir, "attachments_*.zip", "attachments ZIP")
    if attachments_zip is None:
        print("No attachments ZIP found.")
        return None

    attachments_password = getpass("Enter attachments ZIP password (press Enter to skip): ").encode()
    if not attachments_password:
        print("Skipping attachments extraction.")
        return None

    attachments_dir = output_dir / attachments_zip.stem
    ensure_private_directory(attachments_dir)

    with pyzipper.AESZipFile(attachments_zip) as zip_file:
        extracted = safe_extract_zip(zip_file, attachments_dir, attachments_password)

    if cleanup:
        attachments_zip.unlink()

    print(f"Extracted {len(extracted)} attachment file(s) to: {attachments_dir}")
    return attachments_dir


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Decrypt a Lazywarden backup ZIP.")
    parser.add_argument("backup_zip", type=Path, help="Path to the Lazywarden backup ZIP.")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Output directory. Defaults to a directory beside the backup ZIP.",
    )
    parser.add_argument(
        "--cleanup",
        action="store_true",
        help="Remove encrypted extracted JSON/attachment ZIP files after successful processing.",
    )
    parser.add_argument(
        "--no-attachments",
        action="store_true",
        help="Do not look for or prompt to extract attachments.",
    )
    return parser.parse_args()


def main() -> int:
    os.umask(0o077)
    args = parse_args()
    backup_zip = args.backup_zip.expanduser().resolve()

    if not backup_zip.is_file():
        print(f"File not found: {backup_zip}", file=sys.stderr)
        return 1

    output_dir = args.output.expanduser() if args.output else backup_zip.parent / backup_zip.stem
    output_dir = output_dir.resolve()
    ensure_private_directory(output_dir)

    zip_password = getpass("Enter ZIP password: ").encode()
    encryption_password = getpass("Enter encryption password: ")

    try:
        with pyzipper.AESZipFile(backup_zip) as zip_file:
            extracted = safe_extract_zip(zip_file, output_dir, zip_password)
        print(f"Extracted {len(extracted)} file(s) to: {output_dir}")

        decrypted_json = decrypt_backup_json(output_dir, encryption_password, args.cleanup)
        print(f"Decrypted JSON saved to: {decrypted_json}")

        if not args.no_attachments:
            extract_attachments(output_dir, args.cleanup)

    except Exception as error:
        print(f"Lazywarden decrypt failed: {error}", file=sys.stderr)
        return 1

    print(f"Done. Output saved to: {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

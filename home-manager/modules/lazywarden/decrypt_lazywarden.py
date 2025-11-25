#!/usr/bin/env python3
"""
Decrypt a Lazywarden backup that is:
  - ZIP‑protected (ZIP_PASSWORD)
  - AES‑CFB encrypted inside the zip (ENCRYPTION_PASSWORD)

Usage:
    ./decrypt_lazywarden.py /path/to/bw-backup_YYYY_MM_DD_HH_mm_ss.zip
"""

import sys
import json
import base64
import pyzipper  # Use pyzipper instead of zipfile for AES encryption support
import bz2  # Enable bzip2 compression support
import lzma  # Enable LZMA/XZ compression support
from pathlib import Path
from getpass import getpass

from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from argon2.low_level import hash_secret_raw, Type


def derive_key(pw: str, salt: bytes) -> bytes:
    """Derive the 256‑bit AES key – same Argon2 parameters Lazywarden uses."""
    return hash_secret_raw(
        pw.encode(),
        salt,
        time_cost=3,
        memory_cost=65536,
        parallelism=1,
        hash_len=32,
        type=Type.I,
    )


def decrypt_blob(blob: bytes, enc_pwd: str) -> bytes:
    """Reverse of encrypt() in Lazywarden backup."""
    data = base64.urlsafe_b64decode(blob)

    # layout: 16‑byte salt | 16‑byte IV | ciphertext
    salt, iv, ct = data[:16], data[16:32], data[32:]

    key = derive_key(enc_pwd, salt)
    cipher = Cipher(algorithms.AES(key), modes.CFB(iv), backend=default_backend())
    return cipher.decryptor().update(ct) + cipher.decryptor().finalize()


def main(zip_path: Path):
    if not zip_path.is_file():
        sys.exit(f"❌ File not found: {zip_path}")

    zip_pwd = getpass("Enter ZIP password: ").encode()
    enc_pwd = getpass("Enter encryption password (ENCRYPTION_PASSWORD): ")

    # Create output directory with same name as ZIP file
    output_dir = zip_path.parent / zip_path.stem
    output_dir.mkdir(exist_ok=True)

    # ---- 1️⃣  Extract all files from the main backup ZIP
    print(f"📦 Extracting backup ZIP...")
    try:
        with pyzipper.AESZipFile(zip_path) as zf:
            # Check compression method of first file
            if zf.namelist():
                info = zf.getinfo(zf.namelist()[0])
                compress_type = info.compress_type
                compress_names = {
                    0: "stored (no compression)",
                    8: "deflate",
                    12: "bzip2",
                    14: "lzma",
                    93: "zstandard",
                    99: "AES encrypted",
                }
                compress_name = compress_names.get(compress_type, f"unknown ({compress_type})")
                print(f"📦 ZIP compression method: {compress_name}")
            
            zf.extractall(path=output_dir, pwd=zip_pwd)
            print(f"✅ Extracted {len(zf.namelist())} file(s) to: {output_dir}")
    except Exception as e:
        sys.exit(f"❌ ZIP extraction failed: {e}")

    # ---- 2️⃣  Find and decrypt the JSON file
    json_files = list(output_dir.glob("*.json"))
    if not json_files:
        sys.exit(f"❌ No JSON file found in extracted backup")
    
    json_file = json_files[0]
    print(f"\n🔓 Decrypting {json_file.name}...")
    
    try:
        with open(json_file, 'rb') as f:
            encrypted_blob = f.read()
        
        plaintext = decrypt_blob(encrypted_blob, enc_pwd)
        
        # Parse and save decrypted JSON
        data = json.loads(plaintext)
        decrypted_json = output_dir / f"{json_file.stem}_decrypted.json"
        
        with open(decrypted_json, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, sort_keys=True)
        
        print(f"✅ Successfully decrypted backup!")
        print(f"📄 Decrypted JSON saved to: {decrypted_json}")
        
        # Remove the encrypted JSON file
        json_file.unlink()
        
    except Exception as e:
        sys.exit(f"❌ Decryption failed: {e}")

    # ---- 3️⃣  Look for and extract attachments ZIP
    attachments_zips = list(output_dir.glob("attachments_*.zip"))
    
    if attachments_zips:
        attachments_zip = attachments_zips[0]
        print(f"\n📎 Found attachments ZIP: {attachments_zip.name}")
        
        # Ask for attachments password
        attach_pwd = getpass("Enter attachments ZIP password (press Enter to skip): ").encode()
        
        if attach_pwd:
            attachments_dir = output_dir / attachments_zip.stem
            attachments_dir.mkdir(exist_ok=True)
            
            try:
                with pyzipper.AESZipFile(attachments_zip) as zf:
                    print(f"📦 Extracting {len(zf.namelist())} attachment(s)...")
                    zf.extractall(path=attachments_dir, pwd=attach_pwd)
                
                print(f"✅ Successfully extracted attachments!")
                print(f"📁 Attachments saved to: {attachments_dir}")
                
                # Remove the attachments ZIP file after extraction
                attachments_zip.unlink()
                
            except RuntimeError as e:
                if "Bad password" in str(e):
                    print("❌ Incorrect attachments password")
                else:
                    print(f"❌ Attachments extraction failed: {e}")
            except Exception as e:
                print(f"❌ Attachments extraction failed: {e}")
        else:
            print("⏭️  Skipping attachments extraction")
    else:
        print(f"\nℹ️  No attachments ZIP found in backup")
    
    print(f"\n✨ All done! Everything saved to: {output_dir}")




if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: ./decrypt_lazywarden.py <backup‑zip>")
    main(Path(sys.argv[1]))

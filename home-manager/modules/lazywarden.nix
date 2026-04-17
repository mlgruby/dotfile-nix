{ pkgs, ... }:

let
  pythonWithPackages = pkgs.python3.withPackages (
    ps: with ps; [
      cryptography
      argon2-cffi
      pyzipper
    ]
  );

  lazywarden-decrypt = pkgs.writeScriptBin "lazywarden-decrypt" ''
    #!${pythonWithPackages}/bin/python3
    ${builtins.readFile ./lazywarden/decrypt_lazywarden.py}
  '';

  decrypt-lazywarden-legacy = pkgs.writeShellScriptBin "decrypt_lazywarden.py" ''
    exec ${lazywarden-decrypt}/bin/lazywarden-decrypt "$@"
  '';
in
{
  home.packages = [
    lazywarden-decrypt
    decrypt-lazywarden-legacy
  ];
}

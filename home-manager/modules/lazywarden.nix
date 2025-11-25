{ pkgs, ... }:

let
  # Create a Python environment with the required packages
  pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [
    cryptography
    argon2-cffi
    pyzipper  # Support for AES-encrypted ZIP files
  ]);
  
  # Create the wrapper script (handles both backup and attachments)
  decrypt-lazywarden = pkgs.writeScriptBin "decrypt_lazywarden.py" ''
    #!${pythonWithPackages}/bin/python3
    ${builtins.readFile ./lazywarden/decrypt_lazywarden.py}
  '';
in
{
  home.packages = [ decrypt-lazywarden ];
}

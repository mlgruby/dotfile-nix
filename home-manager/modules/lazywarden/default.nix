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
    ${builtins.readFile ./lazywarden-decrypt.py}
  '';
in
{
  home.packages = [
    lazywarden-decrypt
  ];
}

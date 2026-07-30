{ lib, pkgs }:
{
  direnv = pkgs.direnv.overrideAttrs (_old: {
    # Darwin: the upstream zsh test can hang during local builds.
    doCheck = false;
  });

  pipx = pkgs.python312Packages.pipx.overridePythonAttrs (_old: {
    # pipx 1.8.0: tests expect older packaging spacing for URL specs.
    doCheck = false;
  });

  poetry = pkgs.poetry.overrideAttrs (_old: {
    # Poetry 2.4.1: install-output assertions fail with Python 3.14 on Darwin.
    doInstallCheck = false;
  });

  marksman = pkgs.marksman.overrideAttrs (
    _old:
    lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # 2026-02-08: VSTest cannot connect to testhost in the Darwin sandbox.
      doCheck = false;
    }
  );
}

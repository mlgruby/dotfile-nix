## Pre-PR Local Validation

GitHub Actions CI checks were intentionally removed so validation runs locally instead of waiting on macOS CI runners.

Rules:
- Before creating or updating any pull request (`gh pr create` or pushing final PR commits), ALWAYS run `./scripts/testing/pre-pr-check.sh` locally and verify every check passes.
- If `flake.nix`, `flake.lock`, or Nix module derivations changed significantly, run `./scripts/testing/pre-pr-check.sh --build` (or `nix flake check`) locally to verify derivations build cleanly.
- If Zsh aliases, functions, or integration scripts changed, smoke-test them in a clean Zsh shell (`zsh -f -c 'source ...'`) to ensure standard builtins/commands are not shadowed.
- Report exact local check results in the PR body/summary before marking the PR ready.

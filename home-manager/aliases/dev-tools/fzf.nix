# home-manager/aliases/dev-tools/fzf.nix
#
# FZF-powered interactive aliases.
{ ... }:
{
  # File editing with preview
  fe = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' | xargs -r \${EDITOR:-nvim}"; # Fuzzy find and edit file
  ffp = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'"; # Fuzzy find with file preview
  edit = "fzf --preview 'bat --color=always {}' | xargs -r nvim"; # Fuzzy find and edit in nvim

  # Directory navigation
  fcd = "cd $(fd -td | fzf)"; # Fuzzy find directory (excluding hidden)
  fcdh = "cd $(fd -H -td | fzf)"; # Fuzzy find directory (including hidden)

  # Content search
  fif = "rg --color=always --line-number --no-heading --smart-case \"\" | fzf --ansi --preview 'bat --color=always --style=numbers {1} --highlight-line {2}'"; # Fuzzy search file contents

  # Process management
  fkill = "ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs -r kill"; # Fuzzy select and gracefully terminate processes
  fmem = "ps -axm -o pid,ppid,%mem,%cpu,comm | head -20 | fzf --header-lines=1"; # Fuzzy browse top memory usage

  # History and environment
  hist = "history 0 | fzf --ansi --preview 'echo {}' | sed 's/ *[0-9]* *//'"; # Fuzzy search command history
  fenv = "env | fzf --preview 'echo {}' | cut -d= -f2"; # Fuzzy search environment variables
}

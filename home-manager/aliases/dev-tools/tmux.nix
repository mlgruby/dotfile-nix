# home-manager/aliases/dev-tools/tmux.nix
#
# Tmux session management aliases.
{ ... }:
{
  tn = "tmux new -s"; # Create new named session - usage: tn mysession
  ta = "tmux attach -t"; # Attach to session - usage: ta mysession
  tl = "tmux list-sessions"; # List all sessions
  tk = "tmux kill-session -t"; # Kill specific session - usage: tk mysession
  t = "tmux new-session -A -s main"; # Attach to or create main session
  tls = "tmux list-sessions -F '#{session_name}: #{?session_attached,attached,not attached}'"; # List sessions with status
  tkall = "tmux list-sessions -F '#{session_name}' | xargs -I {} tmux kill-session -t {}"; # Kill all sessions
}

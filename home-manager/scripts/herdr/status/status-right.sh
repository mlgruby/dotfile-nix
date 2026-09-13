#!/usr/bin/env bash
# Runs existing modular status-right script and translates tmux markup to standard ANSI for Herdr.
export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/opt/homebrew/bin:$PATH"

TMUX_STATUS="$HOME/.config/tmux/status-right.sh"
if [ ! -f "$TMUX_STATUS" ]; then
  exit 0
fi

raw="$(bash "$TMUX_STATUS" 2>/dev/null || true)"
[ -z "$raw" ] && exit 0

python3 - <<PY
import re, sys

raw = """$raw"""

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def tmux_to_ansi(text):
    def repl(m):
        content = m.group(1)
        if content == 'default':
            return '\x1b[0m'
        parts = content.split(',')
        codes = []
        for p in parts:
            if p.startswith('fg='):
                val = p[3:]
                if val.startswith('#'):
                    r, g, b = hex_to_rgb(val)
                    codes.append(f"38;2;{r};{g};{b}")
            elif p.startswith('bg='):
                val = p[3:]
                if val.startswith('#'):
                    r, g, b = hex_to_rgb(val)
                    codes.append(f"48;2;{r};{g};{b}")
            elif p == 'nobold':
                codes.append('22')
            elif p == 'nounderscore':
                codes.append('24')
            elif p == 'noitalics':
                codes.append('23')
        return ('\x1b[' + ';'.join(codes) + 'm') if codes else ''
    return re.sub(r'#\[(.*?)\]', repl, text)

print(tmux_to_ansi(raw), end="")
PY

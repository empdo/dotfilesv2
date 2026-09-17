#!/usr/bin/env bash
# Link the dotfiles into $HOME with GNU Stow.
# Anything already in the way is moved to ~/.dotfiles-backup/<timestamp>/ first (nothing is deleted).
set -euo pipefail
shopt -s dotglob nullglob

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGS=(hypr quickshell kitty wofi nvim gtk environment systemd easyeffects mime zsh tmux git wallpapers)
# Folders shared with other apps: link the files inside them, never the folder itself
SHARED=" .config Pictures "
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

command -v stow >/dev/null || sudo pacman -S --needed --noconfirm stow

backup() {
  mkdir -p "$BACKUP/$(dirname "$1")"
  mv "$HOME/$1" "$BACKUP/$1"
  echo "  moved ~/$1 -> $BACKUP/$1"
}

clear_way() { # $1 = package dir, $2 = relative path prefix ("" or "dir/")
  local src name t
  for src in "$1/$2"*; do
    name="${src#"$1"/}"; t="$HOME/$name"
    if [[ -L $t ]]; then
      [[ "$(readlink -f "$t")" == "$DOT"/* ]] && continue   # already ours
      backup "$name"
    elif [[ -d $t && -d $src && "$SHARED" == *" $name "* ]]; then
      clear_way "$1" "$name/"
    elif [[ -e $t ]]; then
      backup "$name"
    fi
  done
}

for pkg in "${PKGS[@]}"; do
  dir="$DOT/$pkg"
  [[ -d $dir && -n "$(ls -A "$dir")" ]] || { echo "skip $pkg (empty)"; continue; }
  echo "stow $pkg"
  clear_way "$dir" ""
  stow -d "$DOT" -t "$HOME" "$pkg"
done

systemctl --user daemon-reload 2>/dev/null || true
command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1 || true
echo "Done."

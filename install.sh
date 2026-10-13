#!/usr/bin/env bash
# Fresh Arch install: install packages, then link the dotfiles.
set -euo pipefail
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -Syu --needed git base-devel stow
sudo pacman -S --needed - < "$DOT/pkglist.txt"

if ! command -v paru >/dev/null; then
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
  (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
fi
[[ -s "$DOT/aurlist.txt" ]] && paru -S --needed - < "$DOT/aurlist.txt"

# Oh My Zsh (the .zshrc in this repo expects it)
[[ -d ~/.oh-my-zsh ]] || RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# tmux plugin manager (tmux is no longer the default session manager -- herdr is --
# but the config is still stowed for when tmux is started by hand)
[[ -d ~/.tmux/plugins/tpm ]] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# greetd lives in /etc, outside stow's reach: copy it in rather than symlinking,
# since a root-run login daemon shouldn't read config from a user-writable file
sudo pacman -S --needed greetd
sudo install -Dm644 "$DOT/greetd/etc/greetd/config.toml" /etc/greetd/config.toml
sudo systemctl enable greetd.service

"$DOT/bootstrap.sh"
echo "Log out and back in; zsh starts herdr from then on."

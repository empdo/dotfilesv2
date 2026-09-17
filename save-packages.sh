#!/usr/bin/env bash
# Refresh the package lists (run after installing/removing software)
DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pacman -Qqen > "$DOT/pkglist.txt"
pacman -Qqem > "$DOT/aurlist.txt"
echo "$(wc -l < "$DOT/pkglist.txt") repo + $(wc -l < "$DOT/aurlist.txt") AUR packages saved."

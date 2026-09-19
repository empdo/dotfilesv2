# dotfiles

Arch + Hyprland setup: Quickshell bar and app launcher, hyprpaper, kitty, nvim, zsh/Oh My Zsh, herdr.
Managed with [GNU Stow](https://www.gnu.org/software/stow/) — each folder is a package that mirrors `$HOME`.

## New machine

```bash
sudo pacman -S git
git clone https://github.com/empdo/dotfiles ~/dotfiles
~/dotfiles/install.sh
```

Existing files that would be overwritten are moved to `~/.dotfiles-backup/<timestamp>/`.

## Day to day

```bash
cd ~/dotfiles
./save-packages.sh          # after installing software
git add -A && git commit -m "update" && git push
```

## Session manager

zsh starts [herdr](https://herdr.dev) in every interactive terminal (`zsh/.zshrc`).
It is one shared, persistent session: workspaces, tabs, panes and any agents
running in them survive a closed window.

A new window attaches to whatever tab is focused. Press `prefix + c` in it to
branch onto a tab of its own — from then on each window keeps its own view and
they stop following each other. That step is manual on purpose: focus is only
per-client when a client navigates *itself*. `herdr tab create --focus` and
`herdr tab focus` go through the socket API, which has no client field, so they
move every attached window at once. If you would rather each window be
completely independent, give it its own session instead:

```zsh
herdr --session "kitty-$(date +%s)"   # in place of plain `herdr`
```

That trades away the shared workspace and agent overview, and the sessions stick
around until `herdr session stop`.

`herdr/.config/herdr/config.toml` holds the whole keymap. It is herdr's default
v2 keymap with the changes that keep the old tmux muscle memory intact:

| | herdr default | here |
| --- | --- | --- |
| prefix | `ctrl+b` | `ctrl+s` |
| resize pane | *(resize mode only)* | `prefix H/J/K/L` |
| swap pane | `prefix H/J/K/L` | `prefix ctrl+h/j/k/l` |
| reload config | `prefix shift+r` | `prefix r` |
| resize mode | `prefix r` | `prefix shift+r` |
| detach | `prefix q` | `prefix d` (and `q`) |
| settings | `prefix s` | `prefix shift+s` (`prefix s` is the session navigator, like tmux's `choose-session`) |

Keys are letters wherever there was a choice: this machine uses a Swedish layout,
where the punctuation tmux binds (`%` `"` `&` `;`) sit behind shift.

```bash
herdr config check          # validate after editing
herdr server reload-config  # apply without restarting (or press prefix + r)
```

tmux is still installed and still stowed, it just no longer starts on its own —
run `tmux` and the old `~/.tmux.conf` (same `ctrl+s` prefix) applies as before.

## App launcher

`SUPER + D` opens a Quickshell overlay in place of wofi
(`quickshell/.config/quickshell/modules/launcher`). It reads the XDG desktop
entries directly through Quickshell's `DesktopEntries`, so there is no cache to
rebuild — installing an app makes it show up.

Typing ranks rather than merely filters: an exact name beats a prefix, which
beats a word-boundary hit inside the name, which beats scattered letters
(`vsc` finds Visual Studio Code). Keywords, generic name and comment are
searched too, at descending weight. Desktop actions ("New Private Window") join
the results once you type, and stay out of the resting list.

Launch counts live in `~/.local/state/quickshell/by-shell/<id>/launcher.json`
and nudge the ranking, so the apps you actually use rise to the top — with an
empty query the list *is* that history. Typing a name still beats a favourite
that only fuzzy-matches.

`↑↓` or `ctrl+j/k` select, `⏎` launches, `⇥` completes to the selected name,
`Esc` closes. Entries marked `Terminal=true` are opened in kitty (the `terminal`
property at the top of `Launcher.qml`).

```bash
qs ipc call launcher toggle   # what SUPER + D is bound to
```

## Network and Bluetooth

The bar item under the light/dark toggle
(`quickshell/.config/quickshell/modules/connectivity`) shows whichever
connection is carrying traffic, with a dot when something is connected over
Bluetooth. Hovering it opens a menu with both radios: Wi-Fi networks with
signal and security, and Bluetooth devices with pairing state and battery.

Left click a row to do the obvious thing — connect, or disconnect if it is
already connected — and right click to forget it. Wi-Fi passphrases are asked
for in a separate focused overlay, because a popup anchored to the bar cannot
take keyboard focus and closes as soon as the pointer leaves it.

Everything goes through Quickshell's native NetworkManager and BlueZ bindings;
nothing shells out to `nmcli` or `bluetoothctl`. Scanning and Bluetooth
discovery run only while the menu is on screen.

## Keybind cheatsheet

`SUPER + ALT + K` opens a Quickshell overlay: first a menu of apps, then that
app's keybinds. It covers Hyprland, Neovim, herdr, tmux, kitty and zsh.

`quickshell/.config/quickshell/modules/cheatsheet/collect.py` asks each app for
its *live* binds (`hyprctl binds -j`, `nvim_get_keymap`, `tmux list-keys`, and so
on) and writes `~/.cache/cheatsheet/binds.json`. Hyprland rebuilds the cache on
start and on every `hyprctl reload`, and the overlay watches the file.

herdr is the one exception, because it has no command that prints its live
keymap. Its page is `herdr --default-config` (the installed binary's own
defaults) with `~/.config/herdr/config.toml` layered on top, minus whatever
`herdr config check` says the binary refused — so the only way it can go stale is
a herdr upgrade that moves a default this repo does not override.

The one rule: **a bind's description lives next to the bind**, not in a separate
list that would go stale.

```lua
hl.bind(key("RETURN"), hl.dsp.exec_cmd(terminal), { desc = "Open terminal" })
```
```lua
vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, { desc = "Go to definition" })
```

A Hyprland bind with no `desc` still shows up, greyed out and marked, so it is
obvious what needs one. herdr, tmux, kitty and zsh describe their own binds already.

Other entry points:

```bash
qs ipc call cheatsheet open nvim   # jump straight to one app's sheet
qs ipc call cheatsheet toggle      # what SUPER + ALT + K is bound to
```

## Machine-specific bits

- Monitors `DP-1` / `HDMI-A-3` are hardcoded in `hypr/.config/hypr/hyprland.lua`
  (`hyprpaper.conf` is regenerated by the Quickshell wallpaper picker). Check `hyprctl monitors`.
- `systemd` enables `hyprland.service` and `tailscale-systray.service` for user `emil`.

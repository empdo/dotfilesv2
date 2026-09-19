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

## Bar layout

The bar groups its items into four capsules (`BarSection.qml`) rather than
spacing eight icons evenly down the edge, so it reads as a few groups:
workspaces and the tray at the top, now playing in the middle, the clock on its
own, and volume, quick settings and power together at the bottom. The middle
capsule disappears entirely when nothing is playing, rather than sitting there
empty. Children of a section are laid out in a `Column`, so they must not
set their own anchors. The capsule is deliberately narrower than the 60px items
— their visible glyphs are only about half that, so it stays centred on the
icons rather than on their boxes — and sits at low opacity, enough to group
without drawing attention.

Everything in the bottom capsule sets `smoothBottom`, which pins its popup to
the bottom edge of the screen instead of centring it on its icon. They all sit
low enough that a centred popup would be clipped.

## Now playing

The middle capsule shows whatever is playing over MPRIS
(`quickshell/.config/quickshell/modules/media`). The bar icon is the album art
itself, dimmed while paused and marked with a dot while playing; clicking it
plays or pauses, the way the volume icon mutes. The popup has the art, track,
a seekable progress bar and transport controls.

`MediaService.qml` picks which player the bar speaks for: an explicit choice
from the popup's player pills wins, then whatever is actually playing, then
whatever merely has a track loaded — so a paused Spotify still beats an idle
client. MPRIS does not push position updates, so the service polls `position`
twice a second while something plays and exposes it as `elapsed`. Players that
do not report a length (Firefox and Zen do not; Spotify does) simply have no
progress bar.

## Power menu

Log out, sleep and shut down, from the power icon at the bottom of the bar.
Every action takes two clicks: the popup opens on hover, so a single click
would leave a stray mouse one twitch away from shutting the machine down. The
first click arms an action and the label changes to `Confirm?`; it disarms
after three seconds, when the pointer leaves the button, or when the popup
closes.

Logging out runs `hyprctl dispatch 'hl.dsp.exit()'`, not
`systemctl --user stop hyprland.service`. The unit exists and is enabled, but
this machine's session is started from a TTY login and the unit sits in
`failed`, so stopping it would do nothing. Note the argument is a Lua
dispatcher object, not a string — the config is in Lua mode, where
`hyprctl dispatch exit` and `hyprctl dispatch '"exit"'` are both errors.

## Wallpaper

The Wallpaper tile in the quick settings menu opens the picker
(`quickshell/.config/quickshell/modules/wallpaper/WallpaperPanel.qml`), and
names whichever wallpaper is currently up — read back by watching
`hyprpaper.conf`, which `setwallpaper.sh` rewrites on every change.

The picker is its own layershell panel rather than a popup hanging off the bar,
so it can sit on the left of the screen clear of the bar: 60px for the bar plus
a 5mm gap, worked out from the monitor's `physicalPixelDensity` rather than
hardcoded, so it stays 5mm on a display with a different pitch. On this machine
that lands it at x=81. It has a border and rounded corners, drawn with a
`ClippingRectangle` so the list and its fades are clipped to them.

Clicking a wallpaper applies it and closes the panel; Escape closes it once the
panel has been clicked (its keyboard focus is `OnDemand`, so it does not swallow
typing everywhere else while open), and the tile toggles it.

## Quick settings

The gear in the bar, under the volume icon
(`quickshell/.config/quickshell/modules/settings`), opens a menu with the
quick settings across the top — theme and wallpaper, both a choice rather than
something that is on or off, so neither has a switch — and the two device lists
below, Network on the left and Bluetooth on the right. Each list's radio switch sits beside its heading, next to what it
actually controls.

The wired connection is the first row of the Network list. It sits outside the
scrolling area, so a long list of access points never pushes the connection you
are actually using offscreen, and it is display-only: wired comes up on its own
and clicking could only ever drop it by accident.

Left click any other row to do the obvious thing — connect, or disconnect if it
is already connected — and right click to forget it. Wi-Fi passphrases are
asked for in a separate focused overlay
(`modules/connectivity/WifiPrompt.qml`), because a popup anchored to the bar
cannot take keyboard focus and closes as soon as the pointer leaves it.

The menu is pinned to the bottom edge of the screen (`smoothBottom`, the same
treatment the power popup gets) rather than centred on its icon, which sits too
low in the bar for a panel this tall to be centred without being clipped.

Connectivity itself lives in `modules/connectivity`: `ConnectivityService.qml`
is the single source of truth, and `NetworkList.qml` / `BluetoothList.qml` are
the two lists. Everything goes through Quickshell's native NetworkManager and
BlueZ bindings; nothing shells out to `nmcli` or `bluetoothctl`. Scanning and
Bluetooth discovery run only while the menu is on screen — discovery is
debounced, because BlueZ rejects start/stop calls that land on top of each
other.

One gotcha worth knowing when editing these files: Nerd Font glyphs in the
private-use range are easy to lose in transit and leave behind an empty string,
which renders as a blank gap rather than an error. The ones below U+F900 are
written as `\uXXXX` escapes for that reason.

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

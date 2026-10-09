# dotfiles

Arch + Hyprland setup: Quickshell bar, app launcher, notifications and clipboard, hyprpaper, kitty, nvim, zsh/Oh My Zsh, herdr.
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

It opens flush against the bar rather than floating in the middle of the
screen: the same `RoundedPopupCard` the bar's own popups are drawn in, with its
two concave fillets along the attached edge, so the launcher reads as the bar
unfolding rather than as a panel that happened to land nearby. The wash behind
it stops at the bar — the shell has no business dimming itself to show its own
menu — and is `Theme.background` rather than black, which in the light palette
is the difference between the desktop stepping back and a hole in the screen.
The shape, the placement and the 200ms it takes to grow out of the bar all live
in `BarDrawer.qml`, which the clipboard history opens in too.

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
`Esc` closes.

Hovering a row selects it, so the mouse and the keyboard never disagree about
which row `⏎` would take — but hovering never *scrolls*. The list used to keep
the selected row inside a band one row in from each edge
(`highlightRangeMode: ApplyRange`), which meant any selection change moved the
view, hovering included: putting the pointer on the top or bottom row shoved
the list out from under it, which slid a new row under the pointer, which
selected, which scrolled, until the list had dragged itself to one end. The
view now scrolls only when `reveal()` says so, and only the keyboard calls it —
a hover is not navigation, since the pointer is already on the row it means.
The clipboard list does the same thing for the same reason. Entries marked `Terminal=true` are opened in kitty (the `terminal`
property at the top of `Launcher.qml`).

```bash
qs ipc call launcher toggle   # what SUPER + D is bound to
```

## Bar layout

There is a bar on every output (`Variants` over `Quickshell.screens` in
`shell.qml`), and a screen taller than it is wide gets its bar across the
bottom rather than down the left edge. This machine's second monitor is rotated
a quarter turn, where a vertical bar would eat a twentieth of an already narrow
screen. The orientation is read off the screen's shape rather than its name, so
a monitor added or re-rotated sorts itself out.

Both are the same `Bar.qml`. `horizontal` is threaded down through
`BarSection`, `ExpandableItem`, `RoundedPopupCard`, `BarDrawer`,
`WorkspacesWidget` and `ClockWidget` rather than there being a second bar to
keep in step. Which edge it is comes from `Modules.Shell`, along with the bar's
thickness: the bar and the two drawers that open flush against it all have to
agree, and disagreeing does not look like a wrong number — it looks like a
drawer growing out of the wrong side of the screen. Three of
those only have to swap an axis — a section lays its children out in a `Grid`
whose `columns` is 1 or many, which keeps one child list either way. The other
two are more than a transposition:

- `RoundedPopupCard` draws its path once, in the bar's own terms — `u` is depth
  away from the bar, `v` runs along it — and a `point()` helper turns that into
  canvas coordinates for whichever edge the bar is on. A horizontal popup is
  the same shape a quarter turn round, growing upwards out of the bar with its
  two concave fillets along its bottom edge.
- `ClockWidget` genuinely changes: 60px of width will not take "03:59" at a
  readable size, so a vertical bar gets a component per line down it, while a
  horizontal bar has 60px of height instead and gets the time over the date.

A popup is pinned to the edge its bar is on, so it opens *out of* the bar;
anchored to the far side it grows the other way, appearing at the top of the
screen and reaching down towards the bar. A section centres its items on both
axes for a related reason: a `Grid` aligns cells to the top-left unless told
otherwise, and the items are not all the same size — the workspaces pill fills
the bar's whole thickness while an icon is only 40px of it, which left the tray
and the bell riding high of everything beside them.

Popups are clamped to the screen along the bar in both orientations, which is
what lets the horizontal bar do without `smoothBottom` — the vertical bar's
trick of pinning the bottom three popups to the screen edge, since they sit too
low to be centred on their icon without being clipped.

### Workspaces

Slots, not a list of whatever happens to be open. Hyprland only reports
workspaces that exist, so a plain repeater over them means the third dot is
workspace 3 one minute and workspace 7 the next, and position tells you
nothing. Slots make position *be* the identity: the fourth dot is always
workspace 4, which is what `SUPER + 4` goes to.

The row runs up to the highest workspace in use on that monitor rather than to
a fixed ten, so two workspaces show two dots and a jump to 8 shows eight, with
2 to 7 sitting empty in between. Those gaps are the point — they are what keeps
the eighth dot the eighth. An empty slot stays at low opacity behind a thin
edge, holding the position that gives the others their meaning without
competing with the ones in use. Special workspaces carry negative ids and get
no slot.

Each bar shows only the workspaces living on **its own** monitor, so the two
bars say different things. A workspace is on exactly one monitor at a time, and
which one is half of what you want to know.

The fill distinguishes two states that are easy to conflate. `active` is the
workspace a monitor is showing; `focused` is the one the keyboard is on, and
there is only ever one of those across both screens. So the bar you are working
on has a bright dot, and the other bar shows a muted one saying "this is what
is over there". Filling on `active` alone was the bug this replaced: with two
monitors, two workspaces are always active, so two dots were always lit and
neither told you where you were.

Clicking an empty slot switches to that workspace, which creates it. That goes
through `Hyprland.dispatch` with a **Lua** dispatcher, because this config is
in Lua mode where `workspace 5` is an error — the same trap the power menu
documents. `Hyprland.usingLua` decides which form to send.

## Bar layout (continued)

The bar groups its items into four capsules (`BarSection.qml`) rather than
spacing ten icons evenly down the edge, so it reads as a few groups:
the cat, workspaces, the tray and the notification bell at the top, now playing
in the middle, the clock on its own, and volume, quick settings and power
together at the bottom. The middle
capsule disappears entirely when nothing is playing, rather than sitting there
empty. Children of a section are laid out in a `Column`, so they must not
set their own anchors. The capsule is deliberately narrower than the 60px items
— their visible glyphs are only about half that, so it stays centred on the
icons rather than on their boxes — and sits at low opacity, enough to group
without drawing attention.

Everything in the bottom capsule sets `smoothBottom`, which pins its popup to
the bottom edge of the screen instead of centring it on its icon. They all sit
low enough that a centred popup would be clipped.

## The cat

The drawing at the top of the bar, where the Arch logo used to be. It is drawn
in Krita on a vector layer and exported to
`quickshell/.config/quickshell/icon/cat.svg`, which stays in the repo as the
editable source.

What the bar actually draws is `modules/components/CatIcon.qml`: the same
artwork as Qt `Shape` geometry rather than a picture of it, so its lines are
filled with `Theme.foreground` and follow light and dark mode -- cross-fade
included, since it inherits the palette's own colour animation. Recolouring a
plain `Image` is the thing this avoids: Qt has no way to tint one that survives
a light theme, and it will not load an SVG from a `data:` URL, so rewriting the
colour into the file at runtime is not open either.

Qt's own converter does the work, and the file says at the top which three
substitutions to reapply afterwards:

```bash
/usr/lib/qt6/bin/svgtoqml icon/cat.svg CatIcon.qml
```

`lineWidth` is in screen pixels and is converted back into the drawing's units
inside the component, so the cat keeps the same weight of line at any size.
This matters more than it sounds: Krita exported the strokes at 1.44 units in a
345.6 viewBox, which at bar size works out to a tenth of a pixel and renders as
nothing at all. 1.6px at 30px across is what the bar uses; much past 2.4 and
the eyes close up.

## Now playing

The middle capsule shows whatever is playing over MPRIS
(`quickshell/.config/quickshell/modules/media`). The bar icon is the album art
itself, dimmed while paused and marked with a dot while playing; clicking it
plays or pauses, the way the volume icon mutes. The popup has the art, track,
a seekable progress bar and transport controls.

`MediaService.qml` picks which player the bar speaks for: an explicit choice
from the popup's player pills wins, then whatever is actually playing, then
whatever merely has a track loaded — so a paused Spotify still beats an idle
client.

A player is identified by its **bus name**, not by `uniqueId`. Despite the
name, `uniqueId` is a per-connection counter and every player on this machine
reports `1`, so comparing on it made every pill in the popup believe it was the
current one, and picking any of them landed on whichever player happened to be
first in the list. The bus name is genuinely distinct
(`org.mpris.MediaPlayer2.spotify` against
`org.mpris.MediaPlayer2.firefox.instance_1_137`) and still keeps the choice
free of a dangling object reference: a client that restarts simply stops
matching, and the fallbacks take over again. MPRIS does not push position updates, so the service polls `position`
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

## Notifications

Quickshell is the notification daemon
(`quickshell/.config/quickshell/modules/notifications`), in place of dunst.
Toasts stack in the top right — the bar owns the left edge and its popups fly
out across it — newest on top, sliding in from the edge and back out again.

A toast times itself out after 5s (low) or 7s (normal); hovering it stops the
clock, so nothing can disappear mid-sentence, and moving away starts the wait
over rather than resuming it. Critical notifications never expire on their own,
ignore do not disturb, and get a coloured stripe and border — `Theme.urgent` is
the only colour in an otherwise monochrome palette, spent here because an
urgency nothing shows is an urgency not worth setting.

Left click runs the notification's default action if it has one (the thing that
opens the chat window the message came from), otherwise just dismisses the
toast; right click drops it from the history too, and so does the cross that
appears on hover. Any other actions the app offers are buttons on the card.

The bell at the top of the bar, under the tray, holds the history: the last 50,
with what they came from and how long ago. The badge counts what has arrived
since the list was last opened — a standing count of 50 tells you nothing.
Clicking the bell toggles do not disturb, the same deal the volume icon makes
(hover for the list, click to silence); the popup has that switch too, next to
a `Count` switch that turns the badge off for when a number in the corner of
the eye is worse than not knowing. Both are persisted, for the same reason: a
preference about how loudly the shell talks to you should not quietly reset
when it reloads. `Clear all` is at the bottom. Silenced notifications still land in the history, so
nothing is lost — do not disturb is persisted in
`~/.local/state/quickshell/by-shell/<id>/notifications.json`, because silencing
notifications and having them come back when quickshell reloads is the one way
this can really fail.

The history itself is not persisted: it is what you missed while you were away
from the screen, not a log.

```bash
qs ipc call notifications dismiss   # SUPER + N: clear the toasts on screen
qs ipc call notifications dnd       # SUPER + SHIFT + N: toggle do not disturb
qs ipc call notifications silence   # and unsilence, when a script wants one or the other
qs ipc call notifications clear     # empty the history
```

`NotificationService.qml` is the daemon and the single source of truth. Two
lists, both newest first: `entries` is the history, `popups` the subset
currently on screen, so dismissing a toast only takes it out of the second.
An entry outlives the `Notification` object it came from — apps close and
replace their own notifications constantly (Spotify rewriting "now playing")
and Quickshell deletes the object when they do, so each entry keeps a snapshot
and drops the live reference instead of letting rows vanish out of the history
by themselves. Transient notifications (progress popups, volume OSDs) get a
toast and no row.

**dunst has to be gone, not merely stopped.** `org.freedesktop.Notifications`
is D-Bus activated: with both installed, which daemon you get is a race, and
dunst wins it any time quickshell is restarting. It is out of `pkglist.txt`,
and `systemd/.config/systemd/user/dunst.service` is a symlink to `/dev/null`
masking the unit, so the name stays claimable even if something pulls the
package back in as a dependency.

```bash
sudo pacman -Rns dunst
```

## Clipboard history

`SUPER + SHIFT + V` opens the last 15 things copied
(`quickshell/.config/quickshell/modules/clipboard`). `SUPER + V` was already
floating, so the history sits on shift. It looks and is driven like the
launcher, because it is the same motion: open, type to narrow, `⏎` to take the
top one. `Del` drops the selected entry, `Esc` closes. It opens in the same
`BarDrawer`, at the same size — the two used to be centred slabs of different
widths and different corner radii, which was two panels doing one job in two
voices.

Ranking reuses the launcher's `matchScore` from `search.js`, so a snippet is
found the same way an app is. With an empty query the list stays in copy order
rather than being ranked, since with nothing typed what you want is nearly
always the last thing you copied. Copying something already in the list moves
it up instead of stacking a second identical row.

Wayland only lets the *focused* surface read the clipboard, so Quickshell's own
`clipboardText` is permanently empty in a bar that never takes focus — that was
tried first, and it sees nothing. `wl-paste --watch` goes through the
data-control protocol, which is what it exists for, and wl-clipboard was
already installed for `wl-copy`. Each new entry is handed to a shell that
prints it followed by an ASCII record separator (`\036`), so snippets
containing newlines — most of the interesting ones — arrive whole rather than a
line at a time. Putting one back goes in on stdin for the same reason:
`wl-copy` joins its arguments with spaces, which would flatten every newline.

Images are handled too, by a second watcher. Text and images get a watcher
each, asking for one type apiece, because that is the only way to tell them
apart without a race — `wl-paste --list-types` reports on the clipboard as it
stands now, which is not necessarily the clipboard that raised the
notification. Asked for a single type, each watcher only ever fires for the
kind it can read, which does hold in practice: copying text leaves the image
watcher silent and the other way round.

A copied image is written to `~/.cache/quickshell/by-shell/<id>/clipboard/`
under a name taken from its own content hash, which buys deduplication for
nothing — copying the same picture twice lands on the same path instead of
filling the cache with identical files. Rows show a bounded thumbnail rather
than decoding a full screenshot apiece, and searching matches an image on the
word "image", since it has no text of its own. Dropping a row deletes its file,
and a sweep at startup keeps only as many files as the history has room for, so
a shell killed between writing an image and saving the history cannot leak one
permanently.

The history holds fifteen. Short on purpose: it is for the last few things you
copied rather than an archive, and a list that short is one you can read
instead of search.

PNG only: `image/png` is what applications actually offer for a copied image,
and asking for one format is what keeps the two watchers cleanly separated.

**The history is plain text on disk**, in
`~/.local/state/quickshell/by-shell/<id>/clipboard.json`. That directory is
`0700` so it is as private as anything else in there, but a password pasted out
of a manager lands in it like any other copy — there is no way to tell from
`wl-paste` that it was a secret.

The Clipboard tile in the quick settings menu opens the same panel, and names
how many entries are waiting. The panel is a window owned by `shell.qml` rather
than a singleton like the wallpaper picker, because its IPC handler has to be
registered from the start and a singleton is only built when something first
asks for it — so the tile raises `ClipboardService.toggleRequested` and the
panel listens, instead of reaching into the window directly.

```bash
qs ipc call clipboard menu    # what SUPER + SHIFT + V is bound to
qs ipc call clipboard clear   # empty the history
```

## Authentication prompts

polkit was running on this machine with no agent registered against it, which
fails quietly: anything needing privilege got no dialog and no error, it simply
never happened. `quickshell/.config/quickshell/modules/polkit` is the missing
half, through Quickshell's native polkit binding — nothing shells out, and
there is no second agent to install.

It is a focused layershell overlay for the same reason `WifiPrompt.qml` is one:
a password needs keyboard focus, which a popup anchored to the bar cannot take.
The card names the action being authorised as well as describing it, since the
action id is the only part that says precisely what is being asked for. Whether
the input is masked comes from polkit rather than being assumed, so a prompt
that is not asking for a secret does not pretend to be. A wrong answer starts
the exchange again rather than ending it, and the field empties for the retry.
Clicking away cancels, rather than parking the prompt behind whatever asked.

When more than one account could authorise an action, the card offers the
choice; with one there is nothing to pick and it says nothing.

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

<h1 align="center">lilith-dotfiles</h1>

<p align="center"><i>A minimal, brutalist rice for the <a href="https://github.com/ohto121/lilith">lilith</a> Wayland compositor.<br>
Built for one machine: <b>ThinkPad X1 Carbon Gen 7</b> · <b>Void Linux (musl, runit)</b></i></p>

<p align="center">
  <img alt="Void musl" src="https://img.shields.io/badge/Void-musl%20·%20runit-478061?style=flat-square">
  <img alt="Wayland" src="https://img.shields.io/badge/Wayland-lilith-7fcfc0?style=flat-square">
  <img alt="Palette" src="https://img.shields.io/badge/palette-wallust-c9d1ce?style=flat-square">
  <img alt="Status" src="https://img.shields.io/badge/status-testing%20on%20hardware-orange?style=flat-square">
</p>

<!-- Add screenshots once the desktop is running:
<p align="center"><img src="docs/screenshots/desktop.png" width="820"></p> -->

---

## Contents
[Install](#install) · [After installing](#after-installing) · [Using the desktop](#using-the-desktop) · [What is in it](#what-is-in-it) · [Keys](#keys) · [Customising](#customising) · [Status](#status) · [Layout](#layout) · [Credits](#credits)

## Philosophy

- **Bar-centred.** A floating bar, 30 px tall, centred, 50 % of the screen wide. Everything else is built around it.
- **Minimal.** Square corners, no blur, no transparency, no file icons, no idle daemon, no lock screen, no notification daemon.
- **One palette.** [wallust](https://codeberg.org/explosion-mental/wallust) makes it from the wallpaper; the compositor, foot, yazi, Vis, GTK and Ly follow. Nothing is hand-coloured.
- **musl-aware.** Void's repository first, then a source build into your home, then Flatpak. Prebuilt glibc binaries are never downloaded.
- **Safe.** Idempotent installer, backups of anything replaced, a `verify` step, and it **never touches your user groups**.
- **Light.** Target: about 1 GB of RAM at idle *(not measured yet)*.

---

## Install

> [!NOTE]
> Start from a finished Void **musl** install with Wi-Fi working. Your user needs the groups `wheel audio video network` (set by `void-installer`; this project never changes them).

```sh
sudo xbps-install -Syu
sudo xbps-install -y git
git clone https://github.com/nalobtw/lilith-dotfiles ~/lilith-dotfiles
cd ~/lilith-dotfiles
sh lilith-rice packages      # optional pre-flight: do all package names exist?
sh lilith-rice install       # everything except the network switch
lilith-rice network          # LAST: Wi-Fi moves to NetworkManager; then run nmtui
reboot
```

<details>
<summary><b>Why <code>sh lilith-rice</code> the first time?</b></summary>

Files uploaded through GitHub's website lose their executable flag, so `./lilith-rice` can say *Permission denied*. The install links the command into `~/.local/bin`; afterwards `lilith-rice <command>` works from anywhere. To make the flag stick: `git add --chmod=+x lilith-rice bin/* && git commit && git push`.
</details>

<details>
<summary><b>All installer commands</b></summary>

| Command | Does |
|---|---|
| `install` | everything below in order, then `verify` |
| `deps` `services` `bluetooth` | packages, runit services, rfkill |
| `fonts` `wallpapers` `cursors` `icons` | fonts, the wallpaper, every Catppuccin cursor, Pixora + Papirus |
| `wallust` `source` `config` `build` `select` | palette tool, lilith source, dotfiles + `/etc`, compositor, crosshair selector |
| `ly` `files` `shell` `browsers` `flatpak` | login screen, yazi, zsh, Librewolf + Firefox, Flatpak + Bazaar |
| `media` `toys` `dev` | terminal media apps, terminal toys, Vis and its tools |
| `theme` `verify` `update` `packages` | regenerate theme, check everything, update, check package names |
| `network` | **never part of `install`**: WPA supplicant → NetworkManager |

`DRY=1 lilith-rice <command>` prints every root command instead of running it. Every step is documented in [docs/WHAT-IT-DOES.md](docs/WHAT-IT-DOES.md).
</details>

## After installing

1. **Reboot**, then at the **Ly** login screen choose **lilith**. (tty1 also starts the desktop by itself as a fallback.)
2. Press **`Super+/`** for the key cheatsheet.
3. Run `lilith-rice verify 2>&1 | grep -E "FAIL|warn"`. Every line carries a hint.
4. **Open Vis once** (`Super+T`): [vis-plug](https://github.com/erf/vis-plug) clones the plugins on first start. Wait a few seconds, restart it, check `:plug-list`.
5. Pick your look: wallpaper `Super+Shift+W`, font `Super+Shift+T`, cursor `Super+Shift+C`, icons `Super+Shift+I`.
6. Scale, font, colours and wallpaper are compiled into the compositor: after changing them, `lilith-theme` rebuilds, then restart the session (`Super+Shift+Q`).

## Using the desktop

| | |
|---|---|
| **Windows** | An infinite canvas. `Super+Tab` focuses the next window and centres it, `Super+W/A/S/D` moves focus, `Super+Z` zooms out to see everything, `Super+Home` returns home. Drag with `Super` + left button to move, right button to resize. |
| **Workspaces (tags)** | `Super+1…9` view a tag, `Super+Shift+1…9` send the window there, `Super+0` shows all. |
| **Launch** | `Super+R` launcher (real apps only, Flatpak included), `Super+V` clipboard history. |
| **Capture** | `Print` / `Shift+Print` screenshot area / screen → `~/Pictures/screenshots`. `Super+Print` / `Super+Shift+Print` record area / screen → `~/Videos/recordings`; press again to stop (a red **REC** shows in the bar). |
| **Network** | `Super+N` Wi-Fi, `Super+Shift+N` Bluetooth. |
| **Leave** | `Super+Escape` power menu: exit, suspend, reboot, poweroff. Closing the lid suspends. |
| **Notes** | `notes` in the terminal opens Vis in `~/Notes`. |

---

## What is in it

### Desktop
| Part | What |
|---|---|
| Compositor | [lilith](https://github.com/ohto121/lilith) with ceapeapea's animation and border presets, plus one patch (bar modules, per-device scrolling) |
| Bar | `lilith` · tags · focused window (`desktop` if none) · REC badge ⟶ volume · brightness · battery · date `Nov 17 18:22:24` |
| Menus | launcher, clipboard, cheatsheet, font, wallpaper, cursor, icons, Wi-Fi, Bluetooth, power (wmenu for now, see [Status](#status)) |
| Login | Ly on tty2, the wallpaper as its background |
| Input | touchpad: natural scroll, tap, 1/2/3-finger click; mouse: flat acceleration; layout `gb` |
| Scale | 1.0 · 1.25 · 1.33 (1.25 suggested for the 1440p panel) |

### Apps
| Job | App | Install |
|---|---|---|
| Browsers | **Librewolf** (main), **Firefox** | third-party xbps repo · xbps |
| Terminal · shell | **foot** · **zsh** (autosuggestions, autopair, fzf, zoxide, atuin, thefuck, you-should-use, syntax highlighting) · **pfetch** | xbps · git |
| Files | **yazi** with 17 plugins, drive mounting | xbps · `ya pkg` |
| Editor | **Vis** + 11 plugins, 5 languages (below) | xbps · vis-plug |
| Audio · music | **pipemixer** · **drift** | xbps / git build |
| Video · anime | **mpv** · **ani-cli** · **MovieBox-Tui** | xbps · git · cargo |
| Images · store | **rimg** · **Bazaar** (Flatpak) | git build · Flatpak |
| Toys | cowsay · pipes-rs · peaclock · lavat · unimatrix · csakura · genact · ascii-splash | xbps / cargo / git / npm |

### Vis: language support
| Language | Server | Formatter (`=`) | Linter |
|---|---|---|---|
| C / C++ | clangd | clang-format | clang-tidy (inside clangd) |
| Rust | rust-analyzer | rustfmt | Clippy |
| Lua | lua-language-server | StyLua | the server |
| Bash *(not zsh)* | bash-language-server (runs ShellCheck) | shfmt | ShellCheck |
| Python | basedpyright | Black | Ruff (`:lint`, `:fix`) |

Plugins: vis-plug · vis-lspc · vis-format · vis-lint · vis-quickfix · vis-fzf-open · vis-autoclose · vis-commentary · vis-surround · vis-colorizer · vis-modal (the status line). Run `vis` with no file for the fzf picker, `vis file` to open directly; `Ctrl-p` opens the picker inside Vis; `:help` is the key reference.

### Look
| | |
|---|---|
| Fonts | **Gallant Raster Term** (main) · JetBrains Mono · emoji: SerenityOS Emoji, Mona Color Emoji, Noto Color Emoji · fallbacks: Noto Sans / Serif / Sans Mono / Symbols / Symbols 2 / Math / Music / CJK, GNU Unifont · Symbols Nerd Font for the bar icons |
| Icons | **Pixora** (main) · Papirus |
| Cursors | every Catppuccin cursor; default **mocha rosewater** |
| Wallpaper | *The Voyage of Life: Old Age* (Thomas Cole), `~/Pictures/Wallpapers/The-Voyage-of-Life-Old-Age.png` |

### The machine
`thinkpad_acpi` is loaded at boot; **TLP** is configured in `/etc/tlp.conf` (battery charges between 75 % and 80 %, USB autosuspend off so the mouse dongle never sleeps); elogind handles lid and power button; PipeWire per the Void handbook; Intel microcode from the nonfree repo.

---

## Keys

`Super` is the main key. All original lilith bindings are kept; these are the ones this rice adds or changes. `Super+/` shows all of them.

| Key | Action | Key | Action |
|---|---|---|---|
| `Super+Q` / `Enter` | terminal | `Super+R` | launcher |
| `Super+F` / `Alt+F` | Librewolf / Firefox | `Super+V` | clipboard |
| `Super+E` | yazi | `Super+T` | Vis |
| `Super+M` | drift | `Super+Shift+M` | pipemixer |
| `Super+Shift+A` | Bazaar | `Super+Escape` | power menu |
| `Super+/` | key cheatsheet | `Super+N` / `Shift+N` | Wi-Fi / Bluetooth |
| `Super+Shift+T` | font | `Super+Shift+W` | wallpaper |
| `Super+Shift+C` | cursor | `Super+Shift+I` | icon theme |
| `Print` / `Shift+Print` | screenshot area / screen | `Super+Print` / `+Shift` | record area / screen |

Volume and brightness keys work as usual and are remembered across reboots.

## Customising

| Change | Edit | Then |
|---|---|---|
| Scale, font, wallpaper, cursor, icons | `~/.config/lilith-rice/settings.conf` or the pickers | `lilith-theme`, restart session |
| Colours | change the wallpaper (`lilith-wall <image>`) | `lilith-theme` |
| Bar | `lilith/config/config_bar.h` | `lilith-rice build`, restart session |
| Keys, touchpad, mouse | `lilith/config/config_keys.h`, `config_input.h` | same |
| Vis | `config/vis/visrc.lua`, `config/vis/lilith/*.lua` | restart vis |
| Packages | `packages/*.txt` | `lilith-rice <command>` |

---

## Status

> [!IMPORTANT]
> Everything was written and tested with stand-ins (scripts, config syntax, installer steps with fakes, the patch, the C headers). **The real desktop has not been confirmed on the laptop yet.**

**Not done yet** — see [docs/ROADMAP.md](docs/ROADMAP.md):
- Native bar menus at exactly the bar's width, sitting on the bar (today menus use wmenu across the whole bottom edge), and the authenticator menu.
- vis-quickfix wiring (`:make`, `:cex`, `:grep` with ripgrep, `[q` / `]q`), and clang-tidy / Clippy as project-wide checks.
- Instant colour / scale / font / wallpaper changes; recolouring Ly; idle RAM measurement; screenshots.

## Layout

```
lilith-rice          the installer           lib/apps.sh     app installers (xbps → source → Flatpak)
bin/                 session, status, menu, theme, wall, level, shot, record, ly-bg, pfetch
lilith/              compositor config, presets and the patch
tools/lilith-select/ crosshair area selector (C)
config/              foot · zsh · yazi · vis · clangd · fontconfig · mpv · udiskie · wallust · portals
system/etc/          elogind, modules-load (thinkpad_acpi)
packages/            package and plugin lists      theme/   settings.conf, colors.conf
docs/                WHAT-IT-DOES.md · ROADMAP.md
```

## Credits

[**@ohto121**](https://github.com/ohto121) — lilith · [**@ceapeapea**](https://github.com/ceapeapea) — lilith-dotfiles and vxwm-dotfiles, the design this rice follows · `bin/pfetch` is [pfetch](https://github.com/dylanaraps/pfetch) by Dylan Araps (MIT, lightly modified, see `licenses/`). Files under `lilith/` derive from lilith's configuration and keep its licences; the rest is MIT.

<sub>Hosted on GitHub for now; Codeberg is the preferred home if it ever moves.</sub>

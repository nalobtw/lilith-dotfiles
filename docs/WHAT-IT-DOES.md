# What `lilith-rice` does, exactly

Everything the installer touches, in the order it happens. Nothing else on your system is changed.

- Run it as your **normal user**. It uses `sudo` (or `doas`) only for steps marked **root**.
- **It never adds or removes user groups.** Your groups stay exactly as the Void installer set them.
- First time: `sh lilith-rice <command>` (a GitHub upload can drop the executable flag). Afterwards `lilith-rice <command>` works from any directory.
- `DRY=1 lilith-rice <command>` prints every root command instead of running it. Steps that only touch your home still run.
- Every step is safe to repeat. A file it replaces is first moved to `~/.config-backup/<time>/`.
- Downloads time out instead of hanging (20 s to connect, stalled git transfers abort).
- Target: **Void musl**. Prebuilt glibc binaries are never downloaded.

## The install order

`lilith-rice install` runs these steps, then `verify`. Steps marked *soft* only warn when they fail; the install continues.

| # | Step | | # | Step | |
|---|---|---|---|---|---|
| 1 | `deps` | | 10 | `ly` | soft |
| 2 | `services` | | 11 | `select` | soft |
| 3 | `bluetooth` | | 12 | `files` | soft |
| 4 | `fonts` | soft | 13 | `shell` | soft |
| 5 | `wallpapers` | soft | 14 | `browsers` | soft |
| 6 | `wallust` | soft | 15 | `flatpak` | soft |
| 7 | `source` | | 16 | `media` `toys` `dev` | soft |
| 8 | `config` | | 17 | `cursors` `icons` | soft |
| 9 | `build` | | | | |

`network` is deliberately **not** part of `install` (see the end).

## 1 to 9: the desktop itself

### 1. `deps`: packages
1. **root** `xbps-install -Sy`, then `-Syu`: syncs and updates the whole system (Void does not support partial upgrades).
2. **root** enables **`void-repo-nonfree`** and syncs.
3. **root** installs every package in `packages/void-required.txt` **one at a time**: build tools and lilith's libraries (`wlroots0.19-devel`, wayland, libinput, xkbcommon, fcft, pixman, XWayland), the session (dbus, elogind, NetworkManager, bluez), the base desktop (foot, wmenu, doas, ImageMagick, python3, patch, wl-clipboard, cliphist, grim, slurp, wf-recorder, curl, brightnessctl), audio (PipeWire), fonts, and the X1 Carbon's graphics, firmware and power tools (`tlp`, `thermald`). Failures are listed at the end with a hint.
4. **root** installs the optional list and `intel-ucode` (rebuilds the initramfs, about a minute); failures only warn.

`lilith-rice packages` is a read-only pre-flight: it asks the Void repos whether every name in every list exists.

### 2. `services`: runit
**root** Links `dbus`, `elogind`, `bluetoothd`, `tlp`, `thermald` into `/var/service` unless already there. Nothing is disabled.

### 3. `bluetooth`
**root** `rfkill unblock bluetooth`. Nothing else.

### 4. `fonts` (into `~/.local/share/fonts/lilith`)
**Gallant Raster Term** from git tag `v0.1`; **JetBrains Mono** (SHA-256 checked); **Symbols Nerd Font** (the bar icons need it). Font files of the emoji set (SerenityOS Emoji, Mona Color Emoji) and Noto Symbols, Math and Music are copied from their git repositories (shallow clones; data only, so musl does not matter). **root** `noto-fonts-ttf` (Sans, Serif, Sans Mono), `noto-fonts-cjk`, `noto-fonts-emoji` and `unifont` from xbps (`packages/void-fonts.txt`). Space Grotesk and Terminus from earlier versions are removed. Then `fc-cache -f`. `config/fontconfig/fonts.conf` sets the fallback order.

### 5. `wallpapers`
Downloads wallhaven `g8kyj3` (*The Voyage of Life: Old Age*) as `~/Pictures/Wallpapers/The-Voyage-of-Life-Old-Age.png` (a JPG is converted with ImageMagick). Older `wallhaven-*` files are removed; images you added yourself are never touched.

### 6. `wallust`
Void's package if there is one; otherwise `rust` and `cargo` (**root**) and `cargo install --locked wallust` (a few minutes, once). Installs the config and template matching your wallust version (v2 or v3 syntax) into `~/.config/wallust`.

### 7. `source`
Clones `https://github.com/ohto121/lilith` into `~/.local/src/lilith`, or resets it to upstream. That tree is generated from this repo plus upstream; do not keep edits there.

### 8. `config`
1. **Dotfiles**: symlinks into this repo: `lilith-rice` and `bin/*` into `~/.local/bin`; foot, yazi (`yazi.toml`, `keymap.toml`, `init.lua`, `package.toml`), Vis (the whole `config/vis` folder), clangd, fontconfig, mpv, udiskie, xdg-desktop-portal; `~/.zshrc`, `~/.zprofile`.
2. **Your settings**: `settings.conf` and the neutral fallback `colors.conf` are copied only if missing. Then, once, wallust makes the real colours from the default wallpaper; if it fails nothing is overwritten.
3. **root** elogind (lid, power button, no idle); `thinkpad_acpi` loaded at boot (`/etc/modules-load.d`); **tlp** settings written straight into `/etc/tlp.conf` (governor, boost, **USB autosuspend off**, battery thresholds 75/80; the original is kept as `/etc/tlp.conf.lilith-backup`); `/etc/doas.conf` = `permit persist :wheel` (validated, old file saved); timezone `Europe/Luxembourg` and `KEYMAP="uk"` in `rc.conf`; the power-menu sudo rule (`zzz`, `reboot`, `poweroff` only, validated with `visudo`); the PipeWire/ALSA links from the Void handbook; your login shell (`usermod -s`, shell only).
4. **lilith config**: copies `lilith/config.h` and `lilith/config/*.h` into the source tree, then `lilith-theme --no-build`, which writes `theme.h`, foot's colours and font, yazi's `theme.toml`, GTK's `gtk.css` and `settings.ini` (font, cursor, icons), and the cursor setting. Vis needs no file: it uses the terminal palette, which foot gets from wallust.

### 9. `build`
Checks `wlroots-0.19`, restores stock sources, tries `lilith/patches/0001-lilith-rice.patch` (`patch -p1 -F0`: exact match only), runs `make`. If the patched build fails it rebuilds **stock** lilith and says so. Installs `~/.local/bin/lilith`.

### 9b. `select`
**root** Installs cairo-devel, then runs `make` in `tools/lilith-select` (the protocol code is generated at build time from lilith's layer-shell XML and wayland-protocols' xdg-shell XML) and installs `~/.local/bin/lilith-select`. If it does not build, it only warns and `Print` keeps using `slurp`.

## 10 to 18: login, apps and tools (`lib/apps.sh`)

Every tool follows one ladder: **xbps** (Void's repository) first; if Void musl has no package, a **source build** into your home (cargo, make, npm) or a git clone; **Flatpak** for graphical apps.

| Step | What it does |
|---|---|
| `ly` | **root** Installs Ly, writes the `lilith` Wayland session, makes the login background from the wallpaper (`lilith-ly-bg`), points Ly's `dur` animation at it (`config.lua`, or `config.ini` on older Ly; a Ly without it is left alone), disables `agetty-tty2`, enables `ly`. tty1 still starts the desktop as a fallback. |
| `files` | **root** yazi and its tools (udisks2, udiskie, polkit and its agent, rsync, exfatprogs, file, ffmpeg, poppler, jq, fd, ripgrep, fzf, zoxide, resvg); `ouch`; then `ya pkg add` for every plugin in `packages/yazi-plugins.txt` (the lock file is `package.toml`). udiskie and the polkit agent start with the session. |
| `shell` | zsh, zsh-completions, zsh-autosuggestions, atuin, thefuck from xbps (cargo for zoxide and atuin if missing); git clones of zsh-autopair, zsh-you-should-use, fast-syntax-highlighting into `~/.local/share/zsh/plugins`. |
| `browsers` | **root** Librewolf from the third-party repository [index-0/librewolf-void](https://github.com/index-0/librewolf-void) (an `/etc/xbps.d` entry; xbps asks to trust its key, `-y` accepts), and Firefox from xbps. |
| `flatpak` | **root** flatpak and the portals, then, as you (no root, no polkit): the Flathub remote and Bazaar, `--user`. |
| `media` | **root** mpv, yt-dlp, ffmpeg, aria2, meson, ninja and the PipeWire/ncurses headers (`packages/void-media.txt`); mpv from xbps; **pipemixer**, **drift**, **ani-cli**, **rimg** from xbps if packaged, else built from git (cargo, meson or make, or a single script); **MovieBox-Tui** with `cargo install moviebox-tui --locked` (its `curl | bash` installer is not used). |
| `toys` | cowsay (xbps); pipes-rs and genact (xbps or cargo); ascii-splash (npm into `~/.local`); peaclock, lavat, unimatrix, csakura (xbps if present, else built from git). |
| `dev` | **root** Vis, nodejs, npm, python3-pip; creates `~/Notes`; then for each tool Void's xbps package first (cargo, npm or pip into `~/.local` as the fallback): clangd, clang-format, clang-tidy, bear, rust-analyzer, rustfmt, Clippy, lua-language-server, StyLua, ShellCheck, shfmt, bash-language-server, basedpyright, Black, Ruff. Vis plugins are cloned by vis-plug on the first start of Vis. |
| `cursors` | Every Catppuccin cursor theme (4 flavours x 14 accents, plus dark/light where they exist) into `~/.local/share/icons`; checks the one in `settings.conf`. |
| `icons` | **Pixora** (plain variant only, not Dark or Accent) cloned from its git repository; **Papirus** from xbps (`papirus-icon-theme`), git as the fallback. The one in `settings.conf` (`icons=`) is checked. |

## `verify`
Read-only. Checks commands, services, groups (read-only), files, fonts, wallust, the patch, doas, Ly, timezone, the cursor and icon theme, thinkpad_acpi, TLP thresholds, the Vis plugins, the zsh plugins, Flathub, and that **the scale you set is the one lilith was built with**. Exits non-zero on problems.

## `lilith-rice network` (last, on purpose)
Asks for confirmation. Then **root**: removes the `/var/service/wpa_supplicant` and `/var/service/dhcpcd` **links** (the packages stay; NetworkManager uses wpa_supplicant as its backend) and enables `NetworkManager`. Run `nmtui` to reconnect.

## The scripts it installs

| Script | Job |
|---|---|
| `lilith-session` | Starts lilith in a D-Bus session: `lilith-status \| lilith`. Sets the cursor (`XCURSOR_THEME`, `XCURSOR_SIZE`) and Flatpak's app directories. Log: `~/.cache/lilith/session.log` |
| `lilith-autostart` | PipeWire, restores volume and brightness, the polkit agent, udiskie, clipboard watchers |
| `lilith-status` | Date and time with seconds (`Nov 17 18:22:24`); prefixes `REC\|` while recording (the patched bar turns that into the red badge) |
| `lilith-level` | Volume and brightness keys; remembers the values |
| `lilith-menu` | All bar-style menus (wmenu for now): apps, clip, power, font, wall, cursor, icon, wifi, bluetooth, cheat |
| `lilith-wall` | Sets the wallpaper and runs wallust (colours unchanged if wallust fails) |
| `lilith-theme` | Settings and colours to compositor, foot, yazi, GTK (font, cursor, icons), Ly; rebuilds lilith |
| `lilith-ly-bg` | Wallpaper to Ly login background |
| `lilith-shot`, `lilith-record` | Screenshots (`grim`) and recording (`wf-recorder --no-dmabuf`); the area comes from `lilith-select`, or `slurp` if that is not built; one selection at a time |
| `lilith-select` | The crosshair selector: dimmed screen, small cross cursor, lines from it, selection box, accent colour. Prints `x,y WxH`; exit 1 when cancelled |
| `pfetch` | pfetch (MIT) with four small changes: host and WM overrides, flatpak in the package count, a 16-colour palette |

## Undoing it
```sh
rm ~/.local/bin/lilith ~/.local/bin/lilith-* ~/.local/bin/pfetch
rm ~/.zshrc ~/.zprofile ~/.config/{foot/foot.ini,yazi/{yazi.toml,keymap.toml,init.lua,package.toml,theme.toml},vis,clangd/config.yaml,fontconfig/fonts.conf,mpv/mpv.conf,udiskie/config.yml}
rm -r ~/.local/share/fonts/lilith ~/.local/share/lilith-rice ~/.local/share/zsh/plugins
sudo rm /var/service/{ly,bluetoothd,tlp,thermald}; sudo ln -s /etc/sv/agetty-tty2 /var/service/     # back to a text login
sudo rm /etc/elogind/logind.conf.d/10-lilith.conf /etc/modules-load.d/thinkpad_acpi.conf /etc/sudoers.d/10-lilith-power /usr/share/wayland-sessions/lilith.desktop /etc/xbps.d/20-librewolf.conf
sudo rm /etc/pipewire/pipewire.conf.d/{10-wireplumber,20-pipewire-pulse}.conf /etc/alsa/conf.d/{50-pipewire,99-pipewire-default}.conf
```
`/etc/tlp.conf.lilith-backup` holds the original TLP file. Backups of anything replaced are in `~/.config-backup/`; `/etc/doas.conf.lilith-backup` holds your old doas file, if there was one.

## btop
Installed with the base packages (`void-optional.txt`, xbps). Run `btop`.

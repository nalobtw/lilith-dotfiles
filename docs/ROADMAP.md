# Roadmap

Legend: ✅ written and checked here (stand-ins, fakes, syntax) · 🧪 needs the laptop to confirm · ⬜ not done

## Done
- ✅ One-command installer for Void musl: dry run, backups, safe re-runs, `verify`, `packages` pre-flight, download timeouts; never touches groups
- ✅ Colours from the wallpaper (wallust) → compositor, foot, yazi, GTK, cursor; Vis follows through the terminal palette
- ✅ ceapeapea's animation and border presets unchanged; every lilith key binding kept, no conflicts (94 incl. tag keys)
- ✅ Bar order: `lilith` · tags · window title (`desktop`) · REC ⟶ volume · brightness · **battery** · date `Nov 17 18:22:24`
- ✅ Wallpaper: only *The Voyage of Life: Old Age*, saved as `The-Voyage-of-Life-Old-Age.png`
- ✅ Directories: `~/Pictures/Wallpapers`, `~/Pictures/screenshots`, `~/Videos/recordings`, `~/Notes`
- ✅ **Vis** replaces Neovim: vis-plug and 10 plugins configured in `config/vis/`; lspc (Python → basedpyright), vis-format (`=`: clang-format, rustfmt, StyLua, Black, shfmt), vis-lint (Ruff for Python; no duplicates of server diagnostics), vis-fzf-open (`vis` opens the picker), vis-modal status line
- ✅ Language tools installer: clangd, clang-format, clang-tidy, rust-analyzer, rustfmt, Clippy, lua-language-server, StyLua, ShellCheck, shfmt, bash-language-server, basedpyright, Black, Ruff (xbps first, cargo/npm/pip fallback); `config/clangd/config.yaml`
- ✅ Apps: pipemixer (replaces wiremix), ani-cli (replaces ani-cli-rs), MovieBox-Tui, rimg, genact, ascii-splash
- ✅ Fonts: Gallant, JetBrains Mono, SerenityOS / Mona / Noto emoji, Noto Sans/Serif/Mono/Symbols/Math/Music/CJK, Unifont; fallback chain in `fonts.conf` (loaded by real fontconfig)
- ✅ Icons: Pixora (main) and Papirus; icon picker `Super+Shift+I`; cursor picker unchanged; GTK gets `gtk-icon-theme-name`
- ✅ `thinkpad_acpi` loaded at boot; TLP settings written into `/etc/tlp.conf` (thresholds 75/80)
- ✅ Dependency audit: duplicates and unused packages removed (Vulkan, DejaVu, Terminus, fastfetch check, repeated build tools)
- ✅ pfetch title is `$USER@hostname`, i.e. `nalo@shitbox`

## Next, in this order
1. 🧪 **Run the install on the laptop** and send the `verify` output and logs (see README → After installing). Everything above that says ✅ is untested on real hardware: package names, plugin file layouts, font repository file names, Pixora folder layout, rimg / pipemixer / drift builds.
2. ⬜ **Native bar menus** (layer-shell client): exactly the bar's width, sitting directly on the bar, scaled with `scale` (1.0 / 1.25 / 1.33 first); power menu = the bar's exact size and position; slide-up animation later. Replaces wmenu for: launcher, cheatsheet, font, icon, cursor, Wi-Fi, Bluetooth, power. *Design together before coding.*
3. ⬜ **Authenticator menu** (masked password) for doas/sudo and later the polkit agent.
4. ⬜ **vis-quickfix** wiring: `:make`, `:cex`, `:grep` (ripgrep, stdin closed), `[q` / `]q`, clang-tidy and Clippy as project checks. Its README could not be read automatically (site blocks bots): paste it, or the contents of `~/.cache/vis-plug/plugins/vis-quickfix/`.
5. ⬜ Instant colour / scale / font / wallpaper changes (signal instead of rebuild); recolour Ly; bind the four unbound yazi plugins; measure idle RAM; README screenshots; `lilith-select` fractional scale and multi-output.
6. ⬜ xbps-src tier (build a native musl package when neither xbps nor a language manager fits). Not implemented: today the ladder is xbps → cargo/npm/pip/meson/make → Flatpak.

## Open questions from your list
- The bar spec said "right side" for `lilith · workspaces · window` and "left side" for the rest; implemented as left-to-right: first group at the left end, second group at the right end.
- **Symbols Nerd Font is kept** (not on your font list) because the bar's volume, brightness and battery icons need it.
- `genact`: the repo link you gave is FreestyleH/Genact; the install uses the crates.io `genact` (svenstaro), the well-known one. Say if you want that fork instead.

## Decided
- Void **musl**; Strata, Zen, Zed gone. GitHub is the home for now, Codeberg the likely move.
- No notification daemon, idle daemon, lock screen, seatd or acpid. Volume and brightness live in the bar.

# ======================================================================
#  apps.sh — the application installers of lilith-rice (sourced by ./lilith-rice)
# ----------------------------------------------------------------------
#  Every tool is installed the same way, in this order:
#    1. xbps (Void's own repository)                        preferred: signed, updated by xbps
#    2. a source build into your home (cargo, meson, make, npm, pip)  when Void has no musl package
#    3. Flatpak (user install)                               for graphical apps only (Bazaar)
#  Void musl cannot run glibc-only binaries, so nothing here downloads a prebuilt Linux binary
#  except where the project publishes a musl one. Uses helpers from ./lilith-rice (ok, warn, bad,
#  step, run_root, install_packages, soft, fetch, backup_then, link).
# ======================================================================

have() { command -v "$1" >/dev/null 2>&1; }
LOCAL_BIN="$HOME/.local/bin"
SRC_DIR="$HOME/.local/src"
ZSH_PLUGINS="$HOME/.local/share/zsh/plugins"

# ---------------------------------------------------------------- build helpers (step 2 of the ladder)
# via_cargo <crate> <binary>: build from crates.io (a few minutes), link into ~/.local/bin.
via_cargo() {
	have cargo || install_packages "$RICE_HOME/packages/void-rust.txt" required >/dev/null 2>&1
	have cargo || return 1
	cargo install --locked "$1" >"${TMPDIR:-/tmp}/cargo-$1.log" 2>&1 || return 1
	ln -sf "$HOME/.cargo/bin/$2" "$LOCAL_BIN/$2"
}

# via_npm <package> <binary>: install a Node tool into ~/.local (no root, no global prefix).
via_npm() {
	have npm || return 1
	npm install -g --prefix "$HOME/.local" --fetch-retries=1 --fetch-timeout=30000 "$1" >"${TMPDIR:-/tmp}/npm-$1.log" 2>&1 && have "$2"
}

# via_git <url> <binary>: clone, then build with whatever the project uses.
#   Cargo.toml -> cargo install --path .   meson.build -> meson + ninja   Makefile -> make   a single script named <binary> -> copy
via_git() {
	url=$1; bin=$2; dir="$SRC_DIR/$(basename "$url" .git)"
	mkdir -p "$SRC_DIR"
	if [ -d "$dir/.git" ]; then git -C "$dir" pull -q --ff-only 2>/dev/null; else git clone -q --depth 1 "$url" "$dir" 2>/dev/null || return 1; fi
	log="${TMPDIR:-/tmp}/build-$bin.log"
	if [ -f "$dir/Cargo.toml" ]; then
		have cargo || install_packages "$RICE_HOME/packages/void-rust.txt" required >/dev/null 2>&1
		( cd "$dir" && cargo install --locked --path . >"$log" 2>&1 ) || return 1
		found="$HOME/.cargo/bin/$bin"
	elif [ -f "$dir/meson.build" ]; then
		( cd "$dir" && meson setup --wipe build >"$log" 2>&1 || meson setup build >"$log" 2>&1; ninja -C build >>"$log" 2>&1 ) || return 1
		found=$(find "$dir/build" -maxdepth 2 -type f -perm -u+x -name "$bin" 2>/dev/null | head -n1)
	elif [ -f "$dir/Makefile" ] || [ -f "$dir/makefile" ]; then
		( cd "$dir" && make >"$log" 2>&1 ) || return 1
		found=$(find "$dir" -maxdepth 3 -type f -perm -u+x -name "$bin" 2>/dev/null | head -n1)
	else
		found=$(find "$dir" -maxdepth 3 -type f \( -name "$bin" -o -name "$bin.py" \) 2>/dev/null | head -n1)
		[ -n "$found" ] && chmod +x "$found"
	fi
	[ -n "${found:-}" ] && [ -f "$found" ] && install -Dm755 "$found" "$LOCAL_BIN/$bin"
}

# get_tool <command> <xbps-package> [fallback-function args...]
get_tool() {
	cmd=$1; pkg=$2; shift 2
	if have "$cmd"; then ok "$cmd"; return 0; fi
	if [ -n "$pkg" ] && xbps-query -R "$pkg" >/dev/null 2>&1 && run_root xbps-install -y "$pkg" >/dev/null 2>&1; then
		ok "$cmd (xbps: $pkg)"; return 0
	fi
	if [ $# -gt 0 ] && "$@"; then ok "$cmd (built: $1)"; return 0; fi
	warn "$cmd: not in the Void repos and the fallback failed"
	return 1
}

# get_tool_any <command> <xbps-package>...: the first package that exists in the Void repos wins
get_tool_any() {
	cmd=$1; shift
	if have "$cmd"; then ok "$cmd"; return 0; fi
	for pkg in "$@"; do
		if xbps-query -R "$pkg" >/dev/null 2>&1 && run_root xbps-install -y "$pkg" >/dev/null 2>&1 && have "$cmd"; then
			ok "$cmd (xbps: $pkg)"; return 0
		fi
	done
	warn "$cmd: none of these Void packages provides it: $*"
	return 1
}

# via_pip <package> <binary>: Python tool into ~/.local (no root)
via_pip() {
	have python3 || return 1
	python3 -m pip install --user --break-system-packages "$1" >"${TMPDIR:-/tmp}/pip-$1.log" 2>&1 && have "$2"
}

# ---------------------------------------------------------------- shell: zsh and its plugins
cmd_shell() {
	step "Shell (zsh and plugins)"
	install_packages "$RICE_HOME/packages/void-shell.txt" optional
	get_tool zoxide zoxide via_cargo zoxide zoxide || true
	get_tool atuin atuin via_cargo atuin atuin || true
	get_tool thefuck thefuck || warn "thefuck: not in the Void repos; try: pipx install thefuck"
	# plugins that Void does not package: plain git clones (the standard way to install zsh plugins)
	mkdir -p "$ZSH_PLUGINS"
	for pair in \
	  "zsh-autopair https://github.com/hlissner/zsh-autopair" \
	  "zsh-you-should-use https://github.com/MichaelAquillina/zsh-you-should-use" \
	  "fast-syntax-highlighting https://github.com/zdharma-continuum/fast-syntax-highlighting"; do
		set -- $pair
		if [ -d "$ZSH_PLUGINS/$1/.git" ]; then git -C "$ZSH_PLUGINS/$1" pull -q --ff-only 2>/dev/null; ok "$1 (updated)"
		elif git clone -q --depth 1 "$2" "$ZSH_PLUGINS/$1" 2>/dev/null; then ok "$1"
		else bad "could not clone $2"; fi
	done
}

# ---------------------------------------------------------------- files: yazi, drives, plugins
cmd_files() {
	step "Files (yazi, drives, previews, plugins)"
	install_packages "$RICE_HOME/packages/void-files.txt" required
	get_tool ouch "" via_cargo ouch ouch || true
	# udisks2 is started by D-Bus on demand; udiskie mounts drives you plug in; polkit lets a user
	# mount them. The polkit agent and udiskie are started by lilith-autostart.
	if [ -e /var/service/dbus ]; then ok "dbus is running"; else warn "dbus service is not enabled (lilith-rice services)"; fi
	if have ya; then
		mkdir -p "$CONF/yazi"
		for spec in $(list_items "$RICE_HOME/packages/yazi-plugins.txt"); do
			if grep -q "$spec" "$CONF/yazi/package.toml" 2>/dev/null; then ok "yazi plugin $spec"
			elif ya pkg add "$spec" >/dev/null 2>&1; then ok "yazi plugin $spec"
			else warn "yazi plugin $spec could not be added (run: ya pkg add $spec)"; fi
		done
	else
		bad "yazi is not installed (lilith-rice packages)"
	fi
	echo "  drives: find a USB disk's filesystem with  lsblk -f ;  mount, unmount and eject with M in yazi"
}

# ---------------------------------------------------------------- browsers
cmd_browsers() {
	step "Browsers (Librewolf main, Firefox fallback)"
	conf=/etc/xbps.d/20-librewolf.conf
	repo="repository=https://github.com/index-0/librewolf-void/releases/latest/download/"
	if have librewolf; then
		ok "librewolf (already installed)"
	else
		tmp=$(mktemp); printf '%s\n' "$repo" > "$tmp"
		run_root install -Dm644 "$tmp" "$conf"; rm -f "$tmp"
		warn "adding a third-party repository (index-0/librewolf-void): xbps asks to trust its key; -y accepts it"
		if run_root xbps-install -Suy librewolf >/dev/null 2>&1; then ok "librewolf (index-0/librewolf-void repository)"
		else bad "librewolf could not be installed from the index-0 repository"; fi
	fi
	get_tool firefox firefox || true
}

# ---------------------------------------------------------------- flatpak + flathub + bazaar
cmd_flatpak() {
	step "Flatpak, Flathub and Bazaar"
	install_packages "$RICE_HOME/packages/void-apps.txt" optional
	have flatpak || { bad "flatpak is not installed (lilith-rice packages)"; return; }
	# --user: no root and no polkit; apps live in ~/.local/share/flatpak
	if flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1; then
		ok "Flathub remote (user)"
	else
		bad "could not add Flathub (network?)"; return
	fi
	if flatpak --user info io.github.kolunmi.Bazaar >/dev/null 2>&1; then ok "Bazaar (already installed)"
	elif flatpak --user install -y flathub io.github.kolunmi.Bazaar >/dev/null 2>&1; then ok "Bazaar (Flathub)"
	else warn "Bazaar could not be installed (run: flatpak --user install flathub io.github.kolunmi.Bazaar)"; fi
}

# ---------------------------------------------------------------- media: mpv, drift, pipemixer, ani-cli, MovieBox-Tui, rimg
cmd_media() {
	step "Media (mpv, drift, pipemixer, ani-cli, MovieBox-Tui, rimg)"
	install_packages "$RICE_HOME/packages/void-media.txt" optional
	get_tool mpv mpv || true
	get_tool drift "" via_git https://github.com/socatlolmeow/drift drift || true
	get_tool pipemixer pipemixer via_git https://github.com/heather7283/pipemixer pipemixer || true
	get_tool ani-cli ani-cli via_git https://github.com/pystardust/ani-cli ani-cli || true
	get_tool moviebox-tui "" via_cargo moviebox-tui moviebox-tui || true
	get_tool rimg "" via_git https://github.com/psic4t/rimg rimg || true
}

# ---------------------------------------------------------------- terminal toys
cmd_toys() {
	step "Terminal toys"
	get_tool cowsay cowsay || true
	get_tool pipes-rs pipes-rs via_cargo pipes-rs pipes-rs || true
	get_tool peaclock peaclock via_git https://github.com/octobanana/peaclock peaclock || true
	get_tool lavat "" via_git https://github.com/AngelJumbo/lavat lavat || true
	get_tool unimatrix "" via_git https://github.com/will8211/unimatrix unimatrix || true
	get_tool csakura "" via_git https://github.com/realstrawhat/csakura csakura || true
	get_tool genact genact via_cargo genact genact || true
	get_tool ascii-splash "" via_npm ascii-splash ascii-splash || true
}

# ---------------------------------------------------------------- development: Vis and its tools
# Order for every tool: Void xbps (musl) first, then cargo / npm / pip into ~/.local. Nothing here
# downloads a prebuilt glibc binary. Vis plugins are cloned by vis-plug itself on the first start.
cmd_dev() {
	step "Development (Vis, language servers, formatters, linters)"
	install_packages "$RICE_HOME/packages/void-dev.txt" optional
	mkdir -p "$HOME/Notes" && ok "~/Notes (notes you write with Vis)"
	if have vis; then
		ver=$(vis -v 2>/dev/null | sed -n 's/^vis \([0-9][0-9.]*\).*/\1/p' | head -n1)
		case "${ver:-0}" in 0.9*|0.[1-9][0-9]*|[1-9]*) ok "vis ${ver} (0.9 or newer)" ;; *) warn "vis ${ver:-unknown}: 0.9 or newer is needed for vis-lspc" ;; esac
	else
		bad "vis is not installed (lilith-rice packages)"
	fi
	# C / C++
	get_tool_any clangd clang-tools-extra clang || true
	get_tool_any clang-format clang-tools-extra clang || true
	get_tool_any clang-tidy clang-tools-extra clang || true
	get_tool bear bear || true
	# Rust
	get_tool rust-analyzer rust-analyzer || true
	get_tool_any rustfmt rustfmt rust || true
	get_tool_any cargo-clippy rust-clippy clippy rust || true
	# Lua
	get_tool lua-language-server lua-language-server || true
	get_tool stylua stylua via_cargo stylua stylua || true
	# Bash (not zsh)
	get_tool shellcheck shellcheck || true
	get_tool shfmt shfmt || true
	get_tool bash-language-server bash-language-server via_npm bash-language-server bash-language-server || true
	# Python
	get_tool basedpyright-langserver "" via_npm basedpyright basedpyright-langserver || true
	get_tool black python3-black via_pip black black || true
	get_tool ruff ruff via_pip ruff ruff || true
	# Vis plugins arrive with the first start of vis (vis-plug clones them with git)
	if [ -d "$HOME/.cache/vis-plug/plugins" ] && [ -n "$(ls "$HOME/.cache/vis-plug/plugins" 2>/dev/null)" ]; then
		ok "Vis plugins: $(ls "$HOME/.cache/vis-plug/plugins" | tr '\n' ' ')"
	else
		warn "Vis plugins are not cloned yet: start vis once (Super+T), wait a few seconds, restart it, then :plug-list"
	fi
}

# ---------------------------------------------------------------- the crosshair area selector
# Built from tools/lilith-select (C, cairo + Wayland layer-shell). Without it, Print uses slurp.
cmd_select() {
	step "Crosshair area selector (lilith-select)"
	install_packages "$RICE_HOME/packages/void-select.txt" required
	have wayland-scanner || { bad "wayland-scanner is missing (package: wayland-devel)"; return; }
	src="$LILITH_SRC/protocols/wlr-layer-shell-unstable-v1.xml"
	[ -f "$src" ] || { bad "lilith's source is missing ($src): run lilith-rice source"; return; }
	log="${TMPDIR:-/tmp}/lilith-select-build.log"
	if make -C "$RICE_HOME/tools/lilith-select" WLR_XML="$src" >"$log" 2>&1; then
		install -Dm755 "$RICE_HOME/tools/lilith-select/lilith-select" "$LOCAL_BIN/lilith-select" && ok "lilith-select installed to ~/.local/bin"
	else
		warn "lilith-select did not build; Print keeps using slurp. Build log: $log"
		tail -n 8 "$log" | sed 's/^/        /'
	fi
}

# ---------------------------------------------------------------- Catppuccin cursors (all of them)
cmd_cursors() {
	step "Catppuccin cursors (every flavour and accent)"
	have unzip && have curl || { bad "curl and unzip are needed"; return; }
	icons="$HOME/.local/share/icons"; mkdir -p "$icons"
	tmp=$(mktemp -d); got=0; have_n=0
	for flavour in latte frappe macchiato mocha; do
		for accent in rosewater flamingo pink mauve red maroon peach yellow green teal sky sapphire blue lavender dark light; do
			name="catppuccin-$flavour-$accent-cursors"
			[ -d "$icons/$name" ] && { have_n=$((have_n + 1)); continue; }
			if curl -fsSL --connect-timeout 20 --max-time 120 -o "$tmp/$name.zip" "https://github.com/catppuccin/cursors/releases/latest/download/$name.zip" 2>/dev/null \
			   && unzip -q -o "$tmp/$name.zip" -d "$icons" 2>/dev/null; then got=$((got + 1)); fi
		done
	done
	rm -rf "$tmp"
	total=$((got + have_n))
	if [ "$total" -gt 0 ]; then ok "$total Catppuccin cursor themes in ~/.local/share/icons ($got new)"; else bad "no cursor theme could be downloaded"; fi
	chosen=$(sed -n 's/^cursor="\(.*\)"$/\1/p' "$CONF/lilith-rice/settings.conf" 2>/dev/null | head -n1)
	[ -d "$icons/${chosen:-catppuccin-mocha-rosewater-cursors}" ] && ok "cursor in use: ${chosen:-catppuccin-mocha-rosewater-cursors} (24 px)" \
		|| warn "the cursor set in settings.conf is not installed"
}

# ---------------------------------------------------------------- icon themes: Pixora (main) and Papirus (second)
# Pixora: the plain theme only (not the -Dark or -Accent variants), copied from its git repository.
# Papirus: Void's package first, the upstream git repository as the fallback.
# copy_icon_dirs <repo dir> <name-pattern>: copy every theme folder (has index.theme) whose name matches.
copy_icon_dirs() {
	n=0
	find "$1" -maxdepth 2 -name index.theme -not -path '*/.git/*' 2>/dev/null > "$1/.themes"
	while read -r idx; do
		d=$(dirname "$idx"); name=$(basename "$d")
		case "$name" in $2) rm -rf "$HOME/.local/share/icons/$name"; cp -r "$d" "$HOME/.local/share/icons/$name" && n=$((n + 1)) ;; esac
	done < "$1/.themes"
	[ "$n" -gt 0 ]
}

cmd_icons() {
	step "Icon themes (Pixora main, Papirus second)"
	icons="$HOME/.local/share/icons"; mkdir -p "$icons"
	have git || { bad "git is needed"; return; }
	if [ -f "$icons/Pixora/index.theme" ]; then ok "Pixora (already installed)"
	else
		tmp=$(mktemp -d)
		if git clone -q --depth 1 https://github.com/tsora1603/pixora-icons "$tmp/pixora" 2>/dev/null; then
			if copy_icon_dirs "$tmp/pixora" "Pixora"; then ok "Pixora (plain variant)"
			elif [ -f "$tmp/pixora/index.theme" ] && rm -rf "$icons/Pixora" && mkdir -p "$icons/Pixora" \
			     && cp -r "$tmp/pixora/." "$icons/Pixora/" && rm -rf "$icons/Pixora/.git"; then ok "Pixora (whole repository is the theme)"
			else warn "Pixora: no theme folder called Pixora found in the repository (look at: $tmp/pixora)"; tmp=""; fi
		else
			bad "could not clone the Pixora repository (network?)"
		fi
		[ -n "$tmp" ] && rm -rf "$tmp"
	fi
	install_packages "$RICE_HOME/packages/void-icons.txt" optional
	if [ -f /usr/share/icons/Papirus/index.theme ] || [ -f "$icons/Papirus/index.theme" ]; then ok "Papirus"
	else
		tmp=$(mktemp -d)
		if git clone -q --depth 1 https://github.com/PapirusDevelopmentTeam/papirus-icon-theme "$tmp/papirus" 2>/dev/null \
		   && copy_icon_dirs "$tmp/papirus" "*Papirus*"; then ok "Papirus (from git)"
		else warn "Papirus could not be installed"; fi
		rm -rf "$tmp"
	fi
	chosen=$(sed -n 's/^icons="\(.*\)"$/\1/p' "$CONF/lilith-rice/settings.conf" 2>/dev/null | head -n1)
	icon_installed "${chosen:-Pixora}" && ok "icon theme in use: ${chosen:-Pixora}" || warn "the icon theme set in settings.conf is not installed"
}

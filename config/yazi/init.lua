-- ======================================================================
--  init.lua — yazi: plugin setup
-- ----------------------------------------------------------------------
--  Lives at ~/.config/yazi/init.lua (symlink to this file).
-- ======================================================================

-- git status next to files and folders (fetchers are in yazi.toml)
require("git"):setup()

-- bunny: press ' then the key to jump to a bookmark (fuzzy search with fzf)
require("bunny"):setup({
	hops = {
		{ key = "h", path = "~",                     desc = "Home" },
		{ key = "d", path = "~/Downloads",           desc = "Downloads" },
		{ key = "p", path = "~/Pictures",            desc = "Pictures" },
		{ key = "w", path = "~/Pictures/Wallpapers", desc = "Wallpapers" },
		{ key = "s", path = "~/Pictures/screenshots", desc = "Screenshots" },
		{ key = "e", path = "~/Videos/recordings",   desc = "Recordings" },
		{ key = "n", path = "~/Notes",               desc = "Notes" },
		{ key = "v", path = "~/Videos",              desc = "Videos" },
		{ key = "c", path = "~/.config",             desc = "Config" },
		{ key = "r", path = "~/lilith-dotfiles",     desc = "lilith-dotfiles" },
		{ key = "m", path = "/run/media",            desc = "Mounted drives" },
		{ key = "/", path = "/",                     desc = "Root" },
	},
	desc_strategy = "path",
	ephemeral = true,
	tabs = true,
	notify = false,
	fuzzy_cmd = "fzf",
})

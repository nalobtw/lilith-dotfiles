-- ======================================================================
--  format.lua — vis-format: the one formatting interface
-- ----------------------------------------------------------------------
--  Press = in normal mode to format the whole file. One formatter per language:
--    C / C++  clang-format      Rust  rustfmt      Lua  StyLua
--    Python   Black (Ruff only lints, see lint.lua)      Bash  shfmt
--  The Bash formatter is for Bash scripts, not zsh. Restart vis after editing.
-- ======================================================================

local format = require('plugins/vis-plug').plugins.format
if not format then return end

local function clang(win)
	return 'clang-format ' .. format.with_filename(win, '--assume-filename=')
end

format.formatters.ansi_c = format.stdio_formatter(clang)
format.formatters.cpp    = format.stdio_formatter(clang)
format.formatters.rust   = format.stdio_formatter('rustfmt --emit stdout --edition 2021')
format.formatters.lua    = format.stdio_formatter('stylua -')
format.formatters.python = format.stdio_formatter('black --quiet -')
format.formatters.bash   = format.stdio_formatter(function(win)
	return 'shfmt ' .. format.with_filename(win, '--filename ') .. ' -'
end)

vis:map(vis.modes.NORMAL, '=', format.apply)

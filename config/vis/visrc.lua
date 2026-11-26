-- ======================================================================
--  visrc.lua — Vis: plugin list and the order the config modules load in
-- ----------------------------------------------------------------------
--  Lives at ~/.config/vis/visrc.lua (the whole config/vis folder is linked).
--  Plugins are cloned by vis-plug (git) into ~/.cache/vis-plug/plugins on the FIRST start of
--  vis (needs the network once); open vis, wait a few seconds, then restart it. See :plug-list.
--  Settings live in lilith/*.lua, one topic per file. Colours follow wallust through the
--  terminal palette (lilith-theme recolours foot live), so no colour is set here.
-- ======================================================================

-- vis-plug itself: cloned once by hand, as its README describes
local plug_path = (os.getenv('XDG_CONFIG_HOME') or os.getenv('HOME') .. '/.config') .. '/vis/plugins/vis-plug'
if not pcall(require, 'plugins/vis-plug') then
	os.execute('git clone --quiet https://github.com/erf/vis-plug "' .. plug_path .. '"')
end
local plug = require('plugins/vis-plug')

plug.init({
	{ 'https://codeberg.org/muhq/vis-lspc',        alias = 'lspc' },      -- language servers
	{ 'https://github.com/milhnl/vis-format',      alias = 'format' },    -- formatting (=)
	{ 'https://github.com/rnpnr/vis-lint',         alias = 'lint' },      -- :lint and :fix
	{ 'https://repo.or.cz/vis-quickfix.git',       alias = 'quickfix' },  -- :make, :cex, :grep
	{ 'https://codefloe.com/mcepl/vis-fzf-open',   alias = 'fzf' },       -- :fzf file picker
	{ 'https://codeberg.org/luxanna/vis-autoclose', alias = 'autoclose' },
	{ 'https://github.com/Nomarian/vis-commentary', alias = 'commentary' },
	{ 'https://repo.or.cz/vis-surround.git',       alias = 'surround' },
	{ 'https://github.com/thimc/vis-colorizer',    alias = 'colorizer' }, -- #rrggbb previews
	{ 'https://git.symlinx.net/vis-modal',         alias = 'modal' },     -- the status line
}, true)

-- one module per topic; each one skips itself quietly if its plugin is not installed yet
require('lilith/editor')
require('lilith/statusline')
require('lilith/lsp')
require('lilith/format')
require('lilith/lint')
require('lilith/files')

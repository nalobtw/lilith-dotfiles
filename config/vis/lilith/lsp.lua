-- ======================================================================
--  lsp.lua — vis-lspc: language servers
-- ----------------------------------------------------------------------
--  vis-lspc already maps C/C++ (clangd), Rust (rust-analyzer), Lua (lua-language-server) and
--  Bash (bash-language-server); those mappings are used as they are. Python is overridden:
--  basedpyright-langserver instead of pylsp. Servers start by themselves when a file opens.
--  Keys (vis-lspc defaults): K hover, gd definition, gr references, <Space>e / <Space>n diagnostics,
--  <C-Space> completion; commands: :lspc-rename <name>, :lspc-format, :lspc-navigate-symbols (experimental).
--  The Bash server is for Bash scripts, not zsh. Restart vis after editing.
-- ======================================================================

local lspc = require('plugins/vis-plug').plugins.lspc
if not lspc then return end

lspc.autostart = true
lspc.ls_map.python = {
	name = 'basedpyright',
	cmd = 'basedpyright-langserver --stdio',
	roots = { 'pyproject.toml', 'pyrightconfig.json', '.git' },
}

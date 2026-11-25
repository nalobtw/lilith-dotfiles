-- ======================================================================
--  files.lua — opening files: vis-fzf-open
-- ----------------------------------------------------------------------
--  :fzf searches the current directory tree (fd keeps it fast and skips .git); Enter opens the
--  file, Ctrl-s in a horizontal split, Ctrl-v in a vertical one. Ctrl-p runs :fzf.
--  Starting vis with no file opens the picker (the zsh function in config/zsh/zshrc runs
--  `vis +fzf`); with a file name it opens that file directly.
-- ======================================================================

local fzf = require('plugins/vis-plug').plugins.fzf
if not fzf then return end

fzf.fzf_path = "FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git' fzf"
fzf.fzf_args = '--height=40% --reverse'

vis.events.subscribe(vis.events.INIT, function()
	vis:command('map! normal <C-p> :fzf<Enter>')
end)

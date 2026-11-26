-- ======================================================================
--  editor.lua — basic Vis settings
-- ----------------------------------------------------------------------
--  Auto-indent copies the previous line's leading whitespace; no fixed width, no forced tabs or
--  spaces. System clipboard: vis talks to wl-clipboard by itself; use the "+ register ("+y, "+p).
--  Loaded by visrc.lua. Changes apply the next time vis starts.
-- ======================================================================

vis.events.subscribe(vis.events.INIT, function()
	vis:command('set autoindent on')
	vis:command('set numbers')       -- absolute line numbers
	vis:command('set cursorline')
	vis:command('set ignorecase')
	vis:command('set theme default') -- the stock theme uses the terminal palette = wallust
end)

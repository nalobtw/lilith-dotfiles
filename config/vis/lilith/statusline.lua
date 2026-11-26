-- ======================================================================
--  statusline.lua — vis-modal: the status line
-- ----------------------------------------------------------------------
--  vis-modal shows: mode, file name, * when unsaved, RECORDING while a macro records, then
--  selection size, cursor count and line:column. This file only sets its colours. The names
--  below are the terminal's 16 colours, which lilith-theme recolours from the wallust palette
--  (foot colors.ini and live OSC), so the bar follows the wallpaper. Reload: restart vis.
-- ======================================================================

local modal = require('plugins/vis-plug').plugins.modal
if not modal then return end

modal.STYLES = {
	[vis.modes.NORMAL]           = { REGULAR = 'fore:black,back:blue',    INVERTED = 'fore:blue,back:black' },
	[vis.modes.INSERT]           = { REGULAR = 'fore:black,back:green',   INVERTED = 'fore:green,back:black' },
	[vis.modes.VISUAL]           = { REGULAR = 'fore:black,back:magenta', INVERTED = 'fore:magenta,back:black' },
	[vis.modes.VISUAL_LINE]      = { REGULAR = 'fore:black,back:magenta', INVERTED = 'fore:magenta,back:black' },
	[vis.modes.REPLACE]          = { REGULAR = 'fore:black,back:red',     INVERTED = 'fore:red,back:black' },
	[vis.modes.OPERATOR_PENDING] = { REGULAR = 'fore:black,back:yellow',  INVERTED = 'fore:yellow,back:black' },
	UNFOCUSED                    = { REGULAR = 'fore:black,back:white',   INVERTED = 'fore:white,back:black' },
}

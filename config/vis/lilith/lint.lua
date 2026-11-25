-- ======================================================================
--  lint.lua — vis-lint: :lint and :fix for single files
-- ----------------------------------------------------------------------
--  Language servers (vis-lspc) already report diagnostics for C/C++, Rust, Lua and Bash
--  (bash-language-server runs ShellCheck itself), so those linters and fixers are emptied here
--  to avoid duplicates. Python is linted and fixed by Ruff through stdin; formatting stays with
--  Black. clang-tidy and Clippy are project-level checks (see the README, "Vis").
--  Commands: :lint   :fix
-- ======================================================================

local lint = require('plugins/vis-plug').plugins.lint
if not lint then return end

for _, syntax in ipairs({ 'ansi_c', 'cpp', 'rust', 'lua', 'bash' }) do
	lint.linters[syntax] = {}
	lint.fixers[syntax] = {}
end

lint.linters.python = { 'ruff check --quiet --output-format concise -' }
lint.fixers.python  = { 'ruff check --quiet --fix-only -' }

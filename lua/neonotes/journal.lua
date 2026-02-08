-- Journal module
-- Handles date-based journal entries with forward/backward navigation

local config = require("neonotes.config")
local git = require("neonotes.git")

local M = {}

-- Check if a filename matches the journal date format (yyyy-mm-dd.md)
-- @param filename string: The filename to check
-- @return boolean: true if it's a valid journal entry filename
local function is_journal_entry(filename)
	local extension = config.get_file_extension()
	local pattern = "^%d%d%d%d%-%d%d%-%d%d" .. extension:gsub("%.", "%%.") .. "$"
	return filename:match(pattern) ~= nil
end

-- Extract date from journal filename
-- @param filename string: The journal filename (e.g., "2025-12-31.md")
-- @return string|nil: The date portion (e.g., "2025-12-31") or nil if invalid
local function extract_date(filename)
	return filename:match("^(%d%d%d%d%-%d%d%-%d%d)")
end

-- Check if current buffer is a journal entry
-- @return boolean: true if current file is a journal entry
function M.is_current_buffer_journal()
	local filename = vim.fn.expand("%:t")
	return is_journal_entry(filename)
end

-- Get all journal entries in the current file's directory
-- @return table: Array of {filename, date} sorted by date
local function get_journal_entries_in_directory()
	local current_dir = vim.fn.expand("%:p:h")
	local entries = {}

	-- Get all files in the current directory
	local files = vim.fn.readdir(current_dir)

	for _, filename in ipairs(files) do
		if is_journal_entry(filename) then
			local date = extract_date(filename)
			if date then
				table.insert(entries, {
					filename = filename,
					date = date,
					path = current_dir .. "/" .. filename,
				})
			end
		end
	end

	-- Sort by date
	table.sort(entries, function(a, b)
		return a.date < b.date
	end)

	return entries
end

-- Find the index of the current journal entry
-- @param entries table: Array of journal entries
-- @return number|nil: Index of current entry or nil if not found
local function find_current_entry_index(entries)
	local current_file = vim.fn.expand("%:t")

	for i, entry in ipairs(entries) do
		if entry.filename == current_file then
			return i
		end
	end

	return nil
end

-- Navigate to the next journal entry
function M.next_entry()
	if not M.is_current_buffer_journal() then
		vim.notify("Not in a journal entry", vim.log.levels.WARN)
		return
	end

	local entries = get_journal_entries_in_directory()
	local current_index = find_current_entry_index(entries)

	if not current_index then
		vim.notify("Could not find current entry in journal list", vim.log.levels.ERROR)
		return
	end

	if current_index >= #entries then
		vim.notify("Already at the latest journal entry", vim.log.levels.INFO)
		return
	end

	-- Navigate to next entry
	local next_entry = entries[current_index + 1]
	vim.cmd("edit " .. vim.fn.fnameescape(next_entry.path))
	vim.notify("→ " .. next_entry.date, vim.log.levels.INFO)
end

-- Navigate to the previous journal entry
function M.previous_entry()
	if not M.is_current_buffer_journal() then
		vim.notify("Not in a journal entry", vim.log.levels.WARN)
		return
	end

	local entries = get_journal_entries_in_directory()
	local current_index = find_current_entry_index(entries)

	if not current_index then
		vim.notify("Could not find current entry in journal list", vim.log.levels.ERROR)
		return
	end

	if current_index <= 1 then
		vim.notify("Already at the earliest journal entry", vim.log.levels.INFO)
		return
	end

	-- Navigate to previous entry
	local prev_entry = entries[current_index - 1]
	vim.cmd("edit " .. vim.fn.fnameescape(prev_entry.path))
	vim.notify("← " .. prev_entry.date, vim.log.levels.INFO)
end

local function trim(str)
	return str:match("^%s*(.-)%s*$")
end

-- Get the journal directory (always vault_path/journal/)
-- @return string: Path to the journal directory
local function get_journal_dir()
	return config.get_vault_path() .. "/journal"
end

-- Find the line number of a project header (## project-name) in the current buffer
-- @param project_name string: The project name to search for
-- @return number|nil: 1-indexed line number of the header, or nil if not found
local function find_project_header(project_name)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local header = "## " .. project_name
	for i, line in ipairs(lines) do
		if line == header then
			return i
		end
	end
	return nil
end

-- Insert a project header at the end of the buffer and position cursor below it
-- @param project_name string: The project name to insert
-- @return number: 1-indexed line number of the line below the inserted header
local function insert_project_header(project_name)
	local line_count = vim.api.nvim_buf_line_count(0)
	local last_line = vim.api.nvim_buf_get_lines(0, line_count - 1, line_count, false)[1]

	-- Ensure blank line before the new header (unless buffer is empty or last line is already blank)
	local lines_to_insert = {}
	if last_line ~= "" then
		table.insert(lines_to_insert, "")
	end
	table.insert(lines_to_insert, "## " .. project_name)
	table.insert(lines_to_insert, "")

	vim.api.nvim_buf_set_lines(0, line_count, line_count, false, lines_to_insert)

	-- Return the line after the header
	return line_count + #lines_to_insert
end

-- Create or open today's journal entry
-- @param project_name string|nil: Optional project name (defaults to Git repo name)
function M.today(project_name)
	local journal_dir = get_journal_dir()
	local date = os.date("%Y-%m-%d")
	local extension = config.get_file_extension()
	local filename = date .. extension
	local filepath = journal_dir .. "/" .. filename

	-- Create directory if it doesn't exist
	if vim.fn.isdirectory(journal_dir) == 0 then
		vim.fn.mkdir(journal_dir, "p")
	end

	local file_exists = vim.fn.filereadable(filepath) == 1

	vim.cmd("edit " .. vim.fn.fnameescape(filepath))

	if not file_exists then
		-- Add date header to new journal entries
		local day_name = os.date("%A")
		local header = "# " .. date .. " " .. day_name
		vim.api.nvim_buf_set_lines(0, 0, 0, false, { header, "" })
	end

	-- Resolve project name: explicit arg > git repo > nil
	local project = project_name and project_name ~= "" and trim(project_name) or git.get_project_name()

	if project then
		local header_line = find_project_header(project)
		if header_line then
			-- Move cursor to the line below the existing project header
			vim.api.nvim_win_set_cursor(0, { header_line + 1, 0 })
			vim.notify("Journal: " .. project, vim.log.levels.INFO)
		else
			-- Insert project header and position cursor below it
			local cursor_line = insert_project_header(project)
			vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
			vim.notify("Journal: + " .. project, vim.log.levels.INFO)
		end
	end
end

return M

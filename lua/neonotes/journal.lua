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

-- Determine the project directory for journal entries
-- @param project_name string|nil: Optional project name override
-- @return string: Path to the project journal directory
local function get_project_journal_dir(project_name)
	local vault_path = config.get_vault_path()

	-- If project name is explicitly provided, use it
	if project_name and project_name ~= "" then
		return vault_path .. "/" .. trim(project_name)
	end

	-- Try to get Git repo name
	local repo_name = git.get_project_name()
	if repo_name then
		return vault_path .. "/" .. repo_name
	end

	-- Fall back to vault root
	return vault_path
end

-- Create or open today's journal entry
-- @param project_name string|nil: Optional project name (defaults to Git repo name or vault root)
function M.today(project_name)
	local journal_dir = get_project_journal_dir(project_name)
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

		local project_info = project_name or git.get_project_name() or "default"
		vim.notify("Created journal entry: " .. date .. " (" .. project_info .. ")", vim.log.levels.INFO)
	end
end

return M

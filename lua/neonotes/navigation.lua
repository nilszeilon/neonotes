-- Navigation module
-- Handles following links and opening files

local config = require("neonotes.config")
local links = require("neonotes.links")

local M = {}

-- Resolve a link to a file path
-- @param link_text string: The text of the link (e.g., "my-note")
-- @return string: Absolute path to the note file
function M.resolve_link_path(link_text)
  local vault_path = config.get_vault_path()
  local extension = config.get_file_extension()

  -- Handle links with or without extension
  local filename = link_text
  if not filename:match("%." .. extension:gsub("%.", "") .. "$") then
    filename = filename .. extension
  end

  return vault_path .. "/" .. filename
end

-- Follow the link under the cursor
-- Opens the linked file, creating it if it doesn't exist
function M.follow_link()
  local link_text = links.get_link_under_cursor()

  if not link_text then
    vim.notify("No link under cursor", vim.log.levels.WARN)
    return
  end

  local file_path = M.resolve_link_path(link_text)

  -- Check if file exists
  local file_exists = vim.fn.filereadable(file_path) == 1

  -- Open the file
  vim.cmd("edit " .. vim.fn.fnameescape(file_path))

  if not file_exists then
    vim.notify("Created new note: " .. link_text, vim.log.levels.INFO)
  end
end

-- Go back to the previous file (like browser back button)
function M.go_back()
  vim.cmd("normal! \x0f") -- Ctrl-O
end

return M

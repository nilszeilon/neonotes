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

-- Resolve a tag to its note file path (tags live under vault/tags/)
-- @param tag string: The tag name without the leading `#`
-- @return string: Absolute path to the tag note file
function M.resolve_tag_path(tag)
  local vault_path = config.get_vault_path()
  local extension = config.get_file_extension()
  return vault_path .. "/tags/" .. tag .. extension
end

-- Follow the link or tag under the cursor
-- Opens the linked file, creating it if it doesn't exist
function M.follow_link()
  local link_text = links.get_link_under_cursor()
  if link_text then
    local file_path = M.resolve_link_path(link_text)
    local file_exists = vim.fn.filereadable(file_path) == 1
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    if not file_exists then
      vim.notify("Created new note: " .. link_text, vim.log.levels.INFO)
    end
    return
  end

  local tag = links.get_tag_under_cursor()
  if tag then
    local file_path = M.resolve_tag_path(tag)
    local dir = vim.fn.fnamemodify(file_path, ":h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
    local file_exists = vim.fn.filereadable(file_path) == 1
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    if not file_exists then
      vim.notify("Created new tag note: #" .. tag, vim.log.levels.INFO)
    end
    return
  end

  vim.notify("No link or tag under cursor", vim.log.levels.WARN)
end

-- Wrap the current visual selection in [[wiki-link]] and open the note
function M.link_from_selection()
  -- Leave visual mode so the '<, '> marks are set for the last selection
  vim.cmd("normal! \27")

  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos = vim.api.nvim_buf_get_mark(0, ">")

  if start_pos[1] ~= end_pos[1] then
    vim.notify("Selection must be on a single line", vim.log.levels.WARN)
    return
  end

  local row = start_pos[1] - 1
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
  local start_col = start_pos[2]
  local end_col = math.min(end_pos[2], #line - 1)

  if end_col < start_col then
    vim.notify("Empty selection", vim.log.levels.WARN)
    return
  end

  local selected = line:sub(start_col + 1, end_col + 1)
  local trimmed = selected:match("^%s*(.-)%s*$")
  if trimmed == "" then
    vim.notify("Empty selection", vim.log.levels.WARN)
    return
  end

  local new_line = line:sub(1, start_col) .. "[[" .. trimmed .. "]]" .. line:sub(end_col + 2)
  vim.api.nvim_buf_set_lines(0, row, row + 1, false, { new_line })

  if vim.bo.modified and vim.bo.buftype == "" then
    vim.cmd("silent! write")
  end

  local file_path = M.resolve_link_path(trimmed)
  local file_exists = vim.fn.filereadable(file_path) == 1
  vim.cmd("edit " .. vim.fn.fnameescape(file_path))
  if not file_exists then
    vim.notify("Created new note: " .. trimmed, vim.log.levels.INFO)
  end
end

-- Go back to the previous file (like browser back button)
function M.go_back()
  vim.cmd("normal! \x0f") -- Ctrl-O
end

return M

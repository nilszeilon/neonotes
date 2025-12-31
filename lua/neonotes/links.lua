-- Link detection and parsing module
-- Handles finding and extracting wiki-style links [[link]]

local M = {}

-- Pattern for wiki-style links: [[note-name]]
local LINK_PATTERN = "%[%[([^%]]+)%]%]"

-- Get the link under the cursor
-- @return string|nil: The link text if found, nil otherwise
function M.get_link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- Convert to 1-indexed

  -- Find all links in the current line
  for link_text in line:gmatch(LINK_PATTERN) do
    local start_pos, end_pos = line:find("%[%[" .. link_text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "%]%]")

    if start_pos and end_pos then
      -- Check if cursor is within this link
      if col >= start_pos and col <= end_pos then
        return link_text
      end
    end
  end

  return nil
end

-- Check if the current cursor position is on a link
-- @return boolean: true if on a link, false otherwise
function M.is_on_link()
  return M.get_link_under_cursor() ~= nil
end

-- Get all links in the current buffer
-- @return table: Array of link texts found in the buffer
function M.get_all_links_in_buffer()
  local links = {}
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for _, line in ipairs(lines) do
    for link_text in line:gmatch(LINK_PATTERN) do
      table.insert(links, link_text)
    end
  end

  return links
end

return M

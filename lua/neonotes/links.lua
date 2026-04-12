-- Link detection and parsing module
-- Handles finding and extracting wiki-style links [[link]] and #tags

local M = {}

-- Pattern for wiki-style links: [[note-name]]
local LINK_PATTERN = "%[%[([^%]]+)%]%]"

-- Pattern for tags: #word (letters, digits, underscore, hyphen, slash for nesting)
local TAG_PATTERN = "#[%w_%-/]+"

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

-- Get the tag under the cursor (without the leading `#`)
-- @return string|nil: The tag name if found, nil otherwise
function M.get_tag_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- Convert to 1-indexed

  local init = 1
  while true do
    local start_pos, end_pos = line:find(TAG_PATTERN, init)
    if not start_pos then
      return nil
    end

    -- Require the `#` to not be preceded by a word char or another `#`
    -- (skips markdown headers like `## foo` and inline refs like `foo#bar`)
    local prev = start_pos > 1 and line:sub(start_pos - 1, start_pos - 1) or ""
    local boundary = prev == "" or not prev:match("[%w#]")

    if boundary and col >= start_pos and col <= end_pos then
      return line:sub(start_pos + 1, end_pos)
    end

    init = end_pos + 1
  end
end

return M

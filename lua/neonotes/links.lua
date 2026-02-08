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

return M

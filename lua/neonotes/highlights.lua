-- Lightweight highlighter for wiki-links and tags
-- Paints extmarks on markdown buffers; composes with treesitter.

local M = {}

local ns = vim.api.nvim_create_namespace("neonotes_highlights")

local WIKI_PATTERN = "%[%[[^%]]+%]%]"
local TAG_PATTERN = "#[%w_%-/]+"

local function highlight_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if vim.bo[bufnr].filetype ~= "markdown" then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local row = i - 1

    local init = 1
    while true do
      local s, e = line:find(WIKI_PATTERN, init)
      if not s then
        break
      end
      vim.api.nvim_buf_set_extmark(bufnr, ns, row, s - 1, {
        end_col = e,
        hl_group = "NeonotesWikiLink",
      })
      init = e + 1
    end

    init = 1
    while true do
      local s, e = line:find(TAG_PATTERN, init)
      if not s then
        break
      end
      local prev = s > 1 and line:sub(s - 1, s - 1) or ""
      if prev == "" or not prev:match("[%w#]") then
        vim.api.nvim_buf_set_extmark(bufnr, ns, row, s - 1, {
          end_col = e,
          hl_group = "NeonotesTag",
        })
      end
      init = e + 1
    end
  end
end

function M.setup()
  vim.api.nvim_set_hl(0, "NeonotesWikiLink", { link = "@markup.link", default = true })
  vim.api.nvim_set_hl(0, "NeonotesTag", { link = "@markup.link", default = true })

  local group = vim.api.nvim_create_augroup("NeonotesHighlights", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function(ev)
      highlight_buffer(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost", "BufWinEnter" }, {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "markdown" then
        highlight_buffer(ev.buf)
      end
    end,
  })
end

M.refresh = highlight_buffer

return M

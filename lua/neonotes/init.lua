-- Main entry point for Neonotes plugin
-- Provides the public API and setup function

local config = require("neonotes.config")
local navigation = require("neonotes.navigation")
local links = require("neonotes.links")
local journal = require("neonotes.journal")

local M = {}

-- Setup the plugin with user configuration
-- @param opts table: Configuration options
--   - vault_path: Path to the notes vault (default: ~/notes)
--   - file_extension: Extension for note files (default: .md)
function M.setup(opts)
  config.setup(opts)

  -- Set up autocommands for markdown files
  local group = vim.api.nvim_create_augroup("Neonotes", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "markdown",
    callback = function()
      -- Set up keybinding for following links (Enter key)
      vim.keymap.set("n", "<CR>", function()
        navigation.follow_link()
      end, {
        buffer = true,
        desc = "Follow link under cursor",
        silent = true,
      })

      -- Optional: Set up keybinding to go back (Backspace)
      vim.keymap.set("n", "<BS>", function()
        navigation.go_back()
      end, {
        buffer = true,
        desc = "Go back to previous file",
        silent = true,
      })

      -- Journal navigation keybindings (only when in a journal entry)
      vim.keymap.set("n", "<leader>jn", function()
        journal.next_entry()
      end, {
        buffer = true,
        desc = "Next journal entry",
        silent = true,
      })

      vim.keymap.set("n", "<leader>jp", function()
        journal.previous_entry()
      end, {
        buffer = true,
        desc = "Previous journal entry",
        silent = true,
      })

      vim.keymap.set("n", "<leader>jt", function()
        journal.today()
      end, {
        buffer = true,
        desc = "Today's journal entry",
        silent = true,
      })
    end,
  })
end

-- Public API exports
M.follow_link = navigation.follow_link
M.go_back = navigation.go_back
M.get_link_under_cursor = links.get_link_under_cursor
M.is_on_link = links.is_on_link
M.journal_next = journal.next_entry
M.journal_previous = journal.previous_entry
M.journal_today = journal.today

return M

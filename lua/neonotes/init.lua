-- Main entry point for Neonotes plugin
-- Provides the public API and setup function

local config = require("neonotes.config")
local navigation = require("neonotes.navigation")
local journal = require("neonotes.journal")
local images = require("neonotes.images")
local paste = require("neonotes.paste")
local picker = require("neonotes.picker")

local M = {}

-- Saved cwd to restore when leaving the vault
local saved_cwd = nil
local in_vault_mode = false

-- Setup the plugin with user configuration
-- @param opts table: Configuration options
--   - vault_path: Path to the notes vault (default: ~/notes)
--   - file_extension: Extension for note files (default: .md)
--   - images: Image display configuration (see config.lua for options)
function M.setup(opts)
  config.setup(opts)

  -- Setup image display integration
  images.setup()

  -- Set up autocommands for markdown files
  local group = vim.api.nvim_create_augroup("Neonotes", { clear = true })

  -- Enforce vault cwd while in vault mode (prevents other plugins from changing it)
  vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
    group = group,
    callback = function(ev)
      if not in_vault_mode then
        return
      end
      local vault_path = config.get_vault_path()
      local cwd = vim.fn.getcwd()
      if cwd ~= vault_path then
        vim.cmd("cd " .. vim.fn.fnameescape(vault_path))
      end
    end,
  })

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

      -- Image paste keybinding (Cmd+V in insert mode, or leader+p in normal mode)
      local paste_config = config.get_paste_config()
      if paste_config.enabled then
        vim.keymap.set("n", "<leader>p", function()
          paste.paste_image()
        end, {
          buffer = true,
          desc = "Paste image from clipboard",
          silent = true,
        })

        -- Also support Cmd+Shift+V for pasting images
        vim.keymap.set({ "n", "i" }, "<D-S-v>", function()
          paste.paste_image()
        end, {
          buffer = true,
          desc = "Paste image from clipboard",
          silent = true,
        })

        -- Image picker keybinding
        vim.keymap.set("n", "<leader>i", function()
          picker.pick_image()
        end, {
          buffer = true,
          desc = "Insert image from assets folder",
          silent = true,
        })
      end
    end,
  })
end

-- Navigate to vault root
function M.open_vault()
  local vault_path = config.get_vault_path()

  if not saved_cwd then
    saved_cwd = vim.fn.getcwd()
  end
  in_vault_mode = true
  vim.cmd("cd " .. vim.fn.fnameescape(vault_path))

  local extension = config.get_file_extension()
  local index_file = vault_path .. "/index" .. extension
  if vim.fn.filereadable(index_file) == 0 then
    local f = io.open(index_file, "w")
    if f then
      f:write("# Notes\n")
      f:close()
      vim.notify("Created index file", vim.log.levels.INFO)
    else
      vim.notify("Failed to create index file", vim.log.levels.ERROR)
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(index_file))
end

-- Leave vault mode and restore the previous working directory
function M.close_vault()
  if saved_cwd then
    vim.cmd("cd " .. vim.fn.fnameescape(saved_cwd))
    saved_cwd = nil
  end
  in_vault_mode = false
end

-- Create a new note in vault root (no Git detection)
-- @param note_name string|nil: Name of the note to create
function M.new_note(note_name)
  local vault_path = config.get_vault_path()
  local extension = config.get_file_extension()

  -- Prompt for note name if not provided
  if not note_name or note_name == "" then
    note_name = vim.fn.input("Note name: ")
    if note_name == "" then
      vim.notify("Note creation cancelled", vim.log.levels.WARN)
      return
    end
  end

  -- Always use vault root
  local target_dir = vault_path

  -- Create directory if it doesn't exist
  if vim.fn.isdirectory(target_dir) == 0 then
    vim.fn.mkdir(target_dir, "p")
  end

  -- Add extension if not present
  if not note_name:match("%." .. extension:gsub("%.", "") .. "$") then
    note_name = note_name .. extension
  end

  local filepath = target_dir .. "/" .. note_name
  local file_exists = vim.fn.filereadable(filepath) == 1

  vim.cmd("edit " .. vim.fn.fnameescape(filepath))

  if not file_exists then
    vim.notify("Created note: " .. note_name .. " (vault)", vim.log.levels.INFO)
  end
end

-- Public API exports
M.follow_link = navigation.follow_link
M.go_back = navigation.go_back
M.journal_next = journal.next_entry
M.journal_previous = journal.previous_entry
M.journal_today = journal.today
M.clear_images = images.clear_images
M.refresh_images = images.refresh_images
M.paste_image = paste.paste_image
M.pick_image = picker.pick_image

return M

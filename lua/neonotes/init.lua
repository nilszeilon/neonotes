-- Main entry point for Neonotes plugin
-- Provides the public API and setup function

local config = require("neonotes.config")
local navigation = require("neonotes.navigation")
local links = require("neonotes.links")
local journal = require("neonotes.journal")
local git = require("neonotes.git")

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

-- Navigate to vault or project directory
-- @param project_name string|nil: Optional project name (no auto-detection)
function M.open_vault(project_name)
  local vault_path = config.get_vault_path()
  local target_path = vault_path

  -- If project name is provided, navigate to project directory
  if project_name and project_name ~= "" then
    target_path = vault_path .. "/" .. project_name

    -- Create directory if it doesn't exist
    if vim.fn.isdirectory(target_path) == 0 then
      vim.fn.mkdir(target_path, "p")
      vim.notify("Created project directory: " .. project_name, vim.log.levels.INFO)
    end
  end

  -- Open the directory in netrw or file explorer
  vim.cmd("edit " .. vim.fn.fnameescape(target_path))
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

-- Create a new note in a project path (overrides Git repo detection)
-- @param project_path string: Path like "project/idea" or just "project"
-- @param note_name string|nil: Optional name of the note to create
function M.new_project_note(project_path, note_name)
  local vault_path = config.get_vault_path()
  local extension = config.get_file_extension()

  -- Prompt for project path if not provided
  if not project_path or project_path == "" then
    -- Get list of existing projects
    local projects = {}
    local handle = vim.loop.fs_scandir(vault_path)
    if handle then
      while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then break end
        if type == "directory" then
          table.insert(projects, name)
        end
      end
    end
    table.sort(projects)

    -- Get Git repo name and add it to the list if not already present
    local repo_name = git.get_project_name()
    if repo_name and not vim.tbl_contains(projects, repo_name) then
      table.insert(projects, 1, repo_name)
    end

    -- Add option to create new project
    table.insert(projects, "[New project...]")

    -- Use vim.ui.select for project selection
    vim.ui.select(projects, {
      prompt = "Select project:",
      format_item = function(item)
        if item == repo_name then
          return item .. " (git repo)"
        end
        return item
      end,
    }, function(choice)
      if not choice then
        vim.notify("Note creation cancelled", vim.log.levels.WARN)
        return
      end

      if choice == "[New project...]" then
        -- Prompt for new project path
        project_path = vim.fn.input("New project path: ")
        if project_path == "" then
          vim.notify("Note creation cancelled", vim.log.levels.WARN)
          return
        end
      else
        project_path = choice
      end

      -- Now prompt for note name
      if not note_name or note_name == "" then
        note_name = vim.fn.input("Note name: ")
        if note_name == "" then
          vim.notify("Note creation cancelled", vim.log.levels.WARN)
          return
        end
      end

      -- Build target directory from project path
      local target_dir = vault_path .. "/" .. project_path

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
        vim.notify("Created note: " .. note_name .. " (" .. project_path .. ")", vim.log.levels.INFO)
      end
    end)
    return
  end

  -- If project_path was provided as argument, proceed directly
  if not note_name or note_name == "" then
    note_name = vim.fn.input("Note name: ")
    if note_name == "" then
      vim.notify("Note creation cancelled", vim.log.levels.WARN)
      return
    end
  end

  -- Build target directory from project path
  local target_dir = vault_path .. "/" .. project_path

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
    vim.notify("Created note: " .. note_name .. " (" .. project_path .. ")", vim.log.levels.INFO)
  end
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

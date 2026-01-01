-- Plugin loader
-- This file is automatically sourced by Neovim

if vim.g.loaded_neonotes then
  return
end
vim.g.loaded_neonotes = true

-- Create user commands
vim.api.nvim_create_user_command("NeonotesFollowLink", function()
  require("neonotes").follow_link()
end, {
  desc = "Follow link under cursor",
})

vim.api.nvim_create_user_command("NeonotesGoBack", function()
  require("neonotes").go_back()
end, {
  desc = "Go back to previous file",
})

vim.api.nvim_create_user_command("NeonotesJournalNext", function()
  require("neonotes").journal_next()
end, {
  desc = "Navigate to next journal entry",
})

vim.api.nvim_create_user_command("NeonotesJournalPrevious", function()
  require("neonotes").journal_previous()
end, {
  desc = "Navigate to previous journal entry",
})

vim.api.nvim_create_user_command("NeonotesJournalToday", function(opts)
  local project_name = opts.args ~= "" and opts.args or nil
  require("neonotes").journal_today(project_name)
end, {
  nargs = "?",
  desc = "Open or create today's journal entry (optional: project name)",
})

vim.api.nvim_create_user_command("Neonotes", function(opts)
  local project_name = opts.args ~= "" and opts.args or nil
  require("neonotes").open_vault(project_name)
end, {
  nargs = "?",
  desc = "Navigate to vault or project directory (optional: project name)",
})

vim.api.nvim_create_user_command("NeonotesNew", function(opts)
  require("neonotes").new_note(opts.args ~= "" and opts.args or nil)
end, {
  nargs = "?",
  desc = "Create a new note in vault root (no Git detection)",
})

vim.api.nvim_create_user_command("NeonotesProject", function(opts)
  local args = vim.split(opts.args, "%s+", { trimempty = true })
  local project_path = args[1]
  local note_name = args[2]
  require("neonotes").new_project_note(project_path, note_name)
end, {
  nargs = "*",
  desc = "Create a new note in a project path (usage: NeonotesProject <project/path> [note-name])",
})

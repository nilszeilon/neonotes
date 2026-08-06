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

vim.api.nvim_create_user_command("Neonotes", function()
  require("neonotes").open_vault()
end, {
  desc = "Navigate to vault root",
})

vim.api.nvim_create_user_command("NeonotesClose", function()
  require("neonotes").close_vault()
end, {
  desc = "Leave vault mode and restore previous working directory",
})

vim.api.nvim_create_user_command("NeonotesNew", function(opts)
  require("neonotes").new_note(opts.args ~= "" and opts.args or nil)
end, {
  nargs = "?",
  desc = "Create a new note in vault root",
})

vim.api.nvim_create_user_command("NeonotesPasteImage", function()
  require("neonotes").paste_image()
end, {
  desc = "Paste image from clipboard and save to assets folder",
})

vim.api.nvim_create_user_command("NeonotesInsertImage", function()
  require("neonotes").pick_image()
end, {
  desc = "Insert image from assets folder with preview",
})

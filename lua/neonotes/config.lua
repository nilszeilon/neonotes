-- Configuration module for Neonotes
-- Handles vault settings and user configuration

local M = {}

-- Default configuration
M.defaults = {
  vault_path = vim.fn.expand("~/notes"),
  file_extension = ".md",
}

-- Current active configuration
M.options = {}

-- Setup function to initialize configuration
-- @param opts table: User-provided configuration options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- Expand the vault path to handle ~ and environment variables
  M.options.vault_path = vim.fn.expand(M.options.vault_path)

  -- Ensure vault directory exists
  local vault_path = M.options.vault_path
  if vim.fn.isdirectory(vault_path) == 0 then
    vim.fn.mkdir(vault_path, "p")
  end
end

-- Get the current vault path
-- @return string: Absolute path to the vault
function M.get_vault_path()
  return M.options.vault_path
end

-- Get the file extension for notes
-- @return string: File extension (e.g., ".md")
function M.get_file_extension()
  return M.options.file_extension
end

return M

-- Git utilities module
-- Handles Git repository detection and remote parsing

local M = {}

-- Check if current buffer is in a Git repository
-- @return boolean: true if in a Git repo, false otherwise
function M.is_in_git_repo()
  local git_dir = vim.fn.system("git rev-parse --git-dir 2>/dev/null")
  return vim.v.shell_error == 0
end

-- Get the Git repository root directory
-- @return string|nil: Absolute path to repo root, or nil if not in a repo
function M.get_repo_root()
  if not M.is_in_git_repo() then
    return nil
  end

  local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  root = root:gsub("%s+$", "") -- Trim whitespace

  if vim.v.shell_error == 0 and root ~= "" then
    return root
  end

  return nil
end

-- Get the repository name from Git remote
-- Extracts the repo name from origin, handling formats like:
--   - https://github.com/nilszeilon/neonotes -> neonotes
--   - git@github.com:nilszeilon/neonotes.git -> neonotes
--   - nilszeilon/neonotes -> neonotes
-- @return string|nil: Repository name without user/org prefix, or nil if not found
function M.get_repo_name()
  if not M.is_in_git_repo() then
    return nil
  end

  local remote_url = vim.fn.system("git config --get remote.origin.url 2>/dev/null")
  remote_url = remote_url:gsub("%s+$", "") -- Trim whitespace

  if vim.v.shell_error ~= 0 or remote_url == "" then
    return nil
  end

  -- Extract repo name from various URL formats
  local repo_name = nil

  -- Handle SSH format: git@github.com:user/repo.git
  repo_name = remote_url:match("git@[^:]+:([^/]+)/([^/%.]+)")
  if repo_name then
    return repo_name
  end

  -- Handle HTTPS format: https://github.com/user/repo or https://github.com/user/repo.git
  repo_name = remote_url:match("https?://[^/]+/[^/]+/([^/%.]+)")
  if repo_name then
    return repo_name:gsub("%.git$", "")
  end

  -- Handle short format: user/repo
  repo_name = remote_url:match("^[^/]+/([^/%.]+)")
  if repo_name then
    return repo_name:gsub("%.git$", "")
  end

  return nil
end

-- Get project name for journal organization
-- Returns Git repo name if in a repo, otherwise nil
-- @return string|nil: Project name to use for journal organization
function M.get_project_name()
  return M.get_repo_name()
end

return M

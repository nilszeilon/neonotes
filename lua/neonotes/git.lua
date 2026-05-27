-- Git utilities module
-- Handles Git repository detection and remote parsing

local M = {}

-- Get the directory of the current buffer (falls back to cwd)
-- @return string: Directory path to use for git commands
local function get_buffer_dir()
  local buf_dir = vim.fn.expand("%:p:h")
  if buf_dir and buf_dir ~= "" then
    return buf_dir
  end
  return vim.fn.getcwd()
end

-- Check if a directory is in a Git repository
-- @param dir string|nil: Directory to check (defaults to current buffer's directory)
-- @return boolean: true if in a Git repo, false otherwise
function M.is_in_git_repo(dir)
  dir = dir or get_buffer_dir()
  vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --git-dir 2>/dev/null")
  return vim.v.shell_error == 0
end

-- Get the Git repository root directory
-- @param dir string|nil: Directory to check (defaults to current buffer's directory)
-- @return string|nil: Absolute path to repo root, or nil if not in a repo
function M.get_repo_root(dir)
  dir = dir or get_buffer_dir()
  if not M.is_in_git_repo(dir) then
    return nil
  end

  local root = vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel 2>/dev/null")
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
-- @param dir string|nil: Directory to check (defaults to current buffer's directory)
-- @return string|nil: Repository name without user/org prefix, or nil if not found
function M.get_repo_name(dir)
  dir = dir or get_buffer_dir()
  if not M.is_in_git_repo(dir) then
    return nil
  end

  local remote_url = vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " config --get remote.origin.url 2>/dev/null")
  remote_url = remote_url:gsub("%s+$", "") -- Trim whitespace

  if vim.v.shell_error ~= 0 or remote_url == "" then
    return nil
  end

  -- Extract repo name from various URL formats
  local repo_name = nil

  -- Handle SSH format: git@github.com:user/repo.git
  local user, repo = remote_url:match("git@[^:]+:([^/]+)/([^/%.]+)")
  if repo then
    return repo
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
-- Returns Git repo name from remote if available, otherwise falls back to the repo folder name
-- @param dir string|nil: Directory to check (defaults to current buffer's directory)
-- @return string|nil: Project name to use for journal organization
function M.get_project_name(dir)
  dir = dir or get_buffer_dir()
  local name = M.get_repo_name(dir)
  if name then
    return name
  end

  -- No remote origin — fall back to the repo root directory name
  local root = M.get_repo_root(dir)
  if root then
    return vim.fn.fnamemodify(root, ":t")
  end

  return nil
end

return M

-- Shared helpers for image assets: deciding where images live and building
-- markdown-relative references.

local config = require("neonotes.config")

local M = {}

-- Where an image for `current_file` should be saved:
--  - inside the blog folder (vault/blog/...) -> next to the note, so Syncthing
--    syncs it to the blog dir along with the post
--  - anywhere else -> the vault assets dir (default behaviour)
function M.get_images_dir(current_file)
  local vault_path = config.get_vault_path()
  local paste_config = config.get_paste_config()
  local blog_root = vault_path .. "/" .. (paste_config.blog_dir or "blog")

  local current_dir = vim.fn.fnamemodify(current_file, ":h")
  if current_dir == blog_root or current_dir:sub(1, #blog_root + 1) == blog_root .. "/" then
    return current_dir
  end

  return vault_path .. "/" .. paste_config.images_dir
end

-- Relative path from the current file to the image file, for markdown links
function M.get_relative_path(current_file, image_file)
  local current_dir = vim.fn.fnamemodify(current_file, ":h")
  return vim.fs.relpath(current_dir, image_file) or image_file
end

return M

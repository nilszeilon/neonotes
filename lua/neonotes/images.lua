-- Image display integration for Neonotes
-- Integrates with image.nvim to display images inline in markdown notes

local config = require("neonotes.config")

local M = {}

-- Check if image.nvim is available
local has_image, image = pcall(require, "image")

-- Store whether images are enabled
M.enabled = false

-- Setup image.nvim integration
function M.setup()
  if not has_image then
    vim.notify(
      "image.nvim not found. Install it to enable image display in neonotes.",
      vim.log.levels.WARN
    )
    return false
  end

  local image_config = config.get_image_config()

  -- Only enable if user hasn't explicitly disabled it
  if image_config.enabled == false then
    return false
  end

  -- Setup image.nvim with neonotes-specific configuration
  image.setup({
    backend = "kitty",
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = image_config.clear_in_insert_mode,
        download_remote_images = image_config.download_remote_images,
        only_render_image_at_cursor = image_config.only_render_image_at_cursor,
        filetypes = { "markdown", "vimwiki" },
        resolve_image_path = function(document_path, image_path, fallback)
          -- Use fallback which handles relative paths correctly
          return fallback(document_path, image_path)
        end,
      },
    },
    max_width = image_config.max_width,
    max_height = image_config.max_height,
    max_width_window_percentage = image_config.max_width_window_percentage,
    max_height_window_percentage = image_config.max_height_window_percentage,
    window_overlap_clear_enabled = image_config.window_overlap_clear_enabled,
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    editor_only_render_when_focused = image_config.editor_only_render_when_focused,
    tmux_show_only_in_active_window = image_config.tmux_show_only_in_active_window,
    hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp" },
  })

  M.enabled = true
  return true
end

-- Check if images are enabled
function M.is_enabled()
  return M.enabled and has_image
end

-- Get image.nvim instance (for advanced usage)
function M.get_image_api()
  if not M.is_enabled() then
    return nil
  end
  return image
end

-- Clear all images in current buffer
function M.clear_images()
  if not M.is_enabled() then
    return
  end

  -- Get the image API and clear images from current buffer
  local api = image.get_images({ buffer = vim.api.nvim_get_current_buf() })
  for _, img in ipairs(api) do
    img:clear()
  end
end

-- Refresh/re-render images in current buffer
function M.refresh_images()
  if not M.is_enabled() then
    return
  end

  -- Clear and let image.nvim re-render automatically
  M.clear_images()
end

return M

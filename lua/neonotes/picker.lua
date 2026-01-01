-- Image picker for Neonotes
-- Allows selecting images from the assets folder with preview

local config = require("neonotes.config")

local M = {}

-- Get all image files from the assets directory
-- @return table: List of image file paths
local function get_image_files()
  local vault_path = config.get_vault_path()
  local paste_config = config.get_paste_config()
  local assets_dir = vault_path .. "/" .. paste_config.images_dir

  -- Check if assets directory exists
  if vim.fn.isdirectory(assets_dir) == 0 then
    return {}
  end

  local images = {}
  local extensions = { "png", "jpg", "jpeg", "gif", "webp" }

  -- Recursively find all images in assets directory
  for _, ext in ipairs(extensions) do
    local pattern = assets_dir .. "/**/*." .. ext
    local files = vim.fn.glob(pattern, false, true)
    vim.list_extend(images, files)
  end

  return images
end

-- Get relative path from current file to image file
-- @param current_file string: Path to current markdown file
-- @param image_file string: Path to image file
-- @return string: Relative path for markdown
local function get_relative_path(current_file, image_file)
  local vault_path = config.get_vault_path()

  -- Get path relative to vault
  local vault_relative = image_file:gsub("^" .. vim.pesc(vault_path) .. "/", "")

  return vault_relative
end

-- Pick an image using Telescope (if available)
local function pick_with_telescope()
  local has_telescope, telescope = pcall(require, "telescope.builtin")
  if not has_telescope then
    return false
  end

  local has_actions, actions = pcall(require, "telescope.actions")
  local has_action_state, action_state = pcall(require, "telescope.actions.state")
  local has_pickers, pickers = pcall(require, "telescope.pickers")
  local has_finders, finders = pcall(require, "telescope.finders")
  local has_conf, conf = pcall(require, "telescope.config")
  local has_previewers, previewers = pcall(require, "telescope.previewers")

  if not (has_actions and has_action_state and has_pickers and has_finders and has_conf and has_previewers) then
    return false
  end

  local images = get_image_files()
  if #images == 0 then
    vim.notify("No images found in assets folder", vim.log.levels.WARN)
    return true
  end

  local current_file = vim.fn.expand("%:p")
  local vault_path = config.get_vault_path()

  -- Create display entries with just the filename
  local entries = {}
  for _, img in ipairs(images) do
    local filename = vim.fn.fnamemodify(img, ":t")
    local relative = img:gsub("^" .. vim.pesc(vault_path) .. "/", "")
    table.insert(entries, {
      display = filename,
      path = img,
      relative = relative,
    })
  end

  -- Try to use image.nvim for preview if available
  local has_image, image = pcall(require, "image")
  local preview_images = {}

  pickers
    .new({}, {
      prompt_title = "Select Image",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.display,
            path = entry.path,
          }
        end,
      }),
      sorter = conf.values.generic_sorter({}),
      previewer = previewers.new_buffer_previewer({
        title = "Image Preview",
        define_preview = function(self, entry, status)
          if has_image then
            -- Clear previous images
            for _, img in ipairs(preview_images) do
              pcall(function()
                img:clear()
              end)
            end
            preview_images = {}

            -- Create a temporary buffer with markdown to trigger image rendering
            local bufnr = self.state.bufnr
            vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")

            -- Get image info
            local img_path = entry.value.path
            local filename = vim.fn.fnamemodify(img_path, ":t")

            -- Set buffer content with markdown image syntax
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
              "# " .. filename,
              "",
              "![](" .. img_path .. ")",
            })
          else
            -- Fallback: show file info
            local img_path = entry.value.path
            local size = vim.fn.getfsize(img_path)
            local filename = vim.fn.fnamemodify(img_path, ":t")

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
              "Image: " .. filename,
              "Path: " .. img_path,
              "Size: " .. size .. " bytes",
              "",
              "(Install image.nvim for image preview)",
            })
          end
        end,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          -- Clear preview images
          for _, img in ipairs(preview_images) do
            pcall(function()
              img:clear()
            end)
          end

          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            local relative_path = get_relative_path(current_file, selection.value.path)
            local filename = vim.fn.fnamemodify(selection.value.path, ":t:r")
            local markdown = string.format("![%s](%s)", filename, relative_path)

            -- Insert at cursor
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { markdown })

            vim.notify("Inserted image: " .. filename, vim.log.levels.INFO)
          end
        end)
        return true
      end,
    })
    :find()

  return true
end

-- Pick an image using vim.ui.select (fallback)
local function pick_with_select()
  local images = get_image_files()
  if #images == 0 then
    vim.notify("No images found in assets folder", vim.log.levels.WARN)
    return
  end

  local current_file = vim.fn.expand("%:p")
  local vault_path = config.get_vault_path()

  -- Create display names (just filenames)
  local display_items = {}
  for _, img in ipairs(images) do
    local filename = vim.fn.fnamemodify(img, ":t")
    table.insert(display_items, filename)
  end

  vim.ui.select(display_items, {
    prompt = "Select an image:",
    format_item = function(item)
      return item
    end,
  }, function(choice, idx)
    if not choice then
      return
    end

    local image_path = images[idx]
    local relative_path = get_relative_path(current_file, image_path)
    local filename = vim.fn.fnamemodify(image_path, ":t:r")
    local markdown = string.format("![%s](%s)", filename, relative_path)

    -- Insert at cursor
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { markdown })

    vim.notify("Inserted image: " .. filename, vim.log.levels.INFO)
  end)
end

-- Main image picker function
function M.pick_image()
  -- Check if we're in a markdown file within the vault
  local current_file = vim.fn.expand("%:p")
  local vault_path = config.get_vault_path()

  if not current_file:match("%.md$") then
    vim.notify("Image picker only works in markdown files", vim.log.levels.WARN)
    return
  end

  if not current_file:match("^" .. vim.pesc(vault_path)) then
    vim.notify("Image picker only works within the vault", vim.log.levels.WARN)
    return
  end

  -- Try telescope first, fallback to vim.ui.select
  if not pick_with_telescope() then
    pick_with_select()
  end
end

return M

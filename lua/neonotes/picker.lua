-- Image picker for Neonotes
-- Allows selecting images from the assets folder with preview

local config = require("neonotes.config")
local assets = require("neonotes.assets")

local M = {}

-- Get all image files under the given directory
-- @param search_dir string: Directory to search (assets dir or the blog folder)
-- @return table: List of image file paths
local function get_image_files(search_dir)
  -- Check if the directory exists
  if vim.fn.isdirectory(search_dir) == 0 then
    return {}
  end

  local images = {}
  local extensions = { "png", "jpg", "jpeg", "gif", "webp" }

  -- Recursively find all images in the directory
  for _, ext in ipairs(extensions) do
    local pattern = search_dir .. "/**/*." .. ext
    local files = vim.fn.glob(pattern, false, true)
    vim.list_extend(images, files)
  end

  return images
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

  local current_file = vim.fn.expand("%:p")
  local images = get_image_files(assets.get_images_dir(current_file))
  if #images == 0 then
    vim.notify("No images found", vim.log.levels.WARN)
    return true
  end

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

            local bufnr = self.state.bufnr
            local img_path = entry.value.path
            local filename = vim.fn.fnamemodify(img_path, ":t")
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
              "# " .. filename,
              "",
              "",
            })
            local ok, preview = pcall(image.from_file, img_path, {
              window = self.state.winid,
              buffer = bufnr,
              x = 0,
              y = 2,
              inline = true,
              with_virtual_padding = true,
              max_width_window_percentage = 90,
              max_height_window_percentage = 80,
            })
            if ok and preview then
              preview:render()
              table.insert(preview_images, preview)
            end
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
            local relative_path = assets.get_relative_path(current_file, selection.value.path)
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
  local current_file = vim.fn.expand("%:p")
  local images = get_image_files(assets.get_images_dir(current_file))
  if #images == 0 then
    vim.notify("No images found", vim.log.levels.WARN)
    return
  end

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
    local relative_path = assets.get_relative_path(current_file, image_path)
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

-- Image paste functionality for Neonotes
-- Handles clipboard image detection, saving, and markdown insertion

local config = require("neonotes.config")
local assets = require("neonotes.assets")

local M = {}

-- Sanitize a filename by converting it to kebab-case
-- "My Cool Image" -> "my-cool-image"
-- @param name string: The input filename
-- @return string: Sanitized filename
local function sanitize_filename(name)
  if not name or name == "" then
    return ""
  end

  -- Convert to lowercase
  name = name:lower()

  -- Replace spaces and underscores with hyphens
  name = name:gsub("[%s_]+", "-")

  -- Remove any characters that aren't alphanumeric, hyphens, or dots
  name = name:gsub("[^%w%-%.]+", "")

  -- Remove leading/trailing hyphens
  name = name:gsub("^%-+", ""):gsub("%-+$", "")

  -- Collapse multiple consecutive hyphens
  name = name:gsub("%-+", "-")

  return name
end

-- Detect if clipboard contains an image (macOS)
-- @return boolean: true if clipboard has image data
local function has_clipboard_image()
  local handle = io.popen("osascript -e 'clipboard info'")
  if not handle then
    return false
  end

  local result = handle:read("*a")
  handle:close()

  -- Check if clipboard contains image data
  -- macOS clipboard info returns something like "«class PNGf», 12345" for images
  return result:match("PNGf") ~= nil
    or result:match("TIFF") ~= nil
    or result:match("JPEG") ~= nil
    or result:match("JPEGf") ~= nil
end

-- Save clipboard image to file
-- @param filepath string: Destination filepath
-- @return boolean: true if successful
local function save_clipboard_image(filepath)
  -- Use osascript to save clipboard image to file
  -- We save as PNG to preserve quality
  local script = string.format(
    [[
    osascript -e '
      set theFile to POSIX file "%s"
      set imageData to the clipboard as «class PNGf»
      set fileRef to open for access theFile with write permission
      write imageData to fileRef
      close access fileRef
    '
    ]],
    filepath
  )

  local handle = io.popen(script .. " 2>&1")
  if not handle then
    return false
  end

  local result = handle:read("*a")
  local success = handle:close()

  if not success then
    vim.notify("Failed to save image: " .. result, vim.log.levels.ERROR)
    return false
  end

  return true
end

-- Save the image and insert its markdown reference at the cursor
-- @param image_path string: Full path the image was saved to
-- @param name string: Display name to use in the markdown
-- @return boolean: true if the image was saved and inserted
local function save_and_insert(image_path, name)
  if not save_clipboard_image(image_path) then
    return false
  end

  local current_file = vim.fn.expand("%:p")
  local relative_path = assets.get_relative_path(current_file, image_path)
  local markdown = string.format("![%s](%s)", name, relative_path)

  -- Insert at cursor
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { markdown })

  vim.notify("Image saved: " .. vim.fn.fnamemodify(image_path, ":t"), vim.log.levels.INFO)
  return true
end

-- Main paste image function
function M.paste_image()
  -- Check if we're in a markdown file within the vault
  local current_file = vim.fn.expand("%:p")
  local vault_path = config.get_vault_path()

  if not current_file:match("%.md$") then
    vim.notify("Image paste only works in markdown files", vim.log.levels.WARN)
    return
  end

  if not current_file:match("^" .. vim.pesc(vault_path)) then
    vim.notify("Image paste only works within the vault", vim.log.levels.WARN)
    return
  end

  -- Check if clipboard has an image
  if not has_clipboard_image() then
    vim.notify("No image found in clipboard", vim.log.levels.WARN)
    return
  end

  -- Prompt for filename
  vim.ui.input({
    prompt = "Image name: ",
    default = "image",
  }, function(input)
    if not input or input == "" then
      vim.notify("Image paste cancelled", vim.log.levels.WARN)
      return
    end

    -- Sanitize filename
    local filename = sanitize_filename(input)
    if filename == "" then
      vim.notify("Invalid filename", vim.log.levels.ERROR)
      return
    end

    -- Add .png extension if not present
    if not filename:match("%.png$") then
      filename = filename .. ".png"
    end

    -- Inside the blog folder images are saved next to the note so Syncthing
    -- syncs them to the blog; everywhere else they go to the vault assets dir.
    local images_dir = assets.get_images_dir(current_file)

    -- Create the images directory if it doesn't exist
    if vim.fn.isdirectory(images_dir) == 0 then
      vim.fn.mkdir(images_dir, "p")
    end

    -- Full path to save the image
    local image_path = images_dir .. "/" .. filename

    -- Check if file already exists
    if vim.fn.filereadable(image_path) == 1 then
      vim.ui.select({ "Overwrite", "Cancel" }, {
        prompt = "File " .. filename .. " already exists:",
      }, function(choice)
        if choice ~= "Overwrite" then
          vim.notify("Image paste cancelled", vim.log.levels.WARN)
          return
        end

        save_and_insert(image_path, input)
      end)
      return
    end

    save_and_insert(image_path, input)
  end)
end

return M

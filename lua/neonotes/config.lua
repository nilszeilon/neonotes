-- Configuration module for Neonotes
-- Handles vault settings and user configuration

local M = {}

-- Default configuration
M.defaults = {
	vault_path = vim.fn.expand("~/notes"),
	file_extension = ".md",
	images = {
		enabled = true,
		clear_in_insert_mode = true, -- Clear images in insert mode to reduce flicker
		download_remote_images = true,
		only_render_image_at_cursor = false,
		max_width = nil,
		max_height = nil,
		max_width_window_percentage = 30, -- Smaller images reduce rendering time
		max_height_window_percentage = 30,
		window_overlap_clear_enabled = false, -- Disable to reduce re-renders
		editor_only_render_when_focused = true,
		tmux_show_only_in_active_window = true,
	},
	paste = {
		enabled = true,
		images_dir = "assets",
	},
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

-- Get the image configuration
-- @return table: Image configuration options
function M.get_image_config()
	return M.options.images or M.defaults.images
end

-- Get the paste configuration
-- @return table: Paste configuration options
function M.get_paste_config()
	return M.options.paste or M.defaults.paste
end

return M

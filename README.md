# Neonotes.nvim

A Neovim plugin for Obsidian-like note-taking with wiki-style links and seamless navigation.

## Features

- **Vault-based organization**: Set up a dedicated directory for all your notes
- **Git-aware project detection**: Automatically organize notes by Git repository name
- **Quick vault access**: Jump to your vault or specific project directories
- **Smart note creation**: Create notes with automatic project organization
- **Wiki-style links**: Use `[[note-name]]` to link between notes
- **Directional linking**: Press `Enter` on a link to jump to that note
- **Auto-create notes**: If a linked note doesn't exist, it's created automatically
- **Easy navigation**: Press `Backspace` to go back to the previous note
- **Date-based journals**: Navigate through journal entries with forward/backward commands
- **Multiple journals**: Support for multiple journal directories in your vault
- **Inline image display**: View images directly in your markdown notes (requires image.nvim and Ghostty/Kitty terminal)

## Installation

### Prerequisites

For inline image display support, you'll need:
- **Terminal**: [Ghostty](https://ghostty.org/) or [Kitty](https://sw.kovidgoyal.net/kitty/) (both support the Kitty graphics protocol)
- **ImageMagick**: Required by image.nvim for image processing
  - macOS: `brew install imagemagick`
  - Ubuntu/Debian: `sudo apt-get install imagemagick`
  - Arch: `sudo pacman -S imagemagick`

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  dir = "~/dev/neonotes/neonotes.nvim",
  dependencies = {
    {
      "3rd/image.nvim",
      opts = {},
    },
    "nvim-telescope/telescope.nvim",  -- Optional: for image picker with preview
  },
  config = function()
    require("neonotes").setup({
      vault_path = "~/notes",      -- Path to your notes vault
      file_extension = ".md",      -- File extension for notes
      images = {
        enabled = true,            -- Enable/disable image display
        max_width_window_percentage = 50,
        max_height_window_percentage = 50,
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "~/dev/neonotes/neonotes.nvim",
  requires = { "3rd/image.nvim" },
  config = function()
    require("neonotes").setup({
      vault_path = "~/notes",
      file_extension = ".md",
      images = {
        enabled = true,
      },
    })
  end
}
```

## Usage

### Quick Start

**Navigate to your vault:**
```vim
:Neonotes                    " Open vault root
:Neonotes myproject          " Open specific project directory
```

**Create a new note:**
```vim
:NeonotesNew                 " Prompts for name, uses Git repo if available
:NeonotesNew my-note         " Create in Git repo or vault root
:NeonotesNew my-note work    " Create in ~/notes/work/my-note.md
```

### Basic Workflow

1. Create a note in your vault directory (e.g., `~/notes/index.md`)
2. Add a wiki-style link: `[[my-other-note]]`
3. Place cursor on the link and press `Enter` to follow it
4. The linked note will be created if it doesn't exist
5. Press `Backspace` to go back to the previous note

### Journal Workflow

Journals use the date format `yyyy-mm-dd.md` and are navigated chronologically within their directory.

**Git-aware project organization:**
When you create a journal entry, the plugin automatically organizes it by project:
- If you're in a Git repository, it uses the repo name (e.g., `nilszeilon/neonotes` → `neonotes/`)
- If not in a Git repo, entries are created in the vault root
- You can override this by providing a project name: `:NeonotesJournalToday myproject`

**Example structure:**
```
~/notes/
├── neonotes/           # Auto-created from git repo "nilszeilon/neonotes"
│   ├── 2025-12-29.md
│   ├── 2025-12-30.md
│   └── 2025-12-31.md
├── work-project/       # Manually specified with :NeonotesJournalToday work-project
│   ├── 2025-12-25.md
│   └── 2025-12-31.md
└── 2025-12-15.md       # Created outside a git repo (vault root)
```

**Usage:**
1. From within a Git repo, press `<leader>jt` to create today's journal (auto-organized by repo name)
2. Use `:NeonotesJournalToday myproject` to specify a custom project name
3. Press `<leader>jn` to jump to the next entry
4. Press `<leader>jp` to jump to the previous entry

The navigation only considers entries in the current file's directory, allowing you to maintain separate journals for different projects.

### Keybindings

The following keybindings are automatically set up for markdown files:

**Link Navigation:**
- `<CR>` (Enter): Follow link under cursor
- `<BS>` (Backspace): Go back to previous file

**Journal Navigation:**
- `<leader>jn`: Navigate to next journal entry
- `<leader>jp`: Navigate to previous journal entry
- `<leader>jt`: Open or create today's journal entry

**Image Management:**
- `<leader>p`: Paste image from clipboard (prompts for filename)
- `<Cmd-Shift-V>`: Alternative keybinding for pasting images
- `<leader>i`: Pick and insert image from assets folder (with preview)

### Commands

**Vault & Note Management:**
- `:Neonotes [project]` - Navigate to vault root or project directory
- `:NeonotesNew [note-name] [project]` - Create a new note (Git-aware or manual project)

**Link Navigation:**
- `:NeonotesFollowLink` - Follow link under cursor
- `:NeonotesGoBack` - Go back to previous file

**Journal Navigation:**
- `:NeonotesJournalNext` - Navigate to next journal entry
- `:NeonotesJournalPrevious` - Navigate to previous journal entry
- `:NeonotesJournalToday [project]` - Open or create today's journal entry (optional: specify project name)

**Image Management:**
- `:NeonotesClearImages` - Clear all images in current buffer
- `:NeonotesRefreshImages` - Refresh/re-render images in current buffer
- `:NeonotesPasteImage` - Paste image from clipboard and save to assets folder
- `:NeonotesInsertImage` - Pick and insert image from assets folder with preview

### Configuration

```lua
require("neonotes").setup({
  -- Path to your notes vault (default: "~/notes")
  vault_path = "~/my-notes",

  -- File extension for notes (default: ".md")
  file_extension = ".md",

  -- Image display configuration (requires image.nvim)
  images = {
    enabled = true,                          -- Enable/disable image display
    clear_in_insert_mode = true,             -- Clear images in insert mode (reduces flicker)
    download_remote_images = true,           -- Download and display remote images (http/https)
    only_render_image_at_cursor = false,     -- Only render image under cursor
    max_width = nil,                         -- Max width in pixels (nil = use percentage)
    max_height = nil,                        -- Max height in pixels (nil = use percentage)
    max_width_window_percentage = 40,        -- Max width as percentage (smaller = less flicker)
    max_height_window_percentage = 40,       -- Max height as percentage (smaller = less flicker)
    window_overlap_clear_enabled = false,    -- Disable to reduce re-renders
    editor_only_render_when_focused = true,  -- Only render when Neovim is focused
    tmux_show_only_in_active_window = true,  -- Only show in active tmux pane
  },

  -- Image paste configuration
  paste = {
    enabled = true,                          -- Enable/disable image paste functionality
    images_dir = "assets",                   -- Directory name for storing images (at vault root)
  },
})
```

### Using Images in Notes

Images are automatically displayed when you use standard markdown image syntax:

```markdown
![Alt text](path/to/image.png)
![Remote image](https://example.com/image.jpg)
```

Images can be:
- **Relative paths**: `![diagram](./assets/diagram.png)` - relative to the current note
- **Vault paths**: `![logo](images/logo.png)` - relative to vault root
- **Absolute paths**: `![photo](/Users/username/photos/pic.jpg)`
- **Remote URLs**: `![web](https://example.com/image.png)` - auto-downloaded if enabled

The images will render inline in your terminal as you view your notes.

#### Reducing Image Flicker

Image flickering during typing is caused by image.nvim re-rendering on buffer changes. Here are solutions:

**1. Clear images in insert mode (default)**
```lua
images = {
  clear_in_insert_mode = true,  -- Images disappear when typing, reappear in normal mode
}
```
This is the recommended approach - images hide while you type and show when you're done.

**2. Reduce image size**
```lua
images = {
  max_width_window_percentage = 30,   -- Smaller images render faster
  max_height_window_percentage = 30,
}
```
Smaller images in the editor = less flicker. The actual image files remain full size.

**3. Show only cursor image**
```lua
images = {
  only_render_image_at_cursor = true,  -- Only show image where cursor is
}
```
Reduces total images rendered at once.

**4. Disable window overlap clearing**
```lua
images = {
  window_overlap_clear_enabled = false,  -- Don't clear on window changes
}
```
Prevents re-renders when switching windows.

### Working with Images

#### Pasting Images from Clipboard

Neonotes supports pasting images directly from your clipboard:

1. Copy an image to your clipboard (screenshot, image from browser, etc.)
2. In a markdown note, press `<leader>p` or `<Cmd-Shift-V>`
3. Enter a name for the image (e.g., "My Cool Diagram")
4. The image will be saved to `~/notes/assets/` and markdown inserted

**Filename Sanitization:**
- "My Cool Diagram" → `my-cool-diagram.png`
- Automatically converts to lowercase kebab-case
- Removes special characters
- Adds `.png` extension if not present

**Storage Location:**
All images are stored in a central `assets/` folder at your vault root:
```
~/notes/
├── assets/
│   ├── diagram.png
│   ├── screenshot.png
│   └── photo.jpg
├── project-a/
│   └── article.md          # Uses: ![diagram](assets/diagram.png)
└── project-b/
    └── notes.md            # Uses: ![screenshot](assets/screenshot.png)
```

#### Inserting Existing Images

Browse and insert images from your assets folder with live preview:

1. Press `<leader>i` or run `:NeonotesInsertImage`
2. Browse images with **Telescope** (if installed) or a selection menu
3. **Preview images** in real-time as you navigate (with image.nvim)
4. Select an image to insert the markdown reference

**Features:**
- **Live image preview** in Telescope (requires image.nvim and Telescope)
- **Fuzzy search** through image filenames
- **Automatic relative path** insertion
- **Fallback to vim.ui.select** if Telescope is not available

## Project Structure

```
neonotes.nvim/
├── lua/
│   └── neonotes/
│       ├── init.lua        # Main entry point and public API
│       ├── config.lua      # Configuration management
│       ├── links.lua       # Link detection and parsing
│       ├── navigation.lua  # File navigation and link following
│       ├── git.lua         # Git repository detection
│       ├── journal.lua     # Date-based journal navigation
│       ├── images.lua      # Image display integration (image.nvim)
│       ├── paste.lua       # Clipboard image paste functionality
│       └── picker.lua      # Image picker with preview (Telescope)
├── plugin/
│   └── neonotes.lua       # Plugin loader and commands
└── README.md
```

## How It Works

1. **config.lua**: Manages vault settings and ensures the vault directory exists
2. **links.lua**: Detects wiki-style `[[links]]` and extracts link text from under the cursor
3. **navigation.lua**: Resolves link text to file paths and handles file opening
4. **git.lua**: Detects Git repositories and extracts project names from remote URLs
5. **journal.lua**: Detects date-based journal entries, organizes by project, and provides chronological navigation
6. **images.lua**: Integrates with image.nvim to display images inline in markdown notes
7. **paste.lua**: Handles clipboard image detection, saving, and markdown insertion
8. **picker.lua**: Provides image selection with live preview using Telescope
9. **init.lua**: Ties everything together and sets up keybindings for markdown files

## License

MIT

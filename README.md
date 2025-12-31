# Neonotes.nvim

A Neovim plugin for Obsidian-like note-taking with wiki-style links and seamless navigation.

## Features

- **Vault-based organization**: Set up a dedicated directory for all your notes
- **Wiki-style links**: Use `[[note-name]]` to link between notes
- **Directional linking**: Press `Enter` on a link to jump to that note
- **Auto-create notes**: If a linked note doesn't exist, it's created automatically
- **Easy navigation**: Press `Backspace` to go back to the previous note
- **Date-based journals**: Navigate through journal entries with forward/backward commands
- **Multiple journals**: Support for multiple journal directories in your vault

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  dir = "~/dev/neonotes/neonotes.nvim",
  config = function()
    require("neonotes").setup({
      vault_path = "~/notes",      -- Path to your notes vault
      file_extension = ".md",      -- File extension for notes
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "~/dev/neonotes/neonotes.nvim",
  config = function()
    require("neonotes").setup({
      vault_path = "~/notes",
      file_extension = ".md",
    })
  end
}
```

## Usage

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

### Commands

**Link Navigation:**
- `:NeonotesFollowLink` - Follow link under cursor
- `:NeonotesGoBack` - Go back to previous file

**Journal Navigation:**
- `:NeonotesJournalNext` - Navigate to next journal entry
- `:NeonotesJournalPrevious` - Navigate to previous journal entry
- `:NeonotesJournalToday [project]` - Open or create today's journal entry (optional: specify project name)

### Configuration

```lua
require("neonotes").setup({
  -- Path to your notes vault (default: "~/notes")
  vault_path = "~/my-notes",

  -- File extension for notes (default: ".md")
  file_extension = ".md",
})
```

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
│       └── journal.lua     # Date-based journal navigation
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
6. **init.lua**: Ties everything together and sets up keybindings for markdown files

## License

MIT

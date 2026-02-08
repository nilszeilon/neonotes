# neonotes.nvim

Markdown notes in Neovim with wiki links, a daily journal, and inline images.

## Install

Requires [image.nvim](https://github.com/3rd/image.nvim) for inline images and a terminal that supports the Kitty graphics protocol ([Ghostty](https://ghostty.org/), [Kitty](https://sw.kovidgoyal.net/kitty/)).

ImageMagick is needed by image.nvim: `brew install imagemagick`

### lazy.nvim

```lua
{
  "nilszeilon/neonotes.nvim",
  dependencies = {
    { "3rd/image.nvim", opts = {} },
    "nvim-telescope/telescope.nvim", -- optional, for image picker
  },
  config = function()
    require("neonotes").setup({
      vault_path = "~/notes",
    })
  end,
}
```

## Setup

```lua
require("neonotes").setup({
  vault_path = "~/notes",     -- where your notes live
  file_extension = ".md",     -- default
  images = {
    enabled = true,
    clear_in_insert_mode = true,
    download_remote_images = true,
    only_render_image_at_cursor = false,
    max_width_window_percentage = 30,
    max_height_window_percentage = 30,
  },
  paste = {
    enabled = true,
    images_dir = "assets",    -- saved under vault root
  },
})
```

## Usage

### Notes and links

Create a note anywhere in your vault. Link to other notes with `[[wiki-links]]`.
Press **Enter** on a link to follow it (creates the file if it doesn't exist).
Press **Backspace** to go back.

```
~/notes/
├── journal/
│   ├── 2026-02-07.md
│   └── 2026-02-08.md
├── assets/
│   └── diagram.png
├── index.md
└── some-idea.md
```

### Journal

All journal entries live in `vault/journal/`. One file per day, named `yyyy-mm-dd.md`.

When you open the journal from inside a git repo (`:NeonotesJournalToday` or `<leader>jt`), the plugin:

1. Opens (or creates) today's file in `vault/journal/`
2. Looks for a `## repo-name` header inside the file
3. If found, moves the cursor to the line below it
4. If not found, appends `## repo-name` at the end and positions the cursor there

You can also pass an explicit name: `:NeonotesJournalToday myproject`

A typical journal entry after working on two repos looks like:

```markdown
# 2026-02-08 Saturday

## neonotes.nvim
- rewrote journal module

## other-project
- fixed auth bug
```

Navigate between days with `<leader>jn` (next) and `<leader>jp` (previous).

### Images

Standard markdown image syntax is rendered inline:

```markdown
![diagram](assets/diagram.png)
```

Paste from clipboard with `<leader>p` -- you'll be prompted for a name and the image is saved to `vault/assets/`.

Browse and insert existing images with `<leader>i` (uses Telescope if available).

## Keybindings

Set automatically for markdown files:

| Key | Action |
|---|---|
| `<CR>` | Follow `[[link]]` under cursor |
| `<BS>` | Go back |
| `<leader>jt` | Today's journal |
| `<leader>jn` | Next journal entry |
| `<leader>jp` | Previous journal entry |
| `<leader>p` | Paste image from clipboard |
| `<leader>i` | Insert image from assets |
| `<D-S-v>` | Paste image (macOS Cmd+Shift+V) |

## Commands

| Command | Description |
|---|---|
| `:Neonotes [project]` | Open vault root or a project directory |
| `:NeonotesNew [name]` | Create a note in vault root |
| `:NeonotesProject [path] [name]` | Create a note inside a project path |
| `:NeonotesJournalToday [project]` | Open today's journal (auto-detects git repo) |
| `:NeonotesJournalNext` | Next journal entry |
| `:NeonotesJournalPrevious` | Previous journal entry |
| `:NeonotesFollowLink` | Follow link under cursor |
| `:NeonotesGoBack` | Go back |
| `:NeonotesPasteImage` | Paste clipboard image |
| `:NeonotesInsertImage` | Pick image from assets |
| `:NeonotesClearImages` | Clear rendered images |
| `:NeonotesRefreshImages` | Re-render images |

## License

MIT

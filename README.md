# neonotes.nvim

Markdown notes in Neovim with wiki links, a daily journal, and image asset authoring.

## Install

Use the companion [neonotes-preview.nvim](https://github.com/nilszeilon/neonotes-preview.nvim) plugin for a rendered Markdown split with large headings and local images.

### lazy.nvim

```lua
{
  "nilszeilon/neonotes.nvim",
  dependencies = {
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
  paste = {
    enabled = true,
    images_dir = "assets",    -- saved under vault root
    blog_dir = "blog",        -- vault/blog notes save pastes next to the note
  },
})
```

## Usage

### Notes and links

Create a note anywhere in your vault. Link to other notes with `[[wiki-links]]`.
Use `follow_link()` to follow a link and create its file if it does not exist. Use `go_back()` to return.

Tags work the same way: write `#idea` or `#project/status` and follow the tag to jump to its note under `vault/tags/` (created on first use). Nested tags like `#foo/bar` become `tags/foo/bar.md`.

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

When you open the journal from inside a git repo (`:NeonotesJournalToday` or `<leader>nt`), the plugin:

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

Navigate between days with `<leader>n]` (next) and `<leader>n[` (previous).

### Images

Neonotes can create standard Markdown image references:

```markdown
![diagram](assets/diagram.png)
```

Paste from clipboard with `<leader>np` -- you'll be prompted for a name and the image is saved to
`vault/assets/`. When the current note lives in the blog folder (`vault/blog/`, which Syncthing
mirrors to the blog), the image is saved **next to the note** instead and referenced relative to
it (`![prime](prime.png)`), so it reaches the blog along with the post.

Browse and insert existing images with `<leader>ni` (uses Telescope if available) -- it searches
the same folder as paste would save to.
Rendering belongs to `neonotes-preview.nvim`; Neonotes itself has no image-rendering dependency.

## Keybindings

Neonotes does not install default keybindings. The following mappings are configured in the Lazy plugin spec used for development:

| Key | Action |
|---|---|
| `<leader>no` | Open the vault |
| `<leader>nq` | Close the vault and restore the previous working directory |
| `<leader>nn` | Create a note |
| `<leader>nf` | Follow the link or tag under the cursor |
| `<leader>nl` (visual) | Wrap the selection in `[[...]]` and open the note |
| `<leader>nb` | Go back |
| `<leader>nt` | Open today's journal |
| `<leader>n]` | Open the next journal entry |
| `<leader>n[` | Open the previous journal entry |
| `<leader>np` | Paste an image from the clipboard |
| `<leader>ni` | Insert an image from assets |

## Commands

| Command | Description |
|---|---|
| `:Neonotes` | Open vault root |
| `:NeonotesClose` | Close the vault and restore the previous working directory |
| `:NeonotesNew [name]` | Create a note in vault root |
| `:NeonotesJournalToday [project]` | Open today's journal (auto-detects git repo) |
| `:NeonotesJournalNext` | Next journal entry |
| `:NeonotesJournalPrevious` | Previous journal entry |
| `:NeonotesFollowLink` | Follow link under cursor |
| `:NeonotesGoBack` | Go back |
| `:NeonotesPasteImage` | Paste clipboard image |
| `:NeonotesInsertImage` | Pick image from assets |

## Lua API

`require("neonotes")` exposes:

| Function | Description |
|---|---|
| `setup(opts)` | Configure and initialize Neonotes |
| `open_vault()` | Open the vault index and enter vault mode |
| `close_vault()` | Leave vault mode and restore the previous working directory |
| `new_note(name?)` | Create or open a note in the vault root |
| `follow_link()` | Follow the wiki link or tag under the cursor |
| `link_from_selection()` | Turn a single-line visual selection into a wiki link and follow it |
| `go_back()` | Return to the previous jump-list location |
| `journal_today(project?)` | Open today's journal entry, optionally under a project heading |
| `journal_next()` | Open the next existing journal entry |
| `journal_previous()` | Open the previous existing journal entry |
| `paste_image()` | Save the clipboard image and insert its Markdown reference |
| `pick_image()` | Select an existing asset and insert its Markdown reference |

## License

MIT

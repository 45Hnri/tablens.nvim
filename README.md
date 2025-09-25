<h1 align="center">tablens.nvim</h1>

> [!NOTE]
> a [Telescope](https://github.com/nvim-telescope/telescope.nvim) picker for managing tab pages.

## Setup

The default config looks like this:

```lua
require("tablens").setup {
  highlighting = {
    index = "Special",
    path = nil,
    current = "Function",
    win_count = "Comment",
  },
  keymaps = {
    entry_move_down = "<c-j>",
    entry_move_up = "<c-k>",
    entry_delete = "<c-d>",
    open_picker = "<Leader>ft"
  }
}
```

## Installation

### lazy.nvim

```lua
{
    '45Hnri/tablens.nvim',
    config = {},
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-telescope/telescope-symbols.nvim',
        'nvim-telescope/telescope.nvim',
    }
}
```

## But why would you even use tabs

**This is a long one and reading it will most likely be a waste of your time**

While initially learning about (Neo)vim I was told that tab pages play a
different role than in other tools (e.g. browsers or code editors).

In a browser you would open a new tab every time you'd want another page open
in parallel. Meanwhile Vim has the following design for handling files 
(`:h windows.txt`): 

> Summary:
>    A buffer is the in-memory text of a file.
>    A window is a viewport on a buffer.
>    A tab page is a collection of windows.

So if you edit a file and switch to a second one, Vim will still have the
previous file loaded in a buffer. Therefore you don't need to open a tab page
for every file you want to work with. Your cursor position, undo list or
unwritten changes are persisted.

**Here is where it gets speculative:** Since this behavior isn't obvious for
beginners, Vim might shield them from overusing tab pages. I think there is also
subtle hints of this in the design of Vim:

1. There is no motion to just open a new tab (see the window motions)
    - There is however `<C-w>T` for moving the current window from a split view
    to a new tab (this requires at least 2 windows in one tab page)
    - So you spamming tabs would require you to type `:tabe` by default, which
    isn't super handy
2. The `tabline` comes with a `X` symbol for closing the current tab in the
corner, which is to be clicked
    - This cannot be disabled easily (the docs say disabling the mouse support
    removes this but it doesn't)
    - As a result it feels like a feature targeting newcomers

As a result of them not being as intuitive as other features, some might never
use them.

I got inspired to use Vim by seeing @ThePrimeTimeagen and I started my config
and therefore workflow following his example. In that workflow he solved a
common issue: **Working with multiple files at once**.

Normally this requires you to either:

1. Move through them sequentially using `:bn` / `:bp` or `[b` / `]b` (newer
   addition)
2. (Fuzzy) finding them directly with `:find` or a plugin like `Telescope` 
3. Picking them from custom `quickfix` list

All of which require more than one interaction with your keyboard.

You could also use global `marks` (which I also tried for quite a bit) but they
come with some issues:
1. Numbers are reserved for being set by a `shadafile`
2. They're not session based, so have fun switching projects (there is a
   `shadafile` workaround)
3. You need to manually update their locations since they are line specific

So he wrote a plugin that is now a household staple of Neovim setups:
`Harpoon`. This basically solves the problems of marks and gives you a nice
picker via `Telescope`. Where you can move and delete them.

After seeing [this video](https://www.youtube.com/watch?v=skW3clVG5Fo) and an overall shift in the community to configs 
with minimal plugin usage, I wanted to see what plugins I really need for my
workflow. For most there was a native alternative but eventually I came across
`Harpoon`. Where I was surprised that it's use case still had no popular native
solution.

**This is when I revisited tabs**. Mapping their indices to my number row
allows me to access them directly like with `Harpoon`. You can also access them
sequentially with `gt` and `gT`, move them with `:tabm` and view them with
`:tabf` or `:tabs`.

The only thing I am not happy with is the `tabline`. So I wrote this plugin
to just have a simple picker with some `Harpoon`-like management.

This is really just a custom picker for `Telescope` for some QOL. You can
totally go without and have a good time.

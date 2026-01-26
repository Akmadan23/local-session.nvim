# local-session.nvim

A fast, minimal and implicit session manager configured in lua.
It does not aim to replace standard vim session, it just offers
a different approach, more minimal and implicit.

## How does it work?
Unlike standard vim sessions, where you have to explicitly specify
the path to the session file, with `local-session.nvim` you just create
a file named `.session.lua` (the name can be changed in the configuration)
in the directory where you always open the same files (hence _local_),
and when you launch neovim from that directory with no arguments
the session will be automatically loaded.

### What is a session file?
A session file is a specification of which files will open automatically
on vim startup, where you can specify splits, tabs, custom options
and callback scripts.

### Creating a session file
Technically, session file is a lua file that must return a table (which will be
referred to as the _root table_) with the following properties:

Field       | Type              | Meaning
----------- | ----------------- | --------
path        | string            | Path¹ to the file
focus       | boolean           | If the window should have focus on startup
opts        | table             | Options local to the buffer of the file
split²      | File³             | File to be open in a horizontal split
vsplit²     | File³             | File to be open in a vertical split
callback    | string\|function  | Vim command (if string) or lua function to be ran in the buffer of the file
tabs        | table             | \[___root table_ only__\] List of files to be opened in tabs.
config      | function          | \[___root table_ only__\] Function to be ran before any other operation as a pre-configuration.

> [!IMPORTANT]
> All fields except `path` are optional. `path` can be omitted
> in the _root table_ only if there is a valid `tabs` field.

__Footnotes:__
1. non-absolute paths are considered relative
    to the position of the session file.
2. `split` and `vsplit` conflict with each other.
    If both are specified in the same file, only
    `split` will be applied.
3. a File can be a string containing its path or a table
    with the same properties listed above, except `tabs` and `config`
    which are only accepted in the _root table_.

### Examples

```lua
return {
  -- the main file to edit
  path = "mainFile",

  -- file to edit in a split (it can also be vsplit)
  split = "myFile2",

  -- options local to buffer (mainFile)
  opts = {
    shiftwidth = 2,
    tabstop = 2
  },

  -- function to call inside mainFile's buffer
  callback = function()
    print("Ok")
  end
}
```

or

```lua
return {
  -- files to be opened in tabs
  tabs = {
    "myFile1",
    "myFile2",
    "myFile3",
    "myDir/*", -- can contain wildcards only if it's a string not wrapped by a table
    { path = "myDir/*" }, -- this will open the file named "myDir/*" if exists, not every file inside myDir

    {
      path = "myOtherFile",
      vsplit = {
        path = "mySplitFile",
        opts = { number = false }
      }
    }
  }
}
```

> [!TIP]
> Each file inside the `tabs` group can be treated like the main one
> in the first snippet, with all options available.

## Installation
Install it with your plugin manager of choice,
here is an example using [lazy](https://github.com/folke/lazy.nvim):

```lua
require("lazy").setup {
  ...,
  {
    "akmadan23/local-session.nvim",
    opts = {
      -- your configuration here (can be empty but do not omit it)
    }
  },
  ...
}
```

> [!IMPORTANT]
> Lazy loading is __not__ recommended since `local-session.nvim` needs
> to be active at the very beginning of the neovim start process.

> [!NOTE]
> If you use a different plugin manager remember to call
> the `setup` function, otherwise it will not work.

## Configuration
The plugin comes with the following defaults:

```lua
require("local-session").setup {
  filename = ".session.lua",    -- name of session files
  notify_session_loaded = true, -- if true a success notification will be displayed when a session file is loaded
}
```

## Usage
Normal usage does not require any user interaction, just launch Neovim without file arguments
in a directory containing a `.session.lua` file, and that will be automatically loaded.

### Lua API
- `local_session.load(path)`: loads the session file in the current directory or in `path` if specified.
- `local_session.edit()`: opens in the current buffer the session file in the working directory, if present.

> [!NOTE]
> Assuming `local_session = require("local-session")`.

### Commands
- `:LocalSessionLoad`: alias for `local_session.load()`
- `:LocalSessionEdit`: alias for `local_session.edit()`


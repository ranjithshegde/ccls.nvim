# ccls.nvim

**_ This plugin is a work in progress. It works but is still missing some tests. Use at your own risk_**

This is a lua rewrite of vim-ccls by Martin Pilia

Features include:

- Most off-spec `ccls` features
- Setup lsp either via `lspconfig` or built-in `vim.lsp.start()`
- Use treesitter to highlight NodeTree window
- Update tagstack on jump to new node

Soon to be added:
Add floating previews for each nodes

## Configuration

Call `require("ccls").setup(config)` somewhere in your config

The default values are:

```lua
defaults = {
    win_config = {
        -- Sidebar configuration
        sidebar = {
            size = 50,
            position = "topleft",
            split = "vnew",
            width = 50,
            height = 20,
        },
        -- floating window configuration. check :help nvim_open_win for options
        float = {
            style = "minimal",
            relative = "cursor",
            width = 50,
            height = 20,
            row = 0,
            col = 0,
            border = "rounded",
        },
    },
    filetypes = {"c", "cpp", "objc", "objcpp"},
    lsp = {}
}
```

Any of the configuration options can be opmitted.

### Window configuration

`win_config` table accepts two keys:

-`sidebar`: split options

-`float`: same options supplied to `nvim_open_win` or other default floating
widnows

### Filetypes

By default, this plugin works on all filetypes accepted by `ccls` language
server. You can customize this by adding `filetypes` table to the config

```lua
require("ccls").setup({filetypes = {"c", "cpp", "opencl"}})
```

### Lsp

You can optionally setup LSP through the plugin.
There are two methods.

Using lspcofing:
This requires that you have `nvim-lspconfig` plugin installed and (already
loaded if lazy-loading). Pass the appropriate configurations like this
(pseudo_code)

```lua
    local lspconfig = require "lspconfig"
    local server_config = {
        filetypes = { "c", "cpp", "objc", "objcpp", "opencl" },
        root_dir = lspconfig.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
        init_options = { cache = {
            directory = vim.fs.normalize "~/.cache/ccls/",
        } },
        on_attach = require("my.attach").function,
        capabilities = my_caps_table_or_func
    }
    require("ccls").setup { lsp = { lspconfig = server_config } }
```

Any option omitted will use `lspconfig` defaults
Its also possible to entirely use lspconfig defaults like this:

```lua
require("ccls").setup({lsp = {use_defaults = true}})
```

If using nvim nightly, you can use `vim.lsp.start()` call instead which has the
benifit of reusing the same client on files within the same workspace.

To use that, pass this in your config, without supplying the keys `use_defaults`
or `lspconfig`

```lua
require("ccls").setup {
    lsp = {
        -- check :help vim.lsp.start for config options
        server = {
            name = "ccls", --String name
            cmd = "/usr/bin/ccls", -- point to your binary, has to be string
            args = {--[[Any args table]]
            },
            root_dir = vim.fs.dirname(vim.fs.find({ "compile_commands.json", ".git" }, { upward = true })[1]), -- or some other function
        },
    },
}
```

If neither `use_defaults` bool, `lspconfig` table or `server` table are
supplied, the plugin assumes you have setup ccls LSP eslewhere in your config

## ccls extensions

`ccls` LSP has many off-spec commands/calls. This plugin supports the following

### Quickfix

The below functions return a quickfix list of items

#### `$ccls/vars`

Called via `:CclsVars kind` or `require("ccls").vars(kind)`

#### `$ccls/member`

Called via `require("ccls").member(kind)`.
kind 4 = variables, 3 = functions, 2 = type

individual member calls can also be made via

- `:CclsMember` for Variables
- `:CclsMemberFunction` for functions
- `:CclsMemberTyoe` for types

#### `$ccls/call`

Called via `require("ccls").call(callee)`.
true = outgoing calls, false = incoming calls
Can also be called via

- `:CclsIncomingCalls`
- `:CclsOutgoingCalls`

#### `$ccls/inheritance`

Called via `require("ccls").inheritance(derived)`
derived `true` for derived classes, `false` for base classes

Can also be called via

- `:CclsBase`
- `:CclsDerived`

### Sidebar or float

The following functions are heirarchical and return either a sidebar or a
floating window

Each lua callback has a view option. View is a table with example `{type = "float"}` to use floating window.
For vim commands it can be passed via `:CclsMemberHeirarcy float`
When omitted it uses a sidebar.

Inside the window, use maps:

- `o` to open a node under cursor.
- `c` to close the node under cursor
- `O` to toggle node under cursor
- `CR` to jump to node under cursor
- `q` To quit window

#### `$ccls/member` heirarchy

Called via `require("ccls").memberHeirarchy(kind, view)`.
kind 4 = variables, 3 = functions, 2 = type

individual member calls can also be made via

- `:CclsMemberHeirarcy` for Variables
- `:CclsMemberFunction` for functions
- `:CclsMemberTyoe` for types

#### `$ccls/call` heirarchy

Called via `require("ccls").callHeirarchy(callee)`.
true = outgoing calls, false = incoming calls
Can also be called via

- `:CclsIncomingCallsHeirarchy`
- `:CclsOutgoingCallsHeirarchy`

#### `$ccls/inheritance` heirarcy

Called via `require("ccls").inheritanceHeirarchy(derived)`
derived `true` for derived classes, `false` for base classes

Can also be called via

- `:CclsBaseHierarchy`
- `:CclsDerivedHierarchy`

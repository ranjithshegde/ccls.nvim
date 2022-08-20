# ccls.nvim

[ccls_demo.webm](https://user-images.githubusercontent.com/10258296/185764424-45945b84-f397-4fdf-87d4-abbdaed8a0fc.webm)

**This plugin is a work in progress. It works but is still missing some tests. Use at your own risk**

Inspired by [vim-ccls](https://github.com/m-pilia/vim-ccls) by Martin Pilia.
The entire tree-browser part of the code is a lua rewrite of [vim-yggdrasil](https://github.com/m-pilia/vim-yggdrasil) by Martin Pilia.

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

<details>
    <summary>Code</summary>

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
}
```

</details>

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

You can optionally setup LSP through the plugin. _By default no setup calls are
initiated_.

There are two methods.

**Using lspcofing:**
This requires that you have `nvim-lspconfig` plugin installed and (already
loaded if lazy-loading). Pass the appropriate configurations like this.

<details>
    <summary>Code</summary>

```lua
    local util = require "lspconfig.util"
    local server_config = {
        filetypes = { "c", "cpp", "objc", "objcpp", "opencl" },
        root_dir = function(fname)
            return util.root_pattern("compile_commands.json", "compile_flags.txt", ".git")(fname)
                or util.find_git_ancestor(fname)
        end,
        init_options = { cache = {
            directory = vim.env.XDG_CACHE_HOME .. "/ccls/",
            -- or vim.fs.normalize "~/.cache/ccls" -- if on nightly
        } },
        --on_attach = require("my.attach").func,
        --capabilities = my_caps_table_or_func
    }
    require("ccls").setup { lsp = { lspconfig = server_config } }
```

</details>

Any option omitted will use `lspconfig` defaults.

Its also possible to entirely use lspconfig defaults like this:

```lua
require("ccls").setup({lsp = {use_defaults = true}})
```

**Using direct call:**
If using _nvim nightly_, you can use `vim.lsp.start()` call instead which has the
benefit of reusing the same client on files within the same workspace.

To use that, pass this in your config, without supplying the keys `use_defaults`
or `lspconfig`.

**WARNING:** Requires `nvim nightly` or `nvim 0.8`

<details>
    <summary>Code</summary>

```lua
require("ccls").setup {
    lsp = {
        -- check :help vim.lsp.start for config options
        server = {
            name = "ccls", --String name
            cmd = {"/usr/bin/ccls"}, -- point to your binary, has to be a table
            args = {--[[Any args table]] },
            offset_encoding = "utf-32", -- Can cause problems if not declared
            root_dir = vim.fs.dirname(vim.fs.find({ "compile_commands.json", ".git" }, { upward = true })[1]), -- or some other function that returns a string
            --on_attach = your_func,
            --capabilites = your_table/func
        },
    },
}
```

</details>

If neither `use_defaults` bool, `lspconfig` table or `server` table are
supplied, the plugin assumes you have setup ccls LSP elsewhere in your config.
This is the default behaviour

### Co-existance with clangd

If you wish to use clangd alongside ccls and want to avoid conflicting parallel
requests, you can use the following table to disable specific capabilities.

_Warning:_ Upstream (neovim) maintainers label the process of disabling
capabilities as _hacky_. Until there is a mechanism in-place upstream that
uses predicates to select clients for calls, this is the best solution.

This method uses both disabling certain capabilites and passing `nil` handlers
to others. This makes running two language servers more resource effecient.

use only the following options. If you do not wish to disable said option,
either set it to false or simply leave out that option

<details>
    <summary>Code</summary>

```lua
require("ccls").setup {
    lsp = {
        disable_capabilities = {
            completionProvider = true,
            documentFormattingProvider = true,
            documentRangeFormattingProvider = true,
            documentHighlightProvider = true,
            documentSymbolProvider = true,
            workspaceSymbolProvider = true,
            renameProvider = true,
            hoverProvider = true,
            codeActionProvider = true,
        },
        disable_diagnostics = true
    },
}
```

</details>

<details>
    <summary>Here is a complete setup example from my config (using nvim 0.8 features) </summary>

```lua
    local filetypes = { "c", "cpp", "objc", "objcpp", "opencl" }
    local server_config = {
        filetypes = filetypes,
        init_options = { cache = {
            directory = vim.fs.normalize "~/.cache/ccls/",
        } },
        name = "ccls",
        cmd = { "ccls" },
        offset_encoding = "utf-32",
        root_dir = vim.fs.dirname(
            vim.fs.find({ "compile_commands.json", "compile_flags.txt", ".git" }, { upward = true })[1]
        ),
    }
    require("ccls").setup {
        filetypes = filetypes,
        lsp = {
            server = server_config,
            disable_capabilities = {
                completionProvider = true,
                documentFormattingProvider = true,
                documentRangeFormattingProvider = true,
                documentHighlightProvider = true,
                documentSymbolProvider = true,
                workspaceSymbolProvider = true,
                renameProvider = true,
                hoverProvider = true,
                codeActionProvider = true,
            },
            disable_diagnostics = true,
        },
    }
```
</details>

## ccls extensions

`ccls` LSP has many off-spec commands/calls. This plugin supports the following

### Quickfix

The below functions return a quickfix list of items

#### `$ccls/vars`

Called via `:CclsVars kind` or `require("ccls").vars(kind)`

#### `$ccls/member`

Called via `require("ccls").member(kind)`.
kind 4 = variables, 3 = functions, 2 = type

Individual member calls can also be made via

- `:CclsMember` for Variables
- `:CclsMemberFunction` for functions
- `:CclsMemberType` for types

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

The following functions are hierarchical and return either a sidebar or a
floating window

Each lua callback has a view option. View is a table with example `{type = "float"}` to use floating window.
For vim commands it can be passed via `:CclsMemberHierarchy float`
When omitted it uses a sidebar.

Inside the window, use maps:

- `o` to open a node under cursor.
- `c` to close the node under cursor
- `O` to toggle node under cursor
- `CR` to jump to node under cursor
- `q` To quit window

#### `$ccls/member` hierarchy

Called via `require("ccls").memberHierarchy(kind, view)`.
kind 4 = variables, 3 = functions, 2 = type

individual member calls can also be made via

- `:CclsMemberHierarchy` for Variables
- `:CclsMemberFunction` for functions
- `:CclsMemberTyoe` for types

#### `$ccls/call` hierarchy

Called via `require("ccls").callHierarchy(callee)`.
true = outgoing calls, false = incoming calls
Can also be called via

- `:CclsIncomingCallsHierarchy`
- `:CclsOutgoingCallsHierarchy`

#### `$ccls/inheritance` hierarchy

Called via `require("ccls").inheritanceHierarchy(derived)`
derived `true` for derived classes, `false` for base classes

Can also be called via

- `:CclsBaseHierarchy`
- `:CclsDerivedHierarchy`

<details>
    <summary>Notes</summary>

## NodeTree

As of now, the `NodeTree` filetype which renders a tree structure is a direct
lua rewrite of Martin Pilia's `vim-yggdrasil`. At some point in the future I
will rewrite the logic to utilize lua-ecosystem features and make it a general
purpose Tree browser.

For now, it works exactly as intended but is hacky. The code structure is as follows.

- `ccls/provider.lua` contains functions to make LSP results compatible with
  NodeTree.
- `ccls/tree` Folder has the luafied `yggdrasil` tree code
  - `ccls/tree/tree.lua` has the Tree class.
  - `ccls/tree/node.lua` has the node class reduced to a single node generator call
    to avoid caching problems. Will be modularized when I rewrite the logic.
  - `ccls/tree/utils.lua` has other function calls not part of `tree` or `node` class but necessary

</details>

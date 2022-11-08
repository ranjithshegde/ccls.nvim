# ccls.nvim

A neovim plugin to configure ccls language server and use its extensions.
[ccls](https://github.com/MaskRay/ccls) is a language server for `c`, `cpp` and variants that offers comparable
on-spec features as `clangd` along with a many extensions.

This plugin offers a tree-browser structure to parse the AST provided by [ccls
extensions](https://github.com/MaskRay/ccls/wiki/LSP-Extensions) and to quickly navigate to them.

These AST features include:

- member functions/variables of an object
- base and derived hierarchy of a class
- call hierarchy for a function
- sturcts and variables of the same type in the project

There are some additional functionalities, follow the README for them.

[ccls_demo.webm](https://user-images.githubusercontent.com/10258296/185764424-45945b84-f397-4fdf-87d4-abbdaed8a0fc.webm)

- [ccls extensions](#ccls-extensions)
  - [Quickfix](#quickfix)
    - [`$ccls/member`](#cclsmember)
    - [`$ccls/call`](#cclscall)
    - [`$ccls/inheritance`](#cclsinheritance)
    - [`$ccls/vars`](#cclsvars)
  - [Sidebar or float](#sidebar-or-float)
    - [`$ccls/member` hierarchy](#cclsmember-hierarchy)
    - [`$ccls/call` hierarchy](#cclscall-hierarchy)
    - [`$ccls/inheritance` hierarchy](#cclsinheritance-hierarchy)
- [Configuration](#configuration)
  - [Window configuration](#window-configuration)
  - [Filetypes](#filetypes)
  - [Lsp](#lsp)
    - [Using lspcofing](#using-lspcofing)
    - [Using direct call](#using-direct-call)
    - [Codelens](#codelens)
  - [Coexistence with clangd](#coexistence-with-clangd)
- [NodeTree](#nodetree)
- [TODO](#todo)
  - [Preview](#preview)
  - [Tests](#tests)

**Features include**:

- Most off-spec `ccls` features
- Setup lsp either via `lspconfig` or built-in `vim.lsp.start()`
- Use treesitter to highlight NodeTree window
- Update tagstack on jump to new node
- Setup codelens autocmds

## ccls extensions

`ccls` LSP has many off-spec commands/calls. This plugin supports the following

### Quickfix

The below functions return a quickfix list of items

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

#### `$ccls/vars`

Called via `:CclsVars kind` or `require("ccls").vars(kind)`.
This is similar to `textDocument/references` except it checks for the variable
type.
Kind values are 1 for all occurence of the variable type, 2 for defintion of
current variable and 3 for references without definition.

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

    -- Lsp is not setup by default to avoid overriding user's personal configurations.
    -- Look ahead for instructions on using this plugin for ccls setup
    lsp = {
        codelens = {
            enabled = false,
            events = {"BufEnter", "BufWritePost"}
        }
    }
}
```

</details>

Any of the configuration options can be omitted.

### Window configuration

`win_config` table accepts two keys:

-`sidebar`: split options

-`float`: same options supplied to `nvim_open_win` or other default floating
windows

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

#### Using lspcofing

This requires that you have [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) plugin installed (and already
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
            -- or vim.fs.normalize "~/.cache/ccls" -- if on nvim 0.8 or higher
        } },
        --on_attach = require("my.attach").func,
        --capabilities = my_caps_table_or_func
    }
    require("ccls").setup { lsp = { lspconfig = server_config } }
```

</details>

Any option omitted will use `lspconfig` defaults.

It is also possible to entirely use lspconfig defaults like this:

```lua
require("ccls").setup({lsp = {use_defaults = true}})
```

#### Using direct call

If using _nvim 0.8_, you can use `vim.lsp.start()` call instead which has the
benefit of reusing the same client on files within the same workspace.

To use that, pass this in your config, without supplying the keys `use_defaults`
or `lspconfig`.

**Warning:** Requires `nvim 0.8`

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
            offset_encoding = "utf-32", -- default value set by plugin
            root_dir = vim.fs.dirname(vim.fs.find({ "compile_commands.json", ".git" }, { upward = true })[1]), -- or some other function that returns a string
            --on_attach = your_func,
            --capabilites = your_table/func
        },
    },
}
```

</details>

If neither `use_defaults`, `lspconfig` nor `server` are set,
then the plugin assumes you have setup ccls LSP elsewhere in your config.
This is the default behaviour.

#### Codelens

ccls has minimal codelens capabilites. If you are not familiar with codenels, see [Lsp spec
documentation](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_codeLens).
According to ccls server capabilities tree, ccls supports `resolveProvider`
option of codelens.

To enable codelens, set `lsp = { codelens = {enable = true}}` in the config.
It is necessary to setup autocmds to refresh codelens. The default events are
`BufEnter` and `BufWritePost`. You can customize it this way:

```lua
require('ccls').setup({
    lsp = {
        codelens = {
            enable = true,
            events = {"BufWritePost", "InsertLeave"}
        }
    }
})
```

_Note:_ Setting up codelens using this plugin requires neovim >= 0.8 as
`LspAttach` autocmd is only avaialble from version 0.8

### Coexistence with clangd

If you wish to use clangd alongside ccls and want to avoid conflicting parallel
requests, you can use the following table to disable specific capabilities.

_Warning:_ Upstream (neovim) maintainers label the process of disabling
capabilities as _hacky_. Until there is a mechanism in-place upstream that
uses predicates to select clients for calls, this is the best solution.

This method uses both disabling certain capabilities and passing `nil` handlers
to others. This makes running two language servers more resource efficient.

Use only the following options. If you do not wish to disable said option,
either set it to false or simply leave out that option.

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
        disable_diagnostics = true,
        disable_signature = true,
    },
}
```

</details>

**Note:** For these disabling mechanisms to be attached to the initiated/running ccls
instance, you will have to configure the server through the plugin either using
`lsp = {lspconfig = {my_config_table}}` or `lsp={server={my_0.8.config}}` as
descried earlier.

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
            disable_signature = true,
            codelens = { enable = true }
        },
    }
```

</details>

<details>
    <summary>Notes</summary>

## NodeTree

As of now, the `NodeTree` filetype which renders a tree structure is a direct
lua rewrite of Martin Pilia's `vim-yggdrasil`. At some point in the future I
will rewrite the logic to utilize more lua-ecosystem features and make it
a general purpose Tree browser.

For now, it works exactly as intended but is not easy read. The code structure is as follows.

- `ccls/provider.lua` contains functions to make LSP results compatible with
  NodeTree.
- `ccls/tree` Folder has the luafied `yggdrasil` tree code
  - `ccls/tree/tree.lua` has the Tree class.
  - `ccls/tree/node.lua` has the node class reduced to a single node generator call
    to avoid caching problems. Will be modularized when I rewrite the logic.
  - `ccls/tree/utils.lua` has other function calls not part of `tree` or `node` class but necessary

## TODO

### Preview

Open a floating preview window for node under the cursor from Sidebar

### Tests

This will take some time. Need to figure out how to run a language server for testing.
I will look through other plugins to see how they handle it. No promise on time.

</details>

## Credits

- [MaskRay](https://github.com/MaskRay) Thank you for creating the LSP!
- [vim-ccls](https://github.com/m-pilia/vim-ccls) for inspiration and speicifc ideas on translating LSP data into tree-like structure.
- [vim-yggdrasil](https://github.com/m-pilia/vim-yggdrasil) The entire tree-browser part of the code is a lua rewrite of this plugin.

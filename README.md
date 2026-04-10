cc# ccls.nvim

A neovim plugin to configure ccls language server and use its extensions.
[ccls](https://github.com/MaskRay/ccls) is a language server for `c`, `cpp` and variants that offers comparable
on-spec features as `clangd` along with many extensions.

This plugin offers a tree-browser structure to parse the AST provided by [ccls
extensions](https://github.com/MaskRay/ccls/wiki/LSP-Extensions) and to quickly navigate to them.

These AST features include:

- member functions/variables of an object
- base and derived hierarchy of a class
- call hierarchy for a function
- structs and variables of the same type in the project

There are some additional functionalities, follow the README for them.

[ccls_demo.webm](https://user-images.githubusercontent.com/10258296/185764424-45945b84-f397-4fdf-87d4-abbdaed8a0fc.webm)

> **Requires Neovim >= 0.12**
> If you are on an older version, use the [`pre_refactor_to_0.12`](https://github.com/ranjithshegde/ccls.nvim/releases/tag/pre_refactor_to_0.12) tag.

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
  - [Navigate](#navigate)
- [Configuration](#configuration)
  - [Window configuration](#window-configuration)
  - [Lsp](#lsp)
    - [Default LSP config](#default-lsp-config)
    - [Overriding LSP config](#overriding-lsp-config)
    - [Codelens](#codelens)
  - [Coexistence with clangd](#coexistence-with-clangd)
- [NodeTree](#nodetree)
- [TODO](#todo)

**Features include**:

- off-spec `ccls` features
- Native LSP setup via `vim.lsp.config` / `vim.lsp.enable` (nvim 0.12+)
- Use treesitter to highlight NodeTree window
- Update tagstack on jump to new node
- Setup codelens autocmds

## ccls extensions

`ccls` LSP has many off-spec commands/calls. This plugin supports the following.

### Quickfix

The below functions return a quickfix list of items.

#### `$ccls/member`

Called via `require("ccls").member(kind)`.
kind 4 = variables, 3 = functions, 2 = type

Individual member calls can also be made via

- `:CclsMember` for variables
- `:CclsMemberFunction` for functions
- `:CclsMemberType` for types

#### `$ccls/call`

Called via `require("ccls").call(callee)`.
`true` = outgoing calls, `false` = incoming calls. Can also be called via:

- `:CclsIncomingCalls`
- `:CclsOutgoingCalls`

#### `$ccls/inheritance`

Called via `require("ccls").inheritance(derived)`.
`true` for derived classes, `false` for base classes. Can also be called via:

- `:CclsBase`
- `:CclsDerived`

#### `$ccls/vars`

Called via `:CclsVars kind` or `require("ccls").vars(kind)`.
Similar to `textDocument/references` but filters by variable type.
Kind values: 1 = all occurrences of the variable type, 2 = definition of current variable, 3 = references without definition.

### Sidebar or float

The following functions are hierarchical and return either a sidebar or a floating window.

Each Lua callback has a `view` option. Pass `{type = "float"}` for a floating window.
For vim commands it can be passed via `:CclsMemberHierarchy float`.
When omitted, a sidebar is used.

Inside the window, use the following maps:

- `o` : open node under cursor
- `c` : close node under cursor
- `O` : toggle node under cursor
- `<CRw` : jump to node under cursor
- `q` : quit window

#### `$ccls/member` hierarchy

Called via `require("ccls").memberHierarchy(kind, view)`.
kind 4 = variables, 3 = functions, 2 = type. Can also be called via:

- `:CclsMemberHierarchy` for variables
- `:CclsMemberFunctionHierarchy` for functions
- `:CclsMemberTypeHierarchy` for types

#### `$ccls/call` hierarchy

Called via `require("ccls").callHierarchy(callee, view)`.
`true` = outgoing calls, `false` = incoming calls. Can also be called via:

- `:CclsIncomingCallsHierarchy`
- `:CclsOutgoingCallsHierarchy`

#### `$ccls/inheritance` hierarchy

Called via `require("ccls").inheritanceHierarchy(derived, view)`.
`true` for derived classes, `false` for base classes. Can also be called via:

- `:CclsBaseHierarchy`
- `:CclsDerivedHierarchy`

### Navigate

`$ccls/navigate` lets you jump between semantically related symbols in the AST — parent, child, or siblings — without opening a tree view.

Called via `require("ccls").navigate(direction)` where direction is one of `"U"` (parent), `"D"` (first child), `"L"` (previous sibling), `"R"` (next sibling).

Can also be called via:

- `:CclsNavigateUp`
- `:CclsNavigateDown`
- `:CclsNavigateLeft`
- `:CclsNavigateRight`

## Configuration

Call `require("ccls").setup(config)` somewhere in your config.

The default values are:

<details>
<summary>Defaults</summary>

```lua
{
    win_config = {
        sidebar = {
            size = 50,
            position = "left",
            width = 50,
            height = 20,
        },
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
    lsp = {
        codelens = {
            enable = false,
            events = { "BufEnter", "BufWritePost" },
        },
    },
}
```

</details>

Any of the configuration options can be omitted.

### Window configuration

`win_config` accepts two keys:

- `sidebar`: controls the split window. `position` maps to the `split` field of `nvim_open_win` (e.g. `"left"`, `"right"`). `size` sets the width.
- `float`: options passed directly to `nvim_open_win`.

### Lsp

> **Note:** LSP setup requires Neovim >= 0.12. If you are not on 0.12, use the `pre_refactor_to_0.12` tag and refer to its README.

This plugin uses Neovim's native `vim.lsp.config` / `vim.lsp.enable` API. **No lspconfig dependency is required.**

#### Default LSP config

A default LSP config is provided in `lsp/ccls.lua` and is automatically picked up by Neovim's LSP config discovery (`:h lsp-config`). It sets:

- `cmd = { "ccls" }`
- `filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }`
- `offset_encoding = "utf-32"`
- `workspace_required = true`
- `root_markers = { "compile_commands.json", "compile_flags.txt", ".ccls", ".git" }`

If this is sufficient for your setup, you do not need to pass a `server` table at all. Just call:

```lua
require("ccls").setup({ lsp = {--[[other config, not server table]] })
```

#### Overriding LSP config

To override any of the defaults, pass a `server` table inside `lsp`:

```lua
require("ccls").setup({
    lsp = {
        server = {
            cmd = { "/usr/local/bin/ccls" },
            root_markers = { "compile_commands.json", ".git" },
            -- any other vim.lsp.config-compatible keys
        },
    },
})
```

The `server` table is merged on top of the base config via `vim.lsp.config`.

> **Removed options:** `use_defaults`, `lspconfig`, and `root_dir` (string) are no longer supported. Use `root_markers` (table) instead, which is handled natively by Neovim's LSP client. The `lspconfig` dependency has been fully dropped.

#### Codelens

ccls has minimal codelens capabilities. See the [LSP spec](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_codeLens) for background.

To enable codelens:

```lua
require("ccls").setup({
    lsp = {
        codelens = {
            enable = true,
            events = { "BufWritePost", "InsertLeave" }, -- optional, these are not the defaults
        },
    },
})
```

Default refresh events are `BufEnter` and `BufWritePost`.

### Coexistence with clangd

If you use clangd alongside ccls and want to avoid conflicting parallel requests, you can disable specific capabilities and handlers.

> **Note:** Upstream Neovim maintainers consider disabling capabilities a workaround. This remains the best available approach until a predicate-based client selection mechanism lands upstream.

<details>
<summary>Full example (from my local config)</summary>

```lua
    local cpu_count = #vim.uv.cpu_info()
    local ccls_threads = math.max(1, cpu_count - 1)

    local server_config = {
        cmd = { 'ccls', '--log-file=/tmp/ccls.log', '--v=0' },
        filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'opencl' },
        init_options = {
            threads = ccls_threads,
            index = {
                trackDependency = 1,
                blacklist = { '^build/', '^.cache/', '^bin/', '^packaging', '^res' },
            },
            cache = {
                directory = '.ccls-cache',
            },
        },
    }

    require('ccls').setup {
        lsp = {
            server = server_config,
            disable_capabilities = {
                completionProvider = true,
                documentFormattingProvider = true,
                definitionProvider = true,
                documentRangeFormattingProvider = true,
                documentHighlightProvider = true,
                documentSymbolProvider = true,
                hoverProvider = true,
                referencesProvider = true,
                renameProvider = true,
                typeDefinitionProvider = true,
                workspaceSymbolProvider = true,
            },
            disable_diagnostics = true,
            disable_signature = true,
            codelens = { enable = true } },
    }
```

</details>

## NodeTree

The `NodeTree` filetype renders the tree structure returned by ccls hierarchy queries. It is a Lua rewrite of Martin Pilia's `vim-yggdrasil`. The code structure is:

- `ccls/provider.lua` adapts LSP results into a NodeTree-compatible format
- `ccls/tree/tree.lua` Tree class
- `ccls/tree/node.lua` node constructor and rendering logic

## TODO

### Preview

Open a floating preview window for the node under cursor from the sidebar.

### Tests

Need to figure out how to run a language server in a test environment. Will look through other plugins for prior art.

## Credits

- [MaskRay](https://github.com/MaskRay): thank you for creating the LSP!
- [vim-ccls](https://github.com/m-pilia/vim-ccls): inspiration and ideas for translating LSP data into tree structure.
- [vim-yggdrasil](https://github.com/m-pilia/vim-yggdrasil): the entire tree-browser part of the code is a Lua rewrite of this plugin.

-- Additional syntax highlighting for C and C++

-- Check if this syntax file has been loaded before
if vim.b.current_syntax then
    return
else
    vim.b.current_syntax = "NodeTree"
    vim.cmd "syntax clear"

    local ok, parse = pcall(require, "nvim-treesitter.parsers")
    if ok then
        vim.treesitter.language.register("NodeTree", "cpp")
    else
        vim.cmd "syntax include @cpp syntax/cpp.vim"
    end

    vim.api.nvim_exec(
        [[
    syntax match NodeTreeAnonymousNamespace "\v\(@<=anonymous namespace\)@=" contained
    syntax match NodeTreeLabel "\v^(\s|[▸▾•])*.*"
    \       contains=NodeTreeMarkLeaf,NodeTreeMarkCollapsed,NodeTreeMarkExpanded,NodeTreeAnonymousNamespace,@cpp

    syntax match NodeTreeMarkLeaf        "•" contained
    syntax match NodeTreeMarkCollapsed   "▸" contained
    syntax match NodeTreeMarkExpanded    "▾" contained
    syntax match NodeTreeNode            "\v^(\s|[▸▾•])*.*"
    \      contains=NodeTreeMarkLeaf,NodeTreeMarkCollapsed,NodeTreeMarkExpanded
    ]],
        false
    )

    vim.api.nvim_set_hl(0, "NodeTreeAnonymousNamespace", { link = "CppStructure" })
    vim.api.nvim_set_hl(0, "NodeTreeLabel", { link = "Identifier" })
    vim.api.nvim_set_hl(0, "NodeTreeMarkLeaf", { link = "Type" })
    vim.api.nvim_set_hl(0, "NodeTreeMarkExpanded", { link = "Type" })
    vim.api.nvim_set_hl(0, "NodeTreeMarkCollapsed", { link = "Macro" })
end

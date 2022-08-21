local nodeTree = {}

--- Generates a NodeTree buffer to view the generated AST. Tree data is retrieved
--- from the given {provider}.
function nodeTree.init(provider, bufnr)
    local t = require("ccls.tree.tree"):new(provider, bufnr)

    vim.api.nvim_create_autocmd("BufEnter", {
        buffer = bufnr,
        group = "NodeTree",
        callback = function()
            t:render()
        end,
    })

    vim.opt_local.filetype = "NodeTree"
    t:update()
end

return nodeTree

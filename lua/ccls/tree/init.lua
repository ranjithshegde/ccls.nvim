local nodeTree = {}

--- Turns the current buffer into an Yggdrasil tree view. Tree data is retrieved
--- from the given {provider}, and the state of the tree is stored in a
--- buffer-local variable called b:yggdrasil_tree.
---
--- The {bufnr} stores the buffer number of the view, {maxid} is the highest
--- known internal identifier of the nodes. The {index} is a list that
--- maps line numbers to nodes.
function nodeTree.init(provider, bufnr)
    local t = require("ccls.tree.tree"):new {
        provider = provider,
    }

    vim.api.nvim_create_autocmd("BufEnter", {
        buffer = bufnr,
        group = "NodeTree",
        callback = function()
            print "Aucmd"
            t:tree_render()
        end,
    })
    t.keys()

    vim.opt_local.filetype = "NodeTree"
    t:update()
end

return nodeTree

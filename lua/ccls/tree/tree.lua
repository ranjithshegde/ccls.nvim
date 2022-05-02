local Tree = {
    maxid = -1,
    root = {},
    index = {},
    provider = {},
}

function Tree:new(provider, bufnr)
    Tree.bufnr = bufnr
    Tree.provider = provider
    local t = Tree
    return t
end

--- Expand or collapse the node under cursor, and render the tree.
--- Please refer to *s:node_set_collapsed()* for details about the
--- arguments and behaviour.
function Tree:set_collapsed_under_cursor(collapsed)
    print "At tree set collapse"
    local node = require("ccls.tree.utils").get_node_under_cursor(self)
    node.set_collapsed(collapsed)
    Tree:render()
end

--- Run the action associated to the node currently under the cursor.
function Tree:exec_node_under_cursor()
    print "At tree exec node"
    require("ccls.tree.utils").get_node_under_cursor(self).exec()
end

--- Update the view if nodes have changed. If called with no arguments,
--- update the whole tree. If called with an {object} as argument, update
--- all the subtrees of nodes corresponding to {object}.
function Tree:update(...)
    print "At tree update"
    local args = { ... }

    -- TODO len
    -- if #args < 1 then
    if vim.fn.len(args) < 1 then
        print "at tree update args < 1"
        self.provider:getChildren(function(status, obj)
            self.provider:getTreeItem(function(...)
                require("ccls.tree.utils").tree_set_root_cb(self, obj, ...)
            end, obj)
        end)
    else
        self.provider:getTreeItem(function(...)
            require("ccls.tree.node").node_update(self, args[1], ...)
        end, args[1])
    end
end

--- Destroy the tree view. Wipe out the buffer containing it.
function Tree:wipe()
    vim.api.nvim_buf_delete(self.bunfr or 0, {})
end

--- Render the {tree}. This will replace the content of the buffer with the
--- tree view. Clear the index, setting it to a list containing a guard
--- value for index 0 (line numbers are one-based).
function Tree.render(tree)
    print "At tree render"
    if vim.api.nvim_buf_get_option(0, "filetype") ~= "NodeTree" then
        return
    end

    local cursor = vim.fn.getpos "."
    tree.index = { -1 }
    local text = tree.root:node_render(0)

    vim.opt_local.modifiable = true
    vim.api.nvim_command "silent 1,$delete _"
    vim.cmd("silent 0put=" .. text)
    vim.cmd "$d_"
    vim.opt_local.modifiable = false
    vim.fn.setpos(".", cursor)
end

function Tree.keys()
    vim.keymap.set("n", "<Plug>(nodetree-toggle-node)", function()
        Tree:set_collapsed_under_cursor(-1)
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-open-node)", function()
        Tree:set_collapsed_under_cursor(false)
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-close-node)", function()
        Tree:set_collapsed_under_cursor(true)
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-execute-node)", function()
        Tree:exec_node_under_cursor()
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-wipe-tree)", function()
        Tree:wipe()
    end, { buffer = true, silent = true })
end

return Tree

local Tree = {
    maxid = -1,
    root = {},
    index = {},
    provider = {},
}

function Tree:new(provider, bufnr)
    local t = Tree
    t.bufnr = bufnr
    t.provider = provider
    return t
end

--- Expand or collapse the node under cursor, and render the tree.
--- Please refer to *s:node_set_collapsed()* for details about the
--- arguments and behaviour.
function Tree:set_collapsed_under_cursor(collapsed)
    local node = require("ccls.tree.utils").get_node_under_cursor(self)
    node.set_collapsed(node, collapsed)
    Tree:render()
end

--- Run the action associated to the node currently under the cursor.
function Tree:exec_node_under_cursor()
    local node = require("ccls.tree.utils").get_node_under_cursor(self)
    node.exec(node)
end

--- Update the view if nodes have changed. If called with no arguments,
--- update the whole tree. If called with an {object} as argument, update
--- all the subtrees of nodes corresponding to {object}.
function Tree:update(...)
    local args = { ... }

    if vim.tbl_isempty(args) then
        ---@diagnostic disable-next-line: unused-local
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
function Tree:render()
    if vim.api.nvim_buf_get_option(0, "filetype") ~= "NodeTree" then
        return
    end

    local cursor = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())
    self.index = { -1 }

    local text = self.root.node_render(self.root, 0)
    text = vim.split(text, "\n")

    vim.opt_local.modifiable = true
    vim.api.nvim_buf_set_lines(0, 0, -1, false, text)
    vim.opt_local.modifiable = false

    vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), cursor)
end

return Tree

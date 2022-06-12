local Node = {
    id = nil,
    tree = {},
    object = {},
    tree_item = {},
    parent = {},
    collapsed = "",
    lazy_open = "",
    children = {},
}

-- function Node:clear()
--     self.id = nil
--     self.tree = {}
--     self.object = {}
--     self.tree_item = {}
--     self.parent = {}
--     self.collapsed = ""
--     self.lazy_open = ""
--     self.children = {}
-- end

-- -- Insert a new node in the tree, internally represented by a unique progressive
-- -- integer identifier {id}. The node represents a certain {object} (children of
-- -- {parent}) belonging to a given {tree}, having an associated action to be
-- -- triggered on execution defined by the function object {exec}. If {collapsed}
-- -- is true the node will be rendered as collapsed in the view. If {lazy_open} is
-- -- true, the children of the node will be fetched when the node is expanded by
-- -- the user.
function Node:create(tree, object, treeItem, parent)
    local n = Node
    tree.maxid = tree.maxid + 1
    n.id = tree.maxid
    n.tree = tree
    n.object = object
    n.tree_item = treeItem
    n.children = {}
    n.parent = parent
    n.collapsed = treeItem.collapsibleState == "collapsed"
    n.lazy_open = treeItem.collapsibleState ~= "none"
    return n
end

--- Return the depth level of the node in the tree. The level is defined
--- recursively: the root has depth 0, and each node has depth equal to the depth
--- of its parent increased by 1.
function Node:level()
    if vim.tbl_isempty(self.parent) then
        return 0
    end
    return 1 + self.parent:level()
end

--- Execute the action associated to a node
function Node:exec()
    -- if vim.fn.has_key(self.tree_item, "command") then
    if vim.tbl_contains(vim.tbl_keys(self.tree_item), "command") then
        self.tree_item.command()
    end
end

--- Set the node to be collapsed or expanded.
---
--- When {collapsed} evaluates to 0 the node is expanded, when it is 1 the node is
--- collapsed, when it is equal to -1 the node is toggled (it is expanded if it
--- was collapsed, and vice versa).
function Node:set_collapsed(collapsed)
    ---TODO verify
    self.collapsed = collapsed < 0 and not self.collapsed or not collapsed
end

function Node:node_render(level)
    local indent = string.rep(" ", 2 * level)
    local mark = "• "

    if #vim.tbl_keys(self.children) > 0 or self.lazy_open then
        mark = self.collapsed and "▸ " or "▾ "
    end

    local label = vim.split(self.tree_item.label, "\n")

    -- vim.fn.writefile({ vim.g.ccls_lrepr .. " " .. table.concat(label, "\n") }, "/home/ranjith/l.txt", "a")
    -- vim.g.ccls_lrepr = vim.g.ccls_lrepr + 1

    local indices = vim.fn.range(vim.fn.len(label))
    for index, _ in ipairs(indices) do
        indices[index] = self
    end
    table.insert(self.tree.index, unpack(indices))

    local repr = indent .. mark .. label[1]

    if label[2] then
        print "Success"
        repr = repr
            .. table.concat(vim.tbl_map(function(_, l)
                return "\n" .. indent .. " " .. l
            end, require("ccls.tree.utils").list_unpack(label, 2)))
    end

    local lines = { repr }

    if not self.collapsed then
        if self.lazy_open then
            self.lazy_open = false
            local callback = function(...)
                require("ccls.tree.utils").node_get_children_cb(self, ...)
            end

            self.tree.provider:getChildren(callback, self.object)
        end
        -- if vim.g.foo == 1 then
        --     vim.g.ccls_ls = self
        -- end
        -- vim.g.foo = vim.g.foo + 1
        for _, child in ipairs(self.children) do
            table.insert(lines, child:node_render(level + 1))
        end
    end
    return table.concat(lines, "\n")
end

--- If {status} equals 'success', update all nodes of {tree} representing
--- an {obect} with given {tree_item} representation.
function Node.node_update(tree, object, status, tree_item)
    if status ~= "success" then
        return
    end

    for _, node in
        pairs(require("ccls.tree.utils").search_subtree(tree.root, function(n)
            return n.object == object
        end))
    do
        node.tree_item = tree_item
        node.children = {}
        node.lazy_open = tree_item.collapsibleState ~= "none"
    end
    require("ccls.tree.tree").render(tree)
end

return Node

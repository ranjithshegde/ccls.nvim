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

-- -- Insert a new node in the tree, internally represented by a unique progressive
-- -- integer identifier {id}. The node represents a certain {object} (children of
-- -- {parent}) belonging to a given {tree}, having an associated action to be
-- -- triggered on execution defined by the function object {exec}. If {collapsed}
-- -- is true the node will be rendered as collapsed in the view. If {lazy_open} is
-- -- true, the children of the node will be fetched when the node is expanded by
-- -- the user.
function Node:create(tree, object, treeItem, parent)
    tree.maxid = tree.maxid + 1
    Node.id = tree.maxid
    Node.tree = tree
    Node.object = object
    Node.tree_item = treeItem
    Node.children = {}
    Node.parent = parent
    Node.collapsed = treeItem.collapsibleState == "collapsed"
    Node.lazy_open = treeItem.collapsibleState ~= "none"
    return Node
end

--- Return the depth level of the node in the tree. The level is defined
--- recursively: the root has depth 0, and each node has depth equal to the depth
--- of its parent increased by 1.
function Node:level()
    if self.parent == {} then
        return 0
    end
    return 1 + self.parent:level()
end

--- Execute the action associated to a node
function Node:exec()
    if vim.fn.has_key(self.tree_item, "command") then
        self.tree_item.command()
    end
end

--- Set the node to be collapsed or expanded.
---
--- When {collapsed} evaluates to 0 the node is expanded, when it is 1 the node is
--- collapsed, when it is equal to -1 the node is toggled (it is expanded if it
--- was collapsed, and vice versa).
function Node:set_collapsed(collapsed)
    self.collapsed = collapsed < 0 and not self.collapsed or not collapsed
end

function Node:node_render(level)
    local indent = string.rep(" ", 2 * level)
    local mark = "• "

    -- TODO len
    -- if #self.children > 0 or self.lazy_open ~= false then
    if vim.fn.len(self.children) > 0 or self.lazy_open ~= false then
        mark = self.collapsed and "▸ " or "▾ "
    end

    local label = vim.split(self.tree_item.label, "\n")

    local indices = vim.fn.range(vim.fn.len(label))
    for index, _ in ipairs(indices) do
        indices[index] = self
    end
    table.insert(self.tree.index, unpack(indices))

    local repr = indent .. mark .. label[1]

    if label[2] then
        repr = repr
            .. table.concat(vim.fn.map(require("ccls.tree.utils").list_unpack(label, 2), function(_, l)
                return "\n" .. indent .. " " .. l
            end))
    end

    local lines = repr
    if not self.collapsed then
        if self.lazy_open then
            self.lazy_open = false
            local callback = function(...)
                require("ccls.tree.utils").node_get_children_cb(self, ...)
            end

            self.tree.provider:getChildren(callback, self.object)
        end

        for _, child in ipairs(self.children) do
            table.insert(lines, child:node_render(level + 1))
        end
    end

    local newline = table.concat(lines, "\n")
    vim.pretty_print(newline)
    return newline
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

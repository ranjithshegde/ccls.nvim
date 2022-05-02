local Node = {
    id = nil,
    tree = {},
    object = {},
    tree_item = {},
    parent = {},
    -- collapsed = "",
    -- lazy_open = "",
    children = {},
}

-- -- Insert a new node in the tree, internally represented by a unique progressive
-- -- integer identifier {id}. The node represents a certain {object} (children of
-- -- {parent}) belonging to a given {tree}, having an associated action to be
-- -- triggered on execution defined by the function object {exec}. If {collapsed}
-- -- is true the node will be rendered as collapsed in the view. If {lazy_open} is
-- -- true, the children of the node will be fetched when the node is expanded by
-- -- the user.
function Node:new(tree, object, treeItem, parent)
    tree.maxid = tree.maxid + 1
    -- if vim.g.foo == 2 then
    --     vim.g.ccls_nlid = tree.maxid
    -- end
    print "At node new"
    Node.id = tree.maxid
    Node.tree = tree
    Node.object = object
    Node.tree_item = treeItem
    Node.parent = parent
    Node.collapsed = treeItem.collapsibleState == "collapsed"
    print "is collapsed = "
    print(Node.collapsed)
    Node.lazy_open = treeItem.collapsibleState ~= "none"
    return Node
end

--- Return the depth level of the node in the tree. The level is defined
--- recursively: the root has depth 0, and each node has depth equal to the depth
--- of its parent increased by 1.
function Node:level()
    print "At node level"
    if self.parent == {} then
        return 0
    end
    return 1 + self.parent:level()
end

--- Execute the action associated to a node
function Node:exec()
    print "At node exec"
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
    print "At node set collapsed"
    self.collapsed = collapsed < 0 and not self.collapsed or not collapsed
end

function Node:node_render(level)
    -- print "At node render"
    if not level then
        level = 0
    end
    local indent = string.rep(" ", 2 * level)

    local mark = "• "

    -- TODO len
    -- if #self.children > 0 or self.lazy_open ~= false then
    if vim.fn.len(self.children) > 0 or self.lazy_open ~= false then
        mark = self.collapsed and "▸ " or "▾ "
    end

    local label = vim.split(self.tree_item.label, "\n")

    -- TODO len
    -- self.tree.index = vim.tbl_deep_extend("force", self.tree.index, vim.tbl_map(vim.fn.range, vim.fn.range(#label)))

    -- if vim.g.foo <= 1 then
    --     -- vim.g.ccls_lmap = vim.tbl_map(function(...)
    --     --     self:node_render(...)
    --     -- end, vim.fn.range(vim.fn.len(label)))
    --     -- local foo = vim.fn.string(self.tree.index)
    --     -- vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/node_render_l2_repr.json")
    --     vim.g.ccls_lmap = self.tree.index
    --     vim.g.foo = vim.g.foo + 1
    -- end
    self.tree.index = vim.tbl_extend(
        "force",
        self.tree.index,
        vim.tbl_map(function(...)
            vim.fn.range(...)
        end, vim.fn.range(vim.fn.len(label)))
    )

    -- vim.fn.extend(self.tree.index, vim.fn.map(vim.fn.range(vim.fn.len(label)), self.node_rener))

    -- vim.g.ccls_self = self
    -- vim.g.selfIndex = self.tree.index
    -- vim.g.ccls_label = label
    -- vim.cmd "call extend(g:selfIndex, map(range(len(g:ccls_label)), 'g:ccls_self'))"

    local repr = indent .. mark .. label[1]

    if label[2] then
        repr = repr
            .. table.concat(vim.fn.map(require("ccls.tree.utils").list_unpack(label, 2), function(_, l)
                return "\n" .. indent .. " " .. l
            end))
    end

    -- if vim.g.foo == 2 then
    --     local foo = vim.fn.string(repr)
    --     vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/node_render_l2_repr.json")
    --     -- vim.g.ccls_llabel = label
    --     -- vim.g.ccls_lid = self.tree.maxid
    -- vim.g.ccls_lcol = self.collapsed
    -- end
    -- vim.g.foo = vim.g.foo + 1

    local lines = repr
    if not self.collapsed then
        if self.lazy_open then
            self.lazy_open = false
            local callback = function(...)
                print "at node_render get children callback"
                require("ccls.tree.utils").node_get_children_cb(self, ...)
            end

            -- if vim.g.foo <= 1 then
            --     local foo = vim.fn.string(self.object)
            --     vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/node_render_l1_selfObject.json")
            --     -- vim.g.ccls_llabel = label
            --     vim.g.ccls_lid = self.tree.maxid
            --     vim.g.foo = vim.g.foo + 1
            -- end
            self.tree.provider:getChildren(callback, self.object)
        end
        local count = 1
        -- if vim.tbl_islist(self.children) then
        --     vim.g.ccls_list = true
        -- else
        --     vim.g.ccls_list = false
        -- end
        while count <= #self.children do
            local child = self.children[count]
            table.insert(lines, child:node_render(level + 1))
            count = count + 1
            vim.g.foo = vim.g.foo + 1
        end
        -- for _, child in pairs(self.children) do
        -- while count < vim.fn.len(self.children) do
        -- vim.g.foo = vim.g.foo + 1
        -- table.insert(lines, child:node_render(level + 1))
        -- end
        -- end
    end

    return table.concat(lines, "\n")
end

--- If {status} equals 'success', update all nodes of {tree} representing
--- an {obect} with given {tree_item} representation.
function Node.node_update(tree, object, status, tree_item)
    print "At node update"
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

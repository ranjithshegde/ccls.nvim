-- local Node = {}

--- Return the depth level of the node in the tree. The level is defined
--- recursively: the root has depth 0, and each node has depth equal to the depth
--- of its parent increased by 1.
local function get_level(node)
    if vim.tbl_isempty(node.parent) then
        return 0
    end
    return 1 + node.parent.level(node.parent)
end

--- Execute the action associated to a node
local function exec(node)
    if vim.tbl_contains(vim.tbl_keys(node.tree_item), "command") then
        node.tree_item.command()
    end
end

--- Set the node to be collapsed or expanded.
--- When {collapsed}  is false the node is expanded, when it is true the node is
--- collapsed, when it is nil the node is toggled (it is expanded if it
--- was collapsed, and vice versa).
local function set_collapsed(node, collapsed)
    node.collapsed = collapsed == nil and not node.collapsed or collapsed
end

local function node_render(node, level)
    local indent = string.rep(" ", 2 * level)
    local mark = "• "

    if not vim.tbl_isempty(node.children) or node.lazy_open then
        mark = node.collapsed and "▸ " or "▾ "
    end

    local label = vim.split(node.tree_item.label, "\n")

    local indices = vim.fn.range(#label)
    for _ in ipairs(indices) do
        table.insert(node.tree.index, node)
    end

    local lines = {}

    for i, v in ipairs(label) do
        if i == 1 then
            table.insert(lines, indent .. mark .. v)
        else
            table.insert(lines, indent .. v)
        end
    end

    if not node.collapsed then
        if node.lazy_open then
            node.lazy_open = false
            local callback = function(...)
                require("ccls.tree.utils").node_get_children_cb(node, ...)
            end

            node.tree.provider:getChildren(callback, node.object)
        end
        for _, child in pairs(node.children) do
            table.insert(lines, child.node_render(child, level + 1))
        end
    end
    return table.concat(lines, "\n")
end

--- If {status} equals 'success', update all nodes of {tree} representing
--- an {obect} with given {tree_item} representation.
local function node_update(tree, object, status, tree_item)
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

--- Insert a new node in the tree, internally represented by a unique progressive
--- integer identifier {id}. The node represents a certain {object} (children of
--- {parent}) belonging to a given {tree}, having an associated action to be
--- triggered on execution defined by the function object {exec}. If {collapsed}
--- is true the node will be rendered as collapsed in the view. If {lazy_open} is
--- true, the children of the node will be fetched when the node is expanded by
--- the user.
return function(tree, object, treeItem, parent)
    local n = {}
    tree.maxid = tree.maxid + 1
    n.id = tree.maxid
    n.tree = tree
    n.object = object
    n.tree_item = treeItem
    n.children = {}
    n.parent = parent
    n.collapsed = treeItem.collapsibleState == "collapsed"
    n.lazy_open = treeItem.collapsibleState ~= "none"
    n.node_update = node_update
    n.node_render = node_render
    n.level = get_level
    n.set_collapsed = set_collapsed
    n.exec = exec
    n.node_render = node_render
    return n
end

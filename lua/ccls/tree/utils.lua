local utils = {}

-- Callback to retrieve the tree item representation of an object
function utils.node_get_tree_item_cb(node, object, status, treeItem)
    if status == "success" then
        local newnode = require "ccls.tree.node"(node.tree, object, treeItem, node)
        table.insert(node.children, newnode)
        newnode.tree:render()
    end
end

-- Callback to retrieve the children objects of a node.
function utils.node_get_children_cb(node, status, childObjectList)
    for _, object in pairs(childObjectList) do
        local callback = function(...)
            utils.node_get_tree_item_cb(node, object, ...)
        end
        node.tree.provider:getTreeItem(callback, object)
    end
end

-- Given a funcref {Condition}, return a list of all nodes in the subtree of
-- {node} for which {Condition} evaluates to v:true.
function utils.search_subtree(node, condition)
    if condition(node) then
        return { node }
    end

    if vim.tbl_isempty(node.children) then
        return {}
    end
    local result = {}

    for _, child in pairs(node.children) do
        table.insert(result, utils.search_subtree(child, condition))
    end
    return result
end

--- Return the node currently under the cursor from the given {tree}.
function utils.get_node_under_cursor(tree)
    local index = math.min(vim.fn.line "." + 1, vim.fn.len(tree.index))
    return tree.index[index]
end

--- Callback that sets the root node of a given {tree}, creating a new node
--- with a {tree_item} representation for the given {object}. If {status} is
--- equal to 'success', the root node is set and the tree view is updated
--- accordingly, otherwise nothing happens.
function utils.tree_set_root_cb(tree, object, status, treeItem)
    if status == "success" then
        tree.maxid = -1
        tree.root = require "ccls.tree.node"(tree, object, treeItem, {})
        tree:render()
    end
end

function utils.tbl_haskey(table, any_of, ...)
    local args = { ... }
    if any_of then
        for _, v in ipairs(args) do
            if vim.tbl_contains(vim.tbl_keys(table), v) then
                return true
            end
        end
    else
        for _, v in ipairs(args) do
            if not vim.tbl_contains(vim.tbl_keys(table), v) then
                return false
            end
        end
        return true
    end
end

function utils.assert_table(table)
    if type(table) ~= "table" then
        return false
    else
        return not vim.tbl_isempty(table)
    end
end

return utils

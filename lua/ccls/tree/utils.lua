local utils = {}

-- Callback to retrieve the tree item representation of an object
function utils.node_get_tree_item_cb(node, object, status, treeItem)
    print "at get tree callback"
    if status == "success" then
        local newnode = require("ccls.tree.node"):new(node.tree.maxid, node.tree, object, treeItem, node)
        table.insert(node.children, newnode)
        require("ccls.tree.tree").render(newnode.tree)
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
        return node
    end

    -- TODO len
    -- if #node.children < 1 then
    if vim.fn.len(node.children) < 1 then
        return {}
    end
    local result = {}

    for child in pairs(node.children) do
        vim.tbl_insert(result, utils.search_subtree(child, condition))
    end
    return result
end

--- Return the node currently under the cursor from the given {tree}.
function utils.get_node_under_cursor(node)
    -- TODO len
    -- local index = math.min(vim.fn.line ".", #node.index - 1)
    local index = math.min(vim.fn.line ".", vim.fn.len(node.index) - 1)
    return node.index[index]
end

--- Callback that sets the root node of a given {tree}, creating a new node
--- with a {tree_item} representation for the given {object}. If {status} is
--- equal to 'success', the root node is set and the tree view is updated
--- accordingly, otherwise nothing happens.
function utils.tree_set_root_cb(tree, object, status, treeItem)
    if status == "success" then
        tree.maxid = -1
        tree.root = require("ccls.tree.node"):new(tree.maxid, tree, object, treeItem, {})
        require("ccls.tree.tree").render(tree)
    end
end

function utils.get_first_list(object)
    local ok = false
    local index
    for key, value in pairs(object) do
        if vim.tbl_islist(value) then
            ok = true
            index = key
            break
        end
    end
    return ok, index
end

function utils.get_nth_element(data, index)
    local i = 1
    for _, value in pairs(data) do
        if i == #data then
            print "Table does not have the value"
            return data
        elseif i == index then
            -- vim.pretty_print(value)
            return value
        else
            i = i + 1
        end
    end
end
return utils

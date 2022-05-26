local utils = {}

-- Callback to retrieve the tree item representation of an object
function utils.node_get_tree_item_cb(node, object, status, treeItem)
    print "at get tree callback"
    if status == "success" then
        local node_table = {
            id = node.tree.maxid,
            tree = node.tree,
            object = object,
            tree_item = treeItem,
            parent = node,
            collapsed = treeItem.collapsibleState == "collapsed",
            lazy_open = treeItem.collapsibleState ~= "none",
        }
        local newnode = require("ccls.tree.node"):new(node_table)
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

    if #vim.tbl_keys(node.children) < 1 then
        return {}
    end
    local result = {}

    for _, child in pairs(node.children) do
        vim.tbl_insert(result, utils.search_subtree(child, condition))
    end
    return result
end

--- Return the node currently under the cursor from the given {tree}.
function utils.get_node_under_cursor(node)
    local index = math.min(vim.fn.line ".", #vim.tbl_keys(node.index) - 1)
    return node.index[index]
end

--- Callback that sets the root node of a given {tree}, creating a new node
--- with a {tree_item} representation for the given {object}. If {status} is
--- equal to 'success', the root node is set and the tree view is updated
--- accordingly, otherwise nothing happens.
function utils.tree_set_root_cb(tree, object, status, treeItem)
    if status == "success" then
        tree.maxid = -1

        local node_table = {
            id = tree.maxid,
            tree = tree,
            object = object,
            tree_item = treeItem,
            parent = {},
            collapsed = treeItem.collapsibleState == "collapsed",
            lazy_open = treeItem.collapsibleState ~= "none",
        }
        tree.root = require("ccls.tree.node"):new(node_table)
        require("ccls.tree.tree").render(tree)
    end
end

---Iterate through the table and return the first vim-list or stateless table
---@param object table
---@return boolean false. true if a list is found
---@return list list
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
        if i == index then
            return value
        else
            i = i + 1
        end
    end
end

--- Unpack a table similar to Lua 5.2 table.unpack
---@param list table statless or list
---@param start number the index to start at
---@return table table containing values from start to end
function utils.list_unpack(list, start)
    local l = {}
    local i = 1
    for _, value in ipairs(list) do
        if i > start then
            table.insert(l, value)
        end
        i = i + 1
    end
    return l
end

function utils.expand(t1, t2)
    for k, _ in pairs(t1) do
        if t2[k] then
            t1[k] = t2[k]
        end
    end
    return t1
end

return utils

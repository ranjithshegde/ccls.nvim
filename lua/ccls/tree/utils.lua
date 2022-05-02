local utils = {}

-- Callback to retrieve the tree item representation of an object
function utils.node_get_tree_item_cb(node, object, status, treeItem)
    -- if vim.g.foo <= 1 then
    --     local foo = vim.fn.string(object)
    --     vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/cb_node_tree_obj_l1.json")
    --     vim.g.foo = vim.g.foo + 1
    -- end
    print "at get tree callback"
    -- vim.pretty_print(utils.get_nth_element(node, 1))

    -- print("Before get_tree_cb " .. node.tree.maxid)
    if status == "success" then
        local newnode = require("ccls.tree.node"):new(node.tree, object, treeItem, node)
        -- print("After get_tree_cb " .. node.tree.maxid)
        -- if vim.g.foo <= 1 then
        -- local foo = vim.fn.string(node.tree)
        -- vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/node_get_tree_item_cb_l1_tree.json")
        --     vim.g.ccls_lid = newnode.id
        --     vim.g.foo = vim.g.foo + 1
        -- end
        table.insert(node.children, newnode)
        require("ccls.tree.tree").render(newnode.tree)
    end
end

-- Callback to retrieve the children objects of a node.
function utils.node_get_children_cb(node, status, childObjectList)
    print "at node get children callback"
    -- if vim.g.foo <= 1 then
    --     local foo = vim.fn.string(childObjectList)
    --     vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/node_get_children_cb_l1_cobj.json")
    --     -- vim.g.ccls_lnode = node
    --     vim.g.foo = vim.g.foo + 1
    -- end
    for _, object in pairs(childObjectList) do
        -- if vim.g.foo <= vim.fn.len(childObjectList) then
        -- if vim.g.foo <= 20 then
        --     local foo = vim.fn.string(object)
        --     vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/node_get_children_cb_l1_obj1.json", "a")
        --     vim.g.foo = vim.g.foo + 1
        -- end
        local callback = function(...)
            utils.node_get_tree_item_cb(node, object, ...)
        end
        node.tree.provider:getTreeItem(callback, object)
    end
end

-- Given a funcref {Condition}, return a list of all nodes in the subtree of
-- {node} for which {Condition} evaluates to v:true.
function utils.search_subtree(node, condition)
    print "At search subtree"
    if condition(node) then
        return node
    end

    -- TODO len
    -- if #node.children < 1 then
    if vim.fn.len(node.children) < 1 then
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
    print "At get node under cursor"
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
    print "at tree set root"

    if status == "success" then
        -- if vim.tbl_islist(object) then
        --     print "List Found"
        --     object = object[1]
        -- end
        tree.maxid = -1
        -- print("Before set_tree_cb " .. tree.maxid)
        tree.root = require("ccls.tree.node"):new(tree, object, treeItem, {})
        -- print("After set_tree_cb " .. tree.maxid)
        -- if vim.g.foo <= 1 then
        -- local foo = vim.fn.string(tree.root)
        -- vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/tree_set_root_cb_l1_newnode.json")
        -- vim.g.ccls_lmaxid = tree.root.id
        -- vim.g.foo = vim.g.foo + 1
        -- end
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
        -- if i == #data then
        --     print "Table does not have the value"
        --     return data
        if i == index then
            -- vim.pretty_print(value)
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

return utils

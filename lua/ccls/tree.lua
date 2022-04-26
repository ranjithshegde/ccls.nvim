local Tree = {}
-- Callback to retrieve the tree item representation of an object
function Tree.node_get_tree_item_cb(node, object, status, tree_item)
    if status == "success" then
        local new_node = Tree.node_new(node.tree, object, tree_item, node)
        table.insert(node.children, new_node)
        Tree.tree_render(new_node.tree)
    end
end

-- Callback to retrieve the children objects of a node.
function Tree.node_get_children_cb(node, status, childObjectList)
    for _, object in pairs(childObjectList) do
        local callback = function(...)
            Tree.node_get_tree_item_cb(node, object, ...)
        end
        node.tree.provider.getTreeItem(callback, object)
    end
end

-- Set the node to be collapsed or expanded.
--
-- When {collapsed} evaluates to 0 the node is expanded, when it is 1 the node is
-- collapsed, when it is equal to -1 the node is toggled (it is expanded if it
-- was collapsed, and vice versa).
-- local current_collapsed_state
function Tree.node_set_collapsed(dict, collapsed)
    dict.collapsed = collapsed < 0 and not dict.collapsed or not collapsed
end

-- Given a funcref {Condition}, return a list of all nodes in the subtree of
-- {node} for which {Condition} evaluates to v:true.
function Tree.search_subtree(node, condition)
    if condition(node) then
        return { node }
    end
    if #node.children < 1 then
        return {}
    end
    local result = {}
    for _, child in pairs(node.children) do
        vim.tbl_insert(result, Tree.search_subtree(child, condition))
    end
    return result
end

--- Execute the action associated to a node
function Tree.node_exec(dict)
    if vim.fn.has_key(dict.tree_item, "command") then
        dict.tree_item.command()
    end
end

-- Return the depth level of the node in the tree. The level is defined
-- recursively: the root has depth 0, and each node has depth equal to the depth
-- of its parent increased by 1.
function Tree.node_level(dict)
    if vim.tbl_isempty(dict.parent) then
        return 0
    end
    return 1 + dict.parent.level()
end

local function tablify(s, delimiter)
    local result = {}
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

--- Return the string representation of the node. The {level} argument represents
--- the depth level of the node in the tree and it is passed for convenience, to
--- simplify the implementation and to avoid re-computing the depth.
function Tree.node_render(dict, level)
    local indent = string.rep(" ", 2 * level)
    local mark = "• "

    if #dict.children > 0 or dict.lazy_open ~= false then
        mark = dict.collapsed and "▸ " or "▾ "
    end

    local tempLabel = dict.tree_item.label()
    local label = tablify(dict.tree_item.label(), "\n")
    dict.tree.index = vim.tbl_deep_extend("force", dict.tree.index, vim.tbl_map(dict, vim.fn.range(#label)))

    local repr = indent
        .. mark
        .. label[0]
        .. table.concat(vim.tbl_map(function(l)
            return "\n" .. indent .. " " .. l
        end, label[1]))

    local lines = repr

    if not dict.collapsed then
        if dict.lazy_open then
            dict.lazy_open = false
            local callback = function(...)
                Tree.node_get_children_cb(dict, ...)
            end
            dict.tree.provider.getChildren(callback, dict.object)
        end
        for _, child in pairs(dict.children) do
            table.insert(lines, child.render(level + 1))
        end
    end
    return table.concat(lines, "\n")
end

-- Insert a new node in the tree, internally represented by a unique progressive
-- integer identifier {id}. The node represents a certain {object} (children of
-- {parent}) belonging to a given {tree}, having an associated action to be
-- triggered on execution defined by the function object {exec}. If {collapsed}
-- is true the node will be rendered as collapsed in the view. If {lazy_open} is
-- true, the children of the node will be fetched when the node is expanded by
-- the user.
function Tree.node_new(tree, object, tree_item, parent)
    -- print "Node Render"
    tree.maxid = tree.maxid + 1
    local temp = {
        id = tree.maxid,
        tree = tree,
        object = object,
        tree_item = tree_item,
        parent = parent,
        collapsed = tree_item.collapsibleState == "collapsed",
        lazy_open = tree_item.collapsibleState ~= "none",
        children = {},
    }

    temp.level = function()
        Tree.node_level(temp)
    end
    temp.exec = function()
        Tree.node_exec(temp)
    end
    temp.set_collapsed = function(...)
        Tree.node_set_collapsed(temp, ...)
    end
    temp.render = function(...)
        Tree.node_render(temp, ...)
    end
    return temp
end

--- Callback that sets the root node of a given {tree}, creating a new node
--- with a {tree_item} representation for the given {object}. If {status} is
--- equal to 'success', the root node is set and the tree view is updated
--- accordingly, otherwise nothing happens.
function Tree.tree_set_root_cb(tree, object, status, tree_item)
    if status == "success" then
        tree.maxid = 0
        tree.root = Tree.node_new(tree, object, tree_item, {})
        print "At tree callback root"
        Tree.tree_render(tree)
    end
end

--- Return the node currently under the cursor from the given {tree}.
function Tree.get_node_under_cursor(tree)
    local index
    if tree then
        index = math.min(vim.fn.line ".", #tree.index - 1)
    else
        index = vim.fn.line "."
    end
    return tree.index[index]
end

--- Expand or collapse the node under cursor, and render the tree.
--- Please refer to *s:node_set_collapsed()* for details about the
--- arguments and behaviour.
function Tree.tree_set_collapsed_under_cursor(dict, collapsed)
    local node = Tree.get_node_under_cursor(dict)
    node.set_collapsed(collapsed)
    Tree.tree_render(dict)
end

--- Run the action associated to the node currently under the cursor.
function Tree.tree_exec_node_under_cursor(dict)
    Tree.get_node_under_cursor(dict).exec()
end

--- Render the {tree}. This will replace the content of the buffer with the
--- tree view. Clear the index, setting it to a list containing a guard
--- value for index 0 (line numbers are one-based).
function Tree.tree_render(tree)
    if vim.api.nvim_buf_get_option(0, "filetype") ~= "NodeTree" then
        return
    end

    local cursor = vim.fn.getpos "."
    tree.index = { -1 }
    -- tree.index = { 0 }
    local text = tree.root.render(0)

    vim.opt_local.modifiable = true
    vim.api.nvim_command "silent 1,$delete _"
    vim.cmd("silent 0put=" .. text)
    vim.cmd "$d_"
    vim.opt_local.modifiable = false
    vim.fn.setpos(".", cursor)
end

--- If {status} equals 'success', update all nodes of {tree} representing
--- an {obect} with given {tree_item} representation.
function Tree.node_update(tree, object, status, tree_item)
    if status ~= "success" then
        return
    end

    for _, node in
        pairs(Tree.search_subtree(tree.root, function(n)
            return n.object == object
        end))
    do
        node.tree_item = tree_item
        node.children = {}
        node.lazy_open = tree_item.collapsibleState ~= "none"
    end
    Tree.tree_render(tree)
end

--- Update the view if nodes have changed. If called with no arguments,
--- update the whole tree. If called with an {object} as argument, update
--- all the subtrees of nodes corresponding to {object}.
function Tree.tree_update(dict, ...)
    local args = { ... }

    if #args < 1 then
        dict.provider.getChildren(function(status, obj)
            dict.provider.getTreeItem(function(...)
                Tree.tree_set_root_cb(dict, obj[1], ...)
            end, obj[1])
        end)
    else
        dict.provider.getTreeItem(function(...)
            Tree.node_update(dict, args[1], ...)
        end, args[1])
    end
end

print "at getChildren Tree lamda"
-- print "at getTreeItem Tree lamda"
-- local arg = { ... }
-- vim.pretty_print(arg)

-- function! s:tree_update(...) dict abort
--     if a:0 < 1
--         call l:self.provider.getChildren({ status, obj -> l:self.provider.getTreeItem( function('s:tree_set_root_cb', [l:self, obj[0]]), obj[0]) })
--     else
--         call l:self.provider.getTreeItem(function('s:node_update', [l:self, a:1]), a:1)
--     endif
-- endfunction

--- Destroy the tree view. Wipe out the buffer containing it.
function Tree.tree_wipe(dict)
    vim.api.nvim_buf_delete(dict.bunfr or 0, {})
end

function Tree.keys()
    vim.keymap.set("n", "<Plug>(nodetree-toggle-node)", function()
        Tree.nodeTree.set_collapsed_under_cursor(-1)
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-open-node)", function()
        Tree.nodeTree.set_collapsed_under_cursor(false)
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-close-node)", function()
        Tree.nodeTree.set_collapsed_under_cursor(true)
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-execute-node)", function()
        Tree.nodeTree.exec_node_under_cursor()
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-wipe-tree)", function()
        Tree.nodeTree.wipe()
    end, { buffer = true, silent = true })
end

--- Turns the current buffer into an Yggdrasil tree view. Tree data is retrieved
--- from the given {provider}, and the state of the tree is stored in a
--- buffer-local variable called b:yggdrasil_tree.
---
--- The {bufnr} stores the buffer number of the view, {maxid} is the highest
--- known internal identifier of the nodes. The {index} is a list that
--- maps line numbers to nodes.
function Tree.newTree(provider, bufnr)
    Tree.nodeTree = {
        maxid = -1,
        root = {},
        index = {},
        provider = provider,
    }
    Tree.nodeTree.set_collapsed_under_cursor = function(...)
        Tree.tree_set_collapsed_under_cursor(Tree.nodeTree, ...)
    end
    Tree.nodeTree.exec_node_under_cursor = function()
        Tree.tree_exec_node_under_cursor(Tree.nodeTree)
    end
    Tree.nodeTree.update = function(...)
        Tree.tree_update(Tree.nodeTree, ...)
    end
    Tree.nodeTree.wipe = function()
        Tree.tree_wipe(Tree.nodeTree)
    end

    vim.api.nvim_create_autocmd("BufEnter", {
        buffer = bufnr,
        group = "NodeTree",
        callback = function()
            print "Aucmd"
            Tree.tree_render(Tree.nodeTree)
        end,
    })
    Tree.keys()

    vim.opt_local.filetype = "NodeTree"
    Tree.nodeTree.update()
end

return Tree

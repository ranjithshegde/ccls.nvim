local provider = {
    root = {},
    root_state = "expanded",
    cached_children = {},
    method = "",
    filetype = "",
    bufnr = 0,
    extra_params = {},
}

function provider:new(data, method, filetype, bufnr, extra_params)
    provider.root = data
    provider.method = method
    provider.filetype = filetype
    provider.bufnr = bufnr
    provider.extra_params = extra_params
    local p = provider
    return p
end

--- Get the label for a given node.
local function get_label(data)
    print "At get label"
    -- TODO len
    -- if vim.fn.has_key(data, "fieldName") == 1 and #data.fieldName >= 1 then
    if vim.fn.has_key(data, "fieldName") == 1 and vim.fn.len(data.fieldName) >= 1 then
        -- if vim.g.foo <= 1 then
        --     vim.g.ccls_llabel = data.fieldName
        --     vim.g.foo = vim.g.foo + 1
        -- end
        return data.fieldName
    else
        -- if vim.g.foo <= 1 then
        --     vim.g.ccls_llabel = data.name
        --     vim.g.foo = vim.g.foo + 1
        -- end
        return data.name
    end
end

local function jump(file, line, column)
    local nodeTree_bufno = vim.fn.bufnr "%"
    vim.cmd 'silent execute "normal! <C-W><C-P>'
    if vim.g.ccls_close_on_jump then
        vim.api.nvim_buf_delete(nodeTree_bufno, { force = true })
    end
    local buffer = vim.fn.bufnr(file)
    local command = buffer and "b " .. buffer or "edit " .. file
    -- vim.cmd(command .. " | call cursor(" .. line .. "," .. column .. ")")
    vim.cmd(command)
    vim.fn.cursor { line, column }
end

--- Get the collapsibleState for a node. The root is returned expanded on
--- the first request only (to avoid issues with cyclic graphs).
function provider:get_collapsible_state(data)
    print "At get collapsibleState"
    local result = "none"
    if data.numChildren > 0 then
        if data.id == self.root.id then
            result = self.root_state
            self.root_state = "collapsed"
        else
            result = "collapsed"
        end
    end
    -- if vim.g.foo == 1 then
    --     vim.g.ccls_lstate1 = result
    -- end
    -- if vim.g.foo == 2 then
    --     vim.g.ccls_lstate2 = result
    -- end
    -- vim.g.foo = vim.g.foo + 1
    return result
end

--- Recursively cache the children.
function provider:add_children_to_cache(data)
    print "At add_children_to_cache "
    -- if vim.fn.has_key(data, "children") ~= 1 or #data.children < 1 then
    -- TODO len
    if vim.fn.has_key(data, "children") ~= 1 or vim.fn.len(data.children) < 1 then
        return
    end

    self.cached_children[data.id] = data.children
    for _, child in pairs(data.children) do
        self:add_children_to_cache(child)
    end
end

--- Handle incominc children data.
function provider:handle_children_data(callback, data)
    print "At handle_children_data "
    self:add_children_to_cache(data)
    callback("success", data.children)
end

--- Produce the list of children for an object given as optional argument,
--- or the root of the tree when called with no optional argument.
function provider:getChildren(callback, ...)
    local args = { ... }
    print "getChildren before callback"

    -- TODO lem
    -- if #args < 1 then
    if vim.fn.len(args) < 1 then
        if self.id ~= "" then
            self.id = tonumber(self.id)
        else
            self.id = 0
        end
        callback("success", self.root)
        print "getChildren after callback"
        return
    end

    if type(args[1].id) ~= "number" then
        if args[1].id ~= "" then
            args[1].id = tonumber(args[1].id)
        else
            args[1].id = 0
        end
    end

    -- TODO length
    -- if vim.fn.has_key(args[1], "children") == 1 and #args[1].children > 0 then
    if vim.fn.has_key(args[1], "children") == 1 and vim.fn.len(args[1].children) > 0 then
        -- if vim.g.foo <= 1 then
        --     local foo = vim.fn.string(args[1].children)
        --     vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/get_children_l2_data_children.json")
        --     vim.g.foo = vim.g.foo + 1
        -- end
        callback("success", args[1].children)
        return
    end

    -- vim.g.msg_ccls = "here now"

    if not vim.tbl_isempty(self.cached_children) then
        if vim.fn.has_key(self.cached_children, args[1].id) == 1 then
            callback("success", self.cached_children[args[1].id])
            return
        end
    end

    local params = {
        id = args[1].id,
        hierarchy = true,
        levels = vim.g.ccls_levels or 5,
    }

    params = vim.tbl_extend("force", params, self.extra_params)

    local handler = function(data)
        self:handle_children_data(callback, data)
    end
    print "Expand node ..."

    require("ccls.protocol").create_win_or_float(self.filetype, self.bufnr, self.method, params, handler)
end

--- Produce the parent of a given object.
function provider:getParent(callback, _)
    print "At get parent "
    callback "failure"
end

--- Produce the tree item representation for a given object.
function provider:getTreeItem(callback, data)
    -- if vim.g.foo == 2 then
    --     local foo = vim.fn.string(data)
    --     vim.fn.writefile({ foo }, vim.fn.glob "~/Trials/get_tree_item_l2.json")
    --     -- vim.g.children = data
    -- end
    -- vim.g.foo = vim.g.foo + 1
    print "At get treeItem "
    print "get Tree Item before"
    local file = vim.uri_to_fname(data.location.uri)
    local line = tonumber(data.location.range.start.line) + 1
    local column = tonumber(data.location.range.start.character) + 1
    if type(data.id) ~= "number" then
        if data.id ~= "" then
            data.id = tonumber(data.id)
        else
            data.id = 0
        end
    end
    local collapsibleState = provider:get_collapsible_state(data)
    local label = get_label(data)
    local tree_item = {
        id = data.id,
        command = function()
            jump(file, line, column)
        end,
        label = label,
        collapsibleState = collapsibleState,
    }

    -- if vim.g.foo == 2 then
    --     vim.g.ccls_ltree2 = tree_item
    -- end
    -- vim.g.foo = vim.g.foo + 1

    callback("success", tree_item)
    print "get Tree Item after"
end

return provider

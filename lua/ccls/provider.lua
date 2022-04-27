local provider = {
    root = {},
    root_state = "expanded",
    cached_children = {},
    method = "",
    filetype = "",
    bufnr = 0,
    extra_params = {},
}

function provider:new(p)
    setmetatable(p, self)
    self.__index = self
    return p
end

--- Get the collapsibleState for a node. The root is returned expanded on
--- the first request only (to avoid issues with cyclic graphs).
function provider:get_collapsible_state(data)
    local result = "none"
    if data.numChildren > 0 then
        if data.id == self.root.id then
            result = self.root_state
            self.root_state = "collapsed"
        else
            result = "collapsed"
        end
    end
    return result
end

--- Recursively cache the children.
function provider:add_children_to_cache(data)
    if vim.fn.has_key(data, "children") ~= 1 or #data.children < 1 then
        return
    end

    self.cached_children[data.id] = data.children
    for child in pairs(data.children) do
        self:add_children_to_cache(child)
    end
end

--- Handle incominc children data.
function provider:handle_children_data(callback, data)
    self:add_children_to_cache(data)
    callback("success", data.children)
end

--- Produce the list of children for an object given as optional argument,
--- or the root of the tree when called with no optional argument.
function provider:getChildren(callback, ...)
    local args = { ... }

    if #args < 1 then
        callback("success", self.root)
        return
    end

    if vim.fn.has_key(args[1], "children") == 1 and #args[1].children > 0 then
        callback("success", args[1].children)
        return
    end

    if vim.fn.has_key(self.cached_children, args[1].id) == 1 then
        callback("success", self.cached_children[args[1].id])
        return
    end

    local params = {
        id = args[1].id,
        hierarchy = true,
        levels = vim.g.ccls_levels or 5,
    }

    params = vim.tbl_extend("force", params, self.extra_params)
    --- TODO call request
end

--- Produce the parent of a given object.
function provider:getParent(callback, data)
    callback "failure"
end

--- Produce the tree item representation for a given object.
function provider:getTreeItem(callback, data)
    local file = vim.uri_to_fname(data.location.uri)
    local line = tonumber(data.location.range.start.line) + 1
    local column = tonumber(data.location.range.start.character) + 1

    local tree_item = require("treeItem").new(data, file, line, column)
    callback("success", tree_item)
end

--- Callback to create a tree view.
-- TODO find best way to do table
function provider.handle_tree(bufnr, filetype, method, extra_params, data)
    if type(data) ~= "table" then
        print "No heirarchy for the object under the cursor"
    end

    local au = vim.api.nvim_create_augroup("ccls_float", { clear = true })

    -- TODO add viewport
    local buffer_options = {
        style = "minimal",
        relative = "cursor",
        width = vim.g.ccls_float_width or 50,
        height = vim.g.ccls_float_height or 20,
        row = 0,
        col = 0,
        border = "shadow",
    }
    local float_id = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), 0, buffer_options)
    local float_buf = vim.api.nvim_win_get_buf(float_id)
    vim.fn.win_gotoid(float_id)

    vim.api.nvim_create_autocmd("WinLeave", {
        buffer = float_buf,
        group = au,
        callback = function()
            vim.api.nvim_win_close(float_id, true)
        end,
    })

    local p = provider:new {
        root = data,
        method = method,
        filetype = filetype,
        bufnr = bufnr,
        extra_params = extra_params,
    }

    require("ccls.tree").newTree(p, float_buf)
end

return provider

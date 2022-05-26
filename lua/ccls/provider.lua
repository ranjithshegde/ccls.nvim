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
    self = require("ccls.tree.utils").expand(self, p)
    setmetatable(p, self)
    self.__index = self
    return p
end

--- Get the label for a given node.
local function get_label(data)
    if vim.fn.has_key(data, "fieldName") == 1 and #vim.tbl_keys(data.fieldName) >= 1 then
        return data.fieldName
    else
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
    if vim.fn.has_key(data, "children") ~= 1 or #vim.tbl_keys(data.children) < 1 then
        return
    end

    self.cached_children[data.id] = data.children
    for _, child in pairs(data.children) do
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

    if #vim.tbl_keys(args) < 1 then
        if self.id ~= "" then
            self.id = tonumber(self.id)
        else
            self.id = 0
        end
        callback("success", self.root)
        return
    end

    if type(args[1].id) ~= "number" then
        if args[1].id ~= "" then
            args[1].id = tonumber(args[1].id)
        else
            args[1].id = 0
        end
    end

    if vim.fn.has_key(args[1], "children") == 1 and #vim.tbl_keys(args[1].children) > 0 then
        callback("success", args[1].children)
        return
    end

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
    callback "failure"
end

--- Produce the tree item representation for a given object.
function provider:getTreeItem(callback, data)
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

    callback("success", tree_item)
end

return provider

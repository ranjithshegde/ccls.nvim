local provider = {
    root = {},
    root_state = "expanded",
    cached_children = {},
    method = "",
    bufnr = 0,
    extra_params = {},
}

function provider:create(data, method, bufnr, extra_params)
    provider.root = data
    provider.root_state = "expanded"
    provider.method = method
    provider.bufnr = bufnr
    provider.extra_params = extra_params
    if provider.root.id and provider.root.id ~= "" then
        provider.root.id = tonumber(provider.root.id)
    end
    return provider
end

--- Get the label for a given node.
local function get_label(data)
    if vim.tbl_contains(vim.tbl_keys(data), "fieldName") and vim.fn.len(data.fieldName) >= 1 then
        return data.fieldName
    else
        return data.name
    end
end

local function jump(location)
    local nodeTree_bufno = vim.api.nvim_get_current_buf()
    vim.api.nvim_win_close(vim.fn.bufwinid(nodeTree_bufno), false)
    if vim.g.ccls_close_on_jump then
        vim.api.nvim_buf_delete(nodeTree_bufno, { force = true })
    end
    vim.lsp.util.jump_to_location(location, require("ccls.protocol").offset_encoding or "utf-32", true)
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
    if not vim.tbl_contains(vim.tbl_keys(data), "children") or #vim.tbl_keys(data.children) < 1 then
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

    if vim.fn.len(args) < 1 then
        callback("success", self.root)
        return
    end

    if vim.tbl_contains(vim.fn.keys(args[1]), "children") and #vim.tbl_keys(args[1].children) > 0 then
        callback("success", args[1].children)
        return
    end

    if vim.tbl_contains(vim.tbl_keys(self.cached_children), args[1].id) then
        callback("success", self.cached_children[args[1].id])
        return
    end

    local params = {
        id = args[1].id,
        hierarchy = true,
        levels = vim.g.ccls_levels or 5,
    }

    params = vim.tbl_extend("force", params, self.extra_params)
    if vim.tbl_contains(vim.tbl_keys(args[1]), "kind") then
        params["kind"] = args[1].kind
    end

    local handler = function(data)
        self:handle_children_data(callback, data)
    end
    print "Expand node ..."

    require("ccls.protocol").nodeRequest(self.bufnr, self.method, params, handler)
end

--- Produce the parent of a given object.
function provider:getParent(callback, _)
    callback "failure"
end

--- Produce the tree item representation for a given object.
function provider:getTreeItem(callback, data)
    local tree_item = {
        id = data.id,
        command = function()
            jump(data.location)
        end,
        label = get_label(data),
        collapsibleState = provider:get_collapsible_state(data),
    }

    callback("success", tree_item)
end

return provider

local protocol = {
    tree_item = {},
    provider = {},
}

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

local function nodeRequest(bufnr, method, params, handler)
    local util = require "lspconfig.util"
    bufnr = util.validate_bufnr(bufnr)
    local client = util.get_active_client_by_name(bufnr, "ccls")

    local lspHandler = function(err, result, _, _)
        if err then
            print "No result from CCLS`"
            return
        end
        handler(result)
    end

    if client then
        client.request(method, params, lspHandler)
    else
        print "Ccls is not attached to this buffer"
    end
end

local function qfRequest(params, method, bufnr, name)
    local util = require "lspconfig.util"
    bufnr = util.validate_bufnr(bufnr)
    local client = util.get_active_client_by_name(bufnr, "ccls")

    if client then
        local function handler(_, result, ctx, _)
            if not result or vim.tbl_isempty(result) then
                vim.notify(name .. " not found")
            else
                vim.fn.setqflist({}, " ", {
                    title = name,
                    items = vim.lsp.util.locations_to_items(result, client.offset_encoding),
                    context = ctx,
                })
                vim.cmd "copen"
            end
        end
        client.request(method, params, handler, bufnr)
    else
        print "Ccls is not attached to this buffer"
    end
end

local function create_win_or_float(filetype, bufnr, method, params, handler)
    print "Creating window"
    vim.api.nvim_create_augroup("NodeTree", { clear = true })
    local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
    local temp = nil
    local isNodeTree = vim.api.nvim_buf_get_option(bufnr, "filetype") == "NodeTree"

    -- local ok, _ = pcall(function()
    pcall(function()
        if isNodeTree then
            temp = vim.fn.tempname()
            vim.api.nvim_buf_set_option(0, "buftype", "")
            vim.api.nvim_buf_set_option(0, "filetype", filetype)
            vim.cmd("file " .. temp)
        end
        nodeRequest(bufnr, method, params, handler)
    end)

    -- if ok then
    if isNodeTree then
        vim.api.nvim_buf_set_option(0, "filetype", "NodeTree")
        vim.cmd "silent 0file"
        vim.api.nvim_buf_set_option(0, "buftype", buftype)
        if vim.fn.filereadable(temp) == 1 then
            vim.fn.delete(temp)
        end
    end
    -- end
end

--- Recursively cache the children.
local function add_children_to_cache(dict, data)
    if not vim.fn.has_key(data, "children") == 1 or #data.children < 1 then
        return
    end

    dict.cachedChildren[data.id] = data.children
    for _, child in pairs(data.children) do
        dict.add_children_to_cache(dict, child)
    end
end

--- Handle incominc children data.
local function handle_children_data(dict, callback, data)
    dict.add_children_to_cache(dict, data)
    callback("success", data.children)
end

--- Produce the list of children for an object given as optional argument,
--- or the root of the tree when called with no optional argument.
local function get_children(dict, callback, ...)
    print "Get children callback"
    local args = { ... }
    if #args < 1 then
        callback("success", dict.root)
        return
    end

    if vim.fn.has_key(args[1], "children") == 1 and #args[1].children > 0 then
        callback("success", args[1].children)
        return
    end

    if not vim.tbl_isempty(dict.cached_children) then
        if vim.fn.has_key(dict.cached_children, args[1].id) == 1 then
            callback("success", dict.cached_children[args[1].id])
            return
        end
    end

    local params = {
        id = args[1].id,
        hierarchy = true,
        levels = vim.g.ccls_levels,
    }

    params = vim.tbl_deep_extend("force", params, dict.extra_params)

    if vim.fn.has_key(args[1], "kind") then
        params["kind"] = args[1].kind
    end

    local handler = function(data)
        dict.handle_children_data(dict, callback, data)
    end
    print "Expand node ..."

    create_win_or_float(dict.filetype, dict.bufnr, dict.method, params, handler)
end

--- Produce the parent of a given object.
-- TODO verify dict
local function get_parent(dict, callback, data)
    callback "failure"
end

--- Get the collapsibleState for a node. The root is returned expanded on
--- the first request only (to avoid issues with cyclic graphs).
local function get_collapsible_state(dict, data)
    local result = "none"
    if data.numChildren > 0 then
        result = dict.root.id
        dict.root_state = "collapsed"
    else
        result = "collapsed"
    end
    return result
end

--- Get the label for a given node.
local function get_label(data)
    if vim.fn.has_key(data, "fieldName") == 1 and #data.fieldName >= 1 then
        return data.fieldName
    else
        return data.name
    end
end

--- Produce the tree item representation for a given object.
local function get_tree_item(dict, callback, data)
    print "Getting tree"
    local file = vim.uri_to_fname(data.location.uri)
    local line = tonumber(data.location.range.start.line) + 1
    local column = tonumber(data.location.range.start.character) + 1

    local tree_item = {}
    tree_item.id = data.id ~= "" and 0 + data.id or 0
    tree_item.command = function()
        jump(file, line, column)
    end

    tree_item.collapsibleState = get_collapsible_state(tree_item, data)
    tree_item.label = get_label(data)

    callback("success", tree_item)
    print "After get tree callback"
end

--- Callback to create a tree view.
-- TODO find best way to do table
local function handle_tree(bufnr, filetype, method, extra_params, data)
    if type(data) ~= "table" then
        print "No heirarchy for the object found"
        return
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

    local provider = {}

    provider.root = data
    provider.root_state = "expanded"
    provider.cached_children = {}
    provider.method = method
    provider.filetype = filetype
    provider.bufnr = bufnr
    provider.extra_params = extra_params

    function provider:get_collapsible_state(...)
        -- print "protocol collapsible"
        get_collapsible_state(self, ...)
    end
    function provider:add_children_to_cache(...)
        -- print "protocol children cache"
        add_children_to_cache(self, ...)
    end

    function provider:handle_children_data(...)
        -- print "protocol children handle"
        handle_children_data(self, ...)
    end
    function provider:getChildren(...)
        get_children(self, ...)
    end
    function provider:getParent(...)
        -- print "protocol parent get"
        get_parent(self, ...)
    end
    function provider:getTreeItem(...)
        get_tree_item(self, ...)
    end

    require("ccls.tree").newTree(provider, float_buf)
end

function protocol.request(method, config, hierarchy)
    local bufnr = vim.fn.bufnr "%"
    local params = {
        textDocument = {
            uri = vim.uri_from_bufnr(bufnr),
        },
        position = {
            line = vim.fn.getcurpos()[2] - 1,
            character = vim.fn.getcurpos()[3] - 1,
        },
        hierarchy = hierarchy,
    }
    params = vim.tbl_extend("keep", params, config)

    if hierarchy then
        params.levels = vim.g.ccls_levels or 3

        local handler = function(...)
            handle_tree(bufnr, vim.api.nvim_buf_get_option(bufnr, "filetype"), method, config, ...)
        end
        create_win_or_float(vim.api.nvim_buf_get_option(bufnr, "filetype"), bufnr, method, params, handler)
    else
        local name = method:gsub("%$ccls/", "")
        qfRequest(params, method, bufnr, name)
    end
end

return protocol

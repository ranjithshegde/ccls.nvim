local callbacks = {}
local call_id = 0

local function registerLSP(callback)
    call_id = call_id + 1
    callbacks[call_id] = callback
    return call_id
end

local function jump(file, line, column)
    local nodeTree_bufno = vim.fn.bufnr "%"
    vim.cmd 'silent execute "normal! <C-W><C-P>'
    if vim.g.ccls_close_on_jump then
        vim.api.nvim_buf_delete(nodeTree_bufno)
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

    local callback = function(data)
        handler(data)
    end
    local id = registerLSP(callback)

    local lspHandler = function(err, result, _, _)
        if err then
            print "No result from CCLS`"
            return
        end
        local keys = vim.tbl_keys(callbacks)
        if vim.tbl_contains(keys, id) then
            callbacks[id](result)
            table.remove(callbacks, id)
        end
    end

    if client then
        client.request(method, params, lspHandler, bufnr)
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
    local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
    local temp = nil
    local isNodeTree = vim.api.nvim_buf_get_option(bufnr, "filetype") == "NodeTree"

    local ok, _ = pcall(function()
        temp = vim.fn.tempname()
        vim.api.nvim_buf_set_option(0, "buftype", "")
        vim.api.nvim_buf_set_option(0, "filetype", filetype)
        vim.cmd("file " .. temp)

        nodeRequest(bufnr, method, params, handler)
    end)

    if ok then
        if isNodeTree then
            vim.api.nvim_buf_set_option(0, "filetype", "nodeTree")
            vim.cmd "silent 0file"
            vim.api.nvim_buf_set_option(0, "buftype", buftype)
            if vim.fn.filereadable(temp) == 1 then
                vim.fn.delete(temp)
            end
        end
    end
end

--- Recursively cache the children.
local function add_children_to_cache(data)
    local self = data
    -- local self = {}
    -- setmetatable(self, data)
    if not vim.fn.has_key(data, "children") == 1 or #data.children < 1 then
        return
    end

    self.cachedChildren[data.id] = data.children
    for _, child in pairs(data.children) do
        self.add_children_to_cache(child)
    end
end

--- Handle incominc children data.
local function handle_children_data(callback, data)
    -- local self = {}
    -- setmetatable(self, data)
    local self = data
    self.add_children_to_cache(data)
    callback("success", data.children)
end

local function get_children(callback, ...)
    if not select(1, ...) then
        return
    end

    -- local self = {}
    -- setmetatable(self, select(1, ...))
    local self = select(1, ...)

    local data = select(2, ...)

    if vim.fn.has_key(data, "children") and #data.children > 0 then
        callback("success", data.children)
        return
    end

    if vim.fn.has_key(self.cachec_children, data.id) and #data.children > 0 then
        callback("success", self.cachec_children[data.id])
        return
    end

    local params = {
        id = data.id,
        heirarchy = true,
        levels = vim.g.ccls_levels,
    }

    params = vim.tbl_deep_extend("force", params, self.extra_params)
    if vim.fn.has_key(data, "kind") then
        params["kind"] = data.kind
    end

    local handler = function(dat)
        self.handle_children_data(callback, dat)
    end

    print "Expand node ..."

    create_win_or_float(self.filetype, self.bufnr, self.method, params, handler)
end

local protocol = {}

function protocol.request(method, bufnr, config, heirarchy)
    local params = {
        textDocument = {
            uri = vim.uri_from_bufnr(bufnr),
        },
        position = {
            line = vim.fn.getcurpos()[2] - 1,
            character = vim.fn.getcurpos()[3] - 1,
        },
        heirarchy = heirarchy,
    }
    if heirarchy then
        params.level = vim.g.ccls_levels or 3

        local handler = function(data)
            require("tree.protocol"):handle_tree(
                bufnr,
                vim.api.nvim_buf_get_option(bufnr, "filetype"),
                method,
                config,
                data
            )
        end
        create_win_or_float(vim.api.nvim_buf_get_option(bufnr, "filetype"), bufnr, method, params, handler)
    else
        local name = method:gsub("%$ccls/", "")
        params = vim.tbl_extend("keep", params, config)
        qfRequest(params, method, bufnr, name)
    end
end

return protocol

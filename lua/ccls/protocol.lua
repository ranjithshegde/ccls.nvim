local protocol = {}

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

--- Callback to create a tree view.
-- TODO find best way to do table
local function handle_tree(bufnr, filetype, method, extra_params, data)
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

    local p = require("ccls.provider"):new {
        root = data,
        method = method,
        filetype = filetype,
        bufnr = bufnr,
        extra_params = extra_params,
    }

    require("ccls.tree").init(p, float_buf)
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

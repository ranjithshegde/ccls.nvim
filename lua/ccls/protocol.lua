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

function protocol.create_win_or_float(filetype, bufnr, method, params, handler)
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
            require("ccls.provider").handle_tree(
                bufnr,
                vim.api.nvim_buf_get_option(bufnr, "filetype"),
                method,
                config,
                ...
            )
        end
        protocol.create_win_or_float(vim.api.nvim_buf_get_option(bufnr, "filetype"), bufnr, method, params, handler)
    else
        local name = method:gsub("%$ccls/", "")
        qfRequest(params, method, bufnr, name)
    end
end

return protocol

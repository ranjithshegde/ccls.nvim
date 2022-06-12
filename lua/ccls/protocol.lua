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
            handle_tree(bufnr, vim.api.nvim_buf_get_option(bufnr, "filetype"), method, {}, view, ...)
        end
        protocol.create_win_or_float(vim.api.nvim_buf_get_option(bufnr, "filetype"), bufnr, method, params, handler)
    else
        local name = method:gsub("%$ccls/", "")

        qfRequest(params, method, bufnr, name)
    end
end

return protocol

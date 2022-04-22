local protocol = {}

function protocol.nodeRequest(bufnr, method, params, handler)
    local util = require "lspconfig.util"
    bufnr = util.validate_bufnr(bufnr)
    local client = util.get_active_client_by_name(bufnr, "ccls")

    local lspHandler = function(err, result, _, _)
        if err or not result then
            vim.notify("No result from ccls", vim.log.levels.WARN, { title = "ccls.nvim" })
            return
        end
        handler(result)
    end

    if client then
        client.request(method, params, lspHandler)
    else
        vim.notify("Ccls is not attached to this buffer", vim.log.levels.WARN, { title = "ccls.nvim" })
    end
end

local function qfRequest(params, method, bufnr, name)
    local util = require "lspconfig.util"
    bufnr = util.validate_bufnr(bufnr)
    local client = util.get_active_client_by_name(bufnr, "ccls")

    if client then
        local function handler(_, result, ctx, _)
            if not result or vim.tbl_isempty(result) then
                vim.notify(name .. " not found", vim.log.levels.WARN, { title = "ccls.nvim" })
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
        vim.notify("Ccls is not attached to this buffer", vim.log.levels.WARN, { title = "ccls.nvim" })
    end
end

--- Callback to create a tree view.
local function handle_tree(bufnr, method, extra_params, view, data)
    if type(data) ~= "table" then
        vim.notify("No heirarchy for the object under the cursor", nil, { title = "ccls.nvim" })
    end

    local win_config = require("ccls").win_config
    local au = vim.api.nvim_create_augroup("NodeTree", { clear = true })
    local p = require("ccls.provider"):create(data, method, bufnr, extra_params)
    local float_buf

    if view and view.type and view.type == "float" then
        local float_id = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, win_config.float)
        float_buf = vim.api.nvim_win_get_buf(float_id)
        vim.fn.win_gotoid(float_id)

        vim.api.nvim_create_autocmd("WinLeave", {
            buffer = float_buf,
            group = au,
            callback = function()
                vim.api.nvim_win_close(float_id, true)
            end,
            once = true,
        })
    else
        vim.api.nvim_exec(
            win_config.sidebar.position .. " " .. win_config.sidebar.size .. win_config.sidebar.split,
            false
        )
        local new_buf = vim.api.nvim_get_current_buf()
        if new_buf ~= bufnr then
            float_buf = new_buf
        end
    end

    require("ccls.tree").init(p, float_buf)
end

function protocol.request(method, config, hierarchy, view)
    local bufnr = vim.api.nvim_get_current_buf()
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
            handle_tree(bufnr, method, {}, view, ...)
        end
        protocol.nodeRequest(bufnr, method, params, handler)
    else
        local name = method:gsub("%$ccls/", "")
        qfRequest(params, method, bufnr, name)
    end
end

return protocol

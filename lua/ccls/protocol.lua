local protocol = {}

local config_aug = vim.api.nvim_create_augroup("ccls_lsp_setup", { clear = true })

local function disable_capabilities(rules)
    local on_init = function(client)
        local sc = client.server_capabilities
        for k, v in pairs(rules) do
            if v == true then
                if sc[k] then
                    sc[k] = false
                else
                    vim.notify(
                        "Capabilitiy " .. k .. " is not available or not valid",
                        vim.log.levels.WARN,
                        { title = "ccls.nvim" }
                    )
                end
            end
        end
    end
    return on_init
end

local function set_nil_handlers(config, handles)
    ---@diagnostic disable-next-line: unused-vararg
    local nilfunc = function(...)
        return nil
    end
    if not config.handlers then
        config.handlers = {}
    end
    for _, v in ipairs(handles) do
        config.handlers[v] = nilfunc
    end
end

local function enable_codelens(events)
    local codelens_aug = vim.api.nvim_create_augroup("ccls_codelens", { clear = true })

    vim.api.nvim_create_autocmd("LspAttach", {
        group = config_aug,
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client.name == "ccls" then
                vim.api.nvim_create_autocmd(events, {
                    group = codelens_aug,
                    buffer = args.buf,
                    callback = function()
                        vim.lsp.codelens.enable(true)
                    end,
                    desc = "Refresh ccls codelens",
                })
                vim.lsp.codelens.enable(true)
            end
        end,
        desc = "Create codelens autocmd on Lsp Attach",
    })

    vim.api.nvim_create_autocmd("LspDetach", {
        group = config_aug,
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if client.name == "ccls" then
                vim.api.nvim_clear_autocmds { group = codelens_aug, buffer = args.buf }
            end
        end,
        desc = "Clear codelens autocmd on Lsp Detach",
    })
end

local function qfRequest(params, method, bufnr, name)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
    local client = vim.lsp.get_clients({ name = "ccls", bufnr = bufnr })[1]

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

        client:request(method, params, handler, bufnr)
    else
        vim.notify("Ccls is not attached to this buffer", vim.log.levels.WARN, { title = "ccls.nvim" })
    end
end

--- Callback to create a tree view.
local function handle_tree(bufnr, method, extra_params, view, data)
    if type(data) ~= "table" then
        vim.notify("No hierarchy for the object under the cursor", nil, { title = "ccls.nvim" })
        return
    end

    local win_config = require("ccls").win_config
    local au = vim.api.nvim_create_augroup("NodeTree", { clear = true })
    local p = require("ccls.provider"):create(data, method, bufnr, extra_params)
    local float_buf

    local is_float = view and view.type and view.type == "float"
    local cfg = is_float and win_config.float
        or {
            split = win_config.sidebar.position,
            width = win_config.sidebar.size,
        }

    local win_id = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, cfg)
    float_buf = vim.api.nvim_win_get_buf(win_id)

    if is_float then
        vim.api.nvim_create_autocmd("WinLeave", {
            buffer = float_buf,
            group = au,
            callback = function()
                vim.api.nvim_win_close(win_id, true)
            end,
            once = true,
        })
    end

    require("ccls.tree").init(p, float_buf)
end

function protocol.nodeRequest(bufnr, method, params, handler)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
    local client = vim.lsp.get_clients({ name = "ccls", bufnr = bufnr })[1]

    local lspHandler = function(err, result, _, _)
        if err or not result then
            vim.notify("No result from ccls", vim.log.levels.WARN, { title = "ccls.nvim" })
            return
        end
        handler(result)
    end

    if client then
        protocol.offset_encoding = client.offset_encoding or "utf-32"
        client.request(method, params, lspHandler)
    else
        vim.notify("Ccls is not attached to this buffer", vim.log.levels.WARN, { title = "ccls.nvim" })
    end
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

function protocol.navigate(direction)
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.fn.getcurpos()
    local params = {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        position = {
            line = cursor[2] - 1,
            character = cursor[3] - 1,
        },
        direction = direction,
    }

    local client = vim.lsp.get_clients({ name = "ccls", bufnr = bufnr })[1]
    if not client then
        vim.notify("Ccls is not attached to this buffer", vim.log.levels.WARN, { title = "ccls.nvim" })
        return
    end

    client:request("$ccls/navigate", params, function(err, result)
        if err or not result then
            vim.notify("No navigate result", vim.log.levels.WARN, { title = "ccls.nvim" })
            return
        end
        local location = vim.islist(result) and result[1] or result
        if not location then
            return
        end
        vim.lsp.util.show_document(location, client.offset_encoding, { reuse_win = true, focus = true })
    end, bufnr)
end

function protocol.setup_lsp(config)
    local utils = require "ccls.tree.utils"
    local lsp_config = require("ccls").lsp

    if lsp_config.codelens.enable then
        enable_codelens(lsp_config.codelens.events)
    end

    if utils.assert_table(lsp_config.disable_capabilities) then
        config.on_init = disable_capabilities(lsp_config.disable_capabilities)
    end

    if utils.assert_table(lsp_config.nil_handlers) then
        set_nil_handlers(config, lsp_config.nil_handlers)
    end

    vim.lsp.config("ccls", config)
    vim.lsp.enable("ccls", true)
end

return protocol

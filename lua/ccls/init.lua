local ccls = {
    win_config = {
        sidebar = {
            size = 50,
            position = "topleft",
            split = "vnew",
            width = 50,
            height = 20,
        },
        float = {
            style = "minimal",
            relative = "cursor",
            width = 50,
            height = 20,
            row = 0,
            col = 0,
            border = "rounded",
        },
    },
    lsp = {
        nil_handlers = nil,
        disable_capabilities = nil,
        codelens = {
            enable = false,
            events = { "BufEnter", "BufWritePost" },
        },
    },
}

function ccls.setup(config)
    local utils = require "ccls.tree.utils"

    if not utils.assert_table(config) then
        return
    end

    if utils.assert_table(config.win_config) then
        if utils.assert_table(config.win_config.sidebar) then
            for k, v in pairs(config.win_config.sidebar) do
                ccls.win_config.sidebar[k] = v
            end
        end
        if utils.assert_table(config.win_config.float) then
            for k, v in pairs(config.win_config.float) do
                ccls.win_config.float[k] = v
            end
        end
    end

    if utils.assert_table(config.lsp) then
        local nil_handlers = {}

        if utils.assert_table(config.lsp.codelens) then
            if config.lsp.codelens.enable then
                if vim.fn.has "nvim-0.8" ~= 1 then
                    vim.notify(
                        [[Attempting to configure codelens events. This feature requires nvim>= 0.8]],
                        vim.log.levels.WARN,
                        { title = "ccls.nvim" }
                    )
                else
                    ccls.lsp.codelens.enable = true
                    if utils.assert_table(config.lsp.codelens.events) then
                        ccls.lsp.codelens.events = config.lsp.codelens.events
                    end
                end
            end
        end

        if utils.tbl_haskey(config.lsp, false, "use_defaults") and config.lsp.use_defaults == true then
            require("ccls.protocol").setup_lsp "lspconfig"
            return
        end

        if config.lsp.disable_diagnostics then
            table.insert(nil_handlers, "textDocument/publishDiagnostics")
        end
        if config.lsp.disable_signature then
            table.insert(nil_handlers, "textDocument/signatureHelp")
        end

        if not vim.tbl_isempty(nil_handlers) then
            ccls.lsp.nil_handlers = nil_handlers
        end

        if utils.assert_table(config.lsp.disable_capabilities) then
            ccls.lsp.disable_capabilities = config.lsp.disable_capabilities
        end

        if utils.tbl_haskey(config.lsp, false, "lspconfig") then
            vim.validate { lspconfig = { config.lsp.lspconfig, "table" } }
            require("ccls.protocol").setup_lsp("lspconfig", config.lsp.lspconfig)
            return
        end

        if utils.tbl_haskey(config.lsp, false, "server") then
            if vim.fn.has "nvim-0.8" ~= 1 then
                vim.notify(
                    [[Attempting to set key `config.lsp.server`. This feature requires nvim>= 0.8. Either upadte to nvim-nightly or use config.lsp.lspconfig]],
                    vim.log.levels.ERROR,
                    { title = "ccls.nvim" }
                )
                return
            end
            vim.validate {
                name = { config.lsp.server.name, "string", true },
                cmd = { config.lsp.server.cmd, "table", true },
                args = { config.lsp.server.args, "table", true },
                offset_encoding = { config.lsp.server.offset_encoding, "string", true },
                root_dir = { config.lsp.server.root_dir, "string", true },
            }
            require("ccls.protocol").setup_lsp("server", config.lsp.server)
            return
        end

        vim.notify(
            [[Lsp config: Neither `use_defaults` nor server configurations have been specified.
            This will assume that Lsp configuration for ccls has been handled by the user elsewhere
        ]],
            vim.log.levels.INFO,
            { title = "ccls.nvim" }
        )
    end
end

function ccls.vars(kind)
    require("ccls.protocol").request("$ccls/vars", { kind = kind or 1 }, false)
end

function ccls.call(callee)
    require("ccls.protocol").request("$ccls/call", { callee = callee or false }, false)
end

function ccls.callHierarchy(callee, view)
    require("ccls.protocol").request("$ccls/call", { callee = callee or false }, true, view)
end

function ccls.member(kind)
    require("ccls.protocol").request("$ccls/member", { kind = kind or 4 }, false)
end

function ccls.memberHierarchy(kind, view)
    require("ccls.protocol").request("$ccls/member", { kind = kind or 4 }, true, view)
end

function ccls.inheritance(derived)
    require("ccls.protocol").request("$ccls/inheritance", { derived = derived or false }, false)
end

function ccls.inheritanceHierarchy(derived, view)
    require("ccls.protocol").request("$ccls/inheritance", { derived = derived or false }, true, view)
end

return ccls

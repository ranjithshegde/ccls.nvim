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
}

local function ccls_assert(table)
    return type(table) == "table" and not vim.tbl_isempty(table)
end

local function setup_lspconfig(config, rules, diagnostics)
    local default = {
        cmd = { "ccls" },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_dir = function(fname)
            return require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt", ".git")(fname)
                or require("lspconfig.util").find_git_ancestor(fname)
        end,
        offset_encoding = "utf-32",
        single_file_support = false,
    }
    if not config then
        require("lspconfig").ccls.setup(default)
        return
    end
    if not vim.tbl_isempty(config) then
        vim.tbl_extend("force", default, config)
    end

    if rules and not vim.tbl_isempty(rules) then
        local on_init = function(client, bufnr)
            local sc = client.server_capabilities
            for k, v in pairs(rules) do
                if v == true then
                    sc[k] = false
                end
            end
        end
        default.on_init = on_init
    end

    if diagnostics == true then
        ---@diagnostic disable-next-line: unused-vararg
        local nilfunc = function(...)
            return nil
        end
        if not default.handlers then
            default.handlers = {
                ["textDocument/publishDiagnostics"] = nilfunc,
            }
        else
            default.handlers["textDocument/publishDiagnostics"] = nilfunc
        end
    end

    require("lspconfig").ccls.setup(default)
end

local function setup_server(config, rules, diagnostics)
    if rules and not vim.tbl_isempty(rules) then
        local on_init = function(client, bufnr)
            local sc = client.server_capabilities
            for k, v in pairs(rules) do
                if v == true then
                    sc[k] = false
                end
            end
        end
        config.on_init = on_init
    end

    if diagnostics == true then
        ---@diagnostic disable-next-line: unused-vararg
        local nilfunc = function(...)
            return nil
        end
        if not config.handlers then
            config.handlers = {
                ["textDocument/publishDiagnostics"] = nilfunc,
            }
        else
            config.handlers["textDocument/publishDiagnostics"] = nilfunc
        end
    end
    vim.api.nvim_create_autocmd("FileType", {
        pattern = config.filetypes or { "c", "cpp", "objc", "objcpp" },
        group = vim.api.nvim_create_augroup("ccls_config", { clear = true }),
        callback = function()
            vim.lsp.start(config)
        end,
    })
end

function ccls.setup(config)
    if not ccls_assert(config) then
        return
    end

    local utils = require "ccls.tree.utils"

    if ccls_assert(config.win_config) then
        if ccls_assert(config.win_config.sidebar) then
            for k, v in ipairs(config.win_config.sidebar) do
                ccls.win_config.sidebar[k] = v
            end
        end
        if ccls_assert(config.win_config.float) then
            for k, v in ipairs(config.win_config.sidebar) do
                ccls.win_config.float[k] = v
            end
        end
    end

    if ccls_assert(config.lsp) then
        if utils.tbl_haskey(config.lsp, false, "use_defaults") and config.lsp.use_defaults == true then
            setup_lspconfig()
            return
        end
        if utils.tbl_haskey(config.lsp, false, "lspconfig") then
            vim.validate { lspconfig = { config.lsp.lspconfig, "table" } }

            setup_lspconfig(
                config.lsp.lspconfig,
                config.lsp.disable_capabilities or {},
                config.lsp.disable_diagnostics or false
            )
            return
        end

        if utils.tbl_haskey(config.lsp, false, "server") then
            vim.validate {
                name = { config.lsp.server.name, "string", false },
                cmd = { config.lsp.server.cmd, "table", false },
                args = { config.lsp.server.args, "table", true },
                offset_encoding = { config.lsp.server.offset_encoding, "string", true },
                root_dir = { config.lsp.server.root_dir, "string", false },
            }
            setup_server(
                config.lsp.server,
                config.lsp.disable_capabilities or {},
                config.lsp.disable_diagnostics or false
            )
            return
        end

        vim.notify(
            [[Lsp config: Neither `use_defaults` nor server configurations have been specified.
            This will assume that Lsp configuration for ccls has been handled by the user elsewhere
        ]],
            vim.log.levels.WARN,
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

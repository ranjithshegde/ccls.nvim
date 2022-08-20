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
            require("lspconfig").ccls.setup {}
            return
        end
        if utils.tbl_haskey(config.lsp, false, "lspconfig") then
            vim.validate { lspconfig = { config.lsp.lspconfig, "table" } }
            require("lspconfig").ccls.setup(config.lsp.lspconfig)
            return
        end
        if utils.tbl_haskey(config.lsp, false, "server") then
            vim.validate {
                name = { config.lsp.server.name, "string", false },
                cmd = { config.lsp.server.cmd, "table", false },
                args = { config.lsp.server.args, "table", true },
                root_dir = { config.lsp.server.root_dir, "function", false },
            }
            vim.api.nvim_create_autocmd("FileType", {
                pattern = config.filetypes or { "c", "cpp", "objc", "objcpp" },
                group = vim.api.nvim_create_augroup("ccls_config", { clear = true }),
                callback = function()
                    vim.lsp.start(config.lsp.server)
                end,
            })
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

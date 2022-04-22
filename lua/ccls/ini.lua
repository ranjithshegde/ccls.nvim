local ccls = {}

function ccls.setup() end

function ccls.var(bufnr, kind)
    require("ccls.protocol").request("$ccls/vars", bufnr, { kind = kind or 0 }, false)
end

function ccls.call(bufnr, callee)
    require("ccls.protocol").request("$ccls/call", bufnr, { callee = callee or false }, false)
end

function ccls.callHeirarchy(bufnr, callee)
    require("ccls.protocol").request("$ccls/member", bufnr, { callee = callee or false }, true)
end

function ccls.member(bufnr, kind)
    require("ccls.protocol").request("$ccls/member", bufnr, { kind = kind or 4 }, false)
end

function ccls.memberHeirarchy(bufnr, kind)
    require("ccls.protocol").request("$ccls/member", bufnr, { kind = kind or 4 }, true)
end

function ccls.inheritance(bufnr, derived)
    require("ccls.protocol").request("$ccls/inheritance", bufnr, { derived = derived or false }, false)
end

function ccls.inheritanceHeirarchy(bufnr, derived)
    require("ccls.protocol").request("$ccls/member", bufnr, { kind = derived or false }, true)
end

return ccls

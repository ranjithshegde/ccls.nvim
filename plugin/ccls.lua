local cmd = vim.api.nvim_create_user_command

cmd("CclsVars", function(opts)
    require("ccls").vars(opts.args and tonumber(opts.args))
end, { nargs = "*", desc = "ccls workspace variables" })

cmd("CclsIncomingCalls", function()
    require("ccls").call(false)
end, { desc = "ccls incoming calls" })

cmd("CclsOutgoingCalls", function()
    require("ccls").call(true)
end, { desc = "ccls outgoing calls" })

cmd("CclsBase", function()
    require("ccls").inheritance(false)
end, { desc = "ccls base class" })

cmd("CclsDerived", function()
    require("ccls").inheritance(true)
end, { desc = "ccls inheritance class" })

cmd("CclsMember", function()
    require("ccls").member(4)
end, { desc = "ccls member variables" })

cmd("CclsMemberFunction", function()
    require("ccls").member(3)
end, { desc = "ccls member functions" })

cmd("CclsMemberType", function()
    require("ccls").member(2)
end, { desc = "ccls member types" })

cmd("CclsIncomingCallsHierarchy", function(opts)
    require("ccls").callHierarchy(false, { type = opts.args })
end, { nargs = "*", desc = "ccls incoming calls hierarchy" })

cmd("CclsOutgoingCallsHierarchy", function(opts)
    require("ccls").callHierarchy(true, { type = opts.args })
end, { nargs = "*", desc = "ccls outgoing calls hierarchy" })

cmd("CclsBaseHierarchy", function(opts)
    require("ccls").inheritanceHierarchy(false, { type = opts.args })
end, { nargs = "*", desc = "ccls base class" })

cmd("CclsDerivedHierarchy", function(opts)
    require("ccls").inheritanceHierarchy(true, { type = opts.args })
end, { nargs = "*", desc = "ccls derived class" })

cmd("CclsMemberHierarchy", function(opts)
    require("ccls").memberHierarchy(4, { type = opts.args })
end, { nargs = "*", desc = "ccls member variables" })

cmd("CclsMemberFunctionHierarchy", function(opts)
    require("ccls").memberHierarchy(3, { type = opts.args })
end, { nargs = "*", desc = "ccls member functions" })

cmd("CclsMemberTypeHierarchy", function(opts)
    require("ccls").memberHierarchy(2, { type = opts.args })
end, { nargs = "*", desc = "ccls member types" })

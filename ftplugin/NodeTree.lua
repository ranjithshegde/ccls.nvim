if vim.b.did_ftplugin then
    return
else
    vim.b.did_ftplugin = 1

    vim.opt_local.bufhidden = "wipe"
    vim.opt_local.buftype = "nofile"
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.buflisted = false
    vim.opt_local.foldenable = false
    vim.opt_local.list = false
    vim.opt_local.modifiable = false
    vim.opt_local.number = false
    vim.opt_local.spell = false
    vim.opt_local.swapfile = false
    vim.opt_local.wrap = false

    vim.keymap.set("n", "<Plug>(nodetree-toggle-node)", function()
        require("ccls.tree.tree"):set_collapsed_under_cursor(-1)
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-open-node)", function()
        require("ccls.tree.tree"):set_collapsed_under_cursor(false)
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-close-node)", function()
        require("ccls.tree.tree"):set_collapsed_under_cursor(true)
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-execute-node)", function()
        require("ccls.tree.tree"):exec_node_under_cursor()
    end, { buffer = true, silent = true })

    vim.keymap.set("n", "<Plug>(nodetree-wipe-tree)", function()
        require("ccls.tree.tree"):wipe()
    end, { buffer = true, silent = true })

    if vim.fn.exists(vim.g.nodetree_no_default_maps) ~= 1 then
        vim.keymap.set("n", "o", "<Plug>(nodetree-toggle-node)", { buffer = true })
        vim.keymap.set("n", "<cr>", "<Plug>(nodetree-execute-node)", { buffer = true })
        vim.keymap.set("n", "q", "<Plug>(nodetree-wipe-tree)", { buffer = true })
    end
end

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

    if vim.fn.exists(vim.g.nodetree_no_default_maps) == 1 then
        vim.keymap.set("n", "O", function()
            require("ccls.tree.tree"):set_collapsed_under_cursor(nil)
        end, { buffer = true, silent = true, desc = "Toggle node under cursor" })

        vim.keymap.set("n", "o", function()
            require("ccls.tree.tree"):set_collapsed_under_cursor(false)
        end, { buffer = true, silent = true, desc = "Open node under cursor" })

        vim.keymap.set("n", "c", function()
            require("ccls.tree.tree"):set_collapsed_under_cursor(true)
        end, { buffer = true, silent = true, desc = "Close node under cursor" })

        vim.keymap.set("n", "<CR>", function()
            require("ccls.tree.tree"):exec_node_under_cursor()
        end, { buffer = true, silent = true, desc = "Jump to node under cursor" })

        vim.keymap.set("n", "q", function()
            require("ccls.tree.tree"):wipe()
        end, { buffer = true, silent = true, desc = "Close buffer (clear)" })
    end
end

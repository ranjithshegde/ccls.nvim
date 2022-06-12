# ccls.nvim

_This plugin is a work in progress. It does not work yet. Please do not use it_

This is a lua rewrite of vim-ccls by Martin Pilia

It ingetrages with the built in LSP and implements more extensions from CCLS language server

It also allows to integrate with clangd so that there are no overlaps, if one wants to use both

It does not depend on nvim-lspconfig as it uses the built in `vim.lsp.start()`

In the tree view it allows for floating previews. It also updatess the tagstack when performing a jump

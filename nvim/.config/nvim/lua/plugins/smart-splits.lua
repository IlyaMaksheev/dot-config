vim.pack.add({
  "https://github.com/mrjones2014/smart-splits.nvim",
})

local sp = require("smart-splits")

sp.setup({
  move_cursor_same_row = false,
  zellij_move_focus_or_tab = true,
})

-- moving between splits
vim.keymap.set("n", "<A-h>", sp.move_cursor_left)
vim.keymap.set("n", "<A-j>", sp.move_cursor_down)
vim.keymap.set("n", "<A-k>", sp.move_cursor_up)
vim.keymap.set("n", "<A-l>", sp.move_cursor_right)

vim.keymap.set("n", "<A-Left>", sp.resize_left)
vim.keymap.set("n", "<A-Down>", sp.resize_down)
vim.keymap.set("n", "<A-Up>", sp.resize_up)
vim.keymap.set("n", "<A-Right>", sp.resize_right)

vim.keymap.set("n", "<A-\\>", sp.move_cursor_previous)

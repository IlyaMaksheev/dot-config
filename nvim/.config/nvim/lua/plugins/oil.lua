vim.pack.add({
  { src = "https://github.com/stevearc/oil.nvim.git", name = "oil" },
  "https://github.com/nvim-tree/nvim-web-devicons.git"
})

require("oil").setup({
  default_file_explorer = true,
  columns = {
    "permissions",
    "size",
    "mtime",
    "icon",
  },
  buf_options = {
    buflisted = false,
    bufhidden = "hide",
  },
  win_options = {
    wrap = false,
    signcolumn = "yes",
    cursorcolumn = false,
    foldcolumn = "0",
    spell = false,
    list = false,
    conceallevel = 3,
    concealcursor = "nvic",
  },
  cleanup_delay_ms = 2000,
  use_default_keymaps = false,
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    ["<C-y>"] = "actions.select",

    ["<leader>v"] = { "actions.select", opts = { vertical = true, split = "belowright" } },
    ["<leader>s"] = { "actions.select", opts = { horizontal = true, split = "belowright" } },
    ["<C-q>"] = { "actions.send_to_qflist", opts = { action = "r", only_matching_search = true, target = "qflist" } },

    ["-"] = { "actions.parent", mode = "n" },
    ["_"] = { "actions.open_cwd", mode = "n" },

    ["<leader>p>"] = "actions.preview",

    ["q"] = { "actions.close", mode = "n" },

    ["`"] = { "actions.cd", mode = "n" },
    ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },

    ["gl"] = "actions.refresh",
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },
})

vim.keymap.set("n", "<leader>t", "<cmd>Oil<CR>")

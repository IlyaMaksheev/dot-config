vim.pack.add({
  "https://github.com/saghen/blink.lib",
  "https://github.com/saghen/blink.cmp",
})

local blink = require("blink.cmp")

blink.build():wait(60000)

blink.setup({
  cmdline = { enabled = false },

  completion = {
    keyword = { range = 'full' },

    accept = { auto_brackets = { enabled = false }, },

    list = { selection = { preselect = false, auto_insert = true } },

    menu = {
      auto_show = false,
      draw = {
        columns = {
          { "label",     "label_description", gap = 1 },
          { "kind_icon", "kind" }
        },
      }
    },
    documentation = { auto_show = true, auto_show_delay_ms = 500 },
    ghost_text = { enabled = true },
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },

  snippets = { preset = 'luasnip' },

  signature = { enabled = true },

  keymap = {
    preset = "default",

    ["<C-e>"] = {
      function(cmp)
        if cmp.is_menu_visible() then
          return cmp.cancel()
        end

        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<End>", true, false, true),
          "n",
          false
        )

        return true
      end,
    },
  }
})

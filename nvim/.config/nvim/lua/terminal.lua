vim.api.nvim_create_autocmd("TermOpen", {
  desc = "Hide the sign column in terminal buffers",
  callback = function()
    vim.opt_local.signcolumn = "no"
  end,
})

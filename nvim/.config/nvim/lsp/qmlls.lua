---@type vim.lsp.Config
return {
  cmd = { 'qmlls6' },
  filetypes = { 'qml', 'qmljs' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, '.git')
    local filename = vim.api.nvim_buf_get_name(bufnr)

    on_dir(root or (filename ~= '' and vim.fs.dirname(filename)) or vim.fn.getcwd())
  end,
}

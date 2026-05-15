local colors = require("gruvbox").palette

local M = {}

local highlight_group = "YankHighlight"
local highlight_timeout = 500
local namespace = vim.api.nvim_create_namespace("yank_highlight_manual")

vim.api.nvim_set_hl(0, highlight_group, {
  fg = colors.dark_green_hard,
  bg = colors.light_aqua_soft
})

local function clear_highlight(buffer)
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buffer) then
      vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
    end
  end, highlight_timeout)
end

function M.highlight_range(start_row, start_col, end_row, end_col)
  local buffer = vim.api.nvim_get_current_buf()

  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
  vim.api.nvim_buf_set_extmark(buffer, namespace, start_row, start_col, {
    end_row = end_row,
    end_col = end_col,
    hl_group = highlight_group,
    hl_eol = true,
  })

  clear_highlight(buffer)
end

function M.highlight_buffer()
  local line_count = vim.api.nvim_buf_line_count(0)

  if line_count == 0 then
    return
  end

  M.highlight_range(0, 0, line_count, 0)
end

local function highlight_text_under_cursor(text)
  if text == "" then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local cursor_col = cursor[2]
  local line = vim.api.nvim_get_current_line()
  local start_index = 1

  while true do
    local start_col, end_col = line:find(vim.pesc(text), start_index)

    if start_col == nil then
      return
    end

    start_col = start_col - 1

    if start_col <= cursor_col and cursor_col < end_col then
      M.highlight_range(row, start_col, row, end_col)
      return
    end

    start_index = end_col + 1
  end
end

function M.highlight_cWORD()
  highlight_text_under_cursor(vim.fn.expand("<cWORD>"))
end

function M.highlight_cfile()
  highlight_text_under_cursor(vim.fn.expand("<cfile>"))
end

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', {}),
  desc = 'Hightlight selection on yank',
  pattern = '*',
  callback = function()
    vim.hl.on_yank {
      higroup = highlight_group,
      timeout = highlight_timeout,
      on_visual = true
    }
  end,
})

return M

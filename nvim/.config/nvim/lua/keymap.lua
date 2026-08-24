vim.g.mapleader = " "

local keymap = vim.keymap
local yank_highlight = require("yank-highlight")

keymap.set("n", "<leader>ol", vim.pack.update, { desc = "Open VimPack update" })
keymap.set("n", "<leader>ot", "<cmd>terminal<CR>", { desc = "Open terminal" })
keymap.set("n", "<leader>op", "<cmd>terminal pi<CR>", { desc = "Open PI" })

keymap.set("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
keymap.set("n", "<leader>W", "<cmd>write!<CR>", { desc = "Force write file" })

keymap.set('n', 'gl', '<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-l><CR>', { desc = "Refresh screen" })

keymap.set("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
keymap.set("n", "<leader>Q", "<cmd>quit!<CR>", { desc = "Force quit" })

keymap.set("t", "<C-G>", "<C-\\><C-n>", { desc = "Exit from terminal" })

local quickfix_list_function = function()
  local windows = vim.fn.getwininfo()

  for _, win in ipairs(windows) do
    if win["quickfix"] == 1 then
      vim.cmd.cclose()
      return
    end
  end

  vim.cmd.copen()
end

local loclist_function = function()
  local windows = vim.fn.getwininfo()

  for _, win in ipairs(windows) do
    if win["loclist"] == 1 then
      vim.cmd.lclose()
      return
    end
  end

  vim.cmd.lopen()
end


keymap.set("n", "<leader>e", quickfix_list_function, { desc = "Open quickfix list" })
keymap.set("n", "<leader>c", loclist_function, { desc = "Open location list" })

keymap.set("n", "<leader>d", vim.diagnostic.setloclist, { desc = "Open diagnostics in location list" })

keymap.set("n", "<leader>r", function() vim.cmd("make") end, { desc = "Run make program" })

local function get_make_arguments()
  vim.ui.input(
    { prompt = "make program arugments" },
    function(input)
      if input == nil then return end

      vim.cmd("make " .. input)
    end
  )
end

keymap.set("n", "<leader>R", get_make_arguments, { desc = "Run make program with arguments" })

vim.keymap.set("n", "<leader>yp", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copied file path: " .. path)
end, { desc = "Copy file full path" })

vim.keymap.set("n", "<leader>yn", function()
  local path = vim.fn.expand("%:t")
  vim.fn.setreg("+", path)
  vim.notify("Copied file name: " .. path)
end, { desc = "Copy file name" })

vim.keymap.set("n", "<leader>yb", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.fn.setreg("+", lines, "l")
  yank_highlight.highlight_buffer()
  vim.notify("Copied current buffer to clipboard")
end, { desc = "Copy current buffer to clipboard" })

local function trim_trailing_whitespace(lines)
  return vim.tbl_map(function(line)
    return line:gsub("%s+$", "")
  end, lines)
end

local function extract_fenced_code(lines)
  if #lines < 2 or not lines[1]:match("^%s*```[^`]*$") or not lines[#lines]:match("^%s*```%s*$") then
    return lines, false
  end

  local code = vim.list_slice(lines, 2, #lines - 1)
  local indentation

  for index, line in ipairs(code) do
    if line:match("^%s*$") then
      code[index] = ""
    else
      local current = #(line:match("^%s*") or "")
      indentation = math.min(indentation or current, current)
    end
  end

  if indentation and indentation > 0 then
    for index, line in ipairs(code) do
      if line ~= "" then
        code[index] = line:sub(indentation + 1)
      end
    end
  end

  return code, true
end

local function yank_cleaned_selection()
  local selection_type = vim.fn.mode()
  local selection_start = vim.fn.getpos("v")
  local selection_end = vim.fn.getpos(".")
  local lines = vim.fn.getregion(selection_start, selection_end, { type = selection_type })

  lines = trim_trailing_whitespace(lines)

  local fenced
  lines, fenced = extract_fenced_code(lines)
  local register_type = fenced and "V" or selection_type

  -- Keep Vim paste and the system clipboard consistent with a regular yank.
  vim.fn.setreg('"', lines, register_type)
  vim.fn.setreg("+", lines, register_type)
  vim.fn.setreg("0", lines, register_type)

  if fenced and #lines > 0 then
    local first_row = math.min(selection_start[2], selection_end[2]) + 1
    local last_row = math.max(selection_start[2], selection_end[2]) - 1
    yank_highlight.highlight_selection({ 0, first_row, 1, 0 }, { 0, last_row, 1, 0 }, "V")
  else
    yank_highlight.highlight_selection(selection_start, selection_end, selection_type)
  end

  -- A Lua visual-mode callback does not leave Visual mode like the built-in
  -- yank operator does, so explicitly finish the selection.
  local escape = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(escape, "nx", false)
end

vim.keymap.set("x", "<leader>y", yank_cleaned_selection, { desc = "Yank cleaned selection" })

-- Add some --insert-- mode keybindings
keymap.set("i", "<C-e>", "<C-o>$", { desc = "Move to the end" })
keymap.set("i", "<C-a>", "<C-o>^", { desc = "Move to the start" })
keymap.set("i", "<M-d>", "<C-o>dw", { desc = "Delete one forward word" })
keymap.set("i", "<M-b>", "<C-o>b", { desc = "Move one word backward" })
keymap.set("i", "<M-f>", "<C-o>w", { desc = "Move one word forward" })

local create_scratch_buffer = function()
  local current_window = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_create_buf(true, false)

  vim.api.nvim_win_set_buf(current_window, buffer)

  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].bufhidden = "hide"
  vim.bo[buffer].swapfile = false
  vim.bo[buffer].buflisted = true
end

keymap.set("n", "<leader>n", create_scratch_buffer, { desc = "Create scratch buffer" })

keymap.set("n", "<leader>bl", "<cmd>set list!<CR>", { desc = "Toggle show hidden characters" })
keymap.set("n", "<leader>bs", "<cmd>set spell!<CR>", { desc = "Toggle spell check" })

local function copy(text)
  vim.fn.setreg("+", text) -- system clipboard
  vim.notify("Copied: " .. text)
end

-- Copy WORD under cursor, like W / diW text object
vim.keymap.set(
  "n",
  "<leader>yw",
  function()
    copy(vim.fn.expand("<cWORD>"))
    yank_highlight.highlight_cWORD()
  end,
  { desc = "Copy WORD under cursor to clipboard" }
)

local copy_under_the_cursor = function()
  local file = vim.fn.expand("<cfile>")

  if file == "" then
    vim.notify("No file under cursor", vim.log.levels.WARN)
    return
  end

  -- expand ~ and environment variables
  file = vim.fn.expand(file)

  -- try to resolve relative paths using 'path', similar to gf
  local found = vim.fn.findfile(file, vim.o.path)
  if found ~= "" then
    file = found
  end

  local real = vim.fn.system({ "realpath", "--", file }):gsub("\n$", "")

  if vim.v.shell_error ~= 0 then
    vim.notify("realpath failed for: " .. file, vim.log.levels.ERROR)
    return
  end

  copy(real)
  yank_highlight.highlight_cfile()
end

-- Copy file path under cursor as realpath, gf-like
vim.keymap.set(
  "n",
  "<leader>yf",
  copy_under_the_cursor,
  { desc = "Copy realpath of file under cursor to clipboard" }
)

vim.keymap.set(
  "n",
  "<leader>ys",
  function()
    copy(vim.v.servername)
  end,
  { desc = "Copy neovim server filename" }
)

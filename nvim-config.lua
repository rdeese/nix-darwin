-- fzf-lua configuration
require('fzf-lua').setup({
  winopts = {
    height = 0.85,
    width = 0.80,
    row = 0.35,
    col = 0.50,
    border = 'rounded',
    preview = {
      layout = 'vertical',
      vertical = 'down:45%',
    },
  },
  files = {
    -- Use ripgrep for file listing (respects .gitignore)
    cmd = 'rg --files --hidden --follow -g "!.git"',
    git_icons = false,
    file_icons = false,
  },
  grep = {
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e",
  },
})

-- Keybindings
vim.keymap.set('n', '<C-p>', require('fzf-lua').files, { desc = 'Find files' })
vim.keymap.set('n', '<C-g>', require('fzf-lua').live_grep, { desc = 'Live grep' })
vim.keymap.set('n', '<Leader>fb', require('fzf-lua').buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<Leader>fh', require('fzf-lua').oldfiles, { desc = 'Find history' })

-- Custom tabline functions
local function custom_tab_number(tab_number, selected, buflist)
  local default_highlight, tab_number_highlight, modified_highlight

  if selected then
    default_highlight = '%#TabLineSel#'
    tab_number_highlight = '%#TabLineSel#'
    modified_highlight = '%#MatchParen#'
  else
    default_highlight = '%#TabLine#'
    tab_number_highlight = '%#Folded#'
    modified_highlight = '%#DiffDelete#'
  end

  -- Check if any buffer in this tab is modified
  local any_modified = false
  for _, bufnr in ipairs(buflist) do
    if vim.api.nvim_buf_get_option(bufnr, 'modified') then
      any_modified = true
      break
    end
  end

  local tab_number_string
  if any_modified then
    tab_number_string = modified_highlight .. tab_number .. default_highlight
  else
    tab_number_string = tab_number_highlight .. tab_number .. default_highlight
  end

  return tab_number_string
end

local function truncate_path(path, width)
  local path_len = vim.fn.strchars(path)
  if path_len <= width then
    return path
  end
  local start_index = path_len - width
  return vim.fn.strcharpart(path, start_index, width)
end

local function custom_tab_label(tab_number, selected, allowed_width)
  local buflist = vim.fn.tabpagebuflist(tab_number)
  local num_windows = vim.fn.tabpagewinnr(tab_number, '$')
  local focused_window = vim.fn.tabpagewinnr(tab_number)

  local tab_number_string = custom_tab_number(tab_number, selected, buflist)

  -- Get the buffer name for the focused window
  local bufnr = buflist[focused_window]
  local path = vim.fn.bufname(bufnr)

  -- Shorten the path (e.g., /home/user/file.txt -> ~/file.txt)
  if path ~= '' then
    path = vim.fn.pathshorten(path)
  else
    path = '[No Name]'
  end

  local extra_window_count = ''
  if num_windows > 1 then
    extra_window_count = '+' .. (num_windows - 1)
  end

  -- Calculate width consumed by non-path elements
  local whitespace_width = 4  -- 2 for space between elements, 2 for space around
  local consumed_width = vim.fn.strchars(tostring(tab_number)) +
                         vim.fn.strchars(extra_window_count) +
                         whitespace_width

  local truncated_path = truncate_path(path, allowed_width - consumed_width)

  -- Build the label
  local elements = { tab_number_string, truncated_path }
  if extra_window_count ~= '' then
    table.insert(elements, extra_window_count)
  end

  return ' ' .. table.concat(elements, ' ') .. ' '
end

function _G.custom_tabline()
  local s = ''
  local num_tabs = vim.fn.tabpagenr('$')
  local columns_per_tab = math.floor(vim.o.columns / num_tabs)

  for i = 1, num_tabs do
    local is_selected = (i == vim.fn.tabpagenr())
    local current_highlight

    if is_selected then
      current_highlight = '%#TabLineSel#'
    else
      current_highlight = '%#TabLine#'
    end

    s = s .. current_highlight

    -- Set the tab page number (for mouse clicks)
    s = s .. '%' .. i .. 'T'

    -- Add the custom label
    s = s .. custom_tab_label(i, is_selected, columns_per_tab)
  end

  -- Fill the rest with TabLineFill and reset tab page nr
  s = s .. '%#TabLineFill#%T'

  return s
end

-- Set the custom tabline
vim.o.tabline = '%!v:lua.custom_tabline()'

-- Statusline configuration
vim.o.laststatus = 2  -- Always show statusline

-- Build statusline using Lua
vim.o.statusline = table.concat({
  '%t',  -- filename tail
  ' %#IncSearch#%{&modified?" MODIFIED ":""}%*',  -- modified indicator
  ' %#pandocStrikeoutDefinition#%{&modifiable?"":" READ ONLY "}%*',  -- read-only indicator
  '%=',  -- left/right separator
  ' %c,',  -- cursor column
  ' %l/%L',  -- cursor line/total lines
}, '')

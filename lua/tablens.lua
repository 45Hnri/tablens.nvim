local M = {}

local has_telescope, _ = pcall(require, "telescope")
local has_snacks, Snacks = pcall(require, "snacks")

--- CONFIG
--- @class Highlighting
--- @field index string|nil
--- @field path string|nil
--- @field current string|nil
--- @field win_count string|nil

--- @class Keymaps
--- @field entry_move_down string|nil
--- @field entry_move_up string|nil
--- @field entry_delete string|nil
--- @field open_picker string|nil

--- @class Config
--- @field highlighting Highlighting|nil
--- @field keymaps Keymaps|nil

--- @type Config
M.default_config = {
  highlighting = {
    index = "Special",
    path = nil,
    current = "Function",
    win_count = "Comment",
  },
  keymaps = {
    entry_move_down = "<c-j>",
    entry_move_up = "<c-k>",
    entry_delete = "<c-d>",
    open_picker = "<Leader>ft"
  }
}

--- UTILS

local function num_length(x)
  if x == 1 then return 1 end
  return math.ceil(math.log10(x))
end

local function calc_widths(entries)
  local widths = {
    index = 1,
    name = 20,
    win_count = 1
  }

  for _, entry in pairs(entries) do
    if widths.index < num_length(entry.index) then
      widths.index = num_length(entry.index)
    end
    if widths.name < #entry.buf_name then
      widths.name = #entry.buf_name
    end
    if widths.win_count < num_length(entry.win_count) then
      widths.win_count = num_length(entry.win_count)
    end
  end

  return widths
end

local function get_tab_entries()
  local tab_current = vim.api.nvim_get_current_tabpage()
  local ids = vim.api.nvim_list_tabpages()
  local entries = {}

  for i, id in ipairs(ids) do
    local win_current = vim.api.nvim_tabpage_get_win(id)
    local buf_current = vim.api.nvim_win_get_buf(win_current)
    local win_count = #vim.api.nvim_tabpage_list_wins(id)
    local buf_name = vim.fn.bufname(buf_current)

    entries[#entries + 1] = {
      index = i,
      buf_name = buf_name,
      win_count = win_count,
      id = id,
      buf_current = buf_current,
      win_current = win_current,
      is_current = tab_current == id,
      path = vim.api.nvim_buf_get_name(buf_current),
      lnum = vim.fn.line(".", win_current),
    }
  end

  return entries
end

--- ACTION

---@return boolean status
local function act_delete(item)
  if item.is_current then return false end
  vim.cmd("tabc " .. tostring(item.index))
  return true
end

---@return boolean status
local function act_move(item, dir)
  local index = item.index
  local tab_entries = get_tab_entries()
  local length = #tab_entries
  local tab_current_index = 1
  local index_after = index + tonumber(dir)

  if index_after < 1 or index_after > length then return false end

  for _, tab in pairs(tab_entries) do
    if tab.is_current then
      tab_current_index = tab.index
      break
    end
  end

  vim.cmd(tostring(index) .. "tabdo tabm " .. dir .. "| tabnext " .. tostring(tab_current_index))
  return true
end

--- PICKERS

--- SNACKS
--- @param opts Config
local function snacks_get_tabs(opts)
  local entries = get_tab_entries()
  local widths = calc_widths(entries)

  local items = {}
  for _, e in ipairs(entries) do
    local name = (e.buf_name == "" and e.is_current) and "CURRENT" or e.buf_name
    items[#items + 1] = {
      text = e.is_current and (name .. " CURRENT") or name,
      entry = e,
      file = e.path,
      path = e.path,
      lnum = e.lnum,
    }
  end

  local function format(item)
    local e = item.entry
    local index_str = tostring(e.index)
    local name = (e.buf_name == "" and e.is_current) and "CURRENT" or e.buf_name
    local pad_index = string.rep(" ", math.max(0, widths.index - #index_str))
    local pad_name = string.rep(" ", math.max(0, widths.name - #name))
    local win_count = e.win_count > 1 and tostring(e.win_count) or ""

    return {
      { index_str .. pad_index, opts.highlighting.index },
      { " " },
      { name .. pad_name,       e.is_current and opts.highlighting.current or opts.highlighting.path },
      { " " },
      { win_count,              opts.highlighting.win_count },
    }
  end

  local function snacks_act_delete(picker)
    local selected = picker:selected { fallback = true }
    local it = selected and selected[1] or nil
    if not it then return end

    local success = act_delete(it.entry)
    if (success) then
      picker:close()
      M.get_tabs(opts)
    end
  end

  local function snacks_act_move(picker, dir)
    local selected = picker:selected { fallback = true }
    local it = selected and selected[1] or nil
    if not it then return end

    local success = act_move(it.entry, dir)
    if (success) then
      picker:close()
      M.get_tabs(opts)
    end
  end

  Snacks.picker({
    items = items,
    format = format,
    preview = false,
    confirm = function(_, item)
      if item and item.entry then
        vim.api.nvim_set_current_tabpage(item.entry.id)
      end
    end,
    actions = {
      entry_delete    = snacks_act_delete,
      entry_move_down = function(picker) snacks_act_move(picker, "-1") end,
      entry_move_up   = function(picker) snacks_act_move(picker, "+1") end,
    },
    win = {
      list = {
        keys = {
          [opts.keymaps.entry_delete]    = { "entry_delete", mode = { "i", "n" } },
          [opts.keymaps.entry_move_down] = { "entry_move_down", mode = { "i", "n" } },
          [opts.keymaps.entry_move_up]   = { "entry_move_up", mode = { "i", "n" } },
        },
      },
      input = {
        keys = {
          [opts.keymaps.entry_delete]    = { "entry_delete", mode = { "i", "n" } },
          [opts.keymaps.entry_move_down] = { "entry_move_down", mode = { "i", "n" } },
          [opts.keymaps.entry_move_up]   = { "entry_move_up", mode = { "i", "n" } },
        },
      },
    },
  })
end

--- TELESCOPE
--- @param opts Config
local function tel_get_tabs(opts)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local entry_display = require "telescope.pickers.entry_display"

  local function make_finder()
    local entries = get_tab_entries()
    local widths = calc_widths(entries)
    local displayer = entry_display.create {
      separator = " ",
      items = {
        { width = widths.index },
        { width = widths.name },
        { width = widths.win_count },
      }
    }

    local function make_display(entry)
      local val = entry.value
      local buf_name = val.buf_name == "" and val.is_current and "CURRENT" or val.buf_name
      local buf_name_highlighting = val.is_current and opts.highlighting.current or opts.highlighting.path
      return displayer {
        { val.index,                                 opts.highlighting.index },
        { buf_name,                                  buf_name_highlighting },
        { val.win_count > 1 and val.win_count or "", opts.highlighting.win_count }
      }
    end

    return finders.new_table {
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = make_display,
          ordinal = entry.buf_name .. (entry.is_current and "CURRENT" or ""),
          path = entry.path,
          filename = entry.buf_name,
          lnum = entry.lnum
        }
      end
    }
  end

  local picker = pickers.new(opts, {
    prompt_title = "Tabs",
    finder = make_finder(),
    previewer = conf.grep_previewer(opts),
    sorter = conf.generic_sorter(opts),
    cache_picker = false,
    attach_mappings = function(prompt_bufnr, map)
      local function tel_act_delete()
        local selection = action_state.get_selected_entry()
        local success = act_delete(selection.value)
        if (success) then M.get_tabs(opts) end
      end

      local function tel_act_move(dir)
        local selection = action_state.get_selected_entry()
        local success = act_move(selection.value, dir)
        if (success) then M.get_tabs(opts) end
      end

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.api.nvim_set_current_tabpage(selection.value.id)
      end)

      map({ "i", "n" }, opts.keymaps.entry_delete, tel_act_delete)
      map({ "i", "n" }, opts.keymaps.entry_move_down, function() tel_act_move("-1") end)
      map({ "i", "n" }, opts.keymaps.entry_move_up, function() tel_act_move("+1") end)

      return true
    end,
  })

  picker:find()
end

-- API
--- @param opts Config
M.get_tabs = function(opts)
  if has_telescope then
    tel_get_tabs(opts)
  elseif has_snacks then
    snacks_get_tabs(opts)
  else
    vim.notify("[tablens.nvim] Requires Telescope or Snacks (picker). Neither found.", vim.log.levels.ERROR)
  end
end

--- INIT
--- @param config Config|nil
function M.setup(config)
  if not config then
    config = {}
  end
  config = vim.tbl_deep_extend("keep", config, M.default_config)
  vim.keymap.set("n", config.keymaps.open_picker, function() M.get_tabs(config) end, {
    desc = "Tablens: open picker",
  })
end

return M

-- neoroo/utils/init.lua - Utility functions
-- Common utility functions used throughout the plugin

local M = {}

-- Module references
local config = require('neoroo.core.config')

-- Check if a file exists
---@param path string File path
---@return boolean Exists
function M.file_exists(path)
  return vim.fn.filereadable(path) == 1
end

-- Check if a directory exists
---@param path string Directory path
---@return boolean Exists
function M.dir_exists(path)
  return vim.fn.isdirectory(path) == 1
end

-- Create a directory if it doesn't exist
---@param path string Directory path
---@return boolean Success
function M.ensure_dir(path)
  if not M.dir_exists(path) then
    return vim.fn.mkdir(path, 'p') == 1
  end
  return true
end

-- Get the plugin root directory
---@return string Root directory
function M.get_plugin_root()
  local path = debug.getinfo(1, 'S').source:sub(2)
  path = vim.fn.fnamemodify(path, ':p:h:h:h')
  return path
end

-- Get the data directory for the plugin
---@return string Data directory
function M.get_data_dir()
  local data_dir = vim.fn.stdpath('data') .. '/neoroo'
  M.ensure_dir(data_dir)
  return data_dir
end

-- Get the cache directory for the plugin
---@return string Cache directory
function M.get_cache_dir()
  local cache_dir = vim.fn.stdpath('cache') .. '/neoroo'
  M.ensure_dir(cache_dir)
  return cache_dir
end

-- Get the config directory for the plugin
---@return string Config directory
function M.get_config_dir()
  local config_dir = vim.fn.stdpath('config') .. '/neoroo'
  M.ensure_dir(config_dir)
  return config_dir
end

-- Log a message if debug is enabled
---@param msg string Message to log
---@param level string|nil Log level (default: 'info')
function M.log(msg, level)
  level = level or 'info'
  
  -- Check if debug is enabled
  if not config.get('debug') and level == 'debug' then
    return
  end
  
  -- Check if log level is high enough
  local log_levels = {
    debug = 1,
    info = 2,
    warn = 3,
    error = 4,
  }
  
  local config_level = config.get('log_level') or 'warn'
  if log_levels[level] < log_levels[config_level] then
    return
  end
  
  -- Map level to vim.log.levels
  local vim_level = vim.log.levels.INFO
  if level == 'debug' then
    vim_level = vim.log.levels.DEBUG
  elseif level == 'warn' then
    vim_level = vim.log.levels.WARN
  elseif level == 'error' then
    vim_level = vim.log.levels.ERROR
  end
  
  -- Log message
  vim.notify('[Neoroo] ' .. msg, vim_level)
end

-- Escape special characters in a string for use in a Lua pattern
---@param s string String to escape
---@return string Escaped string
function M.escape_pattern(s)
  return (s:gsub('[%(%)%.%+%-%*%?%[%]%^%$%%]', '%%%1'))
end

-- Split a string by a delimiter
---@param s string String to split
---@param delimiter string Delimiter
---@return table Split string
function M.split(s, delimiter)
  local result = {}
  for match in (s .. delimiter):gmatch('(.-)' .. M.escape_pattern(delimiter)) do
    table.insert(result, match)
  end
  return result
end

-- Join a table of strings with a delimiter
---@param t table Table of strings
---@param delimiter string Delimiter
---@return string Joined string
function M.join(t, delimiter)
  return table.concat(t, delimiter)
end

-- Trim whitespace from a string
---@param s string String to trim
---@return string Trimmed string
function M.trim(s)
  return s:match('^%s*(.-)%s*$')
end

-- Check if a table contains a value
---@param t table Table to check
---@param value any Value to find
---@return boolean Contains
function M.contains(t, value)
  for _, v in ipairs(t) do
    if v == value then
      return true
    end
  end
  return false
end

-- Get the keys of a table
---@param t table Table
---@return table Keys
function M.keys(t)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

-- Get the values of a table
---@param t table Table
---@return table Values
function M.values(t)
  local values = {}
  for _, v in pairs(t) do
    table.insert(values, v)
  end
  return values
end

-- Merge two tables
---@param t1 table First table
---@param t2 table Second table
---@return table Merged table
function M.merge(t1, t2)
  local result = vim.deepcopy(t1)
  for k, v in pairs(t2) do
    result[k] = v
  end
  return result
end

-- Deep merge two tables
---@param t1 table First table
---@param t2 table Second table
---@return table Merged table
function M.deep_merge(t1, t2)
  local result = vim.deepcopy(t1)
  for k, v in pairs(t2) do
    if type(v) == 'table' and type(result[k]) == 'table' then
      result[k] = M.deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

-- Filter a table
---@param t table Table to filter
---@param predicate function Predicate function
---@return table Filtered table
function M.filter(t, predicate)
  local result = {}
  for k, v in pairs(t) do
    if predicate(v, k) then
      result[k] = v
    end
  end
  return result
end

-- Map a table
---@param t table Table to map
---@param fn function Mapping function
---@return table Mapped table
function M.map(t, fn)
  local result = {}
  for k, v in pairs(t) do
    result[k] = fn(v, k)
  end
  return result
end

-- Reduce a table
---@param t table Table to reduce
---@param fn function Reducer function
---@param initial any Initial value
---@return any Result
function M.reduce(t, fn, initial)
  local result = initial
  for k, v in pairs(t) do
    result = fn(result, v, k)
  end
  return result
end

-- Get a random string
---@param length number Length of the string
---@return string Random string
function M.random_string(length)
  local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  local result = ''
  for _ = 1, length do
    local random = math.random(1, #chars)
    result = result .. chars:sub(random, random)
  end
  return result
end

-- Format a timestamp
---@param timestamp number|nil Timestamp (default: current time)
---@param format string|nil Format (default: '%Y-%m-%d %H:%M:%S')
---@return string Formatted timestamp
function M.format_timestamp(timestamp, format)
  timestamp = timestamp or os.time()
  format = format or '%Y-%m-%d %H:%M:%S'
  return os.date(format, timestamp)
end

-- Parse a JSON string
---@param json_str string JSON string
---@return table|nil Parsed JSON
function M.parse_json(json_str)
  local ok, result = pcall(vim.fn.json_decode, json_str)
  if ok then
    return result
  else
    M.log('Failed to parse JSON: ' .. result, 'error')
    return nil
  end
end

-- Stringify a table to JSON
---@param t table Table to stringify
---@return string|nil JSON string
function M.stringify_json(t)
  local ok, result = pcall(vim.fn.json_encode, t)
  if ok then
    return result
  else
    M.log('Failed to stringify JSON: ' .. result, 'error')
    return nil
  end
end

-- Debounce a function
---@param fn function Function to debounce
---@param ms number Milliseconds to wait
---@return function Debounced function
function M.debounce(fn, ms)
  local timer = nil
  return function(...)
    local args = {...}
    if timer then
      timer:stop()
    end
    timer = vim.defer_fn(function()
      fn(unpack(args))
      timer = nil
    end, ms)
  end
end

-- Throttle a function
---@param fn function Function to throttle
---@param ms number Milliseconds to wait
---@return function Throttled function
function M.throttle(fn, ms)
  local timer = nil
  local last_exec = 0
  return function(...)
    local args = {...}
    local now = vim.loop.now()
    local remaining = ms - (now - last_exec)
    
    if remaining <= 0 then
      if timer then
        timer:stop()
        timer = nil
      end
      last_exec = now
      fn(unpack(args))
    elseif not timer then
      timer = vim.defer_fn(function()
        last_exec = vim.loop.now()
        timer = nil
        fn(unpack(args))
      end, remaining)
    end
  end
end

-- Get the visual selection
---@return string Selected text
function M.get_visual_selection()
  -- Save selection marks
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  -- Ensure valid selection
  if start_pos[2] == 0 or end_pos[2] == 0 then
    return ''
  end
  
  -- Get buffer
  local buf = vim.api.nvim_get_current_buf()
  
  -- Get selected lines
  local lines = vim.api.nvim_buf_get_lines(
    buf,
    start_pos[2] - 1,
    end_pos[2],
    false
  )
  
  -- Handle empty selection
  if #lines == 0 then
    return ''
  end
  
  -- Adjust first and last line for partial selection
  if #lines == 1 then
    lines[1] = string.sub(
      lines[1],
      start_pos[3],
      end_pos[3]
    )
  else
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  end
  
  -- Join lines
  return table.concat(lines, '\n')
end

-- Get the current line
---@return string Current line
function M.get_current_line()
  local line = vim.api.nvim_get_current_line()
  return line
end

-- Get the current word
---@return string Current word
function M.get_current_word()
  local word = vim.fn.expand('<cword>')
  return word
end

-- Get the current file path
---@return string Current file path
function M.get_current_file()
  local file = vim.api.nvim_buf_get_name(0)
  return file
end

-- Get the current directory
---@return string Current directory
function M.get_current_dir()
  local dir = vim.fn.expand('%:p:h')
  return dir
end

-- Get the cursor position
---@return table Cursor position (1-indexed)
function M.get_cursor_position()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return {
    row = cursor[1],
    col = cursor[2] + 1, -- Convert to 1-indexed
  }
end

-- Set the cursor position
---@param row number Row (1-indexed)
---@param col number Column (1-indexed)
function M.set_cursor_position(row, col)
  vim.api.nvim_win_set_cursor(0, {row, col - 1}) -- Convert to 0-indexed
end

-- Get the window dimensions
---@return table Window dimensions
function M.get_window_dimensions()
  return {
    width = vim.api.nvim_win_get_width(0),
    height = vim.api.nvim_win_get_height(0),
  }
end

-- Get the editor dimensions
---@return table Editor dimensions
function M.get_editor_dimensions()
  return {
    width = vim.o.columns,
    height = vim.o.lines,
  }
end

-- Check if running in headless mode
---@return boolean Headless
function M.is_headless()
  return vim.g.headless == 1
end

-- Check if running in a GUI
---@return boolean GUI
function M.is_gui()
  return vim.fn.has('gui_running') == 1
end

-- Get the operating system
---@return string Operating system ('windows', 'mac', 'linux', or 'unknown')
function M.get_os()
  if vim.fn.has('win32') == 1 then
    return 'windows'
  elseif vim.fn.has('mac') == 1 then
    return 'mac'
  elseif vim.fn.has('unix') == 1 then
    return 'linux'
  else
    return 'unknown'
  end
end

-- Check if a command exists
---@param cmd string Command to check
---@return boolean Exists
function M.command_exists(cmd)
  if M.get_os() == 'windows' then
    cmd = 'where ' .. cmd
  else
    cmd = 'command -v ' .. cmd
  end
  
  local result = vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

return M
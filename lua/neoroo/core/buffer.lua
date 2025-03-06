-- neoroo/core/buffer.lua - Buffer management utilities
-- Handles buffer operations, visual selections, and context collection

local M = {}

-- Module references
local config = require('neoroo.core.config')

-- Buffer namespace for highlights and extmarks
M.ns_id = vim.api.nvim_create_namespace('neoroo')

-- Buffer names and types
M.BUFFER_TYPES = {
  CHAT = 'neoroo_chat',
  CONFIG = 'neoroo_config',
  PREVIEW = 'neoroo_preview',
}

-- Buffer cache to track created buffers
local buffer_cache = {}

-- Initialize buffer management
function M.setup()
  -- Create autocommands for buffer events
  vim.api.nvim_create_autocmd('BufUnload', {
    pattern = 'neoroo_*',
    callback = function(args)
      -- Remove from cache when buffer is unloaded
      for buf_type, buf_id in pairs(buffer_cache) do
        if buf_id == args.buf then
          buffer_cache[buf_type] = nil
          break
        end
      end
    end,
  })
end

-- Create a new buffer with the given name and options
---@param name string Buffer name
---@param options table Buffer options
---@return number Buffer ID
function M.create_buffer(name, options)
  options = options or {}
  
  -- Default options
  options.listed = options.listed or false
  options.scratch = options.scratch or true
  options.modifiable = options.modifiable ~= nil and options.modifiable or true
  options.readonly = options.readonly ~= nil and options.readonly or false
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(options.listed, options.scratch)
  
  -- Set buffer name
  vim.api.nvim_buf_set_name(buf, name)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', options.modifiable)
  vim.api.nvim_buf_set_option(buf, 'readonly', options.readonly)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', options.bufhidden or 'hide')
  vim.api.nvim_buf_set_option(buf, 'buftype', options.buftype or 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  -- Set filetype if provided
  if options.filetype then
    vim.api.nvim_buf_set_option(buf, 'filetype', options.filetype)
  end
  
  return buf
end

-- Get or create a buffer of the specified type
---@param buf_type string Buffer type from M.BUFFER_TYPES
---@param options table|nil Buffer options
---@return number Buffer ID
function M.get_buffer(buf_type, options)
  -- Check if buffer exists and is valid
  if buffer_cache[buf_type] and vim.api.nvim_buf_is_valid(buffer_cache[buf_type]) then
    return buffer_cache[buf_type]
  end
  
  -- Create new buffer
  local buf_name = buf_type
  local buf = M.create_buffer(buf_name, options)
  
  -- Cache the buffer
  buffer_cache[buf_type] = buf
  
  return buf
end

-- Write content to a buffer
---@param buf number Buffer ID
---@param content string|table Content to write (string or array of lines)
---@param append boolean Whether to append or replace
function M.write_to_buffer(buf, content, append)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  
  -- Convert string to table of lines
  local lines
  if type(content) == 'string' then
    lines = vim.split(content, '\n', { plain = true })
  else
    lines = content
  end
  
  -- Make buffer modifiable
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Write content
  if append then
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, lines)
  else
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end
  
  -- Make buffer non-modifiable if it's a read-only buffer type
  if buf_type == M.BUFFER_TYPES.CHAT or buf_type == M.BUFFER_TYPES.PREVIEW then
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end
  
  return true
end

-- Get visual selection
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

-- Get context from current buffer
---@param options table|nil Context collection options
---@return string Context
function M.get_context(options)
  options = options or {}
  
  -- Default options
  options.include_filename = options.include_filename ~= nil and options.include_filename or true
  options.include_filetype = options.include_filetype ~= nil and options.include_filetype or true
  options.include_cursor_position = options.include_cursor_position ~= nil and options.include_cursor_position or true
  options.include_selection = options.include_selection ~= nil and options.include_selection or true
  options.include_buffer_content = options.include_buffer_content ~= nil and options.include_buffer_content or true
  options.max_lines = options.max_lines or 100
  
  local context_parts = {}
  local buf = vim.api.nvim_get_current_buf()
  
  -- Add filename
  if options.include_filename then
    local filename = vim.api.nvim_buf_get_name(buf)
    if filename and filename ~= '' then
      table.insert(context_parts, "File: " .. filename)
    end
  end
  
  -- Add filetype
  if options.include_filetype then
    local filetype = vim.api.nvim_buf_get_option(buf, 'filetype')
    if filetype and filetype ~= '' then
      table.insert(context_parts, "Filetype: " .. filetype)
    end
  end
  
  -- Add cursor position
  if options.include_cursor_position then
    local cursor = vim.api.nvim_win_get_cursor(0)
    table.insert(context_parts, "Cursor position: line " .. cursor[1] .. ", column " .. cursor[2])
  end
  
  -- Add visual selection if in visual mode
  if options.include_selection and vim.fn.mode():match('[vV]') then
    local selection = M.get_visual_selection()
    if selection and selection ~= '' then
      table.insert(context_parts, "Selected text:\n" .. selection)
    end
  end
  
  -- Add buffer content
  if options.include_buffer_content then
    local line_count = vim.api.nvim_buf_line_count(buf)
    local start_line = math.max(1, line_count - options.max_lines)
    local end_line = line_count
    
    -- If cursor is within view, center context around cursor
    local cursor = vim.api.nvim_win_get_cursor(0)
    local cursor_line = cursor[1]
    if cursor_line > options.max_lines / 2 and cursor_line < line_count - options.max_lines / 2 then
      start_line = math.max(1, cursor_line - math.floor(options.max_lines / 2))
      end_line = math.min(line_count, cursor_line + math.floor(options.max_lines / 2))
    end
    
    local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
    if #lines > 0 then
      table.insert(context_parts, "Buffer content:\n" .. table.concat(lines, '\n'))
    end
  end
  
  -- Join context parts
  return table.concat(context_parts, '\n\n')
end

-- Get context from multiple files
---@param file_patterns table List of file patterns to include
---@param options table|nil Context collection options
---@return string Context
function M.get_project_context(file_patterns, options)
  options = options or {}
  options.max_files = options.max_files or 5
  options.max_lines_per_file = options.max_lines_per_file or 100
  
  local context_parts = {}
  local files_included = 0
  
  -- Find files matching patterns
  for _, pattern in ipairs(file_patterns) do
    local files = vim.fn.glob(pattern, false, true)
    for _, file in ipairs(files) do
      if files_included >= options.max_files then
        break
      end
      
      -- Read file content
      local lines = {}
      local file_handle = io.open(file, 'r')
      if file_handle then
        local line_count = 0
        for line in file_handle:lines() do
          if line_count >= options.max_lines_per_file then
            break
          end
          table.insert(lines, line)
          line_count = line_count + 1
        end
        file_handle:close()
        
        -- Add file content to context
        table.insert(context_parts, "File: " .. file .. "\n" .. table.concat(lines, '\n'))
        files_included = files_included + 1
      end
    end
    
    if files_included >= options.max_files then
      break
    end
  end
  
  -- Join context parts
  return table.concat(context_parts, '\n\n')
end

-- Apply highlighting to a buffer
---@param buf number Buffer ID
---@param start_line number Start line (0-indexed)
---@param end_line number End line (0-indexed)
---@param hl_group string Highlight group
function M.highlight_region(buf, start_line, end_line, hl_group)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Add extmark for highlighting
  vim.api.nvim_buf_add_highlight(
    buf,
    M.ns_id,
    hl_group,
    start_line,
    0,
    -1
  )
  
  -- Highlight additional lines if needed
  if end_line > start_line then
    for line = start_line + 1, end_line do
      vim.api.nvim_buf_add_highlight(
        buf,
        M.ns_id,
        hl_group,
        line,
        0,
        -1
      )
    end
  end
end

-- Clear all highlights in a buffer
---@param buf number Buffer ID
function M.clear_highlights(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, M.ns_id, 0, -1)
  end
end

return M
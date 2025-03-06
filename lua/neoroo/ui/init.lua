-- neoroo/ui/init.lua - User interface components
-- Handles chat interface, floating windows, and other UI elements

local M = {}

-- Module references
local config = require('neoroo.core.config')
local buffer = require('neoroo.core.buffer')
local mode_manager = require('neoroo.modes')

-- Window IDs for tracking
local windows = {
  chat = nil,
  config = nil,
  preview = nil,
}

-- Initialize UI components
function M.setup()
  -- Create highlight groups with darker, more readable colors
  vim.api.nvim_set_hl(0, 'NeorooHeader', { bold = true, fg = '#FFFFFF' })
  vim.api.nvim_set_hl(0, 'NeorooUserMessage', { fg = '#FFFFFF' })
  vim.api.nvim_set_hl(0, 'NeorooAIMessage', { fg = '#FFFFFF' })
  vim.api.nvim_set_hl(0, 'NeorooError', { fg = '#FF6666' })
  vim.api.nvim_set_hl(0, 'NeorooSuccess', { fg = '#66FF66' })
  vim.api.nvim_set_hl(0, 'NeorooWarning', { fg = '#FFCC66' })
  vim.api.nvim_set_hl(0, 'NeorooInfo', { fg = '#FFFFFF' })
  vim.api.nvim_set_hl(0, 'NeorooCodeBlock', { bg = '#1E2132' })
  vim.api.nvim_set_hl(0, 'NeorooModeCode', { fg = '#FFFFFF', bold = true })
  vim.api.nvim_set_hl(0, 'NeorooModeArchitect', { fg = '#FFFFFF', bold = true })
  vim.api.nvim_set_hl(0, 'NeorooModeDebug', { fg = '#FFFFFF', bold = true })
  vim.api.nvim_set_hl(0, 'NeorooModeAsk', { fg = '#FFFFFF', bold = true })
  
  -- Create autocommands for UI events
  vim.api.nvim_create_autocmd('User', {
    pattern = 'NeorooModeChanged',
    callback = function(args)
      -- Update UI when mode changes
      M.update_chat_header()
    end,
  })
end

-- Open chat interface
function M.open_chat()
  -- Get or create chat buffer
  local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CHAT, {
    filetype = 'neoroo-chat',
    modifiable = true,
  })
  
  -- Get window configuration
  local win_config = config.get('ui.chat_window')
  local width = math.floor(vim.o.columns * win_config.width)
  local height = math.floor(vim.o.lines * win_config.height)
  local col = 0
  local row = 0
  
  -- Adjust position based on configuration
  if win_config.position == 'right' then
    col = vim.o.columns - width
  elseif win_config.position == 'bottom' then
    row = vim.o.lines - height - 2 -- Account for command line
  end
  
  -- Check if window exists and is valid
  if windows.chat and vim.api.nvim_win_is_valid(windows.chat) then
    -- Focus existing window
    vim.api.nvim_set_current_win(windows.chat)
  else
    -- Create new window
    windows.chat = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = width,
      height = height,
      col = col,
      row = row,
      border = win_config.border,
      style = 'minimal',
    })
    
    -- Set window options
    vim.api.nvim_win_set_option(windows.chat, 'wrap', true)
    vim.api.nvim_win_set_option(windows.chat, 'linebreak', true)
    vim.api.nvim_win_set_option(windows.chat, 'number', false)
    vim.api.nvim_win_set_option(windows.chat, 'relativenumber', false)
    vim.api.nvim_win_set_option(windows.chat, 'cursorline', false)
    vim.api.nvim_win_set_option(windows.chat, 'signcolumn', 'no')
    
    -- Set dark background color for the window
    vim.api.nvim_win_set_option(windows.chat, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')
    
    -- Create highlight groups for window background
    vim.api.nvim_set_hl(0, 'NormalFloat', { bg = '#1E2132' }) -- Dark background
    vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#FFFFFF', bg = '#1E2132' }) -- White border on dark background
    
    -- Initialize chat buffer if empty
    if vim.api.nvim_buf_line_count(buf) <= 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == '' then
      M.initialize_chat_buffer(buf)
    end
    
    -- Set buffer keymaps
    M.set_chat_keymaps(buf)
  end
  
  -- Update chat header
  M.update_chat_header()
  
  -- Move cursor to input area
  M.focus_input_area()
end

-- Initialize chat buffer with header and initial content
---@param buf number Buffer ID
function M.initialize_chat_buffer(buf)
  -- Make buffer modifiable
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Clear buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  
  -- Add header
  local current_mode = mode_manager.get_current_mode()
  local header = {
    '┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓',
    '┃                         NEOROO CHAT                          ┃',
    '┃                                                              ┃',
    '┃  Mode: ' .. string.format('%-54s', current_mode.name) .. '┃',
    '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛',
    '',
    '-- Type your message below and press Enter to send --',
    '',
    '',
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, header)
  
  -- Apply header highlighting
  for i = 0, 4 do
    buffer.highlight_region(buf, i, i, 'NeorooHeader')
  end
  
  -- Apply mode-specific highlighting
  local mode_hl = 'NeorooMode' .. current_mode.id:gsub("^%l", string.upper)
  if vim.fn.hlexists(mode_hl) == 0 then
    mode_hl = 'NeorooModeCode' -- Fallback
  end
  buffer.highlight_region(buf, 3, 3, mode_hl)
  
  -- Apply instruction highlighting
  buffer.highlight_region(buf, 6, 6, 'NeorooInfo')
  
  -- Make buffer modifiable for input
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
end

-- Update chat header with current mode
function M.update_chat_header()
  local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CHAT)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Get current mode
  local current_mode = mode_manager.get_current_mode()
  
  -- Update mode line
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 3, 4, false, {
    '┃  Mode: ' .. string.format('%-54s', current_mode.name) .. '┃',
  })
  
  -- Apply mode-specific highlighting
  local mode_hl = 'NeorooMode' .. current_mode.id:gsub("^%l", string.upper)
  if vim.fn.hlexists(mode_hl) == 0 then
    mode_hl = 'NeorooModeCode' -- Fallback
  end
  buffer.highlight_region(buf, 3, 3, mode_hl)
  
  -- Make buffer modifiable for input
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
end

-- Set keymaps for chat buffer
---@param buf number Buffer ID
function M.set_chat_keymaps(buf)
  -- Send message on Enter in both normal and insert mode
  vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', ':lua require("neoroo.ui").send_message()<CR>', {
    noremap = true,
    silent = true,
    desc = 'Send message',
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '<Esc>:lua require("neoroo.ui").send_message()<CR>', {
    noremap = true,
    silent = true,
    desc = 'Send message',
  })
  
  -- Change mode
  vim.api.nvim_buf_set_keymap(buf, 'n', '<leader>nm', ':NeorooMode ', {
    noremap = true,
    desc = 'Change mode',
  })
  
  -- Clear chat
  vim.api.nvim_buf_set_keymap(buf, 'n', '<leader>nc', ':lua require("neoroo.ui").clear_chat()<CR>', {
    noremap = true,
    silent = true,
    desc = 'Clear chat',
  })
  
  -- Close chat
  vim.api.nvim_buf_set_keymap(buf, 'n', '<leader>nq', ':lua require("neoroo.ui").close_chat()<CR>', {
    noremap = true,
    silent = true,
    desc = 'Close chat',
  })
  
  -- Escape to normal mode
  vim.api.nvim_buf_set_keymap(buf, 'i', '<Esc>', '<Esc>', {
    noremap = true,
    desc = 'Exit insert mode',
  })
end

-- Focus the input area in the chat buffer
function M.focus_input_area()
  local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CHAT)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Get line count
  local line_count = vim.api.nvim_buf_line_count(buf)
  
  -- Move cursor to the last line
  vim.api.nvim_win_set_cursor(windows.chat, {line_count, 0})
  
  -- Enter insert mode
  vim.cmd('startinsert')
end

-- Send a message from the chat buffer
function M.send_message()
  local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CHAT)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Get line count
  local line_count = vim.api.nvim_buf_line_count(buf)
  
  -- Get message from last line
  local message = vim.api.nvim_buf_get_lines(buf, line_count - 1, line_count, false)[1]
  
  -- Check if message is empty
  if not message or message:match('^%s*$') then
    return
  end
  
  -- Add user message to chat
  M.add_user_message(message)
  
  -- Process message
  M.process_message(message)
  
  -- Clear input line
  vim.api.nvim_buf_set_lines(buf, line_count, line_count + 1, false, {''})
  
  -- Focus input area
  M.focus_input_area()
end

-- Add a user message to the chat
---@param message string User message
function M.add_user_message(message)
  local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CHAT)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Get line count
  local line_count = vim.api.nvim_buf_line_count(buf)
  
  -- Format user message
  local formatted_message = {
    '',
    '🧑 User:',
    message,
    '',
  }
  
  -- Add message to buffer
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count - 1, false, formatted_message)
  
  -- Apply highlighting
  buffer.highlight_region(buf, line_count, line_count, 'NeorooUserMessage')
  
  -- Make buffer modifiable for input
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
end

-- Add an AI message to the chat
---@param message string AI message
function M.add_ai_message(message)
  local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CHAT)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Get line count
  local line_count = vim.api.nvim_buf_line_count(buf)
  
  -- Format AI message
  local current_mode = mode_manager.get_current_mode()
  local formatted_message = {
    '',
    '🤖 ' .. current_mode.name .. ':',
    message,
    '',
  }
  
  -- Add message to buffer
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, line_count - 1, line_count - 1, false, formatted_message)
  
  -- Apply highlighting
  buffer.highlight_region(buf, line_count, line_count, 'NeorooAIMessage')
  
  -- Highlight code blocks
  M.highlight_code_blocks(buf)
  
  -- Make buffer modifiable for input
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
end

-- Process a user message
---@param message string User message
function M.process_message(message)
  -- Get current mode
  local current_mode = mode_manager.get_current_mode()
  
  -- Add thinking message
  M.add_ai_message('Thinking...')
  
  -- Get context
  local context = buffer.get_context()
  
  -- Execute command in current mode
  -- This would normally be asynchronous, but we'll simulate it for now
  vim.defer_fn(function()
    -- Get buffer
    local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CHAT)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    
    -- Get line count
    local line_count = vim.api.nvim_buf_line_count(buf)
    
    -- Remove thinking message
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, line_count - 4, line_count - 1, false, {})
    
    -- Generate response (placeholder for actual AI response)
    local response = "This is a placeholder response. In a real implementation, this would be the result from the AI provider.\n\nHere's a code example:\n\n```lua\nlocal function hello_world()\n  print('Hello, world!')\nend\n\nhello_world()\n```\n\nIs there anything else you'd like to know?"
    
    -- Add AI response
    M.add_ai_message(response)
  end, 1000) -- Simulate 1 second delay
end

-- Highlight code blocks in the chat
---@param buf number Buffer ID
function M.highlight_code_blocks(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Get buffer lines
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Find code blocks
  local in_code_block = false
  local start_line = 0
  
  for i, line in ipairs(lines) do
    if line:match('^```') then
      if in_code_block then
        -- End of code block
        buffer.highlight_region(buf, start_line, i - 1, 'NeorooCodeBlock')
        in_code_block = false
      else
        -- Start of code block
        start_line = i
        in_code_block = true
      end
    end
  end
end

-- Clear the chat
function M.clear_chat()
  local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CHAT)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Reinitialize chat buffer
  M.initialize_chat_buffer(buf)
  
  -- Focus input area
  M.focus_input_area()
end

-- Close the chat
function M.close_chat()
  if windows.chat and vim.api.nvim_win_is_valid(windows.chat) then
    vim.api.nvim_win_close(windows.chat, true)
    windows.chat = nil
  end
end

-- Open chat with specific context
---@param context string Context to include
function M.open_chat_with_context(context)
  -- Open chat
  M.open_chat()
  
  -- Add context as user message
  M.add_user_message("I need help with this:\n\n" .. context)
  
  -- Process message
  M.process_message("I need help with this:\n\n" .. context)
end

-- Open configuration window
function M.open_config()
  -- Get or create config buffer
  local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CONFIG, {
    filetype = 'neoroo-config',
    modifiable = true,
  })
  
  -- Get window configuration
  local win_config = config.get('ui.floating_window')
  local width = win_config.width
  local height = win_config.height
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  -- Check if window exists and is valid
  if windows.config and vim.api.nvim_win_is_valid(windows.config) then
    -- Focus existing window
    vim.api.nvim_set_current_win(windows.config)
  else
    -- Create new window
    windows.config = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = width,
      height = height,
      col = col,
      row = row,
      border = win_config.border,
      style = 'minimal',
    })
    
    -- Set window options
    vim.api.nvim_win_set_option(windows.config, 'wrap', true)
    vim.api.nvim_win_set_option(windows.config, 'linebreak', true)
    vim.api.nvim_win_set_option(windows.config, 'number', false)
    vim.api.nvim_win_set_option(windows.config, 'relativenumber', false)
    vim.api.nvim_win_set_option(windows.config, 'cursorline', true)
    vim.api.nvim_win_set_option(windows.config, 'signcolumn', 'no')
    
    -- Initialize config buffer
    M.initialize_config_buffer(buf)
    
    -- Set buffer keymaps
    M.set_config_keymaps(buf)
  end
end

-- Initialize configuration buffer
---@param buf number Buffer ID
function M.initialize_config_buffer(buf)
  -- Make buffer modifiable
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Clear buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  
  -- Add header
  local header = {
    '┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓',
    '┃                      NEOROO CONFIGURATION                    ┃',
    '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛',
    '',
    'General Settings:',
    '----------------',
    '',
  }
  
  -- Add configuration sections
  local sections = {
    -- General settings
    'Debug Mode: ' .. (config.get('debug') and 'Enabled' or 'Disabled'),
    'Log Level: ' .. config.get('log_level'),
    '',
    
    -- Provider settings
    'AI Provider Settings:',
    '--------------------',
    '',
    'Default Provider: ' .. config.get('providers.default'),
    'OpenAI Model: ' .. config.get('providers.openai.model'),
    'Anthropic Model: ' .. config.get('providers.anthropic.model'),
    '',
    
    -- Mode settings
    'Mode Settings:',
    '-------------',
    '',
    'Default Mode: ' .. config.get('modes.default'),
    '',
    
    -- Available modes
    'Available Modes:',
  }
  
  -- Add modes
  local modes = mode_manager.get_all_modes()
  for _, mode in ipairs(modes) do
    table.insert(sections, '  - ' .. mode.name .. ' (' .. mode.id .. ')' .. (mode.builtin and ' [built-in]' or ' [custom]'))
  end
  
  -- Add footer
  local footer = {
    '',
    '',
    'Press q to close, r to reload configuration',
  }
  
  -- Combine all sections
  local content = vim.list_extend(header, sections)
  content = vim.list_extend(content, footer)
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, content)
  
  -- Apply highlighting
  buffer.highlight_region(buf, 0, 2, 'NeorooHeader')
  buffer.highlight_region(buf, 4, 4, 'NeorooHeader')
  buffer.highlight_region(buf, 10, 10, 'NeorooHeader')
  buffer.highlight_region(buf, 16, 16, 'NeorooHeader')
  buffer.highlight_region(buf, 21, 21, 'NeorooHeader')
  buffer.highlight_region(buf, #content - 1, #content - 1, 'NeorooInfo')
  
  -- Make buffer non-modifiable
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

-- Set keymaps for configuration buffer
---@param buf number Buffer ID
function M.set_config_keymaps(buf)
  -- Close on q
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':lua require("neoroo.ui").close_config()<CR>', {
    noremap = true,
    silent = true,
    desc = 'Close configuration',
  })
  
  -- Reload on r
  vim.api.nvim_buf_set_keymap(buf, 'n', 'r', ':lua require("neoroo.ui").reload_config()<CR>', {
    noremap = true,
    silent = true,
    desc = 'Reload configuration',
  })
end

-- Close configuration window
function M.close_config()
  if windows.config and vim.api.nvim_win_is_valid(windows.config) then
    vim.api.nvim_win_close(windows.config, true)
    windows.config = nil
  end
end

-- Reload configuration
function M.reload_config()
  -- Reload configuration
  require('neoroo').setup()
  
  -- Reinitialize config buffer
  local buf = buffer.get_buffer(buffer.BUFFER_TYPES.CONFIG)
  if vim.api.nvim_buf_is_valid(buf) then
    M.initialize_config_buffer(buf)
  end
  
  -- Notify user
  vim.notify('Neoroo configuration reloaded', vim.log.levels.INFO)
end

return M
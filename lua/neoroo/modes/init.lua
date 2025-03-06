-- neoroo/modes/init.lua - Mode system
-- Handles different AI modes and their behavior

local M = {}

-- Module references
local config = require('neoroo.core.config')

-- Current active mode
local current_mode = nil

-- Built-in mode definitions
local builtin_modes = {
  -- Code mode
  code = {
    name = 'Code',
    description = 'Expert software engineer mode for coding assistance',
    icon = '󰘧 ',
    color = '#7CCDEA',
    prompt_template = "You are an expert software engineer. Help me with the following code:\n\n{context}\n\n{input}",
    tools = { 'file', 'terminal', 'lsp', 'git' },
    context_strategy = 'code',
  },
  
  -- Architect mode
  architect = {
    name = 'Architect',
    description = 'Technical leader mode for design and planning',
    icon = '󰏗 ',
    color = '#F97583',
    prompt_template = "You are an experienced technical leader. Help me design and plan the following:\n\n{context}\n\n{input}",
    tools = { 'file', 'terminal', 'git' },
    context_strategy = 'project',
  },
  
  -- Debug mode
  debug = {
    name = 'Debug',
    description = 'Expert debugger mode for diagnosing issues',
    icon = '󰒕 ',
    color = '#E6B673',
    prompt_template = "You are an expert debugger. Help me diagnose and fix the following issue:\n\n{context}\n\n{input}",
    tools = { 'file', 'terminal', 'lsp', 'git' },
    context_strategy = 'error',
  },
  
  -- Ask mode
  ask = {
    name = 'Ask',
    description = 'General assistance mode for questions',
    icon = '󰞋 ',
    color = '#B0A5F5',
    prompt_template = "You are a knowledgeable assistant. Please answer the following question:\n\n{context}\n\n{input}",
    tools = { 'file', 'terminal' },
    context_strategy = 'minimal',
  },
}

-- Custom mode registry
local custom_modes = {}

-- Initialize the mode system
function M.setup()
  -- Load custom modes from configuration
  if config.get('modes.custom') then
    for name, mode_config in pairs(config.get('modes.custom')) do
      M.register_mode({
        id = name,
        name = mode_config.name or name,
        description = mode_config.description or '',
        icon = mode_config.icon or '󰛨 ',
        color = mode_config.color or '#FFFFFF',
        prompt_template = mode_config.prompt_template or builtin_modes.ask.prompt_template,
        tools = mode_config.tools or {},
        context_strategy = mode_config.context_strategy or 'minimal',
      })
    end
  end
  
  -- Set default mode
  local default_mode = config.get('modes.default') or 'code'
  M.set_mode(default_mode)
end

-- Get a mode by ID
---@param mode_id string Mode ID
---@return table|nil Mode definition
function M.get_mode(mode_id)
  -- Check built-in modes
  if builtin_modes[mode_id] then
    local mode = vim.deepcopy(builtin_modes[mode_id])
    mode.id = mode_id
    return mode
  end
  
  -- Check custom modes
  if custom_modes[mode_id] then
    return vim.deepcopy(custom_modes[mode_id])
  end
  
  return nil
end

-- Set the current mode
---@param mode_id string Mode ID
---@return boolean Success
function M.set_mode(mode_id)
  local mode = M.get_mode(mode_id)
  if not mode then
    vim.notify('Unknown mode: ' .. mode_id, vim.log.levels.ERROR)
    return false
  end
  
  current_mode = mode
  
  -- Notify mode change
  vim.notify('Neoroo mode set to: ' .. mode.name, vim.log.levels.INFO)
  
  -- Trigger mode change event
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'NeorooModeChanged',
    data = { mode = mode },
  })
  
  return true
end

-- Get the current mode
---@return table Current mode
function M.get_current_mode()
  if not current_mode then
    -- Set default mode if not set
    local default_mode = config.get('modes.default') or 'code'
    M.set_mode(default_mode)
  end
  
  return current_mode
end

-- Get all available mode names
---@return table List of mode names
function M.get_mode_names()
  local names = {}
  
  -- Add built-in modes
  for id, _ in pairs(builtin_modes) do
    table.insert(names, id)
  end
  
  -- Add custom modes
  for id, _ in pairs(custom_modes) do
    table.insert(names, id)
  end
  
  table.sort(names)
  return names
end

-- Get all available modes
---@return table List of modes
function M.get_all_modes()
  local modes = {}
  
  -- Add built-in modes
  for id, mode in pairs(builtin_modes) do
    local mode_copy = vim.deepcopy(mode)
    mode_copy.id = id
    mode_copy.builtin = true
    table.insert(modes, mode_copy)
  end
  
  -- Add custom modes
  for id, mode in pairs(custom_modes) do
    local mode_copy = vim.deepcopy(mode)
    mode_copy.builtin = false
    table.insert(modes, mode_copy)
  end
  
  -- Sort by name
  table.sort(modes, function(a, b)
    return a.name < b.name
  end)
  
  return modes
end

-- Register a custom mode
---@param mode_def table Mode definition
---@return boolean Success
function M.register_mode(mode_def)
  -- Validate mode definition
  if not mode_def.id or not mode_def.name or not mode_def.prompt_template then
    vim.notify('Invalid mode definition', vim.log.levels.ERROR)
    return false
  end
  
  -- Check for ID conflicts
  if builtin_modes[mode_def.id] then
    vim.notify('Cannot override built-in mode: ' .. mode_def.id, vim.log.levels.ERROR)
    return false
  end
  
  -- Register the mode
  custom_modes[mode_def.id] = vim.deepcopy(mode_def)
  
  -- Update configuration
  if not config.get('modes.custom') then
    config.set('modes.custom', {})
  end
  
  config.get('modes.custom')[mode_def.id] = {
    name = mode_def.name,
    description = mode_def.description,
    icon = mode_def.icon,
    color = mode_def.color,
    prompt_template = mode_def.prompt_template,
    tools = mode_def.tools,
    context_strategy = mode_def.context_strategy,
  }
  
  return true
end

-- Unregister a custom mode
---@param mode_id string Mode ID
---@return boolean Success
function M.unregister_mode(mode_id)
  -- Cannot unregister built-in modes
  if builtin_modes[mode_id] then
    vim.notify('Cannot unregister built-in mode: ' .. mode_id, vim.log.levels.ERROR)
    return false
  end
  
  -- Check if mode exists
  if not custom_modes[mode_id] then
    vim.notify('Mode not found: ' .. mode_id, vim.log.levels.ERROR)
    return false
  end
  
  -- Unregister the mode
  custom_modes[mode_id] = nil
  
  -- Update configuration
  if config.get('modes.custom') and config.get('modes.custom')[mode_id] then
    local custom_config = config.get('modes.custom')
    custom_config[mode_id] = nil
    config.set('modes.custom', custom_config)
  end
  
  -- If current mode was unregistered, switch to default
  if current_mode and current_mode.id == mode_id then
    local default_mode = config.get('modes.default') or 'code'
    M.set_mode(default_mode)
  end
  
  return true
end

-- Format a prompt for the current mode
---@param input string User input
---@param context string|nil Context
---@return string Formatted prompt
function M.format_prompt(input, context)
  local mode = M.get_current_mode()
  local template = mode.prompt_template
  
  -- Replace placeholders
  local prompt = template
    :gsub('{input}', input or '')
    :gsub('{context}', context or '')
  
  return prompt
end

-- Execute a command in the current mode
---@param command string Command to execute
---@param context string|nil Context
---@return table Result
function M.execute(command, context)
  local mode = M.get_current_mode()
  
  -- Format prompt
  local prompt = M.format_prompt(command, context)
  
  -- Get AI provider
  local provider = require('neoroo.providers').get_provider()
  
  -- Execute command
  return provider.execute(prompt, {
    mode = mode.id,
    tools = mode.tools,
  })
end

return M
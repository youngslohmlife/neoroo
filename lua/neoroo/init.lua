-- neoroo/init.lua - Main module entry point
-- Neoroo: Autonomous AI Coding Agent for Neovim

local M = {}

-- Module references
local config = require('neoroo.core.config')
local buffer_manager = require('neoroo.core.buffer')
local mode_manager = require('neoroo.modes')
local ui = require('neoroo.ui')

-- Setup function to initialize the plugin with user configuration
---@param opts table|nil User configuration options
function M.setup(opts)
  -- Initialize configuration
  config.setup(opts or {})
  
  -- Initialize components
  buffer_manager.setup()
  mode_manager.setup()
  ui.setup()
  
  -- Log initialization
  if config.get('debug') then
    vim.notify('Neoroo initialized', vim.log.levels.INFO)
  end
end

-- Open the chat interface
---@param mode_name string|nil Optional mode to start with
function M.open_chat(mode_name)
  -- Set mode if provided
  if mode_name and mode_name ~= '' then
    mode_manager.set_mode(mode_name)
  end
  
  -- Open chat UI
  ui.open_chat()
end

-- Set the current mode
---@param mode_name string Mode name to set
function M.set_mode(mode_name)
  return mode_manager.set_mode(mode_name)
end

-- Get the current mode
---@return table Current mode information
function M.get_current_mode()
  return mode_manager.get_current_mode()
end

-- Open configuration
function M.open_config()
  ui.open_config()
end

-- Ask about the current selection
function M.ask_about_selection()
  local selection = buffer_manager.get_visual_selection()
  if selection and selection ~= '' then
    -- Set to Ask mode
    mode_manager.set_mode('ask')
    -- Open chat with selection as context
    ui.open_chat_with_context(selection)
  else
    vim.notify('No text selected', vim.log.levels.WARN)
  end
end

-- Execute a command with the AI
---@param command string Command to execute
---@param context string|nil Optional additional context
function M.execute_command(command, context)
  local current_mode = mode_manager.get_current_mode()
  
  -- Collect context if not provided
  if not context then
    context = buffer_manager.get_context()
  end
  
  -- Execute command in current mode
  return current_mode.execute(command, context)
end

-- Register a custom mode
---@param mode_def table Mode definition
function M.register_mode(mode_def)
  return mode_manager.register_mode(mode_def)
end

-- Register a custom tool
---@param tool_def table Tool definition
function M.register_tool(tool_def)
  return require('neoroo.tools').register_tool(tool_def)
end

-- Register a custom provider
---@param provider_def table Provider definition
function M.register_provider(provider_def)
  return require('neoroo.providers').register_provider(provider_def)
end

return M
-- neoroo/core/config.lua - Configuration management
-- Handles user configuration, defaults, and validation

local M = {}

-- Default configuration
local DEFAULT_CONFIG = {
  -- General settings
  debug = false,
  log_level = 'warn', -- 'debug', 'info', 'warn', 'error'
  
  -- UI settings
  ui = {
    chat_window = {
      width = 0.5,      -- 50% of screen width
      height = 0.8,     -- 80% of screen height
      position = 'right', -- 'left', 'right', 'top', 'bottom'
      border = 'rounded', -- 'none', 'single', 'double', 'rounded', 'solid', 'shadow'
    },
    floating_window = {
      border = 'rounded',
      width = 80,
      height = 20,
    },
    syntax_highlighting = true,
    icons = {
      enabled = true,
      mode = {
        code = '󰘧 ',
        architect = '󰏗 ',
        debug = '󰒕 ',
        ask = '󰞋 ',
      },
      status = {
        thinking = '󰔟 ',
        error = '󰀨 ',
        success = '󰄬 ',
      },
    },
  },
  
  -- AI provider settings
  providers = {
    default = 'openai', -- Default provider to use
    openai = {
      api_key = nil, -- Set via OPENAI_API_KEY env var or user config
      model = 'gpt-4',
      temperature = 0.7,
      max_tokens = 2000,
      timeout = 30, -- seconds
    },
    anthropic = {
      api_key = nil, -- Set via ANTHROPIC_API_KEY env var or user config
      model = 'claude-3-opus-20240229',
      temperature = 0.7,
      max_tokens = 2000,
      timeout = 30, -- seconds
    },
    -- Support for custom providers
    custom = {},
  },
  
  -- Mode settings
  modes = {
    default = 'code', -- Default mode to start with
    -- Built-in modes
    code = {
      prompt_template = "You are an expert software engineer. Help me with the following code:\n\n{context}\n\n{input}",
      tools = { 'file', 'terminal', 'lsp', 'git' },
    },
    architect = {
      prompt_template = "You are an experienced technical leader. Help me design and plan the following:\n\n{context}\n\n{input}",
      tools = { 'file', 'terminal', 'git' },
    },
    debug = {
      prompt_template = "You are an expert debugger. Help me diagnose and fix the following issue:\n\n{context}\n\n{input}",
      tools = { 'file', 'terminal', 'lsp', 'git' },
    },
    ask = {
      prompt_template = "You are a knowledgeable assistant. Please answer the following question:\n\n{context}\n\n{input}",
      tools = { 'file', 'terminal' },
    },
    -- Custom modes defined by user
    custom = {},
  },
  
  -- Tool settings
  tools = {
    file = {
      enabled = true,
      max_file_size = 1024 * 1024, -- 1MB
      excluded_patterns = { "node_modules/", ".git/" },
    },
    terminal = {
      enabled = true,
      shell = vim.o.shell,
      timeout = 30, -- seconds
    },
    lsp = {
      enabled = true,
      include_diagnostics = true,
      include_definitions = true,
    },
    git = {
      enabled = true,
      include_diff = true,
      include_blame = true,
    },
    browser = {
      enabled = false, -- Disabled by default as it requires external dependencies
      command = nil,   -- Command to launch headless browser
      timeout = 60,    -- seconds
    },
    -- Custom tools defined by user
    custom = {},
  },
  
  -- Memory settings
  memory = {
    enabled = true,
    storage_path = vim.fn.stdpath('data') .. '/neoroo/memory',
    max_entries = 100,
    context_window = 10, -- Number of recent interactions to include
  },
  
  -- Keymaps
  keymaps = {
    enabled = true,
    chat_toggle = '<leader>nc',
    mode_select = '<leader>nm',
    ask_selection = '<leader>na',
  },
}

-- The active configuration (will be populated in setup)
local config = vim.deepcopy(DEFAULT_CONFIG)

-- Merge user config with defaults recursively
---@param default table Default table
---@param user table User table to merge
---@return table Merged table
local function merge_config(default, user)
  local result = vim.deepcopy(default)
  
  for k, v in pairs(user) do
    if type(v) == 'table' and type(result[k]) == 'table' then
      result[k] = merge_config(result[k], v)
    else
      result[k] = v
    end
  end
  
  return result
end

-- Validate configuration
---@param cfg table Configuration to validate
---@return boolean, string|nil Valid, Error message
local function validate_config(cfg)
  -- Check for required API keys if providers are enabled
  if cfg.providers.default == 'openai' and not (cfg.providers.openai.api_key or os.getenv('OPENAI_API_KEY')) then
    return false, "OpenAI API key is required. Set it in config or OPENAI_API_KEY environment variable."
  end
  
  if cfg.providers.default == 'anthropic' and not (cfg.providers.anthropic.api_key or os.getenv('ANTHROPIC_API_KEY')) then
    return false, "Anthropic API key is required. Set it in config or ANTHROPIC_API_KEY environment variable."
  end
  
  -- Check if default mode exists
  if not cfg.modes[cfg.modes.default] then
    return false, "Default mode '" .. cfg.modes.default .. "' does not exist."
  end
  
  -- Check if browser tool is enabled but command is not set
  if cfg.tools.browser.enabled and not cfg.tools.browser.command then
    return false, "Browser tool is enabled but command is not set."
  end
  
  return true, nil
end

-- Initialize configuration with user options
---@param opts table User configuration options
function M.setup(opts)
  -- Merge user config with defaults
  config = merge_config(DEFAULT_CONFIG, opts)
  
  -- Load API keys from environment variables if not set in config
  if not config.providers.openai.api_key then
    config.providers.openai.api_key = os.getenv('OPENAI_API_KEY')
  end
  
  if not config.providers.anthropic.api_key then
    config.providers.anthropic.api_key = os.getenv('ANTHROPIC_API_KEY')
  end
  
  -- Validate configuration
  local valid, err = validate_config(config)
  if not valid then
    vim.notify('Neoroo configuration error: ' .. err, vim.log.levels.ERROR)
  end
  
  -- Create memory directory if it doesn't exist
  if config.memory.enabled then
    local memory_path = config.memory.storage_path
    if vim.fn.isdirectory(memory_path) == 0 then
      vim.fn.mkdir(memory_path, 'p')
    end
  end
end

-- Get the entire configuration or a specific value
---@param key string|nil Optional key to get a specific value
---@return any Configuration value
function M.get(key)
  if key then
    -- Support nested keys with dot notation (e.g., "ui.chat_window.width")
    local parts = vim.split(key, '.', { plain = true })
    local value = config
    
    for _, part in ipairs(parts) do
      if type(value) ~= 'table' then
        return nil
      end
      value = value[part]
      if value == nil then
        return nil
      end
    end
    
    return value
  end
  
  return config
end

-- Update configuration
---@param key string Key to update
---@param value any New value
function M.set(key, value)
  -- Support nested keys with dot notation
  local parts = vim.split(key, '.', { plain = true })
  local cfg = config
  
  -- Navigate to the parent table
  for i = 1, #parts - 1 do
    local part = parts[i]
    if type(cfg[part]) ~= 'table' then
      cfg[part] = {}
    end
    cfg = cfg[part]
  end
  
  -- Set the value
  cfg[parts[#parts]] = value
  
  -- Validate the updated configuration
  local valid, err = validate_config(config)
  if not valid then
    vim.notify('Neoroo configuration error: ' .. err, vim.log.levels.ERROR)
    -- Revert to default for this key
    M.reset(key)
  end
end

-- Reset configuration to default
---@param key string|nil Optional key to reset
function M.reset(key)
  if key then
    -- Support nested keys with dot notation
    local parts = vim.split(key, '.', { plain = true })
    local default_value = DEFAULT_CONFIG
    local cfg = config
    
    -- Get the default value
    for i, part in ipairs(parts) do
      if i < #parts then
        if type(default_value[part]) ~= 'table' then
          return -- Invalid key path
        end
        default_value = default_value[part]
        cfg = cfg[part]
      else
        -- Set the value to default
        cfg[part] = vim.deepcopy(default_value[part])
      end
    end
  else
    -- Reset entire configuration
    config = vim.deepcopy(DEFAULT_CONFIG)
  end
end

-- Register a custom mode
---@param name string Mode name
---@param mode_config table Mode configuration
function M.register_mode(name, mode_config)
  if not config.modes.custom then
    config.modes.custom = {}
  end
  
  config.modes.custom[name] = mode_config
end

-- Register a custom tool
---@param name string Tool name
---@param tool_config table Tool configuration
function M.register_tool(name, tool_config)
  if not config.tools.custom then
    config.tools.custom = {}
  end
  
  config.tools.custom[name] = tool_config
end

-- Register a custom provider
---@param name string Provider name
---@param provider_config table Provider configuration
function M.register_provider(name, provider_config)
  if not config.providers.custom then
    config.providers.custom = {}
  end
  
  config.providers.custom[name] = provider_config
end

return M
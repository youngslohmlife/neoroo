-- neoroo/tools/init.lua - Tool system
-- Handles various tools like file operations, terminal execution, and browser control

local M = {}

-- Module references
local config = require('neoroo.core.config')

-- Tool implementations
local tools = {}

-- Initialize the tool system
function M.setup()
  -- Load built-in tools
  tools.file = require('neoroo.tools.file')
  tools.terminal = require('neoroo.tools.terminal')
  tools.lsp = require('neoroo.tools.lsp')
  tools.git = require('neoroo.tools.git')
  tools.browser = require('neoroo.tools.browser')
  
  -- Initialize tools
  for name, tool in pairs(tools) do
    if tool.setup then
      tool.setup()
    end
  end
  
  -- Load custom tools from configuration
  if config.get('tools.custom') then
    for name, tool_config in pairs(config.get('tools.custom')) do
      if tool_config.module then
        local ok, custom_tool = pcall(require, tool_config.module)
        if ok and custom_tool then
          tools[name] = custom_tool
          if custom_tool.setup then
            custom_tool.setup()
          end
        else
          vim.notify('Failed to load custom tool: ' .. name, vim.log.levels.ERROR)
        end
      end
    end
  end
end

-- Get a tool by name
---@param name string Tool name
---@return table|nil Tool implementation
function M.get_tool(name)
  -- Check if tool exists and is enabled
  if tools[name] and config.get('tools.' .. name .. '.enabled') then
    return tools[name]
  end
  
  return nil
end

-- Register a custom tool
---@param name string Tool name
---@param tool table Tool implementation
function M.register_tool(name, tool)
  -- Validate tool implementation
  if not tool.execute then
    vim.notify('Invalid tool implementation: ' .. name, vim.log.levels.ERROR)
    return false
  end
  
  -- Register tool
  tools[name] = tool
  
  -- Initialize tool if it has a setup function
  if tool.setup then
    tool.setup()
  end
  
  return true
end

-- Execute a tool
---@param name string Tool name
---@param args table Arguments for the tool
---@return table Result
function M.execute_tool(name, args)
  -- Get tool
  local tool = M.get_tool(name)
  if not tool then
    return {
      success = false,
      error = 'Tool not found or disabled: ' .. name,
    }
  end
  
  -- Execute tool
  return tool.execute(args)
end

-- Create a stub implementation for file tool
-- This would normally be in a separate file
tools.file = {
  setup = function()
    -- Check configuration
    local max_file_size = config.get('tools.file.max_file_size')
    if not max_file_size or max_file_size <= 0 then
      config.set('tools.file.max_file_size', 1024 * 1024) -- Default to 1MB
    end
  end,
  
  execute = function(args)
    -- Validate arguments
    if not args.action then
      return {
        success = false,
        error = 'Missing required argument: action',
      }
    end
    
    -- Handle different actions
    if args.action == 'read' then
      -- Read file
      if not args.path then
        return {
          success = false,
          error = 'Missing required argument: path',
        }
      end
      
      -- Check if file exists
      if vim.fn.filereadable(args.path) == 0 then
        return {
          success = false,
          error = 'File not found: ' .. args.path,
        }
      end
      
      -- Check file size
      local file_size = vim.fn.getfsize(args.path)
      local max_file_size = config.get('tools.file.max_file_size')
      if file_size > max_file_size then
        return {
          success = false,
          error = 'File too large: ' .. file_size .. ' bytes (max: ' .. max_file_size .. ' bytes)',
        }
      end
      
      -- Read file
      local lines = vim.fn.readfile(args.path)
      return {
        success = true,
        content = table.concat(lines, '\n'),
        path = args.path,
      }
    elseif args.action == 'write' then
      -- Write file
      if not args.path then
        return {
          success = false,
          error = 'Missing required argument: path',
        }
      end
      
      if not args.content then
        return {
          success = false,
          error = 'Missing required argument: content',
        }
      end
      
      -- Convert content to lines
      local lines
      if type(args.content) == 'string' then
        lines = vim.split(args.content, '\n', { plain = true })
      else
        lines = args.content
      end
      
      -- Write file
      local ok, err = pcall(function()
        vim.fn.writefile(lines, args.path)
      end)
      
      if not ok then
        return {
          success = false,
          error = 'Failed to write file: ' .. (err or 'unknown error'),
        }
      end
      
      return {
        success = true,
        path = args.path,
      }
    elseif args.action == 'list' then
      -- List files
      if not args.path then
        return {
          success = false,
          error = 'Missing required argument: path',
        }
      end
      
      -- Check if directory exists
      if vim.fn.isdirectory(args.path) == 0 then
        return {
          success = false,
          error = 'Directory not found: ' .. args.path,
        }
      end
      
      -- List files
      local pattern = args.path
      if not pattern:match('/$') then
        pattern = pattern .. '/'
      end
      pattern = pattern .. '*'
      
      local files = vim.fn.glob(pattern, false, true)
      local result = {}
      
      for _, file in ipairs(files) do
        local is_dir = vim.fn.isdirectory(file) == 1
        table.insert(result, {
          path = file,
          is_directory = is_dir,
          size = is_dir and 0 or vim.fn.getfsize(file),
          modified = vim.fn.getftime(file),
        })
      end
      
      return {
        success = true,
        files = result,
        path = args.path,
      }
    else
      -- Unknown action
      return {
        success = false,
        error = 'Unknown action: ' .. args.action,
      }
    end
  end,
}

-- Create a stub implementation for terminal tool
-- This would normally be in a separate file
tools.terminal = {
  setup = function()
    -- Check configuration
    local timeout = config.get('tools.terminal.timeout')
    if not timeout or timeout <= 0 then
      config.set('tools.terminal.timeout', 30) -- Default to 30 seconds
    end
  end,
  
  execute = function(args)
    -- Validate arguments
    if not args.command then
      return {
        success = false,
        error = 'Missing required argument: command',
      }
    end
    
    -- Execute command
    local output = vim.fn.system(args.command)
    local exit_code = vim.v.shell_error
    
    return {
      success = exit_code == 0,
      output = output,
      exit_code = exit_code,
      command = args.command,
    }
  end,
}

-- Create a stub implementation for LSP tool
-- This would normally be in a separate file
tools.lsp = {
  setup = function()
    -- No special setup needed
  end,
  
  execute = function(args)
    -- Validate arguments
    if not args.action then
      return {
        success = false,
        error = 'Missing required argument: action',
      }
    end
    
    -- Handle different actions
    if args.action == 'diagnostics' then
      -- Get diagnostics for current buffer or specified buffer
      local bufnr = args.bufnr or vim.api.nvim_get_current_buf()
      local diagnostics = vim.diagnostic.get(bufnr)
      
      return {
        success = true,
        diagnostics = diagnostics,
        bufnr = bufnr,
      }
    elseif args.action == 'definition' then
      -- Get definition for current position or specified position
      local bufnr = args.bufnr or vim.api.nvim_get_current_buf()
      local row = args.row or vim.api.nvim_win_get_cursor(0)[1] - 1
      local col = args.col or vim.api.nvim_win_get_cursor(0)[2]
      
      local params = {
        textDocument = {
          uri = vim.uri_from_bufnr(bufnr),
        },
        position = {
          line = row,
          character = col,
        },
      }
      
      local result = vim.lsp.buf_request_sync(bufnr, 'textDocument/definition', params, 1000)
      
      return {
        success = result ~= nil,
        result = result,
        bufnr = bufnr,
        row = row,
        col = col,
      }
    else
      -- Unknown action
      return {
        success = false,
        error = 'Unknown action: ' .. args.action,
      }
    end
  end,
}

-- Create a stub implementation for Git tool
-- This would normally be in a separate file
tools.git = {
  setup = function()
    -- No special setup needed
  end,
  
  execute = function(args)
    -- Validate arguments
    if not args.action then
      return {
        success = false,
        error = 'Missing required argument: action',
      }
    end
    
    -- Handle different actions
    if args.action == 'status' then
      -- Get git status
      local output = vim.fn.system('git status --porcelain')
      local exit_code = vim.v.shell_error
      
      if exit_code ~= 0 then
        return {
          success = false,
          error = 'Failed to get git status: ' .. output,
        }
      end
      
      local status = {}
      for line in output:gmatch('[^\r\n]+') do
        local status_code = line:sub(1, 2)
        local file = line:sub(4)
        table.insert(status, {
          status = status_code,
          file = file,
        })
      end
      
      return {
        success = true,
        status = status,
      }
    elseif args.action == 'diff' then
      -- Get git diff
      local path = args.path or '.'
      local output = vim.fn.system('git diff ' .. path)
      local exit_code = vim.v.shell_error
      
      if exit_code ~= 0 then
        return {
          success = false,
          error = 'Failed to get git diff: ' .. output,
        }
      end
      
      return {
        success = true,
        diff = output,
        path = path,
      }
    else
      -- Unknown action
      return {
        success = false,
        error = 'Unknown action: ' .. args.action,
      }
    end
  end,
}

-- Create a stub implementation for Browser tool
-- This would normally be in a separate file
tools.browser = {
  setup = function()
    -- Check if browser tool is enabled
    if config.get('tools.browser.enabled') then
      -- Check if command is set
      local command = config.get('tools.browser.command')
      if not command then
        vim.notify('Browser tool is enabled but command is not set', vim.log.levels.WARN)
        config.set('tools.browser.enabled', false)
      end
    end
  end,
  
  execute = function(args)
    -- Check if browser tool is enabled
    if not config.get('tools.browser.enabled') then
      return {
        success = false,
        error = 'Browser tool is disabled',
      }
    end
    
    -- Validate arguments
    if not args.action then
      return {
        success = false,
        error = 'Missing required argument: action',
      }
    end
    
    -- Handle different actions
    if args.action == 'open' then
      -- Open URL
      if not args.url then
        return {
          success = false,
          error = 'Missing required argument: url',
        }
      end
      
      -- Get browser command
      local command = config.get('tools.browser.command')
      if not command then
        return {
          success = false,
          error = 'Browser command not set',
        }
      end
      
      -- Execute command
      local full_command = command .. ' ' .. args.url
      local output = vim.fn.system(full_command)
      local exit_code = vim.v.shell_error
      
      return {
        success = exit_code == 0,
        output = output,
        exit_code = exit_code,
        url = args.url,
      }
    else
      -- Unknown action
      return {
        success = false,
        error = 'Unknown action: ' .. args.action,
      }
    end
  end,
}

return M
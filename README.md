# Neoroo - Autonomous AI Coding Agent for Neovim

![Neoroo](https://via.placeholder.com/800x200/1e2132/7CCDEA?text=Neoroo)

Neoroo is a native Neovim plugin that brings the full power of autonomous AI coding capabilities to Neovim users, while respecting and leveraging Neovim's modal editing and extensibility model.

## Quick Setup

You can use the following shell script to quickly set up Neovim with Neoroo:

```bash
#!/bin/bash
# setup-neoroo.sh - Quick setup script for Neovim and Neoroo

# Create necessary directories
mkdir -p ~/.config/nvim
mkdir -p ~/.local/share/nvim/site/pack/plugins/start

# Install Neovim (if not already installed)
if ! command -v nvim &> /dev/null; then
    echo "Installing Neovim..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt-get update
        sudo apt-get install -y neovim
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install neovim
    else
        echo "Unsupported OS. Please install Neovim manually."
        exit 1
    fi
fi

# Install dependencies
echo "Installing dependencies..."
git clone --depth 1 https://github.com/nvim-lua/plenary.nvim ~/.local/share/nvim/site/pack/plugins/start/plenary.nvim
git clone --depth 1 https://github.com/MunifTanjim/nui.nvim ~/.local/share/nvim/site/pack/plugins/start/nui.nvim
git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter ~/.local/share/nvim/site/pack/plugins/start/nvim-treesitter

# Install Neoroo
echo "Installing Neoroo..."
git clone --depth 1 https://github.com/username/neoroo ~/.local/share/nvim/site/pack/plugins/start/neoroo

# Create minimal init.lua
echo "Creating minimal Neovim configuration..."
cat > ~/.config/nvim/init.lua << 'EOF'
-- Minimal Neovim configuration with Neoroo

-- Basic Neovim settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.termguicolors = true

-- Set up Neoroo
require('neoroo').setup({
  -- Set Anthropic as the default provider
  providers = {
    default = 'anthropic',
    anthropic = {
      api_key = os.getenv('ANTHROPIC_API_KEY'), -- Set your API key as an environment variable
      model = 'claude-3-7-sonnet-20240229', -- Use Claude 3.7 Sonnet
    },
  },
})

-- Set up keymaps
vim.keymap.set('n', '<leader>nc', '<cmd>NeorooChat<CR>', { desc = 'Open Neoroo chat' })
vim.keymap.set('n', '<leader>nm', '<cmd>NeorooMode ', { desc = 'Set Neoroo mode' })
vim.keymap.set('v', '<leader>na', function()
  require('neoroo').ask_about_selection()
end, { desc = 'Ask Neoroo about selection' })
EOF

echo "Setup complete! To use Neoroo:"
echo "1. Set your Anthropic API key: export ANTHROPIC_API_KEY=your_api_key_here"
echo "2. Start Neovim: nvim"
echo "3. Use <leader>nc to open the Neoroo chat interface"
```

Make the script executable and run it:

```bash
chmod +x setup-neoroo.sh
./setup-neoroo.sh
```

## Features

- **Multiple AI Providers**: Support for OpenAI, Anthropic, and custom providers
- **Specialized Modes**: Built-in modes for different tasks (Code, Architect, Debug, Ask)
- **Custom Mode Creation**: Create your own specialized AI modes through declarative configuration
- **Memory System**: Contextual awareness across sessions
- **Native Neovim Interface**:
  - Modal-first UX adhering to Vim principles
  - Split-window chat interface with proper syntax highlighting
  - Buffer-based interaction model
- **Tool Integration**:
  - File operations with atomic guarantees
  - Terminal execution with output capture
  - Headless browser control for web interactions
  - Git integration for version control awareness
  - LSP-aware code modifications
- **Developer Experience**:
  - Extensive Lua API for customization
  - Event system for plugin interop
  - Custom keymaps and commands
  - Async operations for responsiveness

## Requirements

- Neovim 0.9.0 or higher
- Lua 5.1 or higher (included with Neovim)
- Optional: Node.js for browser automation

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'username/neoroo',
    requires = {
        'nvim-lua/plenary.nvim',
        'MunifTanjim/nui.nvim',
        'nvim-treesitter/nvim-treesitter',
    },
    config = function()
        require('neoroo').setup({
            -- Your configuration here
        })
    end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    'username/neoroo',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'MunifTanjim/nui.nvim',
        'nvim-treesitter/nvim-treesitter',
    },
    config = function()
        require('neoroo').setup({
            -- Your configuration here
        })
    end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'MunifTanjim/nui.nvim'
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'username/neoroo'
```

## Configuration

### Configuration File Location

Neoroo is configured through your Neovim configuration file. The standard locations are:

- **For init.lua**: `~/.config/nvim/init.lua` (Linux/macOS) or `%LOCALAPPDATA%\nvim\init.lua` (Windows)
- **For a separate plugin config**: `~/.config/nvim/lua/plugins/neoroo.lua` (Linux/macOS) or `%LOCALAPPDATA%\nvim\lua\plugins\neoroo.lua` (Windows)

### Minimal Configuration (Anthropic Claude 3.7)

Here's a minimal configuration that sets up Neoroo with Anthropic's Claude 3.7 model:

```lua
-- In your init.lua or a separate plugin config file
require('neoroo').setup({
  -- Set Anthropic as the default provider
  providers = {
    default = 'anthropic',
    anthropic = {
      api_key = 'your_anthropic_api_key_here', -- Or use os.getenv('ANTHROPIC_API_KEY')
      model = 'claude-3-7-sonnet-20240229', -- Claude 3.7 Sonnet
      temperature = 0.7,
      max_tokens = 2000,
    },
  },
})
```

### Setting API Keys

You can set your API keys in three ways:

1. **Directly in the configuration** (not recommended for security reasons):
   ```lua
   anthropic = {
     api_key = 'your_anthropic_api_key_here',
     -- other settings
   }
   ```

2. **Using environment variables** (recommended):
   ```lua
   anthropic = {
     api_key = os.getenv('ANTHROPIC_API_KEY'),
     -- other settings
   }
   ```
   
   Set the environment variable before starting Neovim:
   ```bash
   export ANTHROPIC_API_KEY=your_anthropic_api_key_here
   nvim
   ```

3. **Using a secure credentials file** (alternative approach):
   ```lua
   -- Load API keys from a separate file not tracked in version control
   local api_keys = dofile(vim.fn.expand('~/.config/nvim/api_keys.lua'))
   
   require('neoroo').setup({
     providers = {
       default = 'anthropic',
       anthropic = {
         api_key = api_keys.anthropic,
         -- other settings
       },
     },
   })
   ```

### Full Configuration Options

Neoroo supports many configuration options:

```lua
require('neoroo').setup({
    -- General settings
    debug = false,
    log_level = 'warn', -- 'debug', 'info', 'warn', 'error'
    
    -- AI provider settings
    providers = {
        default = 'anthropic', -- Default provider to use
        openai = {
            api_key = nil, -- Set via OPENAI_API_KEY env var or user config
            model = 'gpt-4',
            temperature = 0.7,
            max_tokens = 2000,
        },
        anthropic = {
            api_key = nil, -- Set via ANTHROPIC_API_KEY env var or user config
            model = 'claude-3-7-sonnet-20240229',
            temperature = 0.7,
            max_tokens = 2000,
        },
    },
    
    -- Mode settings
    modes = {
        default = 'code', -- Default mode to start with
        -- Custom modes can be defined here
    },
    
    -- See documentation for more configuration options
})
```

## Usage

### Commands

- `:NeorooChat [mode]` - Open the Neoroo chat interface
- `:NeorooMode {mode}` - Switch to the specified mode
- `:NeorooConfig` - Open the Neoroo configuration window

### Default Keymaps

- `<leader>nc` - Open Neoroo chat
- `<leader>nm` - Set Neoroo mode (requires mode name)
- `<leader>na` - Ask Neoroo about visual selection (visual mode)

### Chat Interface

The chat interface provides a familiar chat-like experience:

1. Type your message at the bottom of the chat window
2. Press Enter to send
3. Neoroo will respond with AI-generated content
4. Code blocks are syntax highlighted

### Modes

Neoroo provides several built-in modes:

- **Code Mode**: Expert software engineer mode for coding assistance
- **Architect Mode**: Technical leader mode for design and planning
- **Debug Mode**: Expert debugger mode for diagnosing issues
- **Ask Mode**: General assistance mode for questions

You can also create custom modes through configuration.

## Examples

### Ask about code

```lua
-- Select code in visual mode
-- Press <leader>na

-- Or use the command
:NeorooChat code
-- Then type your question
```

### Get design advice

```lua
:NeorooMode architect
:NeorooChat
-- Then describe your design problem
```

### Debug an issue

```lua
:NeorooMode debug
:NeorooChat
-- Then describe the issue you're facing
```

## Customization

### Custom Modes

```lua
require('neoroo').setup({
    modes = {
        custom = {
            my_mode = {
                name = 'My Mode',
                description = 'Custom mode for specific tasks',
                prompt_template = "You are a specialized assistant. Help me with:\n\n{context}\n\n{input}",
                tools = { 'file', 'terminal' },
            },
        },
    },
})
```

### Custom Tools

```lua
require('neoroo').register_tool({
    id = 'my_tool',
    name = 'My Tool',
    description = 'Custom tool for specific tasks',
    execute = function(args)
        -- Tool implementation
        return {
            success = true,
            result = 'Tool executed successfully',
        }
    end,
})
```

## Documentation

For detailed documentation, see `:help neoroo` within Neovim.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT
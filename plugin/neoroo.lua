-- neoroo.lua - Main plugin entry point
-- Neoroo: Autonomous AI Coding Agent for Neovim

if vim.g.loaded_neoroo == 1 then
  return
end
vim.g.loaded_neoroo = 1

-- Set up default commands
vim.api.nvim_create_user_command('NeorooChat', function(opts)
  require('neoroo').open_chat(opts.args)
end, {
  nargs = '?',
  desc = 'Open Neoroo chat interface',
  complete = function()
    return require('neoroo.modes').get_mode_names()
  end
})

vim.api.nvim_create_user_command('NeorooMode', function(opts)
  require('neoroo').set_mode(opts.args)
end, {
  nargs = 1,
  desc = 'Set Neoroo mode',
  complete = function()
    return require('neoroo.modes').get_mode_names()
  end
})

vim.api.nvim_create_user_command('NeorooConfig', function()
  require('neoroo').open_config()
end, {
  desc = 'Open Neoroo configuration',
})

-- Set up default keymaps if not disabled
if vim.g.neoroo_disable_default_keymaps ~= 1 then
  vim.keymap.set('n', '<leader>nc', '<cmd>NeorooChat<CR>', { desc = 'Open Neoroo chat' })
  vim.keymap.set('n', '<leader>nm', '<cmd>NeorooMode ', { desc = 'Set Neoroo mode' })
  vim.keymap.set('v', '<leader>na', function()
    require('neoroo').ask_about_selection()
  end, { desc = 'Ask Neoroo about selection' })
end

-- Initialize the plugin
require('neoroo').setup()
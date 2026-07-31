-- config/vscode.lua — Map leader keys to VSCode/Cursor actions
local vscode = require('vscode')
local map = vim.keymap.set

-- File operations
map('n', '<leader>ff', function() vscode.action('workbench.action.quickOpen') end, { desc = 'Find file' })
map('n', '<leader>fg', function() vscode.action('workbench.action.findInFiles') end, { desc = 'Find in files' })
map('n', '<leader>fr', function() vscode.action('workbench.action.openRecent') end, { desc = 'Recent files' })

-- Code navigation
map('n', 'gd', function() vscode.action('editor.action.revealDefinition') end, { desc = 'Go to definition' })
map('n', 'gr', function() vscode.action('editor.action.goToReferences') end, { desc = 'Go to references' })
map('n', 'gi', function() vscode.action('editor.action.goToImplementation') end, { desc = 'Go to implementation' })
map('n', '<leader>ca', function() vscode.action('editor.action.quickFix') end, { desc = 'Code action' })
map('n', '<leader>rn', function() vscode.action('editor.action.rename') end, { desc = 'Rename' })

-- UI toggles
map('n', '<leader>nt', function() vscode.action('workbench.view.explorer') end, { desc = 'File explorer' })
map('n', '<leader>sb', function() vscode.action('workbench.action.toggleSidebarVisibility') end, { desc = 'Toggle sidebar' })
map('n', '<leader>xx', function() vscode.action('workbench.actions.view.problems') end, { desc = 'Problems panel' })

-- Terminal
map('n', '<leader>z', function() vscode.action('workbench.action.terminal.toggleTerminal') end, { desc = 'Toggle terminal' })

-- Git
map('n', '<leader>gs', function() vscode.action('workbench.view.scm') end, { desc = 'Git panel' })

-- AI (Cursor-specific)
map('n', '<leader>ai', function() vscode.action('aipopup.action.modal.generate') end, { desc = 'Cursor AI' })
map('v', '<leader>ai', function() vscode.action('aipopup.action.modal.generate') end, { desc = 'Cursor AI (selection)' })

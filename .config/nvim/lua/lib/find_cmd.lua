-- lib/find_cmd.lua — Utility to find the best binary, preferring project-local versions
local M = {}

--- Find the best command to run for a tool
--- @param name string Tool name (e.g., 'ruby-lsp', 'rubocop', 'rust-analyzer')
--- @param strategies table List of strategy functions to try in order
--- @return string|nil cmd The command to use, or nil if not found
function M.find(name, strategies)
  for _, strategy in ipairs(strategies) do
    local cmd = strategy(name)
    if cmd then
      return cmd
    end
  end
  return nil
end

--- Check if tool is available in project's Bundler context
function M.bundled(name)
  if vim.fn.filereadable('Gemfile.lock') == 1 then
    local result = vim.fn.system('bundle info ' .. name .. ' 2>/dev/null')
    if vim.v.shell_error == 0 then
      return 'bundle exec ' .. name
    end
  end
  return nil
end

--- Check rustup for a Rust tool
function M.rustup(name)
  local result = vim.fn.system('rustup which ' .. name .. ' 2>/dev/null')
  if vim.v.shell_error == 0 then
    return vim.fn.trim(result)
  end
  return nil
end

--- Check system PATH
function M.system(name)
  if vim.fn.executable(name) == 1 then
    return name
  end
  return nil
end

--- Check mason install directory
function M.mason(name)
  local mason_path = vim.fn.stdpath('data') .. '/mason/bin/' .. name
  if vim.fn.executable(mason_path) == 1 then
    return mason_path
  end
  return nil
end

return M

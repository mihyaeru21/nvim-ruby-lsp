local lspconfig = require('lspconfig')
local util = require('ruby-lsp.util')

local M = {}

M.get_env = function(gemfile_path)
  return {
    BUNDLE_GEMFILE = gemfile_path,
    BUNDLE_PATH__SYSTEM = 'true',
  }
end

M.get_ruby_lsp_dir = function(root_dir)
  return util.join(root_dir, '.ruby-lsp')
end

M.get_custom_gemfile_path = function(root_dir)
  return util.join(M.get_ruby_lsp_dir(root_dir), 'Gemfile')
end

M.restart = function()
  local client = nil
  for _, c in ipairs(lspconfig.util.get_managed_clients()) do
    if c.name == 'ruby_ls' then
      client = c
      break
    end
  end

  if client then
    vim.cmd('LspRestart ruby_ls')
  else
    vim.cmd('LspStart ruby_ls')
  end
end

M.sync = function(root_dir)
  local title = 'Ruby LSP: sync()'
  local notify_record = vim.notify('started.', vim.log.levels.INFO, { title = title, timeout = false })

  local ruby_lsp_dir = M.get_ruby_lsp_dir(root_dir)
  local custom_gemfile_path = M.get_custom_gemfile_path(root_dir)

  -- create .ruby-lsp directory
  if vim.fn.isdirectory(ruby_lsp_dir) == 0 then
    vim.fn.mkdir(ruby_lsp_dir, 'p')
  end

  -- create .gitignore
  local gitignore = util.join(ruby_lsp_dir, '.gitignore')
  if not util.file_exists(gitignore) then
    local file = io.open(gitignore, 'w')
    if file then
      file:write('*\n')
      file:close()
    end
  end

  -- create Gemfile
  if not util.file_exists(custom_gemfile_path) then
    local file = io.open(custom_gemfile_path, 'w')
    if file then
      file:write('# This custom gemfile is automatically generated by the Ruby LSP extension.\n')
      file:write('# It should be automatically git ignored, but in any case: do not commit it to your repository.\n\n')

      file:write('eval_gemfile(File.expand_path("../Gemfile", __dir__))\n')

      if not util.project_has_dependency('ruby-lsp') then
        file:write('gem "ruby-lsp", require: false, group: :development, source: "https://rubygems.org"\n')
      end

      if not util.project_has_dependency('debug') then
        file:write('gem "debug", require: false, group: :development, platforms: :mri, source: "https://rubygems.org"\n')
      end

      file:close()
    end
  end

  -- copy Gemfile.lock to .ruby-lsp/
  local original_lock_path = util.join(root_dir, 'Gemfile.lock')
  local ruby_lsp_lock_path = util.join(ruby_lsp_dir, 'Gemfile.lock')
  util.copy_file(original_lock_path, ruby_lsp_lock_path)

  -- bundle install
  local job_id = vim.fn.jobstart('bundle install', {
    env = M.get_env(custom_gemfile_path),
    stderr_buffered = true,
    on_stderr = function(_jid, data, _event)
      local msg = vim.fn.join(data, '\n')
      if msg == '' then return end

      local opts = { title = title, timeout = 10000 }
      if notify_record then opts.replace = notify_record end
      notify_record = vim.notify(msg, vim.log.levels.ERROR, opts)
    end,
    on_stdout = function(_jid, data, _event)
      local msg = vim.fn.join(data, '\n')
      if msg == '' then return end

      local opts = { title = title, timeout = false }
      if notify_record then opts.replace = notify_record end
      notify_record = vim.notify(msg, vim.log.levels.INFO, opts)
    end,
    on_exit = function(_jid, exit_code, _event)
      local opts = { title = title, timeout = 5000 }
      if notify_record then opts.replace = notify_record end

      if exit_code == 0 then
        vim.notify('succeded.', vim.log.levels.INFO, opts)
        M.restart()
      end
    end,
  })
end

return M

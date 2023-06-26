local lspconfig = require('lspconfig')
local util = require('ruby-lsp.util')
local vscode = require('ruby-lsp.vscode')

-- workaround for textDocument/diagnostic
-- see https://github.com/Shopify/ruby-lsp/issues/188
-- It will be unnecessary if textDocument/diagnostic is implemented in Neovim itself.
-- see https://github.com/neovim/neovim/issues/22838
local adapt_to_lsp_diagnostic = function(config)
  local original = config.on_attach

  config.on_attach = function(client, bufnr)
    if original then
      original(client, bufnr)
    end

    local callback = function()
      local params = vim.lsp.util.make_text_document_params(bufnr)

      client.request(
        'textDocument/diagnostic',
        { textDocument = params },
        function(err, result)
          if err then return end
          if result == nil then return end

          vim.lsp.diagnostic.on_publish_diagnostics(
            nil,
            vim.tbl_extend('keep', params, { diagnostics = result.items }),
            { client_id = client.id }
          )
        end
      )
    end

    callback() -- call on attach

    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePre', 'BufReadPost', 'InsertLeave', 'TextChanged' }, {
      buffer = bufnr,
      callback = callback,
    })
  end
end

local adapt_to_vscode_extension = function(config)
  local root_dir = util.find_root_dir(config.root_dir)
  if not root_dir then return end

  local custom_gemfile_path = vscode.get_custom_gemfile_path(root_dir)
  config.cmd_env = vscode.get_env(custom_gemfile_path)
  config.cmd = { 'bundle', 'exec', 'ruby-lsp' }
end

local M = {}

M.setup = function(ruby_lsp_config)
  lspconfig.util.on_setup = lspconfig.util.add_hook_before(lspconfig.util.on_setup, function(config)
    if config.name ~= 'ruby_ls' then return end

    adapt_to_lsp_diagnostic(config)

    if ruby_lsp_config.vscode then
      adapt_to_vscode_extension(config)
    end
  end)
end

M.sync = function()
  local root_dir = util.find_root_dir(lspconfig.ruby_ls.get_root_dir)
  if not root_dir then return end

  vscode.sync(root_dir)
end

return M

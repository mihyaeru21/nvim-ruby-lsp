local io = require('io')
local lspconfig = require('lspconfig')
local path_util = lspconfig.util.path

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

local file_exists = function(path)
  local f = io.open(path, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local find_root_dir = function(pattern)
  local current = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  if #current == 0 then
    current = vim.fn.getcwd()
  end
  return pattern(path_util.sanitize(current))
end

local adapt_to_vscode_extension = function(config)
  local root_dir = find_root_dir(config.root_dir)
  if not root_dir then return end

  local custom_gemfile_path = path_util.sanitize(path_util.join(root_dir, '.ruby-lsp', 'Gemfile'))

  if file_exists(custom_gemfile_path) then
    config.cmd_env = {
      BUNDLE_GEMFILE = custom_gemfile_path,
      BUNDLE_PATH__SYSTEM = 'true',
    }
    config.cmd = { 'bundle', 'exec', 'ruby-lsp' }
  else
    config.cmd = function(_dispatch)
      return nil
    end
  end
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

return M

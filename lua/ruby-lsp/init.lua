local lspconfig = require('lspconfig')

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

local M = {}

M.setup = function()
  lspconfig.util.on_setup = lspconfig.util.add_hook_before(lspconfig.util.on_setup, function(config)
    if config.name ~= 'ruby_ls' then return end

    adapt_to_lsp_diagnostic(config)
  end)
end

return M

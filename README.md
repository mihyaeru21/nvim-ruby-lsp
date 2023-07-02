# nvim-ruby-lsp

A nvim-lspconfig plugin for [Ruby LSP](https://github.com/Shopify/ruby-lsp).

It is temporarily needed to support the following two items. Once these are implemented in Neovim, Ruby LSP, this plugin will no longer be needed.

- LSP `textDocument/diagnostic` feature
- Coexistence with [Ruby LSP VSCode extension](https://github.com/Shopify/vscode-ruby-lsp)(optional feature)

Ruby LSP now uses `textDocument/diagnostic` instead of `textDocument/publishDiagnostics` for diagnostics since v0.2.2. This is a new feature added in LSP 3.17 and not yet implemented in Neovim's LSP client. Therefore, a workaround is required to display diagnostics. See https://github.com/Shopify/ruby-lsp/issues/188.

Instead of using the project's Gemfile, the VSCode extension creates its own Gemfile to manage dependencies on the Ruby LSP. This plugin provides a `:RubyLspSync` command that provides similar functionality. See https://github.com/Shopify/vscode-ruby-lsp/issues/421.


# Usage

Install with your favorite plugin manager. Here is an example using packer.

```lua
use { 'mihyaeru21/nvim-ruby-lsp', requires = 'neovim/nvim-lspconfig' }
```

Call `require('ruby-lsp').setup()` before setup each servers.

```lua
require('ruby-lsp').setup()

local lspconfig = require('lspconfig')
lspconfig.ruby_ls.setup {
  ...
}
```

## VSCode extension

If you want to enable compatibility with the VSCode extension, give `vscode = true` as follows.

```lua
require('ruby-lsp').setup { vscode = true }
```

Running `:RubyLspSync` will create a `.ruby-lsp` directory, which contains a Gemfile with additional dependencies on `ruby-lsp`. The LSP Client will then be restarted.

```vim
:RubyLspSync
```


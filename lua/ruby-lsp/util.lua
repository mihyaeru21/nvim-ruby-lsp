local io = require('io')
local path_util = require('lspconfig').util.path

local M = {}

M.join = function(...)
  return path_util.sanitize(path_util.join(...))
end

M.file_exists = function(path)
  local f = io.open(path, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

M.find_root_dir = function(pattern)
  local current = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  if #current == 0 then
    current = vim.fn.getcwd()
  end
  return pattern(path_util.sanitize(current))
end

M.project_has_dependency = function(gem)
  return true -- TODO
end

M.copy_file = function(src, dest)
  local src_file = io.open(src, 'rb')

  if src_file then
    local content = src_file:read('*a')
    src_file:close()

    local dest_file = io.open(dest, 'wb')
    if dest_file then
      dest_file:write(content)
      dest_file:close()
    end
  end
end

return M

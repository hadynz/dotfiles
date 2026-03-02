local M = {}

--- Toggle `it.only` on the current line
--- If the line contains `it.only`, it removes it. If it contains `it`, it adds `.only`.
function M.toggle_it_only()
  local line = vim.api.nvim_get_current_line()
  if line:match("^%s*it%.only%s*%(") then
    line = line:gsub("it%.only", "it")
  elseif line:match("^%s*it%s*%(") then
    line = line:gsub("it", "it.only", 1)
  else
    return
  end
  vim.api.nvim_set_current_line(line)
end

return M

local M = {}

function M.close_into_buffer()
  if #vim.api.nvim_list_wins() < 2 then return end
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd("close")
  vim.api.nvim_set_current_buf(buf)
end

return M

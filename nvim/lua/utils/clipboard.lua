local M = {}

--- Copy a file path to the clipboard and notify
---@param path string
function M.copy_file_path(path)
  vim.fn.setreg("+", path)
  vim.notify("Copied: " .. path)
end

--- Copy a file path with line number(s) to the clipboard and notify
---@param path string
function M.copy_file_path_with_lines(path)
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")

  -- Ensure start_line is always the smaller number
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local path_with_lines
  if start_line == end_line then
    path_with_lines = path .. ":" .. start_line
  else
    path_with_lines = path .. ":" .. start_line .. "-" .. end_line
  end

  vim.fn.setreg("+", path_with_lines)
  vim.notify("Copied: " .. path_with_lines)
end

--- Copy file path with line numbers (visual mode) or current line (normal mode)
---@param path string
function M.copy_file_path_smart(path)
  if vim.fn.mode() == "v" or vim.fn.mode() == "V" or vim.fn.mode() == "\22" then
    M.copy_file_path_with_lines(path)
  else
    local current_line = vim.fn.line(".")
    local path_with_line = path .. ":" .. current_line
    vim.fn.setreg("+", path_with_line)
    vim.notify("Copied: " .. path_with_line)
  end
end

return M

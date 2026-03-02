local M = {}

--- Move cursor in given direction while keeping it vertically centered.
--- Excludes plugin buffers (e.g. harpoon, minifiles) which use standard vim behaviour.
---@param direction string "j" or "k"
function M.keep_centered(direction)
  local excluded_filetypes = { "harpoon", "minifiles" }

  for _, filetype in ipairs(excluded_filetypes) do
    if vim.o.filetype == filetype then
      vim.cmd("norm! " .. direction)
      return
    end
  end

  vim.cmd("norm! " .. direction .. "zz")
end

return M

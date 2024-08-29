return {
  "rmagatti/goto-preview",
  event = "BufEnter",
  config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
  opts = {
    width = 130,
    height = 22,
    post_open_hook = function(buff, win)
      -- Resize preview buffer
      vim.keymap.set("n", "<C-right>", "<C-w>>", { buffer = true })
      vim.keymap.set("n", "<C-left>", "<C-w><", { buffer = true })
      vim.keymap.set("n", "<C-up>", "<C-w>-", { buffer = true })
      vim.keymap.set("n", "<C-down>", "<C-w>+", { buffer = true })

      -- Close one buffer at a time
      vim.keymap.set("n", "<Esc>", function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end, { buffer = buff })
    end,
  },
}

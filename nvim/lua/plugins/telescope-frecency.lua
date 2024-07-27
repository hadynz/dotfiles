local open_frecency = function()
  local root = string.gsub(vim.fn.system("git rev-parse --show-toplevel"), "\n", "")
  if vim.v.shell_error == 0 then
    require("telescope").extensions.frecency.frecency({ cwd = root, workspace = "CWD" })
  else
    require("telescope").extensions.frecency.frecency({ workspace = "CWD" })
  end
end

return {
  "nvim-telescope/telescope-frecency.nvim",
  enabled = false,
  config = function()
    require("telescope").load_extension("frecency")
  end,
  keys = {
    { "<leader>r", open_frecency, desc = "Recent Files" },
  },
}

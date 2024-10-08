local lazy_icons = LazyVim.config.icons

local function get_diagnostics(props)
  local icons = {
    error = lazy_icons.diagnostics.Error,
    warn = lazy_icons.diagnostics.Warn,
    info = lazy_icons.diagnostics.Info,
    hint = lazy_icons.diagnostics.Hint,
  }
  local labels = {}

  for severity, icon in pairs(icons) do
    local n = #vim.diagnostic.get(props.buf, { severity = vim.diagnostic.severity[string.upper(severity)] })
    if n > 0 then
      table.insert(labels, { " " .. icon .. n, group = "DiagnosticSign" .. severity })
    end
  end
  if #labels > 0 then
    table.insert(labels, { " ┊" })
  end
  return labels
end

local function get_mini_diff(props)
  local icons = {
    add = lazy_icons.git.added,
    change = lazy_icons.git.modified,
    delete = lazy_icons.git.removed,
  }
  local signs = vim.b[props.buf].minidiff_summary

  local labels = {}
  if signs == nil then
    return labels
  end
  for name, icon in pairs(icons) do
    if tonumber(signs[name]) and signs[name] > 0 then
      table.insert(labels, { " ", icon .. signs[name], group = "MiniDiffSign" .. name })
    end
  end
  if #labels > 0 then
    table.insert(labels, { " 󰊢 " .. signs.n_ranges .. " ┊" })
  end
  return labels
end

return {
  {
    "b0o/incline.nvim",
    config = function()
      require("incline").setup()
    end,
    event = "VeryLazy",
  },
  -- Display floating filepath and filename
  -- {
  --   "b0o/incline.nvim",
  --   enabled = false,
  --   event = {
  --     "BufReadPre",
  --     "BufNewFile",
  --   },
  --   dependencies = { "nvim-web-devicons" },
  --   priority = 1200,
  --   config = function()
  --     require("incline").setup({
  --       highlight = {
  --         groups = {
  --           InclineNormal = { guibg = "#303270", guifg = "#a9b1d6" },
  --           InclineNormalNC = { guibg = "none", guifg = "#a9b1d6" },
  --         },
  --       },
  --       window = {
  --         padding = 0,
  --         margin = { horizontal = 1 },
  --       },
  --       hide = {
  --         cursorline = true, -- Should cursorline be on top of floating status bar
  --       },
  --       render = function(props)
  --         local root_dir = vim.fs.root(vim.fn.getcwd(), ".git")
  --         local filename = vim.fn.expand("%:t")
  --         local absolute_filepath = vim.fn.expand("%:p")
  --         local relative_filepath = vim.fn.expand("%:.")
  --         -- print("absolute_filepath: " .. absolute_filepath)
  --         -- print("relative_filepath: " .. relative_filepath)
  --         -- print("root_dir: " .. root_dir)
  --         local modifiedRelativeFilePath = absolute_filepath:gsub("^" .. root_dir .. "/", "")
  --         -- print("modifiedRelativeFilePath: " .. modifiedRelativeFilePath)
  --         -- print("easy" .. vim.fn.resolve('/' .. relative_filepath))

  --         -- Add modified (unsaved) indicator
  --         if vim.bo[props.buf].modified then
  --           relative_filepath = "[*] " .. relative_filepath
  --         end

  --         local icon, color = require("nvim-web-devicons").get_icon_color(filename)

  --         return {
  --           -- { get_diagnostics(props) },
  --           -- { get_mini_diff(props) },
  --           -- { " " .. icon,                    guifg = color },
  --           -- { " " .. relative_filepath .. " " },
  --           { " " .. filename .. " ",         guifg = "#11111b", guibg = "#cba6f7", gui = "bold" },
  --         }
  --       end,
  --     })
  --   end,
  -- },
}

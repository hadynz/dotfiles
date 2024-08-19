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
  -- Display floating filepath and filename
  {
    "b0o/incline.nvim",
    event = {
      "BufReadPre",
      "BufNewFile",
    },
    dependencies = { "nvim-web-devicons" },
    priority = 1200,
    config = function()
      require("incline").setup({
        highlight = {
          groups = {
            InclineNormal = { guibg = "#303270", guifg = "#a9b1d6" },
            InclineNormalNC = { guibg = "none", guifg = "#a9b1d6" },
          },
        },
        window = {
          padding = 0,
          margin = { horizontal = 1 },
        },
        hide = {
          cursorline = false, -- Should cursorline be on top of floating status bar
        },
        render = function(props)
          local filename = vim.fn.expand("%:t")
          local filepath = vim.fn.expand("%:p:h")

          -- Add modified (unsaved) indicator
          if vim.bo[props.buf].modified then
            filepath = "[*] " .. filepath
          end

          local icon, color = require("nvim-web-devicons").get_icon_color(filename)

          return {
            { get_diagnostics(props) },
            { get_mini_diff(props) },
            { " " .. icon, guifg = color },
            { " " .. filepath .. " " },
            { " " .. filename .. " ", guifg = "#11111b", guibg = "#cba6f7", gui = "bold" },
          }
        end,
      })
    end,
  },
}

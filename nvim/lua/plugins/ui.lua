return {
  -- Display floating filepath and filename
  {
    "b0o/incline.nvim",
    event = "BufReadPre",
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
          margin = { vertical = 0, horizontal = 1 },
          padding = 0,
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
            { " " .. icon,            guifg = color },
            { " " .. filepath .. " " },
            { " " .. filename .. " ", guifg = "#11111b", guibg = "#cba6f7", gui = "bold" },
          }
        end,
      })
    end,
  },
}

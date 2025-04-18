return {
  "b0o/incline.nvim",
  event = "VeryLazy",
  config = function()
    require("incline").setup({
      ignore = {
        floating_wins = false,
      },
      render = function(props)
        -- Don't render anything if cursor is on the first line
        if props.win and vim.api.nvim_win_get_cursor(props.win)[1] == 1 then
          return {}
        end

        local render = {}
        local bufname = vim.api.nvim_buf_get_name(props.buf)

        -- Full name of buffer that includes both path and filename
        local filename = vim.fn.fnamemodify(bufname, ":t")

        -- Upward lookup of root path up to .git root. Determines start of relative path
        local git_root = vim.fs.find(".git", { upward = true, path = vim.fn.fnamemodify(bufname, ":p:h") })[1]
        local relative_path = git_root and bufname:gsub(vim.fn.fnamemodify(git_root, ":h") .. "/", "") or bufname

        -- Extract relative path without filename
        local path_only = vim.fn.fnamemodify(relative_path, ":h")

        local modified = vim.api.nvim_buf_get_option(props.buf, "modified") and "bold,italic" or "None"
        local filetype_icon, color = require("nvim-web-devicons").get_icon_color(filename)

        -- Check if window is narrow (less than 50 columns)
        local win_width = vim.api.nvim_win_get_width(props.win)
        local is_narrow = win_width < 90

        if is_narrow then
          -- If narrow, show only the filename
          table.insert(render, { filename, gui = modified })
          return render
        end

        local buffer = {
          { filetype_icon, guifg = color },
          { " " },
          { path_only .. "/", guifg = "#6c7086" }, -- Muted color for the path
          { filename, gui = modified },
        }

        for _, buffer_ in ipairs(buffer) do
          table.insert(render, buffer_)
        end
        return render
      end,
    })
  end,
}

return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>gh", group = "Current File History" },
        { "<leader>gH", group = "hunks" },
      },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
  opts = function(_, opts)
    opts.current_line_blame = true

    -- Remap hunk bindings from <leader>gh to <leader>gH
    local original_on_attach = opts.on_attach
    opts.on_attach = function(buffer)
      if original_on_attach then
        original_on_attach(buffer)
      end

      local gs = require("gitsigns")
      local map = function(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
      end

      -- Remove original <leader>gh* bindings and remap to <leader>gH*
      local hunk_maps = {
        { { "n", "x" }, "s", ":Gitsigns stage_hunk<CR>", "Stage Hunk" },
        { { "n", "x" }, "r", ":Gitsigns reset_hunk<CR>", "Reset Hunk" },
        { "n", "S", function() gs.stage_buffer() end, "Stage Buffer" },
        { "n", "u", function() gs.undo_stage_hunk() end, "Undo Stage Hunk" },
        { "n", "R", function() gs.reset_buffer() end, "Reset Buffer" },
        { "n", "p", function() gs.preview_hunk_inline() end, "Preview Hunk Inline" },
        { "n", "b", function() gs.blame_line({ full = true }) end, "Blame Line" },
        { "n", "B", function() gs.blame() end, "Blame Buffer" },
        { "n", "d", function() gs.diffthis() end, "Diff This" },
        { "n", "D", function() gs.diffthis("~") end, "Diff This ~" },
      }

      for _, m in ipairs(hunk_maps) do
        -- Delete original <leader>gh* binding
        pcall(vim.keymap.del, m[1], "<leader>gh" .. m[2], { buffer = buffer })
        -- Set new <leader>gH* binding
        map(m[1], "<leader>gH" .. m[2], m[3], m[4])
      end

      -- Navigate between git changes
      map("n", "]c", function() gs.nav_hunk("next") end, "Next Git Change")
      map("n", "[c", function() gs.nav_hunk("prev") end, "Previous Git Change")
    end
  end,
  },
}

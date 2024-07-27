local show_which_key = function()
  require("which-key").show("s")
end

local paste_at_char = function()
  local hop = require("hop-yank")
  hop.paste_char1({
    hint_offset = -1,
  })
end

local hop_end_of_word = function()
  local hop = require("hop")
  hop.hint_words({
    hint_position = require("hop.hint").HintPosition.END,
  })
end

return {
  -- `hop` is an EasyMotion-like plugin allowing you to jump anywhere in a
  -- document with as few keystrokes as possible.
  {
    "smoka7/hop.nvim",
    version = "*",
    main = "hop",
    opts = {
      multi_windows = true,
    },
    keys = {
      { "ss", "<cmd>HopCamelCase<cr>",       desc = "Hop to word",                 mode = { "n", "v", "x", "o" } },
      { "se", hop_end_of_word,               desc = "Hop to word ends",            mode = { "n", "v", "x", "o" } },
      { "sl", "<cmd>HopWordCurrentLine<cr>", desc = "Hop to word on current line", mode = { "n", "v", "x", "o" } },
      { "sp", paste_at_char,                 desc = "Hop paste",                   mode = { "n", "v", "x", "o" } },
      { "sn", "<cmd>HopNodes<cr>",           desc = "Hop to tree node",            mode = { "n", "v", "x", "o" } },
      { "s0", "<cmd>HopLine<cr>",            desc = "Hop to line",                 mode = { "n", "v", "x", "o" } },
      { "s_", "<cmd>HopLineStart<cr>",       desc = "Hop to line start",           mode = { "n", "v", "x", "o" } },
      { "s/", "<cmd>HopPattern<cr>",         desc = "Hop to pattern",              mode = { "n", "v", "x", "o" } },
      { "s",  show_which_key,                desc = "Show which-key" },
    },
  },
}

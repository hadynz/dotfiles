return {
  "echasnovski/mini.ai",
  opts = function()
    local ai = require("mini.ai")
    return {
      custom_textobjects = {
        k = ai.gen_spec.treesitter({ a = "@call.outer", i = "@call.inner" }),
      },
    }
  end,
}

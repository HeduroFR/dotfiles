return {
  "saravenpi/paper.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    local paper = require("paper")
    paper.setup({
      variant = "dark",
      transparent = true,
      italic_comments = true,
      italic_keywords = true,
      bold_functions = true,
    })

    vim.cmd.colorscheme("paper")
  end,
}

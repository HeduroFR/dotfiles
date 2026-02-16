return {
	{
		"catppuccin/nvim",
		lazy = false,
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				custom_highlights = function(colors)
					return {
						["@type.prisma"] = { fg = colors.mauve },
						["@property.prisma"] = { fg = colors.blue },
						["@keyword.prisma"] = { fg = colors.red },
						["@function.prisma"] = { fg = colors.yellow },
						["@string.prisma"] = { fg = colors.green },
						["@attribute.prisma"] = { fg = colors.peach },
					}
				end,
			})
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
}

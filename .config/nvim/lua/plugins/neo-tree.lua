return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
		local neo_tree = require("neo-tree")
		neo_tree.setup({
			filesystem = {
				filtered_items = {
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_hidden = false,
				},
			},
		})

		vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>", { silent = true })
		vim.keymap.set("n", "<leader>bf", ":Neotree buffers reveal float<CR>", { silent = true })
		vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { silent = true })
	end,
}

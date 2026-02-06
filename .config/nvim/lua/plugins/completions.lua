return {
  {
    "hrsh7th/cmp-nvim-lsp",
  },
  {
    "github/copilot.vim",
  },
  {
		"hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",     -- LSP source
      "hrsh7th/cmp-buffer",       -- Buffer source
      "hrsh7th/cmp-path",         -- Path source
      "hrsh7th/cmp-cmdline",      -- Cmdline source
      "saadparwaiz1/cmp_luasnip", -- Snippet source
      "L3MON4D3/LuaSnip",         -- Snippet engine
      "rafamadriz/friendly-snippets", -- Snippets prédéfinis
      "onsails/lspkind.nvim",
    },
    config = function()
			local cmp = require("cmp")
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
				}),
			})
		end,
	},
}

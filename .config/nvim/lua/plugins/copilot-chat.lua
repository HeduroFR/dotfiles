return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		dependencies = {
			{ "github/copilot.vim" }, -- ou { "zbirenbaum/copilot.lua" }
			{ "nvim-lua/plenary.nvim" },
		},
		build = "make tiktoken", -- Seulement sur MacOS/Linux
		opts = {
			debug = false,
			window = {
				layout = "float",
				width = 80, -- Fixed width in columns
				height = 20, -- Fixed height in rows
				border = "rounded", -- 'single', 'double', 'rounded', 'solid'
				title = "🤖 AI Assistant",
				zindex = 100, -- Ensure window stays on top
			},

			headers = {
				user = "👤 You",
				assistant = "🤖 Copilot",
				tool = "🔧 Tool",
			},

			separator = "━━",
			auto_fold = true,
			mappings = {
				complete = {
					detail = "Use @<Tab> or /<Tab> for options.",
					insert = "<Tab>",
				},
				close = {
					normal = "q",
					insert = "<C-c>",
				},
				reset = {
					normal = "<C-r>",
					insert = "<C-r>",
				},
				submit_prompt = {
					normal = "<CR>",
					insert = "<C-s>",
				},
				accept_diff = {
					normal = "<C-y>",
					insert = "<C-y>",
				},
				yank_diff = {
					normal = "gy",
				},
				show_diff = {
					normal = "gd",
				},
				show_system_prompt = {
					normal = "gp",
				},
				show_user_selection = {
					normal = "gs",
				},
			},
		},
		keys = {
			-- Toggle chat
			{
				"<leader>cc",
				function()
					require("CopilotChat").toggle()
				end,
				desc = "Toggle Copilot Chat",
			},
			-- Open chat avec sélection
			{
				"<leader>ce",
				function()
					local input = vim.fn.input("Ask Copilot: ")
					if input ~= "" then
						require("CopilotChat").ask(input)
					end
				end,
				desc = "Ask Copilot",
				mode = { "n", "v" },
			},
			-- Quick chat
			{
				"<leader>cq",
				function()
					local input = vim.fn.input("Quick Chat: ")
					if input ~= "" then
						require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
					end
				end,
				desc = "Quick Chat",
			},
			-- Explain code
			{
				"<leader>cx",
				function()
					require("CopilotChat").ask("Explain this code", {
						selection = require("CopilotChat.select").visual,
					})
				end,
				desc = "Explain Code",
				mode = "v",
			},
			-- Fix code
			{
				"<leader>cf",
				function()
					require("CopilotChat").ask("Correct this code", {
						selection = require("CopilotChat.select").visual,
					})
				end,
				desc = "Fix Code",
				mode = "v",
			},
			-- Optimize code
			{
				"<leader>co",
				function()
					require("CopilotChat").ask("Optimize this code", {
						selection = require("CopilotChat.select").visual,
					})
				end,
				desc = "Optimize Code",
				mode = "v",
			},
			-- Docs
			{
				"<leader>cd",
				function()
					require("CopilotChat").ask("Add documentations to this code", {
						selection = require("CopilotChat.select").visual,
					})
				end,
				desc = "Add Documentation",
				mode = "v",
			},
			-- Tests
			{
				"<leader>ct",
				function()
					require("CopilotChat").ask("Generate some tests on this code", {
						selection = require("CopilotChat.select").visual,
					})
				end,
				desc = "Generate Tests",
				mode = "v",
			},
		},
		config = function(_, opts)
			local chat = require("CopilotChat")
			local select = require("CopilotChat.select")

			-- Prompts personnalisés
			opts.prompts = {
				Explain = {
					prompt = "/COPILOT_EXPLAIN Explain this code",
				},
				Review = {
					prompt = "/COPILOT_REVIEW Review this code and submit some upgrades",
				},
				Fix = {
					prompt = "/COPILOT_GENERATE There is a problem with this code. Fix it.",
				},
				Optimize = {
					prompt = "/COPILOT_GENERATE Optimize this code and enhance perfs and readability.",
				},
				Docs = {
					prompt = "/COPILOT_GENERATE Add documentation JSDoc/TSDoc to this code.",
				},
				Tests = {
					prompt = "/COPILOT_GENERATE Make unit tests for this code.",
				},
				FixDiagnostic = {
					prompt = "Fix the diagnostics in this file.",
					selection = select.diagnostics,
				},
				Commit = {
					prompt = "Write a commit message for this updates, keep in mind the conventionnal commits.",
					selection = select.gitdiff,
				},
			}

			chat.setup(opts)
		end,
	},
}

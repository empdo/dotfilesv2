return {
	{
		"mason-org/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"mason-org/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "ts_ls", "jdtls", "clangd", "qmlls", "tinymist" },
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			vim.lsp.enable("jdtls")
			vim.lsp.enable("qmlls")
			vim.lsp.config("qmlls", {
				capabilities = capabilities,
			})
			vim.lsp.enable("clangd")
			vim.lsp.config("clangd", {
				capabilities = capabilities,
			})
			vim.lsp.enable("ts_ls")
			vim.lsp.config("ts_ls", {
				capabilities = capabilities,
			})
			vim.lsp.enable("tinymist")
			vim.lsp.config("tinymist", {
				capabilities = capabilities,
				settings = {
					formatterMode = "typstyle",
					exportPdf = "onType",
					semanticTokens = "disable",
          tinymist = {
      fontPaths = { "fonts" },  -- relative to workspace root
    },
				},
			})
			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" },
						},
					},
				},
			})
			vim.lsp.enable("lua_ls")
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, {})
			vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
}

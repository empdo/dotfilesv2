return {
  "rebelot/terminal.nvim",
  config = function()
    require("terminal").setup()

    local term_map = require("terminal.mappings")
    vim.keymap.set({ "n", "x" }, "<leader>ts", term_map.operator_send, { expr = true, desc = "Send to terminal" })
    vim.keymap.set("n", "<leader>to", term_map.toggle, { desc = "Toggle terminal" })
    vim.keymap.set("n", "<leader>tO", term_map.toggle({ open_cmd = "enew" }), { desc = "Toggle terminal in buffer" })
    vim.keymap.set("n", "<leader>tr", term_map.run, { desc = "Run in terminal" })
    vim.keymap.set("n", "<leader>tR", term_map.run(nil, { layout = { open_cmd = "enew" } }), { desc = "Run in terminal buffer" })
    vim.keymap.set("n", "<leader>tk", term_map.kill, { desc = "Kill terminal" })
    vim.keymap.set("n", "<leader>t]", term_map.cycle_next, { desc = "Next terminal" })
    vim.keymap.set("n", "<leader>t[", term_map.cycle_prev, { desc = "Previous terminal" })
    vim.keymap.set("n", "<leader>tl", term_map.move({ open_cmd = "belowright vnew" }), { desc = "Move terminal right" })
    vim.keymap.set("n", "<leader>tL", term_map.move({ open_cmd = "botright vnew" }), { desc = "Move terminal far right" })
    vim.keymap.set("n", "<leader>th", term_map.move({ open_cmd = "belowright new" }), { desc = "Move terminal below" })
    vim.keymap.set("n", "<leader>tH", term_map.move({ open_cmd = "botright new" }), { desc = "Move terminal bottom" })
    vim.keymap.set("n", "<leader>tf", term_map.run("", { layout = { open_cmd = "float" } }), { desc = "New floating terminal" })
  end
}

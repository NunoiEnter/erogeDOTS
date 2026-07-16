local map = vim.keymap.set

map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })
map("n", "[q", function() vim.cmd.cprev() end, { desc = "Previous Quickfix" })
map("n", "]q", function() vim.cmd.cnext() end, { desc = "Next Quickfix" })

map("n", "<leader>uf", function() require("conform").format({ lsp_fallback = true }) end, { desc = "Format Buffer" })
map("n", "<leader>us", function() require("snacks").toggle.option("spell", { name = "Spelling" }):toggle() end, { desc = "Toggle Spelling" })
map("n", "<leader>uw", function() require("snacks").toggle.option("wrap", { name = "Word Wrap" }):toggle() end, { desc = "Toggle Word Wrap" })
map("n", "<leader>ul", function() require("snacks").toggle.option("relativenumber", { name = "Relative Numbers" }):toggle() end, { desc = "Toggle Relative Numbers" })
map("n", "<leader>ud", function() vim.diagnostic.enable(not vim.diagnostic.is_enabled()) end, { desc = "Toggle Diagnostics" })
map("n", "<leader>uc", function()
  local current = vim.opt.conceallevel:get()
  vim.opt.conceallevel = current == 0 and 2 or 0
end, { desc = "Toggle Conceal Level" })

map("n", "<leader>w", "<c-w>", { desc = "Windows", remap = true })
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "<leader>qq", function() vim.cmd("qa") end, { desc = "Quit All" })

map("t", "<esc><esc>", [[<C-\><C-n>]], { desc = "Enter Normal Mode" })

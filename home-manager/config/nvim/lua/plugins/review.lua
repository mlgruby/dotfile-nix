local function open_review_pr()
  local result = vim
    .system({ "git", "rev-parse", "--path-format=absolute", "--git-path", "herdr-pr.json" }, { text = true })
    :wait()
  if result.code == 0 then
    local path = vim.trim(result.stdout)
    if vim.fn.filereadable(path) == 1 then
      local ok, metadata = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
      if
        ok
        and type(metadata) == "table"
        and type(metadata.url) == "string"
        and metadata.url:match("^https://[%w.-]+/[%w_.-]+/[%w_.-]+/pull/%d+$")
      then
        vim.cmd("Octo " .. metadata.url)
        return
      end
    end
  end
  vim.cmd("Octo pr edit")
end

return {
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    opts = { picker = "snacks", enable_builtin = true },
    keys = {
      { "<leader>gR", open_review_pr, desc = "Review PR on GitHub" },
      { "<leader>gI", "<cmd>Octo pr list<cr>", desc = "List GitHub PRs" },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Review local changes" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Review file history" },
    },
  },
}

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
    opts = {
      picker = "snacks",
      enable_builtin = true,
      timeout = 30000,
      use_local_fs = false,
      mappings = {
        file_panel = { toggle_viewed = { lhs = "v", desc = "Toggle GitHub Viewed" } },
        review_diff = { toggle_viewed = { lhs = "<leader>rv", desc = "Toggle GitHub Viewed" } },
      },
    },
    config = function(_, opts)
      require("octo").setup(opts)
      require("config.pr_review").setup()
    end,
    keys = {
      { "<leader>gR", open_review_pr, desc = "Review PR on GitHub" },
      { "<leader>gI", "<cmd>Octo pr list<cr>", desc = "List GitHub PRs" },
    },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = function()
      require("config.pr_review").style()
      local actions = require("diffview.actions")
      return {
        enhanced_diff_hl = false,
        file_panel = { listing_style = "list", win_config = { width = 42 } },
        keymaps = {
          file_panel = {
            { "n", "j", actions.select_next_entry, { desc = "Open next file" } },
            { "n", "<down>", actions.select_next_entry, { desc = "Open next file" } },
            { "n", "k", actions.select_prev_entry, { desc = "Open previous file" } },
            { "n", "<up>", actions.select_prev_entry, { desc = "Open previous file" } },
          },
        },
      }
    end,
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Review local changes" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Review file history" },
    },
  },
}

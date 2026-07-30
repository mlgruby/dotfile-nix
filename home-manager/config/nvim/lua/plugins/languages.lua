return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.bashls = opts.servers.bashls or {}
      opts.servers.ts_ls = opts.servers.ts_ls or {}

      for _, server in pairs(opts.servers) do
        if type(server) == "table" then
          server.mason = false
        end
      end
    end,
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = {}
    end,
  },
}

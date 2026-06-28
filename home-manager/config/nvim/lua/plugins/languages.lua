return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = { mason = false },
        ts_ls = { mason = false },
      },
    },
  },
}

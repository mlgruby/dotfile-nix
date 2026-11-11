local M = {}

function M.style()
  vim.opt.fillchars:append({ diff = " ", eob = " " })
  for name, spec in pairs({
    DiffAdd = { bg = "#24352b" },
    DiffDelete = { bg = "#3b2729", fg = "#ba7777" },
    DiffChange = { bg = "#2d3338" },
    DiffText = { bg = "#405047", bold = false },
    DiffviewDiffAddAsDelete = { bg = "#3b2729" },
    DiffviewDiffDelete = { bg = "#3b2729", fg = "#3b2729" },
  }) do
    vim.api.nvim_set_hl(0, name, spec)
  end
end

function M.setup()
  M.style()
  local group = vim.api.nvim_create_augroup("DotfilesReview", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.style })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(event)
      vim.schedule(function()
        local layout = require("octo.reviews").get_current_layout()
        if not layout or not layout.file_panel:is_open() then
          return
        end
        local panel = layout.file_panel
        vim.wo[panel.winid].winbar = " Files | ↑↓ Open | v Viewed"
        vim.wo[layout.left_winid].winbar = " BEFORE"
        vim.wo[layout.right_winid].winbar = " AFTER"
        if not vim.api.nvim_buf_is_valid(event.buf) or vim.bo[event.buf].filetype ~= "octo_panel" then
          return
        end
        vim.api.nvim_win_call(panel.winid, function()
          if not vim.w.dotfiles_review_panel then
            vim.w.dotfiles_review_panel = true
            vim.cmd("wincmd H")
            vim.cmd("vertical resize 44")
          end
        end)
        local function move(next_file)
          if #layout.files == 0 then
            return
          end
          if next_file then
            layout:select_next_file()
          else
            layout:select_prev_file()
          end
          panel:focus()
        end
        for _, key in ipairs({ "j", "<Down>" }) do
          vim.keymap.set("n", key, function()
            move(true)
          end, { buffer = event.buf, desc = "Open next file" })
        end
        for _, key in ipairs({ "k", "<Up>" }) do
          vim.keymap.set("n", key, function()
            move(false)
          end, { buffer = event.buf, desc = "Open previous file" })
        end
      end)
    end,
  })
end

function M.open()
  require("lazy").load({ plugins = { "octo.nvim" } })
  local result = vim
    .system({ "git", "rev-parse", "--path-format=absolute", "--git-path", "herdr-pr.json" }, { text = true })
    :wait()
  if result.code ~= 0 then
    error("Open this viewer from an hpr review checkout")
  end
  local metadata = vim.json.decode(table.concat(vim.fn.readfile(vim.trim(result.stdout)), "\n"))
  local host, owner, repo = metadata.repository:match("^([^/]+)/([^/]+)/([^/]+)$")
  if not host then
    error("Invalid PR repository metadata")
  end
  local query = [[query($owner:String!,$repo:String!,$number:Int!,$endCursor:String){
    repository(owner:$owner,name:$repo){pullRequest(number:$number){
      id headRefOid headRefName headRepository{nameWithOwner}
      files(first:100,after:$endCursor){nodes{path viewerViewedState} pageInfo{hasNextPage endCursor}}
    }}
  }]]
  vim.notify("Loading PR files and GitHub viewed state…")
  vim.system({
    "gh",
    "api",
    "graphql",
    "--hostname",
    host,
    "--paginate",
    "--slurp",
    "-f",
    "query=" .. query,
    "-f",
    "owner=" .. owner,
    "-f",
    "repo=" .. repo,
    "-F",
    "number=" .. metadata.number,
  }, { text = true }, function(response)
    vim.schedule(function()
      if response.code ~= 0 then
        vim.notify(response.stderr, vim.log.levels.ERROR)
        return
      end
      local ok, pages = pcall(vim.json.decode, response.stdout)
      if not ok or not pages[1] or pages[1].errors then
        vim.notify("Could not load GitHub PR viewed state", vim.log.levels.ERROR)
        return
      end
      local files, data = {}, pages[1].data.repository.pullRequest
      for _, page in ipairs(pages) do
        local pr = page.data and page.data.repository.pullRequest
        if not pr or pr.headRefOid ~= metadata.headRefOid then
          vim.notify("PR head changed. Reopen it from the inbox before reviewing.", vim.log.levels.ERROR)
          return
        end
        vim.list_extend(files, pr.files.nodes)
      end
      local Rev = require("octo.reviews.rev").Rev
      local pr = require("octo.model.pull-request").PullRequest:new({
        repo = owner .. "/" .. repo,
        head_repo = data.headRepository.nameWithOwner,
        head_ref_name = data.headRefName,
        number = metadata.number,
        id = data.id,
        left = Rev:new(metadata.base),
        right = Rev:new(metadata.headRefOid),
        files = files,
      })
      require("octo.reviews").Review:new(pr):browse()
    end)
  end)
end

return M

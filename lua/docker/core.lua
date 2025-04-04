-- docker-neovim/lua/docker/core.lua
local M = {}
local popup_win = nil

-- Funções Auxiliares --
local function close_popup()
  if popup_win and vim.api.nvim_win_is_valid(popup_win) then
    vim.api.nvim_win_close(popup_win, true)
    popup_win = nil
  end
end

local function notify(message, level)
  vim.notify("[Docker] " .. message, level or vim.log.levels.INFO, {
    title = "Docker-Neovim",
    icon = "🐳",
    timeout = 3000
  })
end

local function show_output(title, command)
  close_popup()

  local ok, output = pcall(vim.fn.systemlist, command)
  if not ok or vim.v.shell_error ~= 0 then
    notify("Erro: " .. (ok and table.concat(output, "\n") or output, vim.log.levels.ERROR)
    return
  end

  if #output == 0 then
    output = { "Nenhum resultado encontrado" }
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'docker')

  local width = math.min(100, vim.o.columns - 10)
  local height = math.min(30, #output + 2)

  popup_win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 3,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center"
  })

  vim.keymap.set('n', '<ESC>', close_popup, { buffer = buf, silent = true })
  vim.keymap.set('n', 'q', close_popup, { buffer = buf, silent = true })
end

-- Operações Docker --
function M.show_containers()
  show_output("🐳 Contêineres", "docker ps -a --format 'table {{.ID}}\\t{{.Names}}\\t{{.Status}}\\t{{.Ports}}'")
end

function M.show_images()
  show_output("🐳 Imagens", "docker images --format 'table {{.ID}}\\t{{.Repository}}\\t{{.Tag}}\\t{{.Size}}'")
end

function M.show_logs(container)
  if not container or container == "" then
    notify("Especifique o ID/nome do contêiner", vim.log.levels.WARN)
    return
  end
  show_output("📜 Logs: " .. container, "docker logs --tail=50 -f " .. container)
end

function M.inspect_container(container)
  if not container or container == "" then
    notify("Especifique o ID/nome do contêiner", vim.log.levels.WARN)
    return
  end
  show_output("🔍 Inspecionar: " .. container, "docker inspect " .. container)
end

function M.exec_in_container(container, cmd)
  cmd = cmd or "bash"
  if not container or container == "" then
    notify("Especifique o ID/nome do contêiner", vim.log.levels.WARN)
    return
  end
  vim.cmd("TermExec cmd='docker exec -it " .. container .. " " .. cmd .. "'")
end

function M.stop_container(container)
  if not container or container == "" then
    notify("Especifique o ID/nome do contêiner", vim.log.levels.WARN)
    return
  end
  vim.cmd("TermExec cmd='docker stop " .. container .. "'")
  notify("Contêiner " .. container .. " parado")
end

function M.start_container(container)
  if not container or container == "" then
    notify("Especifique o ID/nome do contêiner", vim.log.levels.WARN)
    return
  end
  vim.cmd("TermExec cmd='docker start " .. container .. "'")
  notify("Contêiner " .. container .. " iniciado")
end

function M.prune_system()
  vim.ui.select(
    {"Tudo", "Contêineres", "Imagens", "Volumes", "Redes", "Cancelar"},
    { prompt = "Limpar recursos Docker:" },
    function(choice)
      local commands = {
        ["Tudo"] = "docker system prune -af",
        ["Contêineres"] = "docker container prune -f",
        ["Imagens"] = "docker image prune -af",
        ["Volumes"] = "docker volume prune -f",
        ["Redes"] = "docker network prune -f"
      }
      if commands[choice] then
        vim.cmd("TermExec cmd='" .. commands[choice] .. "'")
      end
    end
  )
end

-- Menu Interativo --
function M.show_docker_menu()
  vim.ui.select(
    {
      "📋 Listar Contêineres",
      "🖼️ Listar Imagens",
      "📜 Ver Logs",
      "🔍 Inspecionar",
      "⚡ Executar Comando",
      "🛑 Parar Contêiner",
      "🚀 Iniciar Contêiner",
      "🧹 Limpar Sistema",
      "🚪 Sair"
    },
    {
      prompt = "🐳 Menu Docker:",
      format_item = function(item)
        return " " .. item .. " "
      end,
    },
    function(choice)
      if not choice then return end

      local actions = {
        ["📋 Listar Contêineres"] = M.show_containers,
        ["🖼️ Listar Imagens"] = M.show_images,
        ["📜 Ver Logs"] = function()
          vim.ui.input(
            { prompt = "Nome/ID do contêiner:" },
            function(input) if input then M.show_logs(input) end end
          )
        end,
        ["🔍 Inspecionar"] = function()
          vim.ui.input(
            { prompt = "Nome/ID do contêiner:" },
            function(input) if input then M.inspect_container(input) end end
          )
        end,
        ["⚡ Executar Comando"] = function()
          vim.ui.input(
            { prompt = "Contêiner:" },
            function(container)
              if container then
                vim.ui.input(
                  { prompt = "Comando (padrão: bash):", default = "bash" },
                  function(cmd) if cmd then M.exec_in_container(container, cmd) end end
                )
              end
            end
          )
        end,
        ["🛑 Parar Contêiner"] = function()
          vim.ui.input(
            { prompt = "Nome/ID do contêiner:" },
            function(input) if input then M.stop_container(input) end end
          )
        end,
        ["🚀 Iniciar Contêiner"] = function()
          vim.ui.input(
            { prompt = "Nome/ID do contêiner:" },
            function(input) if input then M.start_container(input) end end
          )
        end,
        ["🧹 Limpar Sistema"] = M.prune_system
      }

      if actions[choice] then actions[choice]() end
    end
  )
end

-- Configuração --
function M.setup(opts)
  opts = opts or {}
  local keymaps = opts.keymaps or {
    menu = '<leader>dm',
    ps = '<leader>dps',
    images = '<leader>dim',
    prune = '<leader>dpl'
  }

  -- Comandos
  vim.api.nvim_create_user_command("DockerPS", M.show_containers, { desc = "Listar contêineres Docker" })
  vim.api.nvim_create_user_command("DockerImages", M.show_images, { desc = "Listar imagens Docker" })
  vim.api.nvim_create_user_command("DockerLogs", function(o)
    M.show_logs(o.args)
  end, { desc = "Mostrar logs do contêiner", nargs = '?' })

  -- Atalhos
  vim.keymap.set('n', keymaps.menu, M.show_docker_menu, { desc = '🐳 Menu Docker' })
  vim.keymap.set('n', keymaps.ps, ':DockerPS<CR>', { desc = 'Listar contêineres' })
  vim.keymap.set('n', keymaps.images, ':DockerImages<CR>', { desc = 'Listar imagens' })
  vim.keymap.set('n', keymaps.prune, ':lua require("docker").prune_system()<CR>', { desc = 'Limpar sistema Docker' })

  notify("Configuração Docker carregada com sucesso!")
end

return M

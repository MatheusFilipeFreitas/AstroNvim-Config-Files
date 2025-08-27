return {
  -- O plugin principal para integrar o jdtls ao Neovim
  {
    "mfussenegger/nvim-jdtls",
    -- Garante que o plugin seja carregado apenas quando um arquivo Java for aberto
    ft = "java",
    -- Dependências necessárias para o nvim-jdtls funcionar corretamente
    dependencies = {
      "mfussenegger/nvim-dap", -- Essencial para a funcionalidade de depuração (debug)
    },
    config = function()
      -- Esta função de configuração será executada quando o plugin for carregado.

      -- Define o caminho onde o Mason instalou o jdtls
      local jdtls_path = vim.fn.stdpath "data" .. "/mason/packages/jdtls"

      -- Define o caminho para a configuração específica da sua plataforma (Linux, Mac, Windows)
      -- IMPORTANTE: Mude 'config_linux' para 'config_mac' ou 'config_win' se necessário!
      local jdtls_config = "config_linux" 
      if vim.fn.has "mac" then
        jdtls_config = "config_mac"
      elseif vim.fn.has "win32" then
        jdtls_config = "config_win"
      end

      -- Encontra o diretório raiz do projeto (procurando por arquivos de build comuns)
      local root_dir = require("jdtls.setup").find_root { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }
      -- Cria um diretório de workspace único por projeto para evitar conflitos
      local workspace_dir = vim.fn.stdpath "data" .. "/jdtls-workspace/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

      -- Comando de inicialização do jdtls
      local cmd = {
        "java",
        "-Declipse.application=org.eclipse.jdt.ls.core.id1.JavaLanguageServerImpl",
        "-Dosgi.bundles.defaultStartLevel=4",
        "-Declipse.product=org.eclipse.jdt.ls.core.product",
        "-Dlog.protocol=true",
        "-Dlog.level=ALL",
        "-javaagent:" .. jdtls_path .. "/lombok.jar", -- Adiciona suporte ao Lombok
        "-Xms1g",
        "--add-modules=ALL-SYSTEM",
        "--add-opens", "java.base/java.util=ALL-UNNAMED",
        "--add-opens", "java.base/java.lang=ALL-UNNAMED",
        "-jar", vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
        "-configuration", jdtls_path .. "/" .. jdtls_config,
        "-data", workspace_dir,
      }

      -- Inicia o servidor de linguagem jdtls
      require("jdtls").start_or_attach {
        cmd = cmd,
        root_dir = root_dir,
        -- Funções a serem executadas quando o servidor se anexa a um buffer
        on_attach = function(client, bufnr)
          -- Habilita a integração com o depurador (nvim-dap)
          require("jdtls").setup_dap()
          -- Configura automaticamente as classes principais para depuração
          require("jdtls.dap").setup_dap_main_class_configs()
        end,
      }
    end,
  },
}

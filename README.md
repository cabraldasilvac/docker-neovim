# Docker-Neovim Integration

## Installation

```lua
-- Packer
use { 'cabraldasilvac/docker-neovim' }

-- Lazy.nvim
{ 'cabraldasilvac/docker-neovim', opts = {} }
```

### 🔍 Estrutura Detalhada:

1. core.lua

   - Contém toda a lógica Docker original

   - Isolada em um módulo autocontido

   - Funções prefixadas com M. para escopo

2. init.lua

   - Ponto de entrada padrão

   - Configuração mínima necessária

3. setup.lua

   - Metadados para gerenciadores de plugins

   - Compatível com Packer/Lazy.nvim

4. README.md

   - Instruções concisas

   - [![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

   - [![Neovim](https://img.shields.io/badge/Neovim-0.8%2B-green.svg)](https://neovim.io)

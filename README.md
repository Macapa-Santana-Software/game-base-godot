# BranchSkipper (Godot 4.6)

Projeto de jogo 2D em Godot com mecânica de terminal Git in-game para alterar estado do mundo (branch, commit, checkout, push/pull simulados).

## Visao geral

- **Engine:** Godot 4.6 (Forward Plus)
- **Cena principal:** `World/playground.tscn`
- **Genero base:** Puzzle/aventura 2D com progressao por comandos Git
- **Core loop:** coletar fragmentos -> `git add` -> `git commit` -> desbloquear progresso no mundo

## Estrutura do projeto

```text
.
├── GeneralNodes/                # Componentes reutilizaveis (HitBox, HurtBox)
├── Player/                      # Cena e scripts do jogador + state machine
├── Props/
│   ├── Plants/                  # Props visuais/interativos de ambiente
│   └── Fragments/               # Itens colecionaveis (fragmento)
├── Systems/
│   └── GameState/               # Estado global do "repositorio" in-game (autoload)
├── Terminal/
│   ├── Commands/                # Implementacoes dos comandos git simulados
│   ├── UI/                      # Cena/script da UI de terminal
│   ├── World/                   # Objeto terminal no mapa (interacao)
│   └── terminal_command_interpreter.gd
├── Tile Maps/                   # Tilemaps e cenario
├── World/                       # Cenas de fase/mundo (playground)
└── project.godot
```

## Arquitetura funcional

- **`GameState` (autoload)** em `Systems/GameState/game_state.gd`
  - Simula conceitos de Git: `working_directory`, `staging_area`, `branch`, `HEAD`, remoto
  - Emite sinais para atualizar gameplay (`commit_created`, `checkout_applied`, etc.)
- **Interpretador de terminal** em `Terminal/terminal_command_interpreter.gd`
  - Faz parse de `git <comando> [args]`
  - Encaminha para handlers em `Terminal/Commands/`
- **UI terminal** em `Terminal/UI/terminal_ui.tscn` + `terminal_ui.gd`
  - Exibe historico, entrada e resposta dos comandos
- **Orquestracao do mundo** em `World/playground.gd`
  - Conecta jogador, terminal e `GameState`
  - Aplica efeitos de commit/checkout no mundo

## Comandos Git simulados disponiveis

Implementados em `Terminal/Commands/`:

- `git add`
- `git commit`
- `git log`
- `git checkout`
- `git branch`
- `git merge`
- `git push`
- `git pull`
- `git status`

## Fluxo de gameplay atual

1. Jogador coleta fragmentos (`Props/Fragments/fragmento.tscn`)
2. Fragmento entra no diretorio de trabalho no `GameState`
3. Jogador interage com o terminal (tecla de interacao configurada em `interagir`)
4. Executa comandos Git no terminal
5. Commits e checkouts disparam mudancas no mundo e progresso

## Inputs principais

Definidos no `project.godot`:

- Movimento: `up`, `down`, `left`, `right` (WASD + setas + gamepad)
- Ataque: `attack` (espaco)
- Interacao com terminal: `interagir` (T)

## Padroes adotados para organizacao

- **Pastas por dominio**, nao por tipo generico:
  - Terminal (UI, comandos, objeto de mundo)
  - World (cenas principais)
  - Props (objetos de ambiente/coleta)
- **Scripts junto da feature** correspondente
- **Cena + script pareados** no mesmo contexto (ex.: `Terminal/UI/terminal_ui.*`)
- **Estado global centralizado** em `Systems/GameState`

## Convencoes recomendadas (para manter consistencia)

- Nomes de arquivos em `snake_case` para novos assets/scripts
- 1 responsabilidade principal por script
- Evitar logica de regra de negocio em cenas visuais; preferir sistemas (`Systems/`)
- Toda nova mecânica com evento deve expor sinal claro para integracao
- Ao criar novo comando de terminal:
  1. adicionar arquivo em `Terminal/Commands/`
  2. herdar de `GitCommand`
  3. registrar em `TerminalCommandInterpreter._register_handlers()`

## Guia rapido para novos desenvolvedores

1. Abrir projeto no Godot 4.6
2. Rodar cena principal `World/playground.tscn`
3. Ler nesta ordem:
   - `Systems/GameState/game_state.gd`
   - `Terminal/terminal_command_interpreter.gd`
   - `World/playground.gd`
   - `Terminal/UI/terminal_ui.gd`
4. Testar ciclo completo no jogo:
   - coletar fragmento
   - `git status`
   - `git add <item>`
   - `git commit -m "mensagem"`

## Backlog tecnico sugerido

- Padronizar tipos explicitos em todos os scripts (evitar dinamismo onde nao precisa)
- Criar testes automatizados de parse/comandos do terminal
- Separar regras de mundo em um `WorldStateApplier` dedicado
- Adicionar documentacao de contribuicao (`CONTRIBUTING.md`) com fluxo de branch/PR
- Revisar UX de terminal para acessibilidade e responsividade completa

## Notas de manutencao

- `project.godot` aponta para `World/playground.tscn` como cena principal.
- Se mover arquivos `.tscn`/`.gd`, atualize sempre os caminhos `res://` nas cenas e no `project.godot`.
- Preserve arquivos `.uid` dos scripts ao mover para evitar troca de UID no editor.

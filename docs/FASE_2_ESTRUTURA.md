# Fase 2 — "Ecos de Possibilidades": estrutura (Partes 1, 2 e 3)

Cena: `res://fases/fase_2/fase_2.tscn`. Independente da Fase 1; recebe o repositório Git dela.

## Repositório Git (`GameState`)

```
commits:    Array[Dictionary]   { id, mensagem, arquivos, pai, pais }  ← o commit NÃO sabe a branch
branches:   Dictionary          nome -> { head, mundo }                 ← ponteiros; `mundo` é opaco
branch_ativa: String            "main" por padrão (o HEAD)
```

- `pais`: ids dos commits anteriores (`[]` raiz · 1 id comum · 2 ids no merge: `[destino, origem]`).
  `pai` continua sendo o primeiro pai. Commits antigos só com `pai` são lidos por `pais_de()`.
- `arquivos` é o que entrou NAQUELE commit (não um snapshot). O que está versionado numa branch é a
  união dos `arquivos` de todos os seus ancestrais. O commit de merge tem `arquivos: []`.
- O histórico de uma branch segue **todos** os pais a partir do head, sem repetir commits, do mais
  recente ao mais antigo (a ordem de criação é topológica: todo pai nasce antes do filho).

| Operação | Retorno |
|---|---|
| `criar_branch(nome)` (git branch) | `{ok, erro, mensagem}`; aponta para o commit atual; NÃO troca a branch |
| `trocar_branch(nome)` (git switch) | idem; valida existência; ressincroniza a pasta; emite `branch_ativa_mudou` |
| `mesclar(origem)` (git merge) | idem; integra `origem` na branch ATIVA (ver "Merge") |
| `formatar_log(resumido)` (git log) | idem; histórico da branch ativa em BBCode; emite `log_consultado` |
| `historico(branch)`, `obter_head()`, `branch_existe()`, `listar_branches()`, `branches_em(id)` | consultas |
| `pais_de(commit)`, `eh_ancestral(a, d)`, `commits_exclusivos(branch, outra)`, `commits_sem(id_a, id_b)`, `obter_commit_de_merge(destino, origem)` | grafo |
| `arquivos_na_pasta()` | arquivos que existem na pasta da branch ativa |
| `obter_mundo_branch()`, `definir_mundo_branch()` | estado opaco por branch |
| `reset_fase()` | limpa só o temporário (arquivos, staging, inventário, tutoria); **preserva o repositório** |
| `resetar_repositorio()` | reset completo e destrutivo (novo jogo, testes) |

Sinais: `branch_criada(nome, commit_id)`, `branch_ativa_mudou(anterior, nova)`,
`merge_realizado(origem, destino, commit_id, fast_forward)`, `log_consultado(branch)`.
Falhas: `FALHA_NOME_INVALIDO`, `FALHA_BRANCH_JA_EXISTE`, `FALHA_BRANCH_INEXISTENTE`, `FALHA_SEM_COMMITS`,
`FALHA_MESMA_BRANCH`, `FALHA_STAGING_PENDENTE`, `FALHA_JA_NA_BRANCH` (esta não conta como falha
para a tutora).

### Merge

`git merge <origem>` integra `<origem>` na branch **ativa** (o destino):

| Situação | Resultado |
|---|---|
| `origem` já está no histórico do destino | "Already up to date", nada muda |
| o destino é ancestral da origem | fast-forward: o head do destino anda, sem commit novo |
| os históricos divergiram | **novo commit de merge** com `pais = [head do destino, head da origem]`; o head do destino avança para ele; o head da origem não muda |

Exige repositório, origem existente e diferente da ativa e staging vazia. **Sem conflitos**: o modelo só
acrescenta arquivos, então a integração é sempre limpa. Commits e ancestralidade existentes nunca são
reescritos.

### Arquivos entre branches

`inventario_player` é o que o jogador carrega no mundo (não depende da branch). O que aparece na pasta
é derivado: um arquivo commitado **só** em outra branch não existe na pasta da branch ativa (não vira
"não rastreado", não pode ir para a staging, `esta_versionado` é falso). Soltos e staging acompanham o
jogador, como no Git. `trocar_branch` e `mesclar` ressincronizam a pasta. Com uma única branch (Fase 1)
nada muda.

## Camadas da Fase 2 (lógica Git separada da lógica visual)

```
GameState (Git) ──sinais──▶ ProgressoFase2 (adaptador) ──▶ BarreiraFase2, ZonaInteracao, Registro
                                      ├──────────────────▶ RealidadesFase2 (reação do mapa)
                                      └──────────────────▶ LiberadorComandosFase2 ──▶ GameState.comandos_liberados
GameState ──sinais──▶ AtlasUI / AtlasGrafo (leitura apenas)
```

Só o `ProgressoFase2` fala com o GameState para flags e mundo. `RealidadesFase2` e o Atlas nunca
alteram o repositório.

## Árvore da cena

```
Fase2 (fase_2.gd, y_sort)
├── Fundo, Progresso, Realidades, Liberador
├── Mundo (y_sort): Area1_Arquivo … Area5_Registro, Player
├── Limites/SupEsq, InfDir
├── Transicao, MensagemHud, DebugFase2
└── PlayerHealthUI, PauseMenu, DefeatScreen, VictoryScreen, TerminalUI, AtlasUI
```

`TerminalUI` e `AtlasUI` ficam por último para receber Esc antes do menu de pausa.
Cada área: `Piso`, `Paredes`, `Decor`, `Objetos` (y_sort), `Interacoes`, `Conexoes`, `Iluminacao`.

## Atlas das Ramificações (`res://atlas/`)

Artefato físico na Área 1 (`Atlas_Artefato`, tecla de interação). Mostra o repositório REAL:
commit = nó, histórico = fios, branch = linha de realidade (violeta main, verde vida-alternativa),
HEAD = marcador sobre a branch ativa. Merge = nó com dois fios.

| Arquivo | Papel |
|---|---|
| `atlas_layout.gd` | calcula colunas/faixas/ligações/tags a partir do GameState (sem desenho) |
| `atlas_grafo.gd` | desenha (`_draw`), seleção por setas/clique, pulso nos nós novos |
| `atlas_ui.gd/.tscn` | moldura, detalhes do nó, dica contextual, pausa/Esc; reage aos sinais |
| `atlas_estilo.gd` | cores/medidas e **texturas opcionais** para a arte futura |

Faixa de cada commit: cadeia do primeiro pai a partir do head de cada branch (main primeiro). Por isso
os commits da vida continuam na faixa verde depois do merge. Branch recém-criada = etiqueta "fantasma"
tracejada na sua faixa, enquanto o HEAD segue em main.

## Terminal reutilizável

`ConfiguracaoTerminal` (Resource): título, boas-vindas, prompt, comandos, mensagem de comando bloqueado.
O `TerminalUI` tem `@export var config`; sem ela usa `padrao_fase_1()` (comportamento original, a cena
da Fase 1 não muda). Fase 2: `res://terminal/config/terminal_fase_2.tres`.

Comandos (classes finas sobre o GameState): `init, add, commit, status, help` (Fase 1) +
`log [--oneline]`, `branch [<nome>]`, `switch <branch>`, `merge <branch>`.

Terminais na Fase 2: A1 (log/branch), A3 junto às fissuras (`Terminal_Espinheiro` em main e vida,
`Terminal_Ponte` em vida) e A4 (merge). A área do terminal sobrepõe a da fissura: quem o usa está
"sobre" a fissura e, ao trocar de branch, é levado à fissura-par.

## Progressão (fatos reais do GameState)

```
git log (main) → git branch vida-alternativa → git switch vida-alternativa
→ coletar eco_vida.eco → git add + git commit → git switch main
→ coletar eco_main.eco → git add + git commit → git merge vida-alternativa
→ convergência no mundo e no Atlas → registro final (A5)
```

`LiberadorComandosFase2` libera os comandos conforme as flags (mecanismo `comandos_liberados`):
`status, log` sempre · `branch` após o log · `switch` com a branch criada · `add, commit` em vida (ou
depois do commit da vida) · `merge` em main com as duas linhas divergentes.

## Realidades e branches

- **MAIN** e **VIDA** são áreas independentes, lado a lado. A VIDA só aparece depois de
  `git branch vida-alternativa`. A realidade da branch ativa fica normal; as outras escurecem.
- **Acesso:** as portas de cada realidade (`BarreiraFase2.branch_requerida`) só abrem enquanto a
  branch dela está ativa; as barreiras são reversíveis e nunca prendem o jogador.
- **Troca de branch** (`git switch`): se o jogador estava dentro de uma realidade, é reposicionado na
  de destino: (1) fissura-par, se estava sobre uma fissura; (2) última posição lá; (3) entrada.
  **Com o terminal aberto** (jogo pausado) o reposicionamento espera o terminal fechar
  (`GameState.terminal_fechado`) e usa a branch ativa naquele momento.
- **Fissuras** são âncoras (`id_par`): não teleportam, não executam `git switch` e não têm prompt;
  mostram uma dica uma vez, ao chegar.
- **Estado por realidade** em `branches[nome].mundo`: `posicao`, `visitada`, `eco_coletado`,
  `log_consultado`, `registro_observado`. Sobrevive ao reload por derrota.

## Flags (`ProgressoFase2`)

| Flag | Origem |
|---|---|
| `log_consultado`, `branch_criada`, `na_vida_alternativa`, `commit_vida`, `commit_main`, `convergencia_concluida` | **Derivadas do GameState**; `definir()` as recusa |
| `eco_main`, `eco_vida` | exploração (a coleta também põe o arquivo REAL no inventário); persistidas em `mundo` |
| `registro_observado` | observação narrativa do registro final (só após o merge real); persistida |

`eco_main` só pode ser coletado depois do commit da vida (flag `commit_vida`).

## Registro final (Área 5)

`RegistroFinalFase2` só fica disponível com `convergencia_concluida` (merge real) e mostra dados reais:
o commit de merge e as duas linhas integradas (`ProgressoFase2.dados_convergencia()`). Observá-lo libera
o portal de saída. Texto provisório (os diálogos de Eidolon entram na Parte 4).

## Debug (ferramenta de desenvolvimento — nó `DebugFase2`)

N `git branch vida-alternativa` · B `git switch` para a outra branch (ambos chamam o GameState) ·
HOME painel · PAGE DOWN/UP teleporta · END próxima flag não derivada · INSERT zera flags não derivadas.
Só valem sem Ctrl/Alt/Shift/Meta e com o nó habilitado. Evite teclas de função: o editor do Godot as
reserva (F9 pausava o jogo embutido). N e B não constam no Input Map. Desligar: desmarcar `habilitado`
ou apagar o nó. Ao rodar a fase isolada, e só se não houver nenhum commit, cria um repositório simulado.

## Eidolon (Parte 4 — concluída: Etapas 1 a 5)

Consciência fragmentada de um arquivista Codex que vive no Atlas (entidade distinta da IA da Fase 1;
nenhuma relação é confirmada). Arco em 5 etapas (`EidolonEstado.ETAPA_*`): certeza (Área 1) →
desconforto → dúvida → conflito → reinterpretação parcial. As etapas só avançam.

| Arquivo (`fases/fase_2/eidolon/`) | Papel |
|---|---|
| `roteiro_eidolon_fase_2.gd` | **todo o texto**, num só lugar; cada fala tem canal, prioridade, única?, nota técnica e versão de balão |
| `eidolon_estado.gd` | estado persistido (namespace `eidolon_fase_2` em `GameState.progresso_tutoria`) |
| `eidolon_fase_2.gd` | lógica: gatilhos, canais, agrupamento, cooldown, diálogo pendente |

**Persistência.** `progresso_tutoria["eidolon_fase_2"] = {versao, ditas, etapa, notas_pendentes}`; as chaves
da Fase 1 e do Manual não são tocadas. Sobrevive ao reload por derrota (o GameState não é recriado).
`reset_fase()` substitui o dicionário inteiro, então o namespace some: isso só ocorre ao fim da Fase 1 e
em `resetar_repositorio()` (novo jogo), quando a narrativa deve mesmo recomeçar.

**Canais de fala** (reaproveitam o que existe):
- *diálogo bloqueante* — `CaixaDialogo` num `CanvasLayer` (`DialogoEidolon`). Só 3 momentos na fase; o
  despertar é o primeiro. **Nunca abre com o jogo pausado** (terminal, Atlas, menu, derrota): o
  `CaixaDialogo` despausa tudo ao terminar, então a fala espera (tenta de novo ao fechar a interface).
- *terminal* — reação logo após a saída do comando, prefixo `[EIDOLON]` + nota técnica `Em Git:` à parte.
- *balão* — `MensagemHud.falar_em` (cor própria), quando o terminal está fechado.

**Controle de mensagens.** Falas únicas não se repetem (nem após recarregar); eventos quase simultâneos
são agrupados (só o de maior prioridade fala); o balão tem cooldown (só prioridade alta o ignora);
repetir o mesmo comando gera silêncio. `MensagemHud` descarta mensagem de prioridade menor que a que está
na tela. A nota `Em Git:` que não cabe no balão fica pendente e sai na próxima abertura do terminal.

### Dicas graduais (`dicas_eidolon.gd` + `roteiro_dicas_eidolon.gd`)

Componente independente da narrativa: decide **o que** dizer; quem fala (canais, agrupamento, prioridade,
cooldown) é o `EidolonFase2`, que recebe a dica por `entregar()` (prioridade 1, abaixo da narrativa).
Estado em `progresso_tutoria["eidolon_fase_2"]["dicas"]` (por etapa: nível dado, falhas por categoria,
dicas ditas, automáticas, última falha).

- **Níveis** (um por gatilho; nunca os três de uma vez): 1 orientação · 2 conceito (+ nota `Em Git:`) ·
  3 prática (diz o comando; não executa). Cada gatilho entrega nível maior que o já dado na etapa: nada
  repete. Depois do 3, um pedido explícito recebe uma frase final (uma vez) e depois silêncio.
- **Etapa** derivada de fatos reais (flags do `ProgressoFase2`, inventário, staging): consultar_log →
  criar_branch → entrar_vida → coletar_eco_vida → registrar_vida_add/commit → voltar_main →
  coletar_eco_main → registrar_main_add/commit → integrar → observar_registro. Dicas de etapas vencidas
  não voltam.
- **Gatilhos:** `git help` (`ajuda_pedida`; sobe um nível por pedido, ou continua a explicação da última
  falha) e `comando_falhou`, classificado em: *sintaxe* (o terminal já mostra o erro: só fala se repetir,
  ou se puder acrescentar algo, como a grafia da branch), *ordem* (orienta o que falta; escala 1→2→3) e
  *compreensão* (explica o conceito daquela falha; depois a prática). Nome de branch parecido com uma
  existente é grafia (sintaxe); sem relação é compreensão. `git merge` sem os requisitos diz o que falta.
  Não há detecção de estagnação por tempo.
- **Adaptação** (não é contagem de erros): duas etapas seguidas sem ajuda nem falhas de ordem/compreensão
  reduzem o apoio (dicas começam no nível mais baixo); se a última exigiu o nível 3 ou 2+ falhas
  conceituais, o apoio aumenta. Falhas de sintaxe não contam como falta de compreensão.
- **Controle:** no máximo 2 dicas automáticas por etapa, com 15 s entre elas; `git help` com 3 s de
  intervalo; só no terminal (nunca balão); uma dica descartada pelo `EidolonFase2` (agrupamento,
  prioridade) não é registrada e continua elegível (pedidos explícitos são retentados).
- `TerminalUI.ultimo_comando()` expõe o último comando digitado (o sinal de falha só traz comando e motivo).

### Realidades: desconforto e dúvida (Etapa 3)

Eidolon continua chamando divergência de desvio; ele só **encontra evidências que não consegue explicar**.
O arco avança por evidências (`EidolonEstado.registrar_evidencia`, namespace `evidencias`): com 2 ou mais,
passa de Desconforto a Dúvida. Nenhuma fala conclui que integrar é a solução (isso é a Área 4).

- **Área 2** (`area_2_ramificacao.gd`): a trilha verde só existe depois que a branch existe (fade ao surgir) e a
  trilha da branch ativa fica em destaque (HEAD no cenário). Criar a branch NÃO muda o destaque; só `git switch`.
  Ao chegar na área com a branch criada, Eidolon estranha (`a2_desconforto_*`; prioridade 3).
- **Área 3:** a geometria exige alternar (verificado por alcançabilidade): em `main` a ponte desligada isola o
  sul; na vida o espinheiro isola o `eco_vida`; o `eco_main` só se alcança depois de trocar na ponte.
- **Reações aos comandos** (só depois do sucesso, via sinais do GameState; falas únicas, com dados reais):
  `git switch` (1ª troca; 1ª troca dentro da Área 3 = evidência "complementares"; volta a main depois de um
  commit na vida = o arquivo da outra linha não existe aqui), `git add` ("separado não é registrado") e o 1º
  `git commit` na vida (mensagem, id e arquivos do commit REAL).
- **Fragmentos de memória** (`fragmento_memoria.gd`, 3 em main e 3 na vida): opcionais, texto curto, releíveis.
  A 1ª leitura é persistida em `branches[x].mundo["fragmentos"]` (nascem apagados após reload), vira evidência e
  pode gerar uma reação curta (balão com cooldown: se Eidolon falou há pouco, fica em silêncio). Os ecos
  principais (`eco_main`, `eco_vida`) também geram reação (prioridade 3).
- **Reflexão pelo Atlas:** `AtlasUI.no_inspecionado(no)` (só quando o JOGADOR escolhe um nó; abrir o Atlas
  não conta). Inspecionar a memória da vida faz Eidolon comentar, ao fechar o Atlas, de onde ela nasceu (dados
  reais do nó). Não é prova de compreensão e não há nós fictícios.
- **Prioridade das mensagens (HUD):** respostas a uma ação do jogador (interagir) têm prioridade 2 e não são
  engolidas por um balão de fala; dicas de barreira/fissura (0) cedem.

### Convergência (Etapa 4)

O merge e o modelo de commits (dois pais) já existiam; esta etapa é narrativa e visual, sempre consequência de
um merge REAL confirmado pelo GameState (`convergencia_concluida` é derivada).

- **Requisitos reais** (já aplicados, sem alterar o GameState): o `git merge` só é liberado em `main`, com a vida e
  `main` divergentes (`LiberadorComandosFase2`); o GameState recusa origem inexistente, a própria branch e staging
  pendente. Sem conflitos de merge.
- **Área 4** (`area_4_convergencia.gd`): antes, duas metades (violeta/verde) separadas por uma fenda, com os
  elementos de cada realidade esmaecidos nos slots; Eidolon defende a doutrina (balão ao chegar + 1ª abertura do
  terminal). Depois do merge: a fenda some, os elementos das DUAS realidades acendem e surgem os que COEXISTEM
  (pedra+copa, ponte de pedra+raízes, os dois ecos), sempre com as duas cores lado a lado. Placeholders de cor lisa.
  Há um 2º artefato do Atlas na Área 4 (o mesmo `AtlasUI`) para a reflexão sem voltar à Área 1.
- **Eidolon:** conflito (Área 4) → depois do merge: nota curta no terminal e o **ponto de virada** (2º diálogo
  bloqueante, só abre com tudo fechado) → reflexão pelo Atlas → registro final → **fechamento** (3º diálogo): primeira
  reinterpretação parcial e a MESMA lacuna de memória; o gancho é "outros registros" e a porta de vidro, sem explicar
  a Catástrofe.
- **Reflexão pelo Atlas:** só conclui se o jogador inspecionar o nó que o GameState reconhece como o commit de merge
  de `main` com a vida: mesmo id, exatamente os dois pais (o 1º na linha de main, o 2º na da vida). Abrir o Atlas,
  selecionar outros nós ou nós "falsos" não conclui. Eidolon responde ao fechar o Atlas; a nota "Em Git: um commit
  de merge registra a integração de históricos e referencia os dois commits que foram unidos." vem logo depois, como
  mensagem separada. É requisito do registro final (ver Etapa 5).
- **Registro final** (`registro_final.gd`): usa dados reais do merge: id e mensagem do commit, branch de destino,
  os dois pais e quantas memórias próprias cada linha trouxe. Pode ser relido sempre; observá-lo dispara o fechamento.
- **Dicas:** nova etapa `inspecionar_merge` (entre `integrar` e `observar_registro`).
- **HUD:** respostas a uma ação do jogador (interagir) têm prioridade 3 e nunca são engolidas por um balão.

### Calibragem final (Etapa 5)

- **A reflexão é requisito do registro final.** A flag persistida `merge_inspecionado` (mesmo mecanismo de
  `registro_observado`, em `branches[main].mundo`) liga no instante da inspeção VÁLIDA no Atlas, e não quando o
  Eidolon fala. Validação (reaproveitada): mesmo id do commit de merge real do GameState e exatamente os dois pais
  (1º na linha de main, 2º na da vida). Abrir o Atlas, inspecionar outro nó ou um nó fabricado não vale. O registro
  exige `convergencia_concluida` E `merge_inspecionado`.
- **Inspecionar = ENTER, clique ou seleção por setas** (o Atlas abre com o merge já selecionado logo após o merge;
  só olhar não conta). A legenda do Atlas diz isso.
- **Registro antes da reflexão:** o artefato fica esmaecido; ao se aproximar, Eidolon orienta a consultar o Atlas
  (`registro_sem_reflexao`, no máximo a cada 25 s). Sem o merge, a zona avisa que as realidades não convergiram.
- **Fechamento e portal:** o fechamento abre depois do tempo de LEITURA do texto do registro (calculado do texto
  real) e o portal só libera depois dele (`Area5Registro` escuta `EidolonFase2.fechamento_concluido`; recarregar
  com o fechamento já dito libera na hora). Ninguém sai da fase sem ouvi-lo.
- **Recuperação após derrota:** se o merge (ou o registro) aconteceu e o diálogo correspondente ainda não foi dito,
  o `EidolonFase2` o refaz ao carregar a cena (`_recuperar_pendentes`).
- **Textos:** concordância ("1 memória própria", "2 memórias próprias"; "esperam", "não existem" com vários
  arquivos); dica de `inspecionar_merge` indica os dois artefatos do Atlas; dica de `entrar_vida` diz que qualquer
  terminal serve.
- **Terminal:** ESC fecha na primeira vez (`TerminalUI` trata `ui_cancel` em `_input`; antes o campo de texto
  consumia o primeiro ESC). Vale também para a Fase 1 (mesmo componente).
- **Sem alteração:** o cooldown de 12 s do balão (só afeta reações opcionais), os 1 s do ponto de virada (ele já
  espera o terminal fechar) e o fade de 1,4 s (roda depois do diálogo).

**Etapa 1 (feita):** despertar (ao se aproximar do terminal ou do Atlas da Área 1), reação à primeira
`git log` e à criação de branch (`branch_criada` com o nome esperado ou outro). Fragmento da Área 1 trocado
por texto ambíguo. **Etapa 2 (feita):** dicas graduais (acima). **Etapa 3 (feita):** realidades (acima). **Etapa 4 (feita):** convergência (acima). **Etapa 5 (feita):** calibragem final (acima).

Textos provisórios restantes: `ConfiguracaoTerminal`, `AtlasUI` (`_texto_da_dica`), `RegistroFinalFase2`
e as zonas da cena.

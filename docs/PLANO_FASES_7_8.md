# Plano de implementação — Fases 7 e 8

> **Estado: planejado, NÃO implementado.** Este documento transforma a história (`HISTORIA.md`, seções 8 a 10) em um
> **plano de trabalho** para ser feito em outro momento: decisões, etapas na ordem certa, o que mexer em cada arquivo,
> como testar e quando cada etapa está pronta. A história não é repetida aqui; o que importa para implementar está
> resumido em cada etapa.

## Sumário

1. [Objetivo e escopo](#1-objetivo-e-escopo)
2. [Decisões (padrão recomendado)](#2-decisões-padrão-recomendado)
3. [O que já existe e o que falta](#3-o-que-já-existe-e-o-que-falta)
4. [Problema central: a memória entre fases (o "legado")](#4-problema-central-a-memória-entre-fases-o-legado)
5. [Etapas de implementação](#5-etapas-de-implementação)
6. [Fase 7 em detalhe](#6-fase-7-em-detalhe)
7. [Fase 8 em detalhe](#7-fase-8-em-detalhe)
8. [Finais e créditos](#8-finais-e-créditos)
9. [Arte e áudio](#9-arte-e-áudio)
10. [Testes](#10-testes)
11. [Riscos](#11-riscos)
12. [Checklist de pronto](#12-checklist-de-pronto)

---

## 1. Objetivo e escopo

Fechar a história do jogo com duas fases novas:

| Fase | Nome | Papel | Comandos novos |
|---|---|---|---|
| **7** | O Arquivo Vazio | A **revelação**: o jogador recupera o que foi apagado (Walkers anteriores, o último commit de Elian, o nome do Índice). | `reflog`, `cherry-pick` |
| **8** | O Apagador | O **clímax**: chefe em dois planos (mapa 2D + terminal) e a **escolha final** (merge x rebase). | `rebase` (se entrar) |

Fora do escopo desta etapa: áudio (adiado em todo o jogo), fases extras além da 8, remoto (`push`/`pull`).

Regras que valem aqui como em todo o projeto (ver `PLANO_DAS_FASES.md` §2 e `DESIGN_FASES.md`): Git local; mudanças no
`GameState` **aditivas**; HUD igual à das outras fases; **identidade visual própria** em cada fase; arte em PNG gerada por
`tools/gerar_arte_fase_N.gd`; reinício do zero ao morrer; história em notas (`Nota` + `NotasHistoria`); cada fase com teste.

---

## 2. Decisões (padrão recomendado)

Ainda **não foram aprovadas**. Se o dono do projeto não disser o contrário, o padrão abaixo é o que se implementa.

| # | Decisão | Padrão recomendado | Alternativa |
|---|---|---|---|
| D1 | Nomes **Elian Vorn** (Eidolon) e **Índice** (IA) | Manter | Trocar (só texto) |
| D2 | **Fase 8 separada** da 7 | Sim | Tudo numa fase (fica grande demais) |
| D3 | **`rebase` entra** no jogo | Sim (senão o Final B some) | Sem rebase: a escolha vira "preservar tudo x deixar partes para trás" |
| D4 | **Chefe** | Mistura: esquiva no mapa + comandos no terminal | Só terminal (mais simples, menos clímax) |
| D5 | **Walkers anteriores** | 6 (`W-1` a `W-6`); o jogador é o `W-7` | Outro número |
| D6 | **Tom do Final B** | Melancólico (como no roteiro) | Mais neutro |
| D7 | **Onde está a Chave de Arquivista** | **Fase 6**: o eco do Eidolon a deixa cair depois de "Esse hash... eu o conheço" | Perto do portal da Fase 1 (obriga a pegar um item cedo) |
| D8 | **Tempo na luta** com o terminal aberto | O jogo **pausa** (como em todo o jogo): o terminal é "tempo congelado do Git"; o Apagador espera | Tempo real (exige reescrever o terminal) |
| D9 | **Fases além da 8** | Não; o epílogo deixa a porta aberta | Continuar a série |

Cada decisão alterada muda só as etapas indicadas em §5 (ver "Depende de").

---

## 3. O que já existe e o que falta

**Já existe e pode ser usado:**

- `GameState`: `reflog` (+ `formatar_reflog`), `resetar_para`, `reverter`, `escolher_commit` (cherry-pick), stash, `mesclar`,
  `resolver_referencia`, conteúdo por arquivo. Commits descartados por `reset` continuam no *object store*.
- O commit **fantasma da Fase 6**: marcado `misterio`, autor `RS4=` (base64 de "E."), aparece no `git log` como órfão.
- O Eidolon como **segunda voz** em qualquer fase (`TutoraFase1._conversar` / `PREFIXO_EIDOLON`) e o diálogo bloqueante
  (`CaixaDialogo`) que espera o terminal fechar (padrão das Fases 5 e 6).
- `GameState.escolhas_historia` (persiste entre fases) com a escolha do conflito da Fase 5.
- Notas e Diário, HUD recolhível, reinício do zero, `AtlasUI` (grafo do repositório), `ExitArea`/`PortalSaida`.

**Falta (e é o trabalho deste plano):**

| Item | Onde |
|---|---|
| Comandos de terminal `reflog` e `cherry-pick` | `terminal/Commands/` + interpretador + ajuda + manual |
| `rebase` (API + comando) | `GameState` + `terminal/Commands/` |
| **Legado**: lembrar as branches/commits que o jogador criou nas fases 2, 4 e 5 | `GameState` + cada fase (ver §4) |
| Chave de Arquivista (item/estado persistente) | Fase 6 + Fase 7 |
| As cenas e a lógica das Fases 7 e 8 | `fases/fase_7/`, `fases/fase_8/` |
| Suporte a fase que **termina sem tela de vitória** (7 → 8) e a **tela de finais** (8) | `FaseManager`, `VictoryScreen` |
| Chefe, ataques, Walkers aliados, escolha final, créditos | Fase 8 |
| Textos: Walkers, atas, cartas, diálogos de revelação, falas do Apagador, finais | `NotasHistoria`, roteiros |

---

## 4. Problema central: a memória entre fases (o "legado")

A Fase 7 depende de o jogador **ver as branches que ele mesmo criou** (`ponte`, `vida-alternativa`, `ajuste`) como peças da
reconstrução, e a Fase 8 usa o mesmo grafo no final e nos créditos. Hoje isso **não é possível**:

- Cada fase monta o seu repositório e **zera o anterior**: a Fase 1 faz `resetar_repositorio()` ao começar e a Fase 6 faz
  o mesmo em `EstadoRetorno.construir()`. Ao chegar na Fase 7, as branches das fases 2, 4 e 5 **já não existem**.
- `escolhas_historia` guarda só um texto por chave, não um histórico.

**Solução proposta: `GameState.legado`** (persistente, como `escolhas_historia`; entra no checkpoint e é limpo em jogo novo):

```gdscript
# Cada entrada é um "marco" do jogador, registrado quando a fase é concluída:
# { "fase": 2, "branch": "ponte", "commits": [{"mensagem": "conserta a ponte", "arquivos": ["ponte.tile"]}], "merged": true }
var legado: Array[Dictionary] = []
func registrar_legado(entrada: Dictionary) -> void
func legado_da_fase(n: int) -> Array[Dictionary]
```

- **Quem registra:** cada fase, ao ser concluída (no mesmo ponto que hoje chama `FaseManager.concluir_fase_e_avancar()`):
  Fase 2 (`ponte`), Fase 4 (`vida-alternativa` e os ecos), Fase 5 (`ajuste` + a escolha mine/theirs/both), Fase 3 e 6 (o que
  o jogador restaurou/reverteu, se fizer sentido para a história).
- **Quem usa:** a Fase 7 **reconstrói** essas branches num repositório novo (sem depender de o `GameState` as ter mantido) e o
  Atlas final/créditos desenham o grafo a partir dele.
- **Teste:** `legado` sobrevive a `reset_fase()`, volta ao reiniciar a fase e some em jogo novo (como `escolhas_historia`).

> Alternativa mais barata: **parar de zerar o repositório** nas Fases 1 e 6 e deixar o histórico crescer. Foi descartada porque
> cada fase foi feita para começar de um estado conhecido (os testes dependem disso) e misturar tudo quebraria as armadilhas.

---

## 5. Etapas de implementação

Ordem recomendada. Cada etapa termina com os testes dela passando **e** os testes antigos intactos.

| Etapa | Entrega | Depende de |
|---|---|---|
| **E0** | Fechar as decisões D1 a D9 (§2) e escrever os textos curtos que travam o resto (lista em §6/§7) | — |
| **E1** | Comandos `reflog` e `cherry-pick` no terminal (+ `rebase` se D3) | — |
| **E2** | `GameState.legado` e os registros nas Fases 2, 4 e 5 (§4); Chave de Arquivista na Fase 6 (D7) | E0 |
| **E3** | Fase 7 (mecânica): cena, vultos do reflog, Linha de Reconstrução, commit fantasma | E1, E2 |
| **E4** | Fase 7 (história): Walkers, revelação do Eidolon e do Índice, notas, o Apagador acordando | E3 |
| **E5** | Fase 7 (arte): paleta própria, arte em PNG, animação das prateleiras perdendo cor | E3 |
| **E6** | Fase 8 (mecânica): arena, Apagador, os 5 ataques e respostas, Walkers aliados, golpe final | E1, E2, E3 |
| **E7** | Fase 8 (finais): escolha merge x rebase, Final A e Final B, créditos (grafo) | E6 |
| **E8** | Fase 8 (história e arte) | E6, E7 |
| **E9** | Integração: `FaseManager`, fluxo 6 → 7 → 8, sem tela de vitória na 7, `fluxo_fases_test`, documentação | tudo |
| **E10** | Polimento e **áudio** (adiado para o fim de tudo) | tudo |

### E1 — Comandos de terminal

- Criar `git_command_reflog.gd` e `git_command_cherry_pick.gd` seguindo `git_command.gd` e os comandos da Fase 6
  (`git_command_reset.gd`, `git_command_revert.gd` são bons modelos). A lógica já está no `GameState`.
- Registrar em `terminal_command_interpreter.gd`; entradas em `git_command_help.gd` e `manual_comandos.gd`; criar
  `terminal/config/terminal_fase_7.tres` (e `_8`).
- `cherry-pick`: já recusa commit de merge e staging pendente; mensagens de erro em português claro.
- **`rebase` (se D3):** definir o escopo mínimo e documentar — `git rebase <base>` que **reescreve** a linha ativa numa linha
  reta, gerando **hashes novos** e deixando os antigos no *reflog* (para o Final B e para o "Elian não se reconhece").
  Não precisa de modo interativo nem de resolução de conflito.
- **Testes:** `test/comandos_fase_7_test` (cada comando com sucesso e com os erros típicos, igual a `fase_6_fluxo_test`).

### E2 — Legado e Chave de Arquivista

- Implementar `legado` no `GameState` (§4), incluindo checkpoint e limpeza em `resetar_repositorio()`.
- Chamar `registrar_legado(...)` ao concluir as Fases 2, 4 e 5 (e, se útil, 3 e 6).
- **Chave de Arquivista:** chave em `escolhas_historia` (`"chave_arquivista" = "sim"`) dada na Fase 6 depois da fala do Eidolon
  (D7). Um item visual no inventário não é necessário: a porta de vidro lê o estado.
- **Testes:** `legado` persiste/volta/limpa; a Fase 6 entrega a chave uma vez só.

---

## 6. Fase 7 em detalhe

**Cena:** `fases/fase_7/fase_7.tscn` + `fase_7.gd` (padrão das Fases 5 e 6: um `Modelo*`/`Estado*` com os fatos, uma tutora
`extends TutoraFase1`, painel **não** (HUD igual às outras), notas, `DialogoHistoria` para os diálogos bloqueantes).

**Três áreas (uma flag cada):**

1. **O Reflog (achar).** `git reflog` lê o `GameState` e a cena **enche de vultos** (um `VultoReflog` por entrada). Entre eles,
   `W-1` a `W-6`, cada um com a sua última frase na mensagem do commit (lista de 6 frases a escrever; a de `W-3` já está
   escrita: *"Fiz tudo numa linha só. Ninguém me avisou que dava para ramificar."*). Flag: `reflog_lido` + ler os 6.
2. **A Reconstrução (`cherry-pick`).** Um commit-chave em cada branch do **legado** (`ponte`, `vida-alternativa`, `ajuste`).
   O jogador faz `cherry-pick` de cada um para a **Linha de Reconstrução** (`reconstrucao`). Verificação: a branch
   `reconstrucao` contém os commits certos, na ordem certa. Armadilhas: `cherry-pick` na branch errada, commit de merge
   (recusado), staging pendente. Rede de segurança: um altar (como o Altar de Retorno da Fase 6) que desfaz o erro.
3. **O Commit Fantasma (a revelação).** O hash do órfão da Fase 6 (`c0x…`, autor `RS4=`) está no `reflog`. `cherry-pick` dele
   **decifra** a mensagem (o texto de Elian, já escrito em `HISTORIA.md`). Dispara, nesta ordem: o diálogo longo do **Eidolon
   (Elian)** recuperando as memórias; o registro de aprovação em que a **IA lê o próprio nome (Índice)**; a frase do Eidolon
   *"Eu também propus. Nenhum de nós conferiu."*; o Apagador acordando (as prateleiras perdem a cor em ondas, o chão se alisa) e
   *"Isto é inconsistência."* Sem tela de vitória: o portal leva direto à Fase 8.

**Entrada:** o Eidolon (eco) aparece sozinho, fala do hash e a **porta de vidro** (a mesma da Fase 4) só abre se a Chave de
Arquivista estiver no estado. A IA tenta convencer o jogador a não entrar (primeira vez que ela pede para **não** fazer algo).

**Estado/fatos:** `EstadoArquivo` (como `EstadoRetorno`): consultas lidas do `GameState`, flags em `progresso_tutoria`, montagem
do repositório da fase **a partir do legado** (§4).

**Notas sugeridas (a escrever):** placa da porta de vidro, ata do Conselho sobre "Projeto Linha Única", carta de `E.`,
folha do Índice (o "aprove tudo"), uma por Walker anterior (opcionais, no Diário).

**Textos a escrever antes (E0):** as 6 frases dos Walkers; a mensagem completa do commit de Elian (já existe); o diálogo do
Eidolon; o registro da Central e o diálogo do Índice; as falas da IA ao entrar.

**Pistas que pagam aqui** (ver `HISTORIA.md` §10): autor `E.`, W-3 e a lei, a IA "sabendo sem saber como", a paralisia diante de
"conflito", a reação ao `reset --hard`, o commit fantasma, a porta de vidro, a "integração experimental nº 2", as branches do
jogador e a cor verde-água (que reaparece no Final A).

---

## 7. Fase 8 em detalhe

**Cena:** `fases/fase_8/fase_8.tscn`: a **Linha de Reconstrução** (plataforma estreita sobre o vazio) como arena 2D, mais o
terminal (Obelisco/console fixo).

**O chefe (`ChefeApagador`)**, máquina de estados com 5 ataques. Cada ataque cria uma **situação no mundo** (um `Modelo`
de batalha lê o `GameState` como as fases anteriores) e espera **a resposta certa no terminal**:

| Ataque | Situação criada | Resposta | Fase que lembra |
|---|---|---|---|
| Apaga uma plataforma | `reset --hard` simulado: a plataforma some | `reflog` + `reset --hard <hash>` (ou `revert`) | 6 / 7 |
| Corrompe o chão em ruído | arquivos "sujos" na Oficina | `restore` / `restore --staged` | 3 |
| Alisa um caminho (poda) | uma rota única | `switch -c` criando outra rota | 2 / 4 |
| Lança uma "inconsistência" | conflito de merge | `diff`, resolver olhando os dois lados, `add`, `commit` | 5 |
| Congela o estado | o chão começa a sumir | `commit` (trava um estado seguro) | 1 |

- **Dois planos:** no mapa o jogador esquiva (ataques de área telegrafados, dano pelo `HitBox`/`HurtBox` que já existem) e
  corre até o ponto onde vai "responder"; no terminal responde. Com o terminal aberto o jogo pausa (D8).
- **Progresso:** cada resposta certa faz o Apagador "perder forma" (a arte do chefe tem 5 níveis de textura) e dá uma pausa na
  luta. Resposta errada: a IA avisa (agora **ela confere**: *"Espera. Antes de aceitar isso, olha."*), custa vida ou tempo,
  nunca trava.
- **Aliados:** cada `W-n` aparece **uma única vez** para segurar algo (a plataforma de `W-3`, o escudo de `W-5`...).
- **Vozes:** o Eidolon cita as atas para antecipar os ataques (dicas graduais, como `dicas_eidolon.gd` na Fase 4); a IA confere.
- **Golpe final:** `git merge` das branches do **legado** na Linha de Reconstrução. O Apagador só olha a `main`. O merge sai
  limpo porque os conflitos foram resolvidos nas fases certas (a escolha da Fase 5 colore uma fala). O Apagador se desfaz:
  *"Era isso... o que faltava registrar."*
- **Derrota:** reinício do zero **da fase** (padrão do jogo). Considerar *checkpoints entre ataques* (ver Riscos).

**A escolha final** (D3): o Eidolon e a IA apresentam **merge** (a história inteira) ou **rebase** (a história limpa). O jogo
mostra o preço de cada um. A escolha é guardada em `escolhas_historia` (`"final" = "merge" | "rebase"`).

**Estado/fatos:** `EstadoApagador` + `ModeloBatalha` (o que está acontecendo no mundo) + `RoteiroApagador` (todas as falas).

---

## 8. Finais e créditos

| | **Final A: a História Inteira (merge)** | **Final B: a História Limpa (rebase)** |
|---|---|---|
| Mundo | O Atlas abre sobre o céu com o **grafo completo** (todas as branches unidas) | O mundo se organiza: reto, silencioso, uma só linha dourada |
| Elian | Volta por inteiro, assina **"E. Vorn"**: *"Catalogar ambos. Era só isso que eu queria dizer."* | Reescrito junto, não se reconhece: *"Tudo parece certo. Menos eu."* Fica calado |
| Índice | Faz o primeiro commit próprio: *"Assumo."* | Confere tudo sem poder discordar: *"Está tudo certo, não está?"* |
| Walkers | Aparecem como **nós ligados** ao jogador | **Não aparecem** (a linha reescrita não os tem) |
| Créditos | O **grafo do jogador** em câmera lenta (cada commit, branch, merge e conflito resolvido) | **Uma linha reta**, perfeita e curta |
| Epílogo | Outras portas de vidro; o Índice: *"Dá pra ir por aqui?"*; tela escurece em `git switch -` | Última frase do Índice: *"É isto que eles queriam, Walker?"* |

**Implementação:** os créditos desenham o grafo a partir do `legado` e dos commits feitos no jogo (reusar o `AtlasLayout`/`AtlasUI`
em modo de apresentação). No Final A, a cor do grafo é o **verde-água** da Fase 5. A escolha do conflito (mine/theirs/both) muda
**uma fala** do Eidolon e da IA, nunca o final.

---

## 9. Arte e áudio

Cada fase tem identidade própria (`DESIGN_FASES.md`). Já usadas: **1** azul-marinho/ciano/violeta · **2** cânion de brasa
(vermelho-terra) · **3** pedra clara e ouro · **4** violeta (main) x verde (vida) · **5** grafite neutro · **6** concreto
com amarelo-preto.

**Sugestões para propor ao dono do projeto (a decidir, como nas outras fases):**

- **Fase 7 (Arquivo Vazio):** a ideia da história é "cinzento e reto" que **perde cor em ondas**. Opção recomendada:
  **monocromático de papel e cinza quente** (tons de papel velho `#D9D3C7`…`#6F6A60`) onde só os **vultos** têm cor
  (translúcidos, em ciano), e o fim da fase tira **toda** a cor. Evitar azul-marinho, vermelho-terra, dourado, verde, grafite e concreto.
- **Fase 8 (O Apagador):** o **vazio** em preto-azulado muito escuro com a **Linha de Reconstrução** brilhando. As cores do jogo
  (dourado, azul, verde-água, magenta, brasa, concreto) voltam **uma a uma** a cada ataque vencido, como "o jogo inteiro visto de
  cima". O Apagador é **sem rosto**, liso e branco-gelo.

**Cores de significado já reservadas:** ciano = Eidolon/revert · magenta = ruído e commit fantasma · verde-água = Walker/"ambas" ·
dourado = a sua linha · azul = a outra equipe.

**Ferramentas:** `tools/gerar_arte_fase_7.gd` e `_8.gd` no mesmo padrão das outras (PNG pixel a pixel; recolorir obelisco, plataforma
e portal). **Áudio:** fica para depois de tudo (decisão do dono do projeto), junto com o das Fases 1 a 6.

---

## 10. Testes

Padrão do projeto: cena em `test/`, sai com código 1 se falhar, resultado também em `%TEMP%`.

| Teste | Cobre |
|---|---|
| `comandos_fase_7_test` | `reflog`, `cherry-pick` (e `rebase`): sucesso e erros típicos |
| `legado_test` | persiste entre fases, volta ao reiniciar, limpa em jogo novo |
| `fase_7_fluxo_test` | a fase inteira pelo terminal: reflog, reconstrução (com erros), fantasma decifrado |
| `fase_7_historia_test` | a Chave abre a porta, revelações (diálogos que esperam o terminal), notas, HUD |
| `fase_8_batalha_test` | cada ataque + resposta certa e errada; o golpe final; derrota/reinício |
| `fase_8_finais_test` | Final A e Final B (as falas, os Walkers, o grafo dos créditos) |
| `fluxo_fases_test` (atualizar) | 6 → 7 → 8 e o fim (hoje assume a Fase 6 como última) |

Regra: **os testes das Fases 1 a 6 continuam passando em todas as etapas** (`fluxo_fases_test`, `fase_*_test`, `nota_diario_test`,
`hud_abas_test`).

---

## 11. Riscos

| Risco | Mitigação |
|---|---|
| **Legado** (§4) mexe em várias fases | Aditivo; começar por E2 com teste; não alterar o que as fases já fazem, só registrar |
| **Luta em dois planos** com o terminal pausando o jogo pode parecer lenta | Telegrafar os ataques e dar uma janela clara de resposta; protótipo curto (1 ataque) antes de fazer os 5 |
| **Derrota no chefe** zera tudo (padrão do jogo) e pode frustrar | Avaliar *checkpoint por ataque* só na Fase 8 (exceção consciente, documentada) |
| **`rebase`** é novo e sutil | Escopo mínimo (linear, sem interativo); testes dos hashes novos e do reflog |
| Fase 7 depende de o jogador **ter feito** as branches | O legado registra o que o jogador fez; se faltar algo (fase aberta direto por F6), a cena monta um legado padrão |
| Muito texto novo | Escrever tudo em roteiros únicos (`roteiro_*.gd`) e notas no catálogo; revisar tom em bloco |
| Escopo | Cada etapa (E0..E10) é entregável sozinha; dá para parar após a E5 (Fase 7 completa) |

---

## 12. Checklist de pronto

**Por fase (7 e 8):**

- [ ] Mecânica completa e jogável; armadilhas com rede de segurança; reinício do zero funcionando
- [ ] História no roteiro; notas no catálogo; diálogos obrigatórios que esperam o terminal
- [ ] Arte em PNG (gerador em `tools/`), identidade própria, HUD igual às outras
- [ ] Teste(s) da fase passando, mais todos os anteriores
- [ ] Docs atualizados (`PLANO_DAS_FASES.md`, `DESIGN_FASES.md`, `GUIA_DESENVOLVEDOR.md`, este arquivo)
- [ ] `FaseManager.FASES` e `RESUMOS` atualizados; `fluxo_fases_test` atualizado

**Do jogo todo:**

- [ ] Final A e Final B jogáveis até os créditos
- [ ] Prints do README regerados (`tools/capturar_prints.tscn`) com as Fases 7 e 8
- [ ] Áudio (etapa própria, por último)

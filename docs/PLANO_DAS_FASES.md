# Plano das fases — BranchSkipper

> Documento central do roteiro. Explica, fase a fase, o **objetivo**, os **comandos**, a **história** (a que existe
> e a que pode existir), como cada fase **funciona** e as **ideias** para o futuro. É o lugar para registrar decisões.
> Detalhes técnicos finos de uma fase ficam em documentos próprios (hoje: `FASE_4_ESTRUTURA.md`; o terminal e o
> inventário estão no `GUIA_DESENVOLVEDOR.md`).

## Sumário

1. [Visão geral](#1-visão-geral)
2. [Regras do projeto](#2-regras-do-projeto)
3. [Sequência e fluxo entre fases](#3-sequência-e-fluxo-entre-fases)
4. [Os comandos do jogo](#4-os-comandos-do-jogo)
5. [As fases em detalhe](#5-as-fases-em-detalhe) (1 a 6)
6. [Arco narrativo e fases futuras](#6-arco-narrativo-e-fases-futuras)
7. [O repositório (`GameState`): o que existe e o que falta](#7-o-repositório-gamestate-o-que-existe-e-o-que-falta)
8. [Backlog de ideias](#8-backlog-de-ideias)
9. [Decisões em aberto](#9-decisões-em-aberto)
10. [Testes e como criar uma fase nova](#10-testes-e-como-criar-uma-fase-nova)

---

## 1. Visão geral

BranchSkipper é um jogo 2D de exploração que **ensina Git por dentro do mundo**: cada conceito vira algo que o jogador vê
e mexe (uma ponte, um mural, uma câmara). O jogador, chamado **Walker**, é guiado por uma **IA assistente** (a tutora)
que fala pelo terminal e por balões, e usa um **terminal Git de verdade** (comandos reais, respostas no estilo do Git).

Princípios de design:

- **O mundo reflete o repositório.** Pontes, portas e objetos reagem ao estado real do Git, nunca a um "roteiro" paralelo.
- **Um conceito por vez.** Os comandos são liberados aos poucos pela tutora; comando fora de hora é recusado com uma dica.
- **Errar é parte do aprendizado.** Há armadilhas (descartar o que era bom, `reset --hard`) e redes de segurança
  (altares que desfazem o erro) para ninguém ficar preso.
- **Metáforas consistentes:** a pasta é uma **sala/Oficina**, a staging area é a **caixa/Palco**, o commit é uma **foto**
  (save point), a branch é uma **realidade/cópia segura**.

Tipos de fase (pedido do orientador):

| Tipo | O que é |
|---|---|
| **Tutorial (T)** | Simples, apresenta comandos de forma clara, mas sem ser "besta": tem uma armadilha ou uma decisão. |
| **Elevada (E)** | Um problema maior, que cobra o uso combinado do que já foi aprendido. |

---

## 2. Regras do projeto

- **Git local apenas.** Ficam fora do escopo `push`, `pull`, `fetch`, `clone` e `remote` (exigiriam um modelo de remoto novo).
- **Não quebrar o que já funciona.** Mudanças no `GameState` são **aditivas** (nada que existia muda de comportamento) e
  cada fase tem teste (seção 10).
- **Cada comando novo nasce numa fase tutorial** e só depois é cobrado numa elevada. (Exceção consciente: a Fase 6 é
  tutorial e apresenta três comandos, um por área.)
- **Visual primeiro simples, depois bonito.** As fases novas usam arte provisória desenhada por código para validar a
  mecânica; a arte final vem depois.
- **A história é consequência do repositório:** falas e eventos nascem de fatos reais do Git (um merge de verdade, um
  `reset` de verdade), não de contadores soltos.

---

## 3. Sequência e fluxo entre fases

Ordem em `FaseManager.FASES` (índice 0 a 5):

| # | Pasta | Nome | Tipo | Comandos que a fase introduz |
|---|---|---|---|---|
| 1 | `fases/fase_1/` | (Fase 1) | T | `init`, `add`, `commit`, `status` |
| 2 | `fases/fase_2/` | A Ponte Quebrada | T | `log`, `branch`, `switch`, `merge` |
| 3 | `fases/fase_3/` | O Mural Corrompido | T | `diff`, `restore`, `restore --staged` |
| 4 | `fases/fase_4/` | Ecos de Possibilidades | **E** | (reaplica 1 e 2 num problema maior) |
| 5 | `fases/fase_5/` | Linhas Cruzadas | T | merge com conflito, `merge --abort` |
| 6 | `fases/fase_6/` | Ponto de Retorno | T | `revert`, `stash`, `reset` |

**Saída e entrada.** Cada portal leva à fase seguinte pelo **mesmo caminho**: o botão "próxima fase" da tela de vitória
chama `FaseManager.concluir_fase_e_avancar()`, que limpa o estado temporário (`GameState.reset_fase()`, o repositório é
preservado) e abre a fase seguinte. A **última** fase só mostra "FIM DE JOGO" e uma mensagem, sem botão nem resumo.
Abrir uma fase direto (F6) funciona: a tela de vitória alinha o índice com a cena atual. Para criar fases novas, basta
acrescentá-las ao fim de `FASES` (ver seção 10).

---

## 4. Os comandos do jogo

| Comando | Fase | Onde vive a lógica |
|---|---|---|
| `init`, `add`, `commit`, `status`, `help` | 1 | `GameState` (repositório real) |
| `log`, `branch`, `switch`, `merge` | 2 | `GameState` |
| `diff`, `restore` (`--staged`) | 3 | **Modelo local** `ModeloMural` (runas: base / índice / atual) |
| `merge` com conflito, `merge --abort` | 5 | **Modelo local** `ModeloConflito` |
| `revert`, `reset` (`--soft/--mixed/--hard`), `stash` (`pop`, `list`) | 6 | `GameState` (repositório real) |
| `reflog`, `cherry-pick` | futuro (Fase 7) | Já existem no `GameState`; falta o comando de terminal |
| `rebase` | futuro, opcional | Não existe (conflita com "commits nunca são reescritos") |

Como funciona o encaixe dos modelos locais: os comandos `status`, `add`, `diff`, `merge` e `commit` **desviam** para o
modelo da fase **somente quando a cena o tem** (`ModeloMural.ativo()` / `ModeloConflito.ativo()`). Nas outras fases seguem
o `GameState`, como sempre.

---

## 5. As fases em detalhe

### Fase 1 — Os primeiros passos · T

**Objetivo.** Criar um repositório e registrar o primeiro estado do mundo.

**Comandos.** `init` → `status` → `add` → `commit` (e `help`).

**História (existente).** O jogador acorda num fragmento do sistema central, que entrou em colapso: "tá uma bagunça
completa por aqui, e nada está registrado". A IA assistente ("o que sobrou de mim") explica que o Git tira "fotos" do
projeto. Há pedaços de código jogados pelo chão da sala (`setup`, `readme`, `main`) e uma chave cósmica.

**Como funciona.** Uma sala com o **Obelisco de Dados** (o terminal, tecla T), arquivos coletáveis, Slimes (inimigos) e um
portal de saída. O portal só abre quando **todos** os arquivos estão versionados. A tutora percebe dificuldade (falhas
seguidas) e passa de uma pista conceitual para a resposta direta; depois do primeiro ciclo `add` → `commit` ela retira o
apoio.

**Técnico.** `fases/fase_1/`, `Dialogo/Fase1/` (`TutoraFase1` é a base de todas as outras tutoras), Manual do Sistema.

**História possível.** Dar nome ao colapso (o que aconteceu com o sistema central?) e plantar a primeira pista do arco
maior (seção 6): a IA "não lembra" por que tudo caiu.

---

### Fase 2 — A Ponte Quebrada · T

**Objetivo.** Entender que dá para trabalhar numa **cópia segura** (branch) e trazer o resultado de volta (merge) sem arriscar
a linha principal.

**Comandos.** `log` → `branch ponte` → `switch ponte` → (`add` + `commit`) → `switch main` → `merge ponte`.

**História (existente).** Um abismo separa o jogador do portal e a ponte está quebrada. A IA propõe consertá-la numa cópia
segura e só depois trazê-la para o mundo principal.

**Como funciona.** Uma sala só. A peça `ponte.tile` só existe (e só pode ser coletada) na branch `ponte`. A ponte tem três
estados lidos do repositório: **quebrada**, **fantasma** (consertada na branch, mas a `main` ainda não a tem: não dá para
atravessar) e **sólida** (merge feito: a passagem abre para sempre). O `git log` mostra um commit passado ("Ponte intacta").

**Técnico.** `fases/fase_2/` (`EstadoPonte`, `PonteTutorial`, `TutoraPonte`, painel de objetivos). Visual "Cânion de brasa": ver `docs/DESIGN_FASES.md`.

**História possível.** Quem quebrou a ponte? Ligar ao arco: um commit antigo da ponte aparece no `log` com um autor que o
jogador não reconhece.

---

### Fase 3 — O Mural Corrompido · T

**Objetivo.** Ver **o que mudou** num arquivo (`diff`) e **desfazer** mudanças sem perder o resto (`restore`), entendendo as
três zonas do Git: pasta, staging e commit.

**Comandos.** `status` → `diff` → `restore <arquivo>` → `restore --staged <arquivo>` (e `add` para recuperar).

**História (existente).** Os Escribas gravaram o **Selo** nas runas de um mural. Na noite passada a **Corrupção** trocou a cor
de várias runas por "ruído". Uma mudança, porém, é boa: foi o próprio jogador quem corrigiu a runa do mar.

**Como funciona.** Três zonas em fila, com portas que abrem conforme o jogador aprende:

1. **Mural da Entrada** (`status` + `diff`): as runas alteradas têm contorno laranja; o `diff` mostra `-cor: dourado` /
   `+cor: ruído` e as runas afetadas brilham.
2. **Oficina** (`restore`): descartar só a corrupção e **manter** `mar.runa`. É a armadilha: restaurar a boa apaga o
   trabalho, e o `restore` não tem volta. O **Altar da Reescrita** (ENTER) refaz a mudança perdida.
3. **Palco** (`restore --staged`): o chão tem as áreas Oficina / Palco / Arquivo e as runas **andam** entre elas conforme o
   estado. Um `git add .` apressado mandou tudo ao Palco; o jogador tira a `eclipse.runa` (corrompida) e descarta, mantendo
   a `aurora.runa`.

**Visual.** Runas coloridas (moldura = versão do commit, miolo = versão atual, xadrez magenta = ruído), contorno laranja
(Oficina) ou azul (Palco), brilho no `diff`.

**Técnico.** `fases/fase_3/`: `ModeloMural` guarda base/índice/atual de cada runa em `progresso_tutoria` (o `GameState`
ainda não guarda conteúdo). `RunaMural`, `PortaMural`, `AltarReescrita`, `TutoraMural`.

**História (implementada).** A IA explica o ruído ("o que sobra de trabalho que ninguém registrou") e hesita ("Eu sei disso. Não sei como sei"); a mudança
boa do mar é de **alguém**; ao fechar a zona 2 a assinatura **W-3** reaparece ao lado do mar; ao limpar o mural o ruído recua e surge a lei
original ("Registrar não é prender. É lembrar."), e a IA diz "Alguém esteve aqui antes de você, Walker. E fez a coisa certa." Três notas
(placa dos Escribas, ata do Conselho, folha solta do mar). Texto das notas em `NotasHistoria`.

**Teste.** `test/fase_3_mecanica_test.tscn` (fluxo, armadilha e Altares, história, reinício pelo menu).

**Visual.** "Pedra clara e ouro" (arte em PNG gerada por `tools/gerar_arte_fase_3.gd`); ver `docs/DESIGN_FASES.md`.

**História possível.** Quem é a Corrupção? Ligar ao "ruído" que reaparece na Fase 6 (o commit fantasma ilegível).

**Ideias.** O `diff` como **lente** que ilumina a diferença direto sobre as runas; a parede de glitch rachar aos poucos.

---

### Fase 4 — Ecos de Possibilidades · E (a elevada)

**Objetivo.** Dominar branches e merge num problema maior: duas realidades que evoluem em separado e **convergem**.
É a fase de mais profundidade narrativa e visual.

**Comandos.** `log`, `branch`, `switch`, `add`, `commit`, `merge` (sem conflito), com orientação gradual do Eidolon (dicas em níveis: orientação, conceito, prática) em vez de passos prontos.

**História (existente).** O jogador explora o **Atlas das Ramificações** e conhece o **Eidolon**: a consciência fragmentada
de um arquivista Codex, que defende a **doutrina de não integrar** (as realidades devem ficar separadas). O arco do Eidolon
tem 5 etapas: certeza → desconforto → dúvida → conflito → reinterpretação parcial. Ao fim, o merge prova que as duas
realidades coexistem. O Eidolon tem uma **lacuna de memória** que ele não explica, e a fase termina com o gancho
"outros registros" e a **porta de vidro**, sem explicar a Catástrofe.

**Como funciona.** Cinco áreas (Arquivo, Ramificação, duas realidades em paralelo, Convergência, Registro). `main` (violeta)
e `vida-alternativa` (verde) são realidades independentes; as portas de cada uma só abrem na branch certa; **fissuras**
ligam as duas. O jogador cria a branch, troca de realidade, coleta um eco em cada uma, registra e faz o merge. O **Atlas**
mostra o grafo real (commit = nó, merge = nó com dois fios). Depois do merge, o mundo mostra as duas realidades
**coexistindo**. O registro final exige que o jogador **inspecione o commit de merge** no Atlas.

**Técnico.** `fases/fase_4/` e `docs/FASE_4_ESTRUTURA.md` (documento detalhado: camadas, flags, Eidolon, dicas graduais,
calibragem). Teste: `test/fase_4_progressao_test.tscn`.

**História possível.** O commit fantasma da Fase 6 pode ser **um registro do Eidolon**: a lacuna de memória dele. A porta de
vidro (Fase 4) é o lugar onde isso volta.

---

### Fase 5 — Linhas Cruzadas · T

**Objetivo.** Entender o **merge com conflito**: dois ramos mudaram o **mesmo** arquivo e o Git pede uma decisão. Conflito
não é erro; é o Git pedindo ao jogador que decida.

**Comandos.** `status` → `merge ajuste` (para com `CONFLICT`) → `diff` (marcadores) → escolher o lado no mundo →
`add selo.runa` → `commit`. Saída segura: `merge --abort`.

**História (existente).** O **selo** que guarda a passagem foi pintado por duas equipes ao mesmo tempo: a sua linha (`main`)
de dourado, a outra equipe (branch `ajuste`) de azul. Uma parede de glitch (`<<<<<<<  =======  >>>>>>>`) só cai quando as
duas linhas se encontrarem.

**Como funciona.** Uma sala só. O primeiro `merge` junta sozinho o que pode (`porta.runa`) e **para** em `selo.runa`. O `diff`
mostra a versão do jogador acima de `=======` e a da outra equipe abaixo. O jogador **resolve no mundo**, em um de três
pedestais (ENTER): a sua versão, a dela ou as duas. O `add` marca o conflito como resolvido (e recusa enquanto houver
marcadores) e o `commit` fecha o merge. Dá para reescolher antes do `add` e para abortar a qualquer momento.

**Estados** do `ModeloConflito`: `pre → conflito → resolvido → preparado → concluido`.

**Técnico.** `fases/fase_5/`: `ModeloConflito`, `RunaConflito`, `PedestalEscolha`, `TutoraConflito`. O commit final é gravado
também no `GameState`. Teste: `test/fase_5_gamestate_test.tscn` (a Parte 2 joga a fase pelo terminal).

**História (implementada).** O Eidolon acompanha o jogador pela voz (cor ciano, `[EIDOLON]`) e defende que uma versão deve prevalecer; a IA paralisa diante
de "conflito"; cada escolha (minha/deles/ambas) tem uma reação; ao fechar o merge vem o **abalo do Eidolon**, um diálogo obrigatório que espera o terminal
fechar. Três notas (placa, carta de "E.", ata do Conselho). Roteiro em `fases/fase_5/roteiro_conflito.gd`. A escolha fica em
`GameState.escolhas_historia` (chave `GameState.ESCOLHA_CONFLITO`), que sobrevive a `reset_fase()`, para as Fases 6, 7 e 8 usarem.
**Visual (implementado):** "Grafite neutro" (arte em PNG gerada por `tools/gerar_arte_fase_5.gd`); a parede racha com luz verde-água na escolha "ambas". Ver `docs/DESIGN_FASES.md`.

**Ideias.** Cada escolha abrir um caminho diferente até o portal; um segundo conflito opcional, mais difícil; a parede
rachar conforme o conflito é resolvido.

---

### Fase 6 — Ponto de Retorno · T (a última por enquanto, **sem fechamento**)

**Objetivo.** Aprender as **três maneiras de voltar atrás** e o custo de cada uma: `revert` (desfaz sem apagar a história),
`stash` (guarda o trabalho para depois) e `reset` (volta no tempo; `--soft` mantém o trabalho, `--hard` o destrói).

**Comandos.** `log` + `revert` · `stash` + `stash pop` · `reset --soft` + `commit` + `reset --hard`.

**História (existente).** Todo commit é um **marco no tempo**; errar é normal, mas cada jeito de voltar tem um custo. Um commit
ruim sabotou a ponte; há uma emergência no Corredor; dois commits apressados esperam na Câmara do Reset. No fim aparece um
**commit fantasma** que o jogador não criou, com a mensagem ilegível. A IA diz só "Isso não era nosso... mas fica para
depois". A fase **não fecha** a história.

**Como funciona.** Três áreas em fila, um comando em cada, usando o repositório **real**:

1. **A Ponte (`revert`).** O último commit é o ruim. `git revert HEAD` cria um commit **novo** que o desfaz; a história continua
   inteira. Se o jogador desfaz o commit errado, aprende que dá para **desfazer o desfazer**.
2. **O Corredor (`stash`).** A lanterna está na caixa (trabalho pela metade) e o portão de inspeção só deixa passar pasta limpa.
   `git stash` guarda o trabalho, o portão abre, o jogador puxa a alavanca da emergência (ENTER) e recupera com `stash pop`.
3. **A Câmara do Reset (`reset`).** Primeiro a **planta** foi commitada cedo demais: `reset --soft HEAD~1` volta o commit e mantém
   o trabalho na caixa; depois `commit` direito. Em seguida, um **experimento** arriscado: `reset --hard HEAD~1` o destrói de vez.
   Armadilha: o `--hard` na planta a destrói (e o `--soft` no experimento o deixa na caixa). O **Altar de Retorno** (ENTER) recoloca
   a câmara como estava.

**Visual principal: a linha do tempo de commits.** O HEAD anda por ela; commits descartados viram **fantasmas** translúcidos;
um `revert` faz nascer um nó ciano; uma **prateleira** mostra o stash; os arquivos da câmara mudam de aspecto conforme estão no
histórico, na caixa, soltos ou destruídos. O **commit fantasma ilegível** aparece em magenta.

**Técnico.** `fases/fase_6/`: `EstadoRetorno` (fatos + progresso + montagem das situações), `FaixaTempo`/`LinhaDoTempo`,
`PonteRetorno`, `ObjetoRetorno`, `InteracaoRetorno` (alavanca e altar), `PrateleiraStash`, `TutoraRetorno`. Usa `GameState`
(`reverter`, `resetar_para`, `guardar_stash`, `aplicar_stash`). Ao entrar, a fase **zera o repositório** se ainda não foi montada
(cada tutorial é independente). Teste: `test/fase_6_fluxo_test.tscn`; captura visual: `test/fase_6_captura.tscn`.

**História (implementada).** A IA comenta o `revert` ("o jeito honesto"), o `stash` ("adiar não é abandonar") e, ao ver o arquivo virar **poeira** no `reset --hard`, diz
"Sentiu isso? É assim que eles faziam." e "Desculpa. Eu não sei por que disse isso." (a Purga). O **Eidolon** é só um **eco** ciano que foge do jogador no corredor
e, no fim, aparece e diz "Esse hash... eu o conheço." (diálogo). O **commit fantasma** aparece no `git log` como **órfão**, com o autor `RS4=` (base64 de "E.").
A IA lembra, em uma frase, a escolha do conflito da Fase 5. Três notas. A tela final não promete continuação: "Um registro ficou para trás. Nenhuma branch aponta para ele."
Roteiro: `tutora_retorno.gd`, `eco_eidolon.gd`. Teste: `test/fase_6_historia_test.tscn`. **Visual:** "Concreto brutalista com sinalização" (ver `docs/DESIGN_FASES.md`).

**Ideias.** Um **segundo fantasma** legível só depois de `reflog` (Fase 7); a linha do tempo clicável (viajar até um commit).

---

## 6. Arco narrativo e fases futuras

### O que já está plantado

- **IA assistente** (Fases 1, 2, 3, 5, 6): ajuda o Walker; o que "sobrou" de um sistema que colapsou.
- **Eidolon** (Fase 4): arquivista fragmentado, doutrina de não integrar, **lacuna de memória** que ele não explica.
- **Porta de vidro / "outros registros"** (fim da Fase 4): o gancho para o que vem depois.
- **Commit fantasma ilegível** (fim da Fase 6): um registro que ninguém criou e nenhuma branch alcança.

### A revelação (Fase 7, ainda não existe): "O Apagador"

A **Catástrofe** foi um `reset --hard` (ou reescrita de histórico) que **apagou o histórico**. A lacuna de memória do Eidolon são
**commits perdidos**, e as memórias que ele não consegue explicar eram dele mesmo. Isso fecha o gancho da Fase 4 e dá sentido ao
fantasma da Fase 6.

- **Comandos:** `reflog` (achar o que parece perdido), `cherry-pick` (recuperar commits soltos) e, opcionalmente, `rebase`.
- **Áreas:** a porta de vidro abre para o **Arquivo Vazio** (o repositório pós-catástrofe, quase sem commits); o **reflog** mostra
  os commits "apagados" como fantasmas; a **reconstrução** reúne fragmentos de várias branches numa só linha.
- **Chefe: o Apagador.** Ataca "reescrevendo a história" e a luta liga cada fase aos comandos: ele apaga uma plataforma
  (`reset`) e o jogador a restaura (`reflog`/`revert`); `merge` dá o golpe final; `branch` cria rotas; `commit` trava um estado
  seguro. Sugestão: **mistura** de esquiva no mapa e comandos no terminal.
- **Final emocional:** escolher entre história linear e limpa (`rebase`) ou preservar todas as ramificações, bagunçada mas
  completa (`merge`). O jogo recompensa as duas de formas diferentes. Se o `rebase` ficar de fora, a escolha sai.
- **Extras:** o Atlas mostra o grafo completo, com todas as ramificações do jogador unidas, como créditos visuais; Atlas jogável
  (clicar num nó e viajar até aquele commit); uma fase de **recap** reusando mapas das fases anteriores em versão corrompida.

### Outras fases possíveis (ideias soltas)

- **Tags / marcos:** nomear um commit importante (`tag`), útil para o "ponto de retorno".
- **Histórico limpo:** `commit --amend` e mensagens de commit boas como puzzle.
- **Trabalho em equipe local:** várias branches de "personagens" para estender a Fase 5.
- **Remoto** (`clone`/`push`/`pull`): só se o escopo mudar; exigiria um modelo novo no `GameState`.

---

## 7. O repositório (`GameState`): o que existe e o que falta

**Já existe** (aditivo, testado): `reflog` (+ `formatar_reflog`), `resetar_para` (soft/mixed/hard), `reverter` (inclusive o revert
de um revert), `escolher_commit` (cherry-pick), `guardar_stash`/`aplicar_stash`, `resolver_referencia` (`HEAD`, `HEAD~N`,
`HEAD^`, branch, id) e conteúdo opcional por arquivo (`criar_commit(msg, conteudos)` + `conteudo_em`). Commits descartados
por um `reset` **continuam no object store**, o que torna o `reflog` possível.

**Ainda falta:**

| Capacidade | Por que | Hoje |
|---|---|---|
| Conflito de merge nativo | `merge` com conflito no `GameState` | Simulado no `ModeloConflito` (Fase 5) |
| Conteúdo por arquivo em todo o repositório | unificar `ModeloMural` e `ModeloConflito` ao `GameState` | Cada modelo guarda o seu |
| Comandos de terminal para `reflog` e `cherry-pick` | Fase 7 | Só a API do `GameState` |
| `rebase` | final com escolha | Não existe |
| Desfazer/copiar commit de merge | `revert`/`cherry-pick` de merge | Recusado com mensagem |

**Recomendação.** Unificar os modelos locais ao `GameState` só quando a Fase 7 pedir, e **antes** escrever um teste de regressão
das fases 1 a 6 (hoje há testes para 4, 5, 6 e o fluxo entre fases).

---

## 8. Backlog de ideias

- **Visual:** `diff` como lente sobre as runas; parede de glitch que rachou conforme o conflito é resolvido; a linha do tempo
  clicável; arte final no lugar dos desenhos por código; luzes e partículas nos `reset --hard`.
- **IA:** mais dicas graduais (a Fase 4 já tem o sistema completo: `dicas_eidolon.gd`) levadas às outras tutoras; reação a
  tempo parado (hoje não há detecção por tempo).
- **Acessibilidade:** textos em dois níveis (metáfora + termo real, como já é feito) e opção de legenda do que o comando fez.
- **Conteúdo:** Manual do Sistema com mais exemplos; um **glossário** no menu de pausa.
- **Ferramentas:** um painel de debug por fase (a Fase 4 tem o `DebugFase4`); testes automatizados para a Fase 3.
- **Estrutura:** extrair o padrão repetido (`Modelo*` + `Tutora*` + `Painel*` + `Porta*`) para uma base comum de "fase tutorial".

---

## 9. Decisões em aberto

- [ ] Fase 3: criar teste automatizado (lacuna).
- [ ] Fase 5: escrever o abalo do Eidolon (a doutrina de não integrar falhando) ou manter como tutorial puro?
- [ ] Fase 6: o fantasma ilegível é **do Eidolon**? (Define a ligação com a Fase 4 e a revelação da Fase 7.)
- [ ] Fase 7: manter `rebase` e a escolha final `rebase` vs `merge`, ou simplificar?
- [ ] Chefe da Fase 7: ação, puzzle de comandos, ou mistura (sugestão: mistura).
- [ ] Unificar os modelos locais ao `GameState` agora ou só na Fase 7?
- [ ] Mais de uma elevada? Hoje só a Fase 4 é elevada; avaliar uma elevada depois da Fase 6 (a Fase 7 cumpriria esse papel).

---

## 10. Testes e como criar uma fase nova

### Testes

Rode a cena no editor (F6) ou em modo headless; cada teste sai com código 1 se algo falhar.

| Teste | O que cobre |
|---|---|
| `test/fase_4_progressao_test.tscn` | Jornada da Fase 4 pelas operações reais do `GameState` (48 verificações) |
| `test/fase_5_gamestate_test.tscn` | Novas capacidades do `GameState` + a Fase 5 inteira pelo terminal (61 verificações) |
| `test/fase_6_fluxo_test.tscn` | A Fase 6 inteira pelo terminal, com os erros típicos (44 verificações) |
| `test/fluxo_fases_test.tscn` | Saída/entrada entre as 6 fases e o fim de jogo (48 verificações) |
| `test/game_state_sinais_test.tscn` | Sinais do `GameState` (manual: lê-se o Output) |
| `test/fase_6_captura.tscn` | Gera PNGs da Fase 6 (precisa de janela) |

### Checklist para uma fase nova

1. Criar `fases/fase_N/` com a cena, o script da fase e (para tutorial) uma tutora (`extends TutoraFase1`) e um painel de
   objetivos (a HUD das fases segue o padrão da Fase 1: quadro da IA recolhível, sem painel de objetivos). Copiar o padrão de `fases/fase_5/` (sala única) ou `fases/fase_3/` (zonas).
2. Se precisar de um comando novo: classe em `terminal/Commands/`, registro em `terminal_command_interpreter.gd`, entradas em
   `git_command_help.gd` e `manual_comandos.gd`, e um `terminal/config/terminal_fase_N.tres`.
3. Acrescentar a cena ao **fim** de `FaseManager.FASES` e um resumo em `RESUMOS` (`victory_screen.gd`).
4. No script da fase, o botão "próxima fase" deve só chamar `FaseManager.concluir_fase_e_avancar()`.
5. Escrever um teste que jogue a fase pelo interpretador do terminal e atualizar `fluxo_fases_test.gd`.
6. Registrar a fase aqui (objetivo, comandos, história, como funciona, ideias).

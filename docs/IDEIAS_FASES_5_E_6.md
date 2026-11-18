# Plano de fases — controle do roteiro (7 fases)

> Documento de **planejamento**, nada daqui está implementado além do que está marcado "Pronta".
> Serve de controle: cada fase será detalhada depois no formato do `FASE_4_ESTRUTURA.md`
> (áreas, flags, comandos liberados, falas do Eidolon).
> (O nome do arquivo é histórico: ele nasceu só com as fases 5 e 6.)

## Regras do projeto (decisões já tomadas)

- **Não alterar o `GameState` por enquanto.** Ele é frágil. Só mexer quando chegar a fase que exige.
- **Fora do escopo:** `push`, `pull`, `fetch`, `clone`, `remote`. O jogo ensina **Git local**.
- **Conflito de merge** não é suportado hoje, mas **vai ser necessário** (Fase 5). A mudança no
  `GameState` fica para a hora certa.
- O orientador pediu dois tipos de fase:
  - **Tutorial (T):** simples, apresentam os comandos de forma clara, sem ser "besta".
  - **Elevada (E):** um problema maior, que cobra o uso combinado do que já foi aprendido.
- Cada comando novo **nasce numa fase tutorial** e só depois é cobrado numa elevada.

---

## Retrospecto: o que já existe

| Fase | Tipo | Comandos | Situação |
|---|---|---|---|
| 1 | T | `init`, `add`, `commit`, `status` (+ `help`) | Pronta (`fases/fase_1/`) |
| 2 "A Ponte Quebrada" | T | `log`, `branch`, `switch`, `add`, `commit`, `merge` (liberados aos poucos pela tutora) | Pronta (`fases/fase_2/`) |
| "Ecos de Possibilidades" | E | os mesmos, sem conflito, com duas realidades, Atlas e Eidolon | Pronta, em standby em `fases/fase_4/` (Fase 4) |

Na sequência atual (`global_fase_manager.gd`) só existem as fases 1 e 2.

---

## Lista de comandos do jogo

| Comando | Fase onde nasce | Estado no `GameState` |
|---|---|---|
| `init`, `add`, `commit`, `status`, `help` | 1 | Existe |
| `log`, `branch`, `switch`, `merge` (sem conflito) | 2 | Existe |
| `diff` | 3 | **Falta** (exige conteúdo por arquivo) |
| `restore`, `restore --staged` | 3 | **Falta** (exige conteúdo por arquivo) |
| `merge` com conflito (+ resolver) | 5 | **Falta** (exige conteúdo e marcadores) |
| `stash` (`stash`, `stash pop`) | 6 | **Falta** |
| `revert` | 6 | **Falta** (hoje o commit só acrescenta arquivos) |
| `reset` (`--soft`, `--hard`) | 6 | **Falta** (mover o head é simples; `--hard` mexe nos arquivos) |
| `reflog` | 7 | **Falta** (registro de movimentos do HEAD) |
| `cherry-pick` | 7 | **Falta** |
| `rebase` | 7 (final, opcional) | **Falta**, e conflita com "commits nunca são reescritos" |

Já bloqueados no interpretador como "não implementados": `diff, checkout, rebase, clone, fetch, pull,
push, remote, reset, restore, rm, mv, stash, tag, config, show, revert, cherry-pick`. `reflog` ainda
não está na lista.

---

## Plano fase a fase

### Fase 1 — (existente) · T
**Comandos:** `init, add, commit, status`. **Objetivo:** criar um repositório, preparar arquivos e
registrar o primeiro commit. Sem alterações.

### Fase 2 — "A Ponte Quebrada" · T
**Comandos:** `log, branch, switch, add, commit, merge`. **Objetivo:** consertar a ponte numa cópia
segura (branch) e trazer o conserto de volta (merge). Sem alterações.

### Fase 3 — "Desfazer" (nova) · T
**Comandos novos:** `diff`, `restore`, `restore --staged`.
**Objetivo do jogador:** ver o que mudou num arquivo e voltar atrás sem perder o resto.
**Ideia de puzzle:** um arquivo foi estragado (um símbolo, uma peça do cenário). O jogador usa `diff`
para achar o que mudou e `restore` para trazer a versão boa. Segunda parte: um arquivo foi para a
staging por engano e sai com `restore --staged`.
**Dificuldade:** baixa. Um conceito por área, o comando é dito pela tutora na hora certa (como na
Fase 2).
**Depende do `GameState`:** conteúdo por arquivo (não existe hoje).
**Decidido:** "O Mural Corrompido", combinando mural de runas (`diff`) e Palco (`restore --staged`), com a
armadilha de uma mudança boa que não pode ser descartada. A Fase 4 NÃO usa `diff`/`restore`.
**Protótipo (validar mecânica, sem arte):** `fases/fase_3/`. Para não mexer no `GameState`, o conteúdo das
runas vive em `ModeloMural` (base / índice / atual); os comandos `status`, `add`, `diff` e `restore` falam
com ele só quando a cena tem o mural (Fases 1 e 2 não mudam).

### Fase 4 — "Ecos de Possibilidades" · E
**Comandos:** todos da 1 a 3. **Objetivo:** duas realidades (`main` e `vida-alternativa`) evoluem em
separado e convergem num merge. Abre a lacuna de memória do Eidolon e o gancho "outros registros"
(porta de vidro).
**Situação:** pronta. Falta só entrar na sequência e **decidir se usa `diff`/`restore`** (opcional,
para não tocar numa fase pronta e frágil).

### Fase 5 — "Linhas Cruzadas" (nova) · T
**Comandos novos:** merge com conflito (resolver e concluir) e `diff` aplicado ao conflito.
**Objetivo do jogador:** entender que dois ramos podem mudar o **mesmo** arquivo e o Git pede uma
decisão: ficar com um lado, com o outro, ou juntar os dois.
**Ideia:** parede de "glitch" mostrando `<<<<<<<  =======  >>>>>>>` como barreira física. O jogador
escolhe o lado e fecha com `add` + `commit`. **Um único arquivo, um único conflito.** É tutorial.
**Eidolon:** a doutrina "não integrar" falha quando as duas linhas discordam (primeiro abalo real).
**Depende do `GameState`:** conteúdo por arquivo, detecção de conflito e marcadores. **Esta é a
mudança grande, para quando chegar a hora.**

### Fase 6 — "A Catástrofe" (nova) · E
**Comandos novos:** `revert`, `reset` (`--soft`, `--hard`), `stash`.
**Objetivo do jogador:** lidar com erros de verdade, com risco.
**Ideias de áreas:**
1. *Ponte instável:* um commit ruim; `revert` volta sem apagar a história.
2. *Corredor do stash:* um perigo obriga a guardar o trabalho pela metade, resolver outra coisa e
   recuperar (`stash` / `stash pop`).
3. *Câmara do reset:* puzzle de risco; `--soft` serve, `--hard` destrói um item. Aprende-se a
   diferença na prática.
**Mecânica nova:** inimigos "corrompidos" (reaproveitando o Slime), derrotados quando o problema
é resolvido.
**Eidolon:** a Catástrofe é nomeada, mas **ainda não explicada** (ele aponta um `reset --hard`
sem perceber a ligação).
**Depende do `GameState`:** mover head, desfazer commit, guardar/recuperar trabalho.

### Fase 7 — "O Apagador" (final) · E
**Comandos novos:** `reflog`, `cherry-pick`; opcional: `rebase` (escolha final).
**Objetivo do jogador:** recuperar o histórico "apagado" e usar tudo que aprendeu.
**Revelação:** a Catástrofe foi um `reset --hard` (ou reescrita de histórico) do próprio Eidolon.
A lacuna de memória são commits perdidos; fecha o gancho da Fase 4.
**Áreas:**
1. *A porta de vidro:* abre no fim da Fase 4. Do outro lado, o Arquivo Vazio (repositório quase sem commits).
2. *Reflog:* os commits "apagados" aparecem como fantasmas; `git reflog` os acha, `cherry-pick` ou `reset` os recupera.
3. *Reconstrução:* reunir fragmentos de várias branches numa só linha (merge e cherry-pick em sequência).
4. *Chefe, o Apagador:* ataca "reescrevendo a história". Esquiva no mapa + comandos no terminal: apaga
   uma plataforma (`reset`) e o jogador a restaura (`reflog`/`revert`); `merge` no golpe final.
5. *Final:* o Atlas mostra o grafo completo, com as ramificações unidas.
**Final com escolha:** história linear e limpa (`rebase`) ou todas as ramificações (`merge`). Se o
`rebase` ficar de fora, o final vira só `merge` e a escolha sai.
**Depende do `GameState`:** registro de movimentos do HEAD, `cherry-pick`; `rebase` é a parte mais difícil.

---

## Ordem de impacto no `GameState` (para quando chegar a hora)

1. **Conteúdo por arquivo** — base de `diff`, `restore` e conflito (Fases 3 e 5).
2. **Conflito de merge** (Fase 5).
3. **Mover head / `revert` / `stash`** (Fase 6).
4. **Registro de movimentos (`reflog`) e `cherry-pick`** (Fase 7).
5. **`rebase`** (Fase 7, só se mantivermos a escolha final).

Fases 1, 2 e 4 não exigem nada novo.

---

## Decisões em aberto

- [ ] Fase 3: confirmar `diff` + `restore` como tema (ou trocar por `stash`).
- [ ] Fase 4: usar `diff`/`restore` nela ou deixá-la intocada?
- [ ] Manter `rebase` e a escolha final `rebase` vs `merge`, ou simplificar?
- [ ] Chefe da Fase 7: ação, puzzle de comandos, ou mistura (sugestão: mistura)?
- [ ] Nomes finais das fases 3, 5, 6 e 7.
- [ ] Qual fase detalhar primeiro (sugestão: Fase 3, a mais simples e que abre o conteúdo por arquivo).

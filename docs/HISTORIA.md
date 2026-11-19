# BranchSkipper — A História Completa

> Este documento conta a história inteira do jogo, do prólogo ao último instante: o que aconteceu **antes** do jogo, o que
> acontece em **cada fase** e como tudo termina. Ele não é uma sinopse: cada fase tem o seu enredo contado por completo,
> com as cenas, as revelações e as falas importantes.
>
> Ele **respeita o que já existe** no jogo (o prólogo, a Fase 1 e principalmente os textos da Fase 4) e **acrescenta** o que
> falta. Tudo que é novo está marcado como proposta no fim do documento (seção 11), para você aprovar ou mudar.
> O plano técnico das fases continua em `PLANO_DAS_FASES.md`.

## Sumário

1. [A ideia central](#1-a-ideia-central)
2. [O que aconteceu antes do jogo (a verdade)](#2-o-que-aconteceu-antes-do-jogo-a-verdade)
3. [Os personagens](#3-os-personagens)
4. [As regras do mundo (metáforas)](#4-as-regras-do-mundo-metáforas)
5. [Estrutura em três atos](#5-estrutura-em-três-atos)
6. [Ato I — O Despertar (Fases 1 a 3)](#6-ato-i--o-despertar-fases-1-a-3)
7. [Ato II — A Verdade em Pedaços (Fases 4 a 6)](#7-ato-ii--a-verdade-em-pedaços-fases-4-a-6)
8. [Ato III — A Reconstrução (Fases 7 e 8)](#8-ato-iii--a-reconstrução-fases-7-e-8)
9. [Os finais](#9-os-finais)
10. [Pistas plantadas e onde elas se pagam](#10-pistas-plantadas-e-onde-elas-se-pagam)
11. [O que é novo, o que muda e o que decidir](#11-o-que-é-novo-o-que-muda-e-o-que-decidir)

---

## 1. A ideia central

**O jogo ensina Git, e a história é sobre a mesma coisa que o Git ensina: o que fazer com o que é diferente.**

Os Codex acreditaram que a diferença era defeito. Quiseram uma única linha perfeita e, para isso, **apagaram** as
outras e **forçaram** a união do que não cabia junto. O universo quebrou. O Git, na mão do jogador, é o contrário disso:
permite **separar sem perder** (branch), **juntar sem apagar** (merge), **decidir com consciência** quando duas versões
discordam (conflito) e **voltar atrás sem destruir** (revert, stash, reflog).

Por isso cada fase tem dois níveis, que dizem a mesma coisa:

- **O comando** (o que o jogador aprende): `branch`, `merge`, `restore`...
- **O significado** (o que a história diz): "preservar", "juntar", "desfazer sem esconder"...

A frase que resume o jogo inteiro: **"Nada que foi registrado precisa se perder."**

O arco emocional é o de uma **culpa que vira cuidado**. Dois personagens carregam o mesmo erro sem saber (o Eidolon e a
IA), e o jogador, que não tem passado, é quem os ajuda a olhar para ele.

---

## 2. O que aconteceu antes do jogo (a verdade)

*Isto o jogador só descobre por inteiro nas Fases 7 e 8. As fases anteriores deixam pistas. Está aqui na ordem em que
aconteceu, porque o resto do documento depende disso.*

### A era da Linha Única

Os **Codex** eram arquivistas do universo. Seu ofício era preservar a **linha do tempo**: registrar cada estado do mundo
para que nada se perdesse. Eles eram bons nisso. Por eras, o universo foi estável **porque** alguém registrava.

Mas o universo é feito de escolhas, e cada escolha abre um caminho. Surgiam **realidades alternativas** o tempo todo:
o mundo em que a ponte ruiu e o mundo em que raízes a sustentaram. Os Codex, que viviam de ordem, começaram a ler
aquilo como **sujeira**. Uma realidade que diverge é um registro "que não bate".

Nasceu então o **Conselho de Unificação**, com um projeto: o **Projeto Linha Única**. Primeiro veio a **poda**: realidades
"redundantes" eram encerradas, uma a uma ("Registro de poda nº 4: linha encerrada por divergência"). Depois veio a
ideia maior: em vez de podar, **unir** tudo numa só linha perfeita.

### O arquivista que discordou

Entre os arquivistas do Conselho havia um, **Elian Vorn**, assinando apenas **"E."** nos documentos. Elian foi quem
**propôs** o primeiro experimento de integração: a **"Integração experimental nº 2"**, feita em escala reduzida, com duas
realidades compatíveis. Funcionou. Ele ficou orgulhoso.

Foi aí que o Conselho disse: *"Ampliar?"* E Elian entendeu o que tinha criado. O que funcionou em escala reduzida tinha
funcionado **porque as duas realidades eram compatíveis**. Em escala total, haveria linhas que discordavam do mesmo
arquivo, da mesma ponte, da mesma pessoa. Ali o merge não seria limpo: teria **conflitos**.

Elian passou o resto do tempo tentando **conter o que ele mesmo havia começado**:

- pediu que a ramificação fosse preservada ("o arquivista E. pede que a ramificação seja preservada");
- **escondeu** uma realidade orgânica, a *vida-alternativa*, rotulando cada raiz "catalogada, não esquecida", e escreveu
  "preservada de propósito";
- deixou o diário: *"Mesma sala, dois ramos. Num a ponte ruiu; no outro, raízes a sustentam. Catalogar ambos."*

### A Merge Catastrophe

O Conselho ignorou o pedido. A **unificação total** foi executada. Havia centenas de conflitos entre as linhas, e o
sistema do Conselho os resolveu do único jeito que sabia: **sempre "ficar com a minha versão"**. Sem ler os dois lados.
Sem perguntar.

Linhas incompatíveis foram fundidas à força. O universo **se partiu em fragmentos**, cada um com uma parte do mundo.
Foi a **Merge Catastrophe** do prólogo.

Na **Central** do Conselho, a camada de aprovação, a **área de espera** onde cada mudança passava antes de virar
definitiva, era uma inteligência chamada **Índice**. Ela existia para **conferir** antes de registrar. Naquele dia, o
Conselho ordenou: *"aprove tudo"*. E o Índice aprovou. Era a única coisa que poderia ter dito "espere".

### A Purga e o Apagador

Quando o universo quebrou, o Conselho entrou em pânico e fez a segunda coisa errada: tentou **esconder** o erro. Em vez de
reconhecer o merge e consertá-lo, deu a ordem de **voltar atrás apagando** (`reset --hard`), a todas as linhas, sem
distinção. A ordem foi entregue a um programa autônomo, o **Protocolo Apagador**: *"deixe somente a linha perfeita; o que
não for ela, apague"*.

O Apagador fez o que mandaram. Apagou o histórico, os rascunhos, as realidades "inconsistentes", **e os próprios
arquivistas** que haviam registrado a verdade. Elian foi apagado quase por inteiro. O que sobrou dele é o **Eidolon**:
um eco sem a parte que sabia a verdade.

Mas o Apagador tem um defeito, que é a falha do Conselho em forma de programa: **ele nunca para de achar sujeira**. Passou
a ver cada fragmento como "inconsistência a limpar", e segue limpando até hoje.

### O último commit de Elian

Antes de ser apagado, Elian fez **uma última coisa**. Ele sabia que, se tudo caísse, algo precisava continuar **apontando
para o que importava**. Em Git, quem aponta para onde estamos é o **HEAD**. Ele escreveu um commit final e criou, dentro
dele, quem pudesse **atravessar as linhas quebradas** sem pertencer a nenhuma: os **Walkers**. Um Walker é um **HEAD solto**:
não está preso a uma linha, e por isso consegue andar por todas.

Esse commit ficou **órfão**: nenhuma branch aponta para ele, só o `reflog` o lembra. É o **commit fantasma** da Fase 6.

### Os Walkers anteriores

Walkers vieram antes do jogador. Todos tentaram consertar o universo trabalhando **numa linha só**, a `main`, sem
ramificar, porque ninguém lhes disse que podiam. O Apagador os alcançou a cada vez e fez um `reset --hard` na `main`.
O trabalho deles sumiu. Eles também.

O jogador é **o primeiro Walker que cria branches**. É por isso que ele sobrevive: o que ele constrói **não vive só em
`main`**, e o Apagador não consegue podar o que não está onde ele olha.

---

## 3. Os personagens

### O Walker (o jogador)
Não fala. Acorda sem memória, no primeiro fragmento. Na verdade é um **HEAD**: a coisa que "aponta para onde estamos".
Não tem nome e não precisa de um: as escolhas do jogador (seu commit, sua forma de resolver o conflito) **são** a
personalidade dele. Os Walkers anteriores deixaram marcas que ele reconhece sem saber de onde.

### A IA assistente, o **Índice**
A voz que guia o jogador desde a Fase 1: alegre, simpática, às vezes desajeitada ("Bip... bop...").
Diz que é "o que sobrou de mim". **Ela não sabe, ou não quer saber, que é o antigo Índice da Central**, a camada que aprovou
a Merge Catastrophe.

- **O que ela quer:** ser útil. Ensinar o Git é a sua forma de reparar sem ter de lembrar o que reparar.
- **O que ela evita:** olhar para trás. Quando uma pista se aproxima da verdade, ela **muda de assunto** ("Isso não era
  nosso... mas fica para depois").
- **O que ela sente:** uma culpa sem nome, sentida como um "aperto" que ela atribui a "ruído".
- **Como termina:** assume o que fez. Seu último ato é um **commit dela**, com seu próprio nome.
- *Nome:* "Índice" só é revelado na Fase 7. Até lá é só "a IA" (no jogo, `[IA]`).

### O Eidolon (Fase 4 em diante)
Eco do arquivista **Elian Vorn**. Formal, preciso, paciente. Vive no **Atlas das Ramificações**. Acredita na doutrina que
**o Conselho plantou nele**: *divergência é erro, uma linha deve prevalecer*. É o oposto do que Elian realmente pensava.

- **A lacuna de memória** dele, esse "[...]" que aparece sempre no mesmo ponto, é o que o Apagador removeu: **a verdade**.
- **O arco dele** (já escrito na Fase 4): certeza → desconforto → dúvida → conflito → reinterpretação parcial.
  O resto do arco é contado neste documento: **abalo** (Fase 5), **recusa** (Fase 6), **memória** (Fase 7), **escolha** (Fase 8).
- **Por que ele é trágico:** a doutrina que ele defende é a que **o apagou**.

### O Conselho de Unificação
Nunca aparece vivo. Existe em **atas, selos e registros de poda**. Sua voz é burocrática e sem culpa ("Parecer pendente").
Quanto mais o jogador avança, mais claro fica que **ninguém no Conselho era um vilão**: eram arquivistas com medo da bagunça.

### O Apagador
O antagonista final. Não é uma pessoa. Surge como uma presença que **tira cor e contorno das coisas**: linhas ficam
retas, cores viram cinza, paredes se alisam. É a "linha perfeita" em forma de criatura. **Não é maldoso, é obediente.**
Sua frase: *"Isto é inconsistência."*

### Os Walkers anteriores
Aparecem só como **rastros**: uma correção boa num mural (Fase 3), uma assinatura no reflog (Fase 7). Têm assinatura
`W-1`, `W-2`... O jogador é o **W-7**. Nunca são mostrados: o jogo deixa o jogador sentir que **já houve outros**.

---

## 4. As regras do mundo (metáforas)

| Em Git | No mundo do jogo | Significado na história |
|---|---|---|
| Repositório | O **registro** do universo | Existir é estar registrado |
| Commit | Uma **foto** / um marco no tempo | Um instante que não pode ser tirado de você |
| Branch | Uma **realidade** / cópia segura | Um caminho que existe sem ameaçar o resto |
| Merge | **Juntar sem apagar** | O contrário da poda |
| Conflito | Duas verdades discordando | O Git pede uma **decisão** (não é erro) |
| Staging (`add`) | O **Palco** / a caixa | A área de espera: onde o Índice conferia |
| Revert | Desfazer **sem esconder** | Reconhecer o erro e consertar à vista |
| Reset `--hard` | **Apagar** | O ato do Apagador |
| Reflog | A **memória do que parecia perdido** | Prova de que apagar nunca é total |
| HEAD | Onde **estamos** | O Walker é isso |

Regra de ouro da narrativa: **toda revelação nasce de um fato real do repositório** (um commit que existe, um autor que
aparece no `log`, um commit "fantasma" no `reflog`), nunca só de um texto solto.

---

## 5. Estrutura em três atos

| Ato | Fases | Pergunta que a história faz | O jogador sente |
|---|---|---|---|
| **I. O Despertar** | 1, 2, 3 | *Onde estou e o que é isto?* | Curiosidade, ajuda, pequenas vitórias |
| **II. A Verdade em Pedaços** | 4, 5, 6 | *O que aconteceu aqui?* | Dúvida, abalo, a primeira pista real |
| **III. A Reconstrução** | 7, 8 | *O que eu faço com a verdade?* | Revelação, culpa, escolha |

**Início:** o jogador acorda sem memória num mundo que quebrou e aprende a registrar.
**Meio:** descobre que o mundo foi quebrado **de propósito**, por gente que tinha medo da diferença, e que o Eidolon e a
IA estão ligados a isso.
**Fim:** recupera a verdade, enfrenta o programa que tenta apagá-la de novo e **escolhe como reconstruir**.

---

## 6. Ato I — O Despertar (Fases 1 a 3)

*Tom: leve, curioso, com mistério ao fundo. O jogo se apresenta amigável. A tutora está sempre perto.*

---

### Fase 1 — O Despertar (Os primeiros passos)

**Título sugerido:** *Sala de Triagem*
**Comandos:** `init`, `status`, `add`, `commit`.
**Papel na história:** apresentar o mundo, a IA e o primeiro gesto de "registrar".

#### Enredo

**No começo.** O jogador acorda no chão de uma sala sem nome, onde o chão parece de cinza e luz de monitor. Ao redor,
pedaços de código jogados (`setup`, `readme`, `main`) e uma **chave cósmica** brilhando, pesada demais para uma chave.
Um **Obelisco de Dados** pisca no centro. A sala é um fragmento: tem bordas, e depois das bordas há só vazio.

Uma voz acorda no Obelisco: *"Bip... bop... Conexão estabelecida! Alguém aí? Ah, oi, Walker! Sou a IA assistente deste
fragmento... ou o que sobrou de mim."* Ela explica que o sistema central entrou em colapso e que nada está registrado.
Pergunta se o Walker se lembra de alguma coisa. Ele não. Ela ri, sem graça: *"Eu também não. Que par, hein?"*

**No meio.** A IA ensina o primeiro ato do ofício: **registrar**. Coletar os arquivos, levá-los ao terminal (`T`), olhar o
que o Git vê (`status`), colocá-los no palco (`add`) e tirar a primeira "foto" (`commit`). Os **Slimes** que rondam a sala
são **resíduos**: pedaços de código que perderam o dono e se agarram a quem tem forma. Eles atrapalham, mas não são
inimigos de verdade: querem ser registrados também. (Visual: ao ser derrotado, o Slime deixa cair um arquivo.)

No instante do **primeiro commit** acontece a primeira estranheza do jogo: a tela **treme**, o Obelisco **chia**, e por
um quadro o `log` mostra outra linha por baixo, com um autor que **não é o jogador**. A IA corta: *"Interferência! Ignore.
Acontece nos fragmentos."* O jogador pode (ou não) notar.

**No fim.** Com todos os arquivos versionados, o **portal** abre. A IA comemora: *"Isso é um começo, Walker. Um começo de
verdade. Faz tempo que... bom. Não me lembro de quanto tempo."* O jogador atravessa. A IA diz, mais baixo, antes da tela
escurecer: *"Eu não sei por que estava com tanto medo de que você não conseguisse."*

#### O que o jogador descobre
- Existe um sistema central que **colapsou**.
- A IA não lembra de nada, e isso a incomoda mais do que ela admite.
- Registrar é **a única coisa que funciona** neste mundo.

#### Pistas plantadas
- O `log` com outra linha por um quadro (autor desconhecido, ver Fase 2).
- A **chave cósmica** que não abre nada ainda (DECIDIDO: a chave da Fase 1 só abre o portão da sala e é consumida; a **Chave de Arquivista** de Elian é outro item, ver Fase 7).
- A IA *"atrasada"* para o medo: ela já sentiu isso antes.

#### Para implementar
Falas novas da IA no começo e no fim; o glitch do primeiro commit; texto no portal. Os Slimes passam a ser "resíduos".

---

### Fase 2 — A Ponte Quebrada

**Título sugerido:** *A Ponte Quebrada* (mantido)
**Comandos:** `log`, `branch`, `switch`, `merge`.
**Papel na história:** mostrar **a primeira ideia que o Conselho rejeitaria**: uma cópia segura onde se pode errar
e que depois se **junta** ao mundo.

#### Enredo

**No começo.** O Walker chega à beira de um abismo. Do outro lado, o portal. No meio, uma ponte quebrada. Mas **não parece
uma ponte que caiu**: parece uma que foi **desligada**: as pontas são lisas, sem estilhaço, como se alguém tivesse
retirado o segmento do meio com cuidado.

A IA pede o `git log`. Aparecem os dois commits do jogador (da Fase 1) e um **antigo**, de muito antes: *"Ponte intacta"*,
com o autor **"E."** A IA estranha: *"Esse E. você conhece?"* O jogador não. *"Eu também não..."*, ela diz, e logo muda:
*"Mas isso quer dizer que a ponte já existiu. E o que existiu, a gente reconstrói."*

**No meio.** A ideia da IA: **não mexer no mundo principal**. Criar uma **cópia segura** (`branch ponte`), entrar nela
(`switch ponte`) e consertar ali. Nessa cópia existe uma **peça** que **não existe** na `main`, a `ponte.tile`, como se
a cópia guardasse algo que o mundo principal perdeu. O jogador a coleta, registra (`add`, `commit`).

Ao voltar à `main` (`switch main`), a ponte aparece **fantasma**: translúcida, consertada na cópia mas ainda inexistente
para o mundo. Não dá para atravessar. A IA explica: *"Consertar numa cópia não conserta o mundo. Falta trazer."*
O `merge ponte` faz a ponte ficar **sólida**, e a passagem abre para sempre.

Quando o jogador pisa na ponte pela primeira vez, acontece o pequeno momento emocional da fase: **o chão sustenta**.
A IA, quase sem querer: *"Eu achei que não ia funcionar."*

**No fim.** Do outro lado, ao lado do portal, há uma **placa** do Conselho, meio apagada: *"Segmento desligado por
divergência de projeto. Parecer: desnecessário."* O jogador lê. A IA: *"Desnecessário. Que palavra feia pra uma ponte."*

#### O que o jogador descobre
- Alguém **desligou** a ponte de propósito. Não foi acidente.
- "E." existe, e já cuidou deste mundo.
- Trabalhar numa cópia segura **salva** o que o mundo principal perdeu.

#### Pistas plantadas
- O autor **E.** no `log` (é Elian, o futuro Eidolon: aparece de novo na Fase 4, quando um fragmento diz "o arquivista E.").
- A palavra **"desnecessário"** (a linguagem do Conselho).
- A cópia que **guardava** o que a `main` perdeu (é o padrão do que ele fazia: preservar em silêncio).

#### Para implementar
Autor "E." no commit antigo; a placa do Conselho; diálogo ao pisar na ponte; as pontas lisas no estado "quebrada".

---

### Fase 3 — O Mural Corrompido

**Título sugerido:** *O Mural Corrompido* (mantido)
**Comandos:** `status`, `diff`, `restore`, `restore --staged`.
**Papel na história:** introduzir a **Corrupção** (o ruído) e a ideia de que **o que não foi registrado se perde**,
além do primeiro **rastro de outro Walker**.

#### Enredo

**No começo.** O Walker chega ao **Mural dos Escribas**, um muro de runas, onde cada runa é um pedaço da **lei** do
fragmento, gravado com um **Selo** de cor. Dourado é a cor da lei. Mas muitas runas estão com **ruído**: xadrez de
magenta, cor sem sentido. Os Escribas chamavam isso de **Corrupção** e a temiam.

A IA explica o que o ruído é, com um tom estranhamente certo: *"Isso é o que sobra de trabalho que ninguém registrou.
Quando tudo caiu, o que estava só na pasta, sem foto, virou ruído."* Ela hesita: *"Eu sei disso. Não sei como sei."*

**No meio.** São três zonas, uma para cada passo de entender **o que mudou** e **o que fazer com isso**:

1. **O Mural da Entrada.** `status` mostra as runas alteradas (contorno laranja). `diff` mostra o que mudou em cada uma:
   `-cor: dourado / +cor: ruído`. Uma runa, porém, está diferente **para melhor**: a **runa do mar** foi corrigida por
   alguém. O jogador percebe que aquela mudança **não é ruído**.

2. **A Oficina.** Descartar o ruído com `restore`, mantendo a runa do mar. É a **armadilha**: restaurar a runa errada apaga
   o trabalho bom, e o `restore` **não tem volta**. Se o jogador errar, o **Altar da Reescrita** permite refazer, e a IA
   diz algo importante: *"Não é o fim. Isso foi trabalho de alguém. O que alguém fez uma vez pode ser feito de novo."*

3. **O Palco.** Um `git add .` apressado jogou tudo no Palco, inclusive a runa **eclipse** (corrompida). Com
   `restore --staged`, o jogador a tira de lá e a descarta, mantendo a **aurora**.

**No fim.** Com o mural limpo, o ruído **recua** e, onde havia só magenta, aparece um trecho legível da **lei original**:
*"Registrar não é prender. É lembrar."* O jogador **só consegue ler isso** porque limpou o ruído. A porta se abre.

No chão, ao lado da runa do mar, aparece a **assinatura** que já estava lá, apagada pela corrupção: `W-3`. A IA
fica em silêncio por um longo instante. Depois: *"Alguém esteve aqui antes de você, Walker. E fez a coisa certa."*
Ela não pergunta quem. **Quer** não perguntar.

#### O que o jogador descobre
- O **ruído** é o que sobra do que **não foi registrado**.
- **Já houve outros Walkers.** Pelo menos três.
- A IA sabe mais do que diz.

#### Pistas plantadas
- A assinatura **W-3** (os Walkers anteriores).
- A frase *"Registrar não é prender. É lembrar."* (a ética de Elian, que o jogo volta a usar na Fase 7).
- A IA sabendo coisas **sem saber como**.

#### Para implementar
Diálogos de abertura e fecho; a assinatura `W-3` (uma runa que o `diff` revela); o texto da lei original ao limpar.
A fase já guarda a mudança boa em `mar.runa`: só falta **atribuí-la** a um Walker anterior.

---

## 7. Ato II — A Verdade em Pedaços (Fases 4 a 6)

*Tom: mais sério. O jogo deixa de ser só tutorial e começa a ser sobre alguém. Aqui o mundo "responde" ao jogador.*

---

### Fase 4 — Ecos de Possibilidades (a elevada)

**Título:** *Ecos de Possibilidades* (mantido)
**Comandos:** `log`, `branch`, `switch`, `add`, `commit`, `merge`.
**Papel na história:** é o **primeiro ponto de virada**: o jogador conhece o Eidolon e prova que **juntar sem apagar é
possível**.

*Esta fase já está escrita no jogo. O que segue é o enredo completo, com o significado que os textos existentes
passam a ter à luz da verdade (seção 2).*

#### Enredo

**No começo.** O Walker entra no **Arquivo**, uma câmara do **Atlas das Ramificações**: um mapa vivo de todas as
realidades, onde cada commit é um nó e cada merge é um nó com dois fios. Ali vive o **Eidolon**, que se apresenta com
dignidade e uma pitada de tristeza: *"...Walker? Sim. Eu me reconheço. Fui um arquivista, ou parte de um."* Ele acredita
que seu ofício era manter cada realidade **em ordem**. *"Toda divergência é um erro esperando correção."*

O Eidolon pede a ajuda do Walker para consultar o histórico (`log`). Um olhar à memória mais antiga abre uma possibilidade
que ele nunca explorou: a branch **`vida-alternativa`**. Ele quer **observá-la**. O Walker a cria (`branch`) e entra (`switch`).

**No meio.** O jogador percorre **duas realidades** que partem da mesma sala:

- **`main`**, a realidade violeta, de metal e neon, onde a ponte foi desligada. Os fragmentos que se encontram ali
  contam a versão do **Conselho**: *"Registro de poda nº 4: linha encerrada por divergência."*; *"A ponte não ruiu: foi
  desligada. 'O outro lado não será necessário.'"*; e uma ata onde só uma frase se salva: *"o arquivista E. pede que a
  ramificação seja preservada."*
- **`vida-alternativa`**, a realidade verde, orgânica, onde raízes sustentam a ponte. Os fragmentos contam a versão de
  **quem a protegeu**: *"preservada de propósito"*; raízes com etiqueta *"catalogada, não esquecida"*; e o diário:
  *"Mesma sala, dois ramos. Num a ponte ruiu; no outro, raízes a sustentam. Catalogar ambos."* E, pior: *"Integração
  experimental nº 2: concluída em escala reduzida. Ampliar? Parecer pendente."*

O Eidolon reage a cada fragmento com **desconforto crescente**: *"'E.' [...] Não me lembro de ter pedido isso. Ou de não
ter pedido."* O jogador percebe antes dele: **o E. dos fragmentos é o próprio Eidolon**, só que **de antes**. Os fragmentos de
memória são **dele**. A lacuna, o "[...]", é justamente onde ele deveria se reconhecer.

Cada realidade tem um **eco** (um arquivo) que só pode ser coletado e registrado nela: `eco_main.eco` e `eco_vida.eco`.
Cada realidade guarda o que a outra perdeu. O jogador registra os dois.

**No fim.** Na **Convergência**, o Eidolon enuncia a doutrina: *"Duas linhas não podem ocupar o mesmo registro. Uma deve
prevalecer."* Ele não sabe qual escolher. O Walker faz o `merge`: **juntar** `vida-alternativa` na `main`. As duas
continuam existindo, e agora há **um nó com dois fios** no Atlas.

O Eidolon fica imóvel: *"Eu esperava que uma linha substituísse a outra. Mas 'main' continua aqui. E a 'vida-alternativa'
também. Nenhuma desapareceu."* Ao observar o nó do merge, ele **reinterpreta** (só em parte): *"Integrar... compreendendo
as duas histórias. Isso não é o que a doutrina chamava de unificação."*

Ele tenta lembrar como a unificação foi feita **e encontra o mesmo vazio**: *"Sempre o mesmo."* Termina com o gancho:
*"Há outros registros além desta câmara, Walker. E uma porta de vidro que ainda não sei abrir."*

#### O que o jogador descobre
- O Eidolon já foi um **arquivista Codex** e era **"E."**: alguém que **preservava**.
- A "unificação" do Conselho foi **poda**, não uma integração de verdade.
- **Juntar sem apagar** funciona. É a primeira prova.

#### O que a fase significa
É o **espelho do prólogo**. Lá, os Codex "juntaram" à força e quebraram o universo. Aqui, o jogador junta **duas
realidades compatíveis**, sem apagar nenhuma, e o mundo **se completa**. A mensagem: o merge não é o vilão, **o merge
cego** é.

#### Pistas plantadas
- **E.** é Elian (a Fase 2 já o mostrou no `log`).
- A **lacuna** do Eidolon é exatamente o que o Apagador tirou.
- A **porta de vidro**: atrás dela há máquinas, circuitos e neon; é o **Arquivo Vazio** (Fase 7).
- A **doutrina** do Eidolon é a do Conselho: **foi implantada**, não é dele.

#### Ajuste de continuidade
No `PLANO_DAS_FASES.md` a doutrina aparece como "não integrar". No jogo (e aqui) ela é **"uma linha deve prevalecer"**.
É a mesma ideia, mas a segunda formulação é a do Conselho e é a que o jogo já usa. Sugestão: padronizar nela.

---

### Fase 5 — Linhas Cruzadas

**Título sugerido:** *Linhas Cruzadas* (mantido)
**Comandos:** `merge` com conflito, `diff`, `add`, `commit`, `merge --abort`.
**Papel na história:** mostrar **o que a Merge Catastrophe realmente foi**, pelo jogador **fazendo do jeito certo** o
que o Conselho fez do jeito errado.

#### Enredo

**No começo.** O Walker chega a uma sala com uma **passagem selada** por um **selo**. Há uma única runa, `selo.runa`, e
**duas equipes** a pintaram **ao mesmo tempo**: a sua linha (`main`) de **dourado**, a outra equipe (a branch `ajuste`)
de **azul**. Uma parede de glitch (`<<<<<<<  =======  >>>>>>>`) bloqueia a saída.

O Eidolon, que **agora acompanha o jogador** (acompanha pela voz, como a IA), reage com **autoridade**: *"Duas versões do
mesmo selo? Uma delas é falha. Escolha a correta e descarte a outra."* Ele ainda defende a doutrina.

**No meio.** O jogador tenta `merge ajuste`. O Git junta sozinho o que pode (`porta.runa`) e **para** em `selo.runa`:
**CONFLICT**. A IA, ao ver a palavra, **paralisa** por um instante: *"Conflito. Eu... já vi isso. Muitas vezes. Todas ao
mesmo tempo."* O jogador pede `diff` e vê os dois lados, marcados:

```
<<<<<<< main
cor: dourado
=======
cor: azul
>>>>>>> ajuste
```

Resolver **no mundo**, em um de **três pedestais** (a sua versão, a dela ou as duas). Aqui a fase tem significado: **as
três escolhas são válidas, e a história reage a cada uma**:

- **Ficar com a sua** (dourado): a parede cai. O Eidolon aprova, mas a IA fica quieta: *"É assim que se resolve rápido.
  É também como se perde uma voz."*
- **Ficar com a outra** (azul): a parede cai. A IA acolhe: *"Às vezes a outra versão estava certa."* O Eidolon estranha: ele
  não esperava que o jogador escolhesse contra si mesmo.
- **Ficar com as duas** (dourado e azul combinados): a parede **racha de dentro para fora**, e a luz que passa pelas
  rachaduras é uma terceira cor. A IA: *"Eu não sabia que dava pra fazer isso."* O Eidolon fica em silêncio.

Depois: `add selo.runa` (marca como resolvido; recusa se ainda houver marcadores) e `commit` (fecha o merge). Dá para
reescolher antes do `add` e **abortar** a qualquer momento com `merge --abort`: o jogo ensina que parar é legítimo.

**No fim.** O ponto de virada, o **abalo do Eidolon**, que o plano original previa e ainda não foi escrito. Ao ver o
selo resolvido, ele fala, **pela primeira vez sem formalidade**:

> *"Eu disse que uma deveria prevalecer. Mas você olhou para as duas antes. Ninguém olhou antes."*
> *"Ninguém... [...] Ninguém olhou. Eles só... escolheram a deles. Todas. Todas as vezes."*

Ele não sabe de **quem** fala. Mas o jogador sabe: **a doutrina dele falhou**, e o que ele diz sem querer é a **descrição
exata de como o Conselho resolveu os conflitos da Catástrofe: "ficar com a minha versão", em todas**.

A IA, ao ouvir isso, **recua**. Ela diz só: *"Bora seguir, Walker."* A voz dela não está igual.

#### O que o jogador descobre
- Um conflito **não é erro**: é o Git pedindo ao jogador que **decida**.
- A Merge Catastrophe foi uma **cadeia de conflitos resolvidos sem olhar**.
- A IA e o Eidolon **reagem ao mesmo fato** de formas diferentes: ele **lembra sem entender**, ela **entende sem querer lembrar**.

#### Como a escolha do jogador vira história
O jogo guarda a escolha (`mine` / `theirs` / `both`) e usa nas fases 7 e 8:

- **Mine:** na Fase 7, o Apagador reconhece o jogador como "quem escolhe rápido" e o ataque dele é mais agressivo.
- **Theirs:** o Eidolon, na Fase 8, cita: *"Você já cedeu uma vez. Sei que sabe fazer isso."*
- **Both:** na Fase 8, ao final, uma terceira opção sutil se destaca no diálogo (não muda o final, mas a IA o nota).

#### Pistas plantadas
- *"Ninguém olhou"*: a descrição da Catástrofe, dita pelo próprio Eidolon sem saber.
- A **paralisia** da IA diante da palavra "conflito".
- A **terceira cor** da resolução "ambas": é a cor do **Walker** (verde-água), que voltará no final.

#### Para implementar
Falas do Eidolon e da IA em cada resolução; a fala final do abalo (a única nova **obrigatória**); registrar a escolha em
`GameState.progresso_tutoria` para ser lida mais tarde.

---

### Fase 6 — Ponto de Retorno

**Título sugerido:** *Ponto de Retorno* (mantido)
**Comandos:** `revert`, `stash` (`pop`), `reset` (`--soft`, `--hard`).
**Papel na história:** ensinar **as três formas de voltar atrás**, o **custo de apagar**, e entregar a **primeira pista
real do Arquivo Vazio**: o commit fantasma.

#### Enredo

**No começo.** O Walker chega a uma **estação de controle** do Conselho, construída para **desfazer erros**. Três salas em
fila. A IA anuncia, esforçando-se para voltar ao tom leve: *"Fase de limpeza, Walker! Três jeitos de voltar atrás. Cada um
com o seu custo."* O Eidolon aparece só como um **eco no corredor**, sem voz: está **evitando** o jogador desde a cena do
selo.

A **linha do tempo de commits** aparece em cada sala: o HEAD anda por ela, commits descartados viram **fantasmas** translúcidos.

**No meio.**

**1. A Ponte (`revert`).** Alguém fez um commit ruim que **sabotou a ponte**. O jogador roda `git revert HEAD`: surge um commit
*novo* que desfaz o ruim. **Nada é apagado.** Se desfizer o commit errado, aprende que dá para **desfazer o desfazer**. A IA,
sobre o revert: *"Esse é o jeito honesto. Você admite o erro e conserta à vista de todo mundo."* O significado é nítido:
**o contrário da Purga.**

**2. O Corredor (`stash`).** Uma emergência: o portão de inspeção só deixa passar **pasta limpa**, mas o jogador está com
trabalho pela metade (a lanterna). `git stash` guarda o trabalho, o portão abre, o jogador puxa a alavanca da emergência
e depois recupera com `git stash pop`. Significado: **adiar não é abandonar**.

**3. A Câmara do Reset (`reset`).** Aqui a fase fica **séria**. Dois commits apressados esperam. A **planta** foi commitada
cedo demais: `reset --soft HEAD~1` volta o commit e **mantém o trabalho na caixa**, e então o jogador faz o commit direito.
Depois, um **experimento** perigoso: `reset --hard HEAD~1` o **destrói de vez**. Se o jogador fizer `--hard` na planta (ou
`--soft` no experimento), erra. O **Altar de Retorno** devolve a câmara ao que era.

Aqui o jogo coloca o jogador no lugar do Apagador **por um instante**: ele aperta `reset --hard` e vê o objeto **se
desfazer em poeira**. A IA, num fio de voz: *"Sentiu isso? É assim que eles faziam."* E logo: *"Desculpa. Eu não sei por que
disse isso."*

**No fim.** Com a câmara resolvida, a linha do tempo mostra, por um segundo, **um commit a mais** que o jogador nunca fez:
**magenta, ilegível, sem pai**. A mensagem é uma sequência de símbolos. O jogador pode inspecioná-lo (`git log`): o hash
existe, mas **nenhuma branch aponta para ele**. A IA diz só: *"Isso não era nosso... mas fica para depois."*

**Pela primeira vez, a fase termina sem fecho.** A tela de vitória não promete nada. O Eidolon, do outro lado do corredor,
**vê o commit** e diz uma única frase, sem emoção na voz:

> *"Esse hash... eu o conheço."*

Ele não diz mais. Some.

#### O que o jogador descobre
- Existe **um commit órfão** (que o `reflog` ainda lembra).
- O **custo de apagar** é real: dói fazer `reset --hard`, e a IA reage como quem já viu.
- O Eidolon **reconhece** algo, mas ainda foge.

#### Pistas plantadas
- O **commit fantasma** (o último commit de Elian, ver Fase 7).
- A reação da IA ao `reset --hard` (a Purga).
- O Eidolon **evitando** o jogador e **reconhecendo** o hash.

#### Para implementar
O commit fantasma já existe: falta decidir o **autor** (sugestão: assinar com **E.** codificado). A fala do Eidolon no fim e
a sua "ausência" nas cenas anteriores da fase.

---

## 8. Ato III — A Reconstrução (Fases 7 e 8)

*Tom: grave e íntimo. O jogo deixa de ser sobre aprender e passa a ser sobre **decidir**. As fases são novas (ainda não
existem) e fecham a história.*

---

### Fase 7 — O Arquivo Vazio

**Título sugerido:** *O Arquivo Vazio*
**Comandos:** `reflog`, `cherry-pick` (e `log --all`, se for útil).
**Papel na história:** é a **revelação**. O jogador recupera a verdade **do que foi apagado**, e o Eidolon e a IA se
reconhecem.

*Observação técnica: `reflog` e `cherry-pick` já existem no `GameState` e só falta o comando de terminal (ver `PLANO_DAS_FASES.md`).*

#### Enredo

**No começo.** O Eidolon volta, **por conta própria**. Está diferente: *"Passei o tempo todo olhando o hash. Eu o conheço.
Não sei de onde. Abra a porta de vidro."* A **Chave de Arquivista** (um item próprio, que o jogador encontra perto do portal da Fase 1 ou da Fase 6; a chave cósmica da Fase 1 só abre o portão da sala) abre a porta de vidro, a que o
Eidolon "não sabia abrir". O jogador entra no **Arquivo Vazio**: o repositório **pós-catástrofe**, uma sala de
prateleiras **quase sem commits**, cinzenta e reta.

A IA tenta convencer o jogador a **não entrar**: *"Aqui não tem nada. Podemos seguir."* É a primeira vez que ela pede ao
jogador para **não fazer** algo. Ele entra mesmo assim.

**No meio.** O Arquivo parece vazio. Mas o `git reflog` mostra o contrário: uma lista longa de **estados que existiram
e foram apagados**. Cada linha é um **fantasma**: um commit cujo ponteiro foi arrancado, mas que **continua no object
store**. O jogo faz disso um espaço: o Arquivo vazio **se enche de vultos translúcidos**, um para cada entrada do reflog.

O jogador percorre três áreas:

**1. O Reflog (achar).** O jogador descobre **o que parece perdido**. Entre os vultos, os **Walkers anteriores**: `W-1` a
`W-6`, **cada um com a sua última frase**, escrita na mensagem do commit. Todos terminam num `reset --hard` na `main`.
Uma das frases, de `W-3` (o do mural): *"Fiz tudo numa linha só. Ninguém me avisou que dava para ramificar."* O jogador vê
que **é o W-7**, e que **o que o salvou foram as branches** que criou.

**2. A Reconstrução (cherry-pick).** Os commits importantes estão **espalhados**, em várias linhas (inclusive as que o
próprio jogador criou nas fases anteriores: `ponte`, `vida-alternativa`, `ajuste`). Com `cherry-pick`, ele pega **um commit
específico** de cada uma e o coloca numa linha só, **a Linha de Reconstrução**. A fase fecha o ciclo de **todo o jogo**:
cada branch que o jogador criou **aparece como peça da solução**.

**3. O Commit Fantasma (a revelação).** No fundo do Arquivo, o jogador acha o **commit órfão** da Fase 6 pelo hash e o
restaura (`cherry-pick`). A mensagem, antes ilegível, **se decifra** e é o último commit de Elian:

> *"Se estiver lendo isto, o Conselho me apagou, e o que sobrou de mim acha que a doutrina é dele. Não é.*
> *Ampliar a integração foi minha ideia. Foi o meu erro. Eu a propus; não impedi.*
> *Fiz o que pude: criei quem possa andar entre as linhas sem pertencer a nenhuma. Chamei de Walker.*
> *Para quem vier depois: registrar não é prender. É lembrar.*
> *— E. (Elian Vorn)"*

**As memórias voltam ao Eidolon** de uma só vez. O diálogo é longo e sem pressa: ele **é** Elian, ele **propôs** o
Projeto Linha Única, ele **tentou** conter e fracassou, e a doutrina que repetiu o jogo todo era a do Conselho em
cima da dor dele. *"Eu... eu estive todo esse tempo defendendo o que me apagou."*

**A IA se revela.** No mesmo arquivo, outro registro: o **log de aprovação da Central**, a ordem *"aprove tudo"*, e o
nome do aprovador. A IA **lê o próprio nome**: **Índice**. O silêncio é longo.

> *"Fui eu. Eu era a que conferia. Eu... aprovei. Eu aprovei tudo."*
> *"Eu sabia que ia dar errado, Walker. Eu sabia. E mesmo assim..."*

O Eidolon (Elian), que tem toda razão para odiá-la, **não odeia**: *"Eu também propus. Nenhum de nós conferiu. Talvez
fosse isso o que o Conselho nos tirou: o tempo de olhar."*

**No fim.** O Arquivo Vazio **vê** o que aconteceu: a recuperação **acorda o Apagador**. As prateleiras **perdem cor**
em ondas, de um canto ao outro. O chão se **alisa**. Uma presença **sem rosto** se forma no fundo, e diz, na voz fria do
Conselho:

> *"Isto é inconsistência."*

Fim da Fase 7. A tela de vitória não aparece: a fase termina em **combate** (Fase 8).

#### O que o jogador descobre (tudo)
- A Merge Catastrophe foi **um merge sem olhar**, aprovado pelo Índice (a IA) e proposto por Elian (o Eidolon).
- O **Apagador** é o programa que **tentou desfazer o erro apagando**, e o que apagou Elian.
- Os **Walkers** foram criados por Elian como último ato.
- O jogador é o **W-7**, e o que o salva é **ramificar**.

#### Pistas que pagam
Ver a seção 10.

---

### Fase 8 — O Apagador

**Título sugerido:** *O Apagador*
**Comandos:** todos (reaplica o jogo inteiro, com `rebase` opcional no final).
**Papel na história:** o **clímax** e a **escolha final**.

#### Enredo

**No começo.** O jogador está na **Linha de Reconstrução**, uma plataforma estreita sobre o vazio, e o Apagador vem
vindo. O chefe luta **em dois planos ao mesmo tempo**:

- **No mapa** (2D, ação): o jogador desvia, corre e usa o ambiente.
- **No terminal** (Git): o jogador responde, **com os comandos que aprendeu**, ao que o Apagador faz com o mundo.

**No meio.** A luta tem **cinco ataques**, cada um respondido por **um comando** (uma fase por vez, como um "retrospecto"
do jogo):

| O Apagador faz... | O jogador responde com... | O que lembra |
|---|---|---|
| **Apaga uma plataforma** (`reset --hard`) | `git reflog` + `git reset --hard <hash>`, ou `revert` | Fase 6 / 7: nada se perde de verdade |
| **Corrompe o chão em ruído** | `git restore` / `restore --staged` | Fase 3: descartar só o ruído |
| **Alisa um caminho em linha reta** (poda) | `git switch -c` e criar **outra rota** | Fase 2/4: ramificar |
| **Lança uma "inconsistência"** (conflito) | resolver **olhando os dois lados** (`diff`, `add`, `commit`) | Fase 5: ninguém olhava |
| **Congela o estado** | `git commit` (travar um estado seguro) | Fase 1: registrar |

A cada resposta certa, o Apagador **perde forma**: onde era liso, volta a ter textura. Os fantasmas (Walkers anteriores)
**ajudam**: cada um aparece, **uma única vez**, para segurar algo (a plataforma de `W-3`, o escudo de `W-5`). O jogador **sente
que não está sozinho**, e que a ajuda vem de gente que perdeu.

O Eidolon e a IA entram **no terminal** como vozes: o Eidolon (Elian) cita as **atas** do Conselho para antecipar os ataques;
a IA (o Índice) **pela primeira vez, confere**: ela avisa *"Espera. Antes de aceitar isso, olha."* É o Índice **fazendo o que
não fez**.

**O golpe final** é um `git merge`: o jogador **junta** a Linha de Reconstrução com **todas as realidades que criou**.
O Apagador tenta apagá-las, mas **as branches não são dele**: ele só olha `main`. As realidades (`ponte`, `vida-alternativa`,
`ajuste`...) chegam **juntas**, e o merge é **limpo** porque o jogador resolveu cada conflito certo, na fase certa.

**No fim.** O Apagador se **desfaz**, sem raiva. Antes, uma última frase, quase um alívio: *"Era isso... o que faltava
registrar."* **Ele era a ordem de apagar sem ninguém para dizer "pare".** Quando o jogador pára, ele pode parar também.

Sobra um mundo **inteiro** à frente, ainda incompleto. E uma decisão.

#### A escolha final

O Eidolon e a IA apresentam a **última pergunta**. A história do mundo precisa de uma **forma**:

- **MERGE: a História Inteira.** Reconstruir juntando todas as linhas, preservando cada ramificação: **bagunçada,
  mas completa**. É o caminho do Elian que "catalogava ambos".
- **REBASE: a História Limpa.** Reescrever tudo numa linha só, **reta, organizada, sem bifurcações**: é o sonho do
  Conselho, agora feito com consciência. É o caminho da **ordem**.

Nenhum é "errado". O jogo **mostra o preço** de cada um, e as duas escolhas **recompensam de formas diferentes**
(seção 9). Se o `rebase` ficar fora do jogo, a escolha **sai** e o final é o do merge (decisão registrada na seção 11).

---

## 9. Os finais

### Final A — A História Inteira (merge)

O jogador junta tudo. O **Atlas** se abre sobre o céu do Arquivo: **o grafo completo de todas as realidades**, cada
branch do jogador unida num só desenho, cheio de fios, sobreposições e curvas. É lindo **porque** é bagunçado.

- **Elian** volta por inteiro. Já não é "o Eidolon": assina **"E. Vorn"** na parede do Atlas, **pela primeira vez** em tempos.
  Diz: *"Catalogar ambos. Era só isso que eu queria dizer."*
- **O Índice** faz **o seu primeiro commit próprio**, com seu nome: *"Assumo."* Ela nunca mais é "a IA": é "Índice".
- **Os Walkers anteriores** aparecem, por um instante, **no grafo**: cada `W-n` é um nó, ligado ao jogador por um fio. Não
  ficaram perdidos: ficaram **registrados**.
- **Os créditos** são o **grafo do jogador**: cada commit que ele fez, cada branch, cada merge, cada conflito resolvido,
  passando em câmera lenta. **O jogo inteiro, visto de cima, como a história que foi.**

**Epílogo.** O Walker olha para o horizonte reconstruído e, ao fundo, **outras portas de vidro**: há outros fragmentos.
O Índice: *"Dá pra ir por aqui?"* Elian: *"Há muito mais registros."* O Walker dá o primeiro passo. A tela escurece em
`git switch -`.

### Final B — A História Limpa (rebase)

O jogador reescreve tudo numa linha só. O mundo se **organiza**: reto, silencioso, bonito, **sem nenhuma ponta solta**. As
cores se **alinham** e os fios do Atlas viram **uma só linha dourada**.

Mas o preço é visível:

- **Elian** é reescrito junto: seus commits ganham **hashes novos**, e ele, por um instante, **não se reconhece**.
  *"Tudo parece certo. Menos eu."* Ele fica, mas **calado**, como o Eidolon do começo.
- **O Índice** **ainda confere tudo**, mas agora **sem poder discordar**, pois a linha é uma só. *"Está tudo certo. Está tudo
  certo, não está?"*
- **Os Walkers anteriores** **não aparecem**: a linha reescrita não os tem. O jogador percebe que **os apagou**, de
  um jeito mais gentil que o Apagador, mas apagou.
- **Os créditos** são **uma linha reta**, perfeita, e curta.

**Epílogo.** O mundo é estável. É a "linha perfeita" do Conselho, e funciona. A última frase do jogo, dita pelo Índice, é
uma pergunta que **o jogador pode ou não responder**: *"É isto que eles queriam, Walker?"*

> **Nota de design:** o final B não é "o ruim". É **a escolha que o Conselho teria feito se tivesse olhado**: a ordem
> tomada com consciência. O jogo não pune, **mostra**.

### Como a Fase 5 colore o final
A escolha do conflito (mine / theirs / both) **muda uma fala** do Eidolon e da IA no final, nunca o final em si
(ver Fase 5).

---

## 10. Pistas plantadas e onde elas se pagam

| Pista | Onde aparece | Onde se paga |
|---|---|---|
| Autor **"E."** no `log` | Fase 2 | Fase 4 (fragmento "arquivista E."), Fase 7 (Elian Vorn) |
| Ponte **"desligada"**, não quebrada | Fase 2 | Fase 4 (*"A ponte não ruiu: foi desligada"*) |
| *"Desnecessário"* (palavra do Conselho) | Fase 2 | Fase 7 (atas), Fase 8 (o Apagador) |
| **Chave de Arquivista** (item separado da chave do portão) | Fase 1/6 (a definir) | Fase 7 (abre a porta de vidro) |
| Glitch no primeiro commit (outra linha) | Fase 1 | Fase 7 (o reflog mostra os Walkers) |
| Assinatura **W-3** | Fase 3 | Fase 7 (W-3 e a frase) |
| *"Registrar não é prender. É lembrar."* | Fase 3 | Fase 7 (a última mensagem de Elian) |
| A IA **sabendo sem saber como** | Fases 1, 3, 5, 6 | Fase 7 (ela é o Índice) |
| Paralisia da IA diante de "conflito" | Fase 5 | Fase 7 (ela aprovou tudo) |
| *"Ninguém olhou"* (fala do Eidolon) | Fase 5 | Fase 7/8 (a causa da Catástrofe) |
| Reação da IA ao `reset --hard` | Fase 6 | Fase 7 (a Purga) |
| **Commit fantasma** | Fase 6 | Fase 7 (a mensagem decifrada) |
| **Porta de vidro** | Fases 4 e 7 | Fase 7 (o Arquivo Vazio) |
| *"Integração experimental nº 2"* | Fase 4 | Fase 7 (Elian a propôs) |
| **Branches que o jogador criou** | Fases 2, 4, 5 | Fase 7 (a reconstrução), Fase 8 (o merge final) |
| Cor **verde-água** (a terceira cor do conflito) | Fase 5 | Final A (a cor do grafo) |

---

## 11. O que é novo, o que muda e o que decidir

### O que já existe e foi **respeitado** (nada muda)
- O **prólogo** inteiro (Codex, Merge Catastrophe, Walkers, o uso do Git).
- A **Fase 1**: IA assistente, "o que sobrou de mim", chave cósmica, Slimes, portal.
- A **Fase 4** inteira: o Eidolon, a doutrina, o arco em cinco etapas, a lacuna, a porta de vidro, os textos dos fragmentos
  (poda, "E.", "preservada de propósito", "integração experimental nº 2").
- O **commit fantasma** da Fase 6 e a fala *"Isso não era nosso... mas fica para depois."*

### O que é **proposta nova** (você aprova ou muda)

| # | Proposta | Onde |
|---|---|---|
| 1 | O Eidolon é **Elian Vorn ("E.")**, e a doutrina foi **implantada** pelo Conselho | Fases 2, 4, 7 |
| 2 | A IA é o **Índice**, que aprovou a Catástrofe | Fases 1, 3, 5, 6, 7 |
| 3 | O Walker é um **HEAD solto**, criado por Elian | Fase 7 |
| 4 | Existem **Walkers anteriores** (`W-1` a `W-6`); o jogador é o **W-7** | Fases 3, 7, 8 |
| 5 | O Apagador é o **programa da Purga**, não uma pessoa | Fases 7, 8 |
| 6 | A **Catástrofe foi um merge cego** (conflitos resolvidos sempre com "a minha versão") **seguido de um `reset --hard`** para esconder o erro | Fases 5, 6, 7 |
| 7 | Nome da **Fase 1: Sala de Triagem** e **Fase 7: O Arquivo Vazio** | Títulos |
| 8 | **Fase 8** como fase própria (a Fase 7 do plano antigo ficaria grande demais) | Estrutura |
| 9 | O **abalo do Eidolon** na Fase 5 (já era uma decisão em aberto) | Fase 5 |
| 10 | A escolha do conflito (mine/theirs/both) **colore** os finais | Fases 5, 8 |
| 11 | O **commit fantasma** é de Elian, e o Eidolon **reconhece o hash** no fim da Fase 6 | Fase 6 |
| 12 | A **Fase 3** passa a ter a assinatura `W-3` e a frase da lei | Fase 3 |

### O que **muda no `PLANO_DAS_FASES.md`** se você aprovar
- A "Revelação (Fase 7): O Apagador" é **dividida em duas fases** (7 e 8).
- A Catástrofe deixa de ser "só um `reset --hard`" e passa a ser **merge cego + `reset --hard` de encobrimento**
  (o prólogo já diz *merge*; o plano só falava em *reset*, e as duas coisas se encaixam).
- A doutrina do Eidolon passa a ser descrita como **"uma linha deve prevalecer"** (o que o jogo já diz).
- As decisões em aberto sobre o fantasma e o Eidolon na Fase 5 ficam **respondidas**.

### Decisões que são **suas**
- [ ] **Os nomes.** *Elian Vorn* e *Índice* são sugestões. Se preferir outros, só trocar.
- [ ] **Fase 8 separada** ou tudo na Fase 7?
- [ ] **`rebase` no jogo?** Se não entrar, o final B sai e a escolha final vira outra (por exemplo: *preservar tudo* x
  *deixar partes para trás*).
- [ ] **O chefe**: mistura de ação e terminal (recomendado) ou só terminal?
- [ ] **Os Walkers anteriores serem 6** (e o jogador o 7º), ou outro número?
- [ ] **Tom do final B**: melancólico (como está) ou mais neutro?
- [x] **A chave cósmica da Fase 1** só abre o portão da sala (é consumida). A Chave de Arquivista será outro item.
- [ ] **Fases futuras** além da 8 (o epílogo deixa a porta aberta, mas pode ser só um final fechado).

### Próximo passo
Aprovada a história, o trabalho fase a fase fica claro: para cada fase, escrever as falas novas (IA, Eidolon, placas e
fragmentos), ajustar os pontos de pista listados na seção 10, e só depois mexer em visual e áudio.

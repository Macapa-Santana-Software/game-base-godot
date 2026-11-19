# Design das fases

Regras decididas:
- **Cada fase tem identidade visual própria** (paleta, tipo de cenário, forma dos elementos). Nenhuma fase repete a paleta de outra.
- **A HUD é a mesma em todas as fases** (quadro da IA recolhível, Manual, inventário, corações, terminal, menus): mesma estrutura,
  posições e tema (o estilo dos painéis da Fase 4). Só o cenário muda.

## Identidades (visão geral)
| Fase | Identidade | Cores de significado reservadas |
|---|---|---|
| 1 — Sala de Triagem | Santuário azul-marinho, ciano e violeta (`tema_santuario`) | ciano (cristais), violeta |
| 2 — A Ponte Quebrada | Cânion de brasa (vermelho-terra, cobre) | brasa (a ponte acesa) |
| 3 — O Mural Corrompido | Pedra clara e ouro | magenta = ruído; laranja/azul/verde = Oficina/Palco/Arquivo |
| 4 — Ecos de Possibilidades | `main` violeta x `vida-alternativa` verde, neutro azul-marinho no Atlas | violeta, verde, ciano |
| 5 — Linhas Cruzadas | Grafite neutro | dourado (sua linha), azul (a outra), magenta (glitch), verde-água ("ambas") |
| 6 — Ponto de Retorno | Concreto brutalista com sinalização amarelo-preto | ciano (revert/Eidolon), magenta (fantasma), vermelho (emergência) |
| 7 — O Arquivo Vazio | **a propor** (sugestão: papel e cinza quente, só os vultos têm cor) | ver `PLANO_FASES_7_8.md` §9 |
| 8 — O Apagador | **a propor** (sugestão: vazio escuro; as cores voltam uma a uma a cada ataque vencido) | ver `PLANO_FASES_7_8.md` §9 |

## Fase 2 — A Ponte Quebrada: **Cânion de brasa**
Um cânion profundo de rocha avermelhada. Sem roxo (a Fase 1 já é ciano/violeta) e sem amarelo-ouro (a Fase 3 é dourada).

**Paleta**
| Uso | Cor |
|---|---|
| Rocha escura (paredões, fundo) | `#2A1512` |
| Rocha clara (chão, margens) | `#5C2E22` |
| Cobre / ferrugem (detalhes, bordas) | `#B5532E` |
| Brasa (cristais, luz do abismo) | `#FF5A3C` |
| Brasa clara (brilho, ponte acesa) | `#FF9A6B` |
| Cinza-carvão (ponte desligada) | `#4A4343` |

**Cenário**
- Duas margens de pedra rachada com bordas de cristal vermelho-brasa; paredões altos dos lados.
- Abismo em degradê: preto no topo, brasa lá no fundo, com faíscas subindo devagar.
- Bandeiras rasgadas do Conselho nas margens (pista da história) e a placa perto do portal.

**A ponte (os 3 estados)**
- **Quebrada / desligada:** pontas lisas em cinza-carvão, sem estilhaço. Cristais apagados.
- **Fantasma (consertada só na branch):** placas hexagonais translúcidas, brilho fraco de brasa clara.
- **Sólida (merge feito):** placas acesas em brasa, que se encaixam uma a uma da margem esquerda para a direita (animação no merge).

**Som (depois):** vento grave de cânion, estalos de cristal, um zumbido ao ligar a ponte.

## Status: IMPLEMENTADO (arte em PNG, desenhada pixel a pixel na paleta acima)
A arte fica em `fases/fase_2/arte/` e é **gerada** por `tools/gerar_arte_fase_2.gd` (para ajustar uma cor ou um desenho, edite o
gerador e rode: `godot --headless --path . --script res://tools/gerar_arte_fase_2.gd`). O gerador também recolore o Obelisco, a plataforma
e o portal existentes para o tom de brasa.

| Arte | Arquivos |
|---|---|
| Chão, paredão, abismo (degradê pontilhado + silhuetas), beira do abismo com cristais | `piso_canion`, `parede_canion`, `abismo_canion`, `borda_canion` |
| Cristais, pedras, colunas (inteira e quebrada), rachadura de brasa | `cristal_a/b/c`, `pedras_1..3`, `coluna_canion`, `coluna_quebrada_canion`, `rachadura_brasa` |
| Bandeira do Conselho (4 quadros, ondula) | `bandeira_conselho` |
| Ponte: toco desligado, placa fantasma, placa acesa, trilhos | `ponte_toco`, `ponte_placa_fantasma`, `ponte_placa_acesa`, `ponte_trilho_*` |
| Peça `ponte.tile` (também no inventário) | `peca_ponte` |
| Obelisco, plataforma e portal em brasa | `obelisco_*_brasa`, `plataforma_terminal_brasa`, `portal_saida_brasa` |
| Brilho aditivo (cristais, abismo, placas) | `brilho_brasa` |

Código: `placas_ponte.gd` (`PlacasPonte`) monta as placas e faz `acender()` (uma a uma, da esquerda para a direita, no merge) e `apagar()`;
`ponte_tutorial.gd` só chama esses dois. `paleta_canion.gd` guarda as cores. As faíscas são um `CPUParticles2D` na cena.
Os tocos da ponte, o cenário e os adereços são nós normais na `fase_2.tscn` (editáveis no Inspetor).

## HUD
Segue o estilo da Fase 1: corações (canto superior esquerdo), aba do Manual (esquerda), quadro da IA verde (superior direito, com
"próximo passo" e "comandos") e inventário (embaixo, centro). Na Fase 2 o painel de objetivos foi retirado: o quadro da IA já diz o próximo passo,
como na Fase 1. Hoje só a Fase 4 tem painéis de Objetivos e Conceitos (recolhíveis).

Falta: áudio da fase (adiado para todas as fases).

## Fase 3 — O Mural Corrompido: **Pedra clara e ouro**
HUD igual à da Fase 1 (painel de objetivos retirado). O cenário é neutro e claro para as cores das runas se destacarem.
Cores **reservadas pela mecânica**: dourado, prata, azul, verde, roxo e vermelho = valor das runas; **magenta/preto (xadrez) = ruído da Corrupção**
(também a barreira das portas); laranja = Oficina, azul = Palco, verde = Arquivo.

| Uso | Cor |
|---|---|
| Calcário (lajes, paredão) | `#C9C3B4` · `#AAA597` · `#8E897C` · `#6E695C` · `#4A463E` |
| Ouro (filetes, frisos, candelabros) | `#B8913A` · `#E8B84A` · `#F7DB8A` |
| Tinta (contornos e textos) | `#2B2822` |

**Cenário:** lajes de calcário em fiadas, paredões com friso de runas douradas e cornija de ouro, selos dourados gravados sob cada Obelisco,
colunas (inteiras e quebradas) com faixa de ouro, candelabros com chama animada e pedras soltas. As portas são **barreiras de ruído** (glitch
magenta que pisca e se dissolve ao abrir). As zonas do Palco são faixas do chão com moldura colorida e cantos de ouro. Cada runa é um **tablete
de pedra** com moldura de ouro e um **glifo gravado** (sol, lua, estrela, terra, mar, fogo, vento, aurora, eclipse); o altar da reescrita tem uma
bacia dourada. Obelisco, plataforma e portal foram recoloridos para ouro.

**Arte:** `fases/fase_3/arte/`, gerada por `tools/gerar_arte_fase_3.gd` (`godot --headless --path . --script res://tools/gerar_arte_fase_3.gd`).

## Fase 5 — Linhas Cruzadas: **Grafite neutro**
Sala de metal escuro sem tom de cor, para as cores de **significado** brilharem: **dourado** (a sua linha), **azul** (a outra equipe), **magenta** (o glitch dos
marcadores) e **verde-água** (a resolução "ambas", a cor do Walker, que volta no final). Prata só em filetes e detalhes.

| Uso | Cor |
|---|---|
| Grafite (chão, paredões) | `#141517` · `#1F2023` · `#2E3033` · `#3D4045` · `#4A4D52` · `#62666C` |
| Prata (filetes, rebites, taças) | `#6E737B` · `#8E939B` · `#B8BCC4` · `#DDE0E5` |
| Verde-água (só nas fendas de "ambas") | `#2EE6C5` |

**Cenário:** placas de grafite com rebites e veios de metal escovado, paredões com painéis e luzes de status, faixas de chão douradas (main) e azuis
(ajuste), racks de servidor com luzes piscando, colunas de metal, restos de placa e emendas no chão. Runas = tabletes de grafite com glifo (selo, porta, "?").
Cada pedestal tem uma gema da cor da escolha (dourada, azul ou as duas). Obelisco, plataforma e portal recoloridos para grafite/prata.

**A parede:** barreira de glitch magenta. Nas escolhas "minha" e "deles" ela **treme e cai**; em "ambas" ela **racha de dentro para fora** com luz verde-água
e então cai. Como a cena pausa durante o terminal e o diálogo do abalo, a animação toca depois que eles terminam.
**Arte:** `fases/fase_5/arte/`, gerada por `tools/gerar_arte_fase_5.gd`.

## Fase 6 — Ponto de Retorno: **Concreto brutalista com sinalização**
Estação de controle do Conselho: concreto cinza-quente com faixas de alerta amarelo-preto. Cores de **significado** reservadas: **ciano** (o commit do revert e o Eidolon),
**magenta** (o commit fantasma e o glitch das tábuas ruins) e **vermelho** (a emergência: giroflex e alavanca).

| Uso | Cor |
|---|---|
| Concreto (chão, paredões) | `#1D1C19` · `#2E2C28` · `#4A4741` · `#6A665E` · `#8B867C` · `#A8A398` · `#C4BFB2` |
| Sinalização de alerta | `#F2C230` e preto `#1B1A18` |
| Emergência | `#D8423A` |

**Cenário:** lajes de concreto com juntas e manchas, paredões de concreto moldado com furos de fôrma e faixa de alerta, o poço da Área 1 com canos e luzinhas de serviço,
passarela de aço (toco, tábuas ruins em glitch e passarela inteira), portões de aço (amarelo-preto na inspeção, luz vermelha na câmara), prateleira do stash com caixotes,
cartuchos de aço para os arquivos (planta e experimento), alavanca (2 quadros), altar de retorno, pilares, barreiras, caixotes, giroflex e números "1, 2, 3" pintados no chão.
O **experimento** deixou de ser magenta (o magenta é do fantasma): agora é vermelho. Quando um arquivo é destruído por `reset --hard`, **vira poeira** (partículas).
**Arte:** `fases/fase_6/arte/`, gerada por `tools/gerar_arte_fase_6.gd`.

## HUD recolhível (todas as fases)
O estilo da HUD da Fase 4 vale para todas: painéis **recolhíveis** com uma aba na borda. Hoje: **Manual** (tecla M, esquerda) e **Quadro da IA**
(tecla I, direita; Fases 1, 2, 3, 5 e 6), além dos painéis de Objetivos (O) e Conceitos (C) da Fase 4. O quadro da IA começa aberto e lembra a escolha
na sessão; ao mudar o próximo passo com ele recolhido, a aba mostra um selo piscando.
**Transparência:** com o painel recolhido ("para dentro") a aba fica translúcida (40%) e ainda mais dentro do terminal (28%); volta a ficar opaca
com o mouse em cima ou com o painel aberto. Regra única em `GeneralNodes/UI/aba_hud.gd` (`AbaHud`); teste: `test/hud_abas_test.tscn`.

## Menu de pausa
Todas as fases com o menu de pausa têm **REINICIAR FASE** (pede um segundo clique): recomeça do zero, como morrer
(`FaseManager.reiniciar_fase_atual()`). Todas as fases (1 a 6) têm o menu de pausa.

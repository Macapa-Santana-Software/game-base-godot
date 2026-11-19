# Design das fases

Regras decididas:
- **Cada fase tem identidade visual própria** (paleta, tipo de cenário, forma dos elementos). Nenhuma fase repete a paleta de outra.
- **A HUD é a mesma em todas as fases** (quadro da IA, objetivos, inventário, terminal, menus): mesma estrutura, posições e tema.
  Só o cenário muda. A HUD será redesenhada uma vez, para todas, numa etapa própria.

## Identidades já existentes
| Fase | Identidade |
|---|---|
| 1 — Sala de Triagem | Santuário cinza-azulado, ciano e violeta (tema_santuario) |
| 3 — Mural Corrompido | Mural de runas douradas, ruído magenta |
| 4 — Duas realidades | Vida (verde, natureza) x Convergência |
| 5 / 6 | Conflito (glitch) / linha do tempo |

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
como na Fase 1. (A classe `PainelObjetivosPonte` continua no projeto porque as fases 3, 5 e 6 ainda a usam.)

Falta: áudio da fase.

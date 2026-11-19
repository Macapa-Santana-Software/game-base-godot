class_name NotasHistoria extends RefCounted
## CATÁLOGO das notas da história (cartas, placas, atas, diários, registros), num só lugar,
## como o roteiro do Eidolon: quem escreve a história edita só este arquivo.
##
## Como usar uma nota numa fase:
##   1. Escreva a nota aqui, em NOTAS, com um id único (ex.: `&"f2_placa_conselho"`).
##   2. Na cena, instancie um nó `Nota` (GeneralNodes/Nota/nota.gd) e preencha só o `id_nota`.
##
## (Também dá para preencher título/texto direto no nó `Nota`, sem passar por aqui. Serve para um
## teste rápido, mas o texto do catálogo tem prioridade e é o que o Diário mostra depois.)
##
## Cada entrada:
##   fase    número da fase onde a nota é encontrada (0 = sem fase). Ordena o Diário.
##   tipo    "carta" | "placa" | "ata" | "diario" | "registro" (muda o ícone e a cor)
##   titulo  título curto (aparece na lista do Diário)
##   autor   quem escreveu ("" = sem assinatura)
##   texto   o corpo. Aceita BBCode: [b]negrito[/b], [i]itálico[/i], [color=#FFE08A]cor[/color].
##
## Regra de ouro (ver docs/HISTORIA.md): as notas são OPCIONAIS e nunca ensinam o comando em si.
## Elas dão significado ao que o jogador já está fazendo. Mantenha cada uma curta (até ~6 linhas).

const TIPOS := {
	"carta": {"rotulo": "CARTA", "cor": Color("FFE08A")},
	"placa": {"rotulo": "PLACA", "cor": Color("9AA7B8")},
	"ata": {"rotulo": "ATA DO CONSELHO", "cor": Color("D94C91")},
	"diario": {"rotulo": "DIÁRIO DE CAMPO", "cor": Color("53D69A")},
	"registro": {"rotulo": "REGISTRO", "cor": Color("36D6E9")},
}

const NOTAS := {
	# ---- Fase 1 ----
	&"f1_placa_triagem": {
		"fase": 1,
		"tipo": "placa",
		"titulo": "Sala de Triagem",
		"autor": "",
		"texto": "[b]SALA DE TRIAGEM — FRAGMENTO 07[/b]

Todo arquivo que entra aqui espera ser registrado.
O que não for registrado... não fica.",
	},
	&"f1_carta_elian": {
		"fase": 1,
		"tipo": "carta",
		"titulo": "Carta deixada no chão",
		"autor": "E.",
		"texto": "Se você está lendo isto, o sistema ainda responde.

Não confie em quem chamar um estado de \"limpo\" só porque ele está vazio.
Registre tudo. Um registro não prende o que foi: ele guarda para depois.

[i]Boa sorte, Walker.[/i]",
	},
	# EXEMPLO de formato (usado pelo teste das notas).
	&"exemplo_carta": {
		"fase": 0,
		"tipo": "carta",
		"titulo": "Exemplo de carta",
		"autor": "E.",
		"texto": "Esta é uma nota de exemplo.\n\nSe você a lê no jogo, o sistema de [b]Notas[/b] e o [b]Diário[/b] estão funcionando.\n\n[i]Catalogar ambos.[/i]",
	},
}


## Dados da nota `id`, ou {} se ela não está no catálogo.
static func obter(id: StringName) -> Dictionary:
	return NOTAS.get(id, {})


## Aparência do tipo (rótulo e cor). Tipo desconhecido vira "carta".
static func tipo(nome: String) -> Dictionary:
	return TIPOS.get(nome, TIPOS["carta"])

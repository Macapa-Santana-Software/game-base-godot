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
	# ---- Fase 2 ----
	&"f2_registro_segmento": {
		"fase": 2,
		"tipo": "registro",
		"titulo": "Registro do segmento 12",
		"autor": "Sistema do fragmento",
		"texto": "[b]SEGMENTO 12 — PONTE DO ABISMO[/b]
Estado: [color=#FFE08A]DESLIGADO[/color]
Dano estrutural: nenhum.
As pontas foram seladas com precisão.

[i]Isto não caiu. Alguém retirou.[/i]",
	},
	&"f2_placa_conselho": {
		"fase": 2,
		"tipo": "ata",
		"titulo": "Placa do Conselho",
		"autor": "Conselho dos Codex",
		"texto": "Segmento desligado por divergência de projeto.

[b]Parecer: desnecessário.[/b]

[i](a tinta está quase apagada)[/i]",
	},
	# ---- Fase 3 ----
	&"f3_placa_escribas": {
		"fase": 3,
		"tipo": "placa",
		"titulo": "Mural dos Escribas",
		"autor": "",
		"texto": "[b]MURAL DOS ESCRIBAS[/b]\n\nCada runa leva o Selo da lei.\nRuna sem Selo não é lei: é ruído.\n\n[i]Não confunda o que mudou com o que quebrou.[/i]",
	},
	&"f3_ata_corrupcao": {
		"fase": 3,
		"tipo": "ata",
		"titulo": "Ata da Corrupção",
		"autor": "Conselho dos Codex",
		"texto": "A Corrupção é o resíduo do trabalho não registrado.\n\nRecomenda-se descartar todo estado não registrado, [b]inclusive o que parecer bom[/b].\n\n[b]Parecer: desnecessário.[/b]",
	},
	&"f3_diario_mar": {
		"fase": 3,
		"tipo": "diario",
		"titulo": "Folha solta",
		"autor": "",
		"texto": "Corrigi a runa do mar. Azul não combinava com ela: era verde.\n\nNinguém vai registrar isto. Se você achar a runa certa, deixe-a como está.\n\n[i]Boa sorte.[/i]",
	},
	# ---- Fase 5 ----
	&"f5_placa_selo": {
		"fase": 5,
		"tipo": "placa",
		"titulo": "Selo da Passagem",
		"autor": "",
		"texto": "[b]SELO DA PASSAGEM[/b]\n\nDuas equipes, uma tinta.\nQuem pintou por último não é quem pintou certo.",
	},
	&"f5_carta_ler_as_duas": {
		"fase": 5,
		"tipo": "carta",
		"titulo": "Carta sobre duas versões",
		"autor": "E.",
		"texto": "Quem diz que uma versão é falha raramente leu as duas.\n\nAntes de resolver, leia o que está dos dois lados dos marcadores.\n\n[i]Foi o que eu não fiz, uma vez.[/i]",
	},
	&"f5_ata_unificacao": {
		"fase": 5,
		"tipo": "ata",
		"titulo": "Ata de Unificação nº 4",
		"autor": "Conselho dos Codex",
		"texto": "Em caso de divergência entre linhas, prevalece a versão da linha principal.\n\nNão é necessário examinar a outra.\n\n[b]Parecer: desnecessário.[/b]",
	},
	# ---- Fase 6 ----
	&"f6_placa_estacao": {
		"fase": 6,
		"tipo": "placa",
		"titulo": "Estação de Retorno nº 3",
		"autor": "",
		"texto": "[b]ESTAÇÃO DE RETORNO Nº 3[/b]\n\nTodo erro será corrigido.\nTodo estado será revisado.\n\n[i](alguém riscou \"revisado\" e escreveu, por cima, \"lembrado\")[/i]",
	},
	&"f6_carta_revert": {
		"fase": 6,
		"tipo": "carta",
		"titulo": "Carta sobre desfazer",
		"autor": "E.",
		"texto": "Quem desfaz com [b]revert[/b] admite o erro e o deixa à vista.\nQuem desfaz com [b]reset[/b] finge que ele nunca existiu.\n\nNão confunda corrigir com esquecer.\n\n[i]— E.[/i]",
	},
	&"f6_ata_purga": {
		"fase": 6,
		"tipo": "ata",
		"titulo": "Ata da Purga",
		"autor": "Conselho dos Codex",
		"texto": "Para estados divergentes que não se deixam corrigir, o instrumento adequado é o [b]reset --hard[/b].\n\nO que for apagado deixa de ser problema.\n\n[b]Parecer: desnecessário.[/b]",
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

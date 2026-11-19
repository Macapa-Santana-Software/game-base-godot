extends Node
## Teste das NOTAS e do DIÁRIO (GeneralNodes/Nota/): leitura, primeira vez x releitura, notas do catálogo
## x notas definidas só na cena, ordem e persistência do diário, pausa do jogo e fechamento pelo teclado.
## Não mexe no diário real do jogador (usa `persistir = false` e restaura o estado no fim).
## Rode a cena (F6) ou headless; o resultado também vai para %TEMP%/nota_diario_teste.txt.
## Sai com código 1 se algo falhar.

const ARQUIVO_SAIDA := "nota_diario_teste.txt"
const NotaScript := preload("res://GeneralNodes/Nota/nota.gd")

var _falhas: int = 0
var _total: int = 0
var _saida: FileAccess
var _lidas_sinal: Array = []


func _log(linha: String) -> void:
	print(linha)
	if _saida:
		_saida.store_line(linha)
		_saida.flush()


func _ok(condicao: bool, descricao: String) -> void:
	_total += 1
	if condicao:
		_log("  OK     " + descricao)
	else:
		_falhas += 1
		_log("  FALHA  " + descricao)


func _frames(n: int = 3) -> void:
	for _i in range(n):
		await get_tree().process_frame


func _ready() -> void:
	var pasta := OS.get_environment("TEMP") if OS.get_environment("TEMP") != "" else "/tmp"
	_saida = FileAccess.open(pasta.path_join(ARQUIVO_SAIDA), FileAccess.WRITE)

	var estado_do_jogador: Dictionary = Diario.estado()
	var persistia: bool = Diario.persistir
	Diario.persistir = false
	Diario.limpar()

	await _testar()

	Diario.fechar()
	get_tree().paused = false
	Diario.restaurar(estado_do_jogador)
	Diario.persistir = persistia
	_log("[TESTE NOTAS E DIÁRIO] %d verificações, %d falhas" % [_total, _falhas])
	get_tree().quit(1 if _falhas > 0 else 0)


func _nova_nota(id: StringName, titulo: String, texto: String, fase_n: int = 0) -> Node:
	var nota := NotaScript.new()
	nota.id_nota = id
	nota.titulo = titulo
	nota.texto = texto
	nota.fase = fase_n
	nota.autor = "Teste"
	add_child(nota)
	return nota


func _testar() -> void:
	await _frames()
	Diario.nota_lida.connect(func(id: StringName, primeira: bool) -> void: _lidas_sinal.append([id, primeira]))

	_log("— Estado inicial —")
	_ok(Diario.total_lidas() == 0, "o diário começa vazio")
	_ok(not Diario.ocupado(), "nenhuma tela aberta")
	_ok(not get_tree().paused, "o jogo não está pausado")

	_log("— Nota definida só na cena —")
	var nota_a := _nova_nota(&"teste_a", "Placa A", "Texto da placa A.", 2)
	await _frames()
	_ok(not Diario.foi_lida(&"teste_a"), "antes de ler, a nota não consta como lida")
	var recebido: Array = []
	nota_a.lida.connect(func(id: StringName, primeira: bool) -> void: recebido.append([id, primeira]))
	nota_a.interagir()
	await _frames()
	_ok(Diario.foi_lida(&"teste_a"), "depois de ler, consta como lida")
	_ok(Diario.ocupado(), "a tela de leitura abriu")
	_ok(get_tree().paused, "o jogo pausa durante a leitura")
	_ok(recebido == [[&"teste_a", true]], "a nota emitiu `lida` com primeira_vez = true")
	_ok(_lidas_sinal.size() == 1 and _lidas_sinal[0][1] == true, "o Diário emitiu `nota_lida` (primeira vez)")

	_log("— Fechar pelo teclado —")
	var esc := InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	Input.parse_input_event(esc)
	await _frames()
	_ok(not Diario.ocupado(), "Esc fecha a leitura")
	_ok(not get_tree().paused, "o jogo volta ao normal ao fechar")

	_log("— Releitura —")
	nota_a.interagir()
	await _frames()
	_ok(recebido.size() == 2 and recebido[1][1] == false, "reler emite primeira_vez = false")
	_ok(Diario.total_lidas() == 1, "reler não duplica a nota no diário")
	var interagir := InputEventAction.new()
	interagir.action = &"interagir_porta"
	interagir.pressed = true
	Input.parse_input_event(interagir)
	await _frames()
	_ok(not Diario.ocupado(), "a tecla de interagir também fecha a leitura")

	_log("— Nota do catálogo —")
	var nota_c := _nova_nota(&"exemplo_carta", "", "")  # sem texto na cena: vem do catálogo
	await _frames()
	nota_c.interagir()
	await _frames()
	_ok(Diario.foi_lida(&"exemplo_carta"), "a nota do catálogo foi lida sem texto na cena")
	_ok(String(Diario.dados_de(&"exemplo_carta").get("titulo", "")) == "Exemplo de carta", "o texto vem do catálogo")
	Diario.fechar()
	await _frames()

	_log("— Nota sem texto —")
	var vazia := _nova_nota(&"teste_vazia", "Vazia", "")
	await _frames()
	vazia.interagir()
	await _frames()
	_ok(not Diario.foi_lida(&"teste_vazia") and not Diario.ocupado(), "nota sem texto não abre nem conta como lida")

	_log("— Lista do Diário —")
	var nota_b := _nova_nota(&"teste_b", "Carta B", "Texto B.", 1)
	await _frames()
	nota_b.interagir()
	await _frames()
	Diario.fechar()
	await _frames()
	var itens: Array[Dictionary] = Diario.entradas()
	_ok(itens.size() == 3, "a lista tem as 3 notas lidas")
	_ok(itens[0]["id"] == &"exemplo_carta" and itens[1]["id"] == &"teste_b" and itens[2]["id"] == &"teste_a",
		"ordenada por fase (0, 1, 2)")
	Diario.abrir_diario()
	await _frames()
	_ok(Diario.ocupado() and get_tree().paused, "abrir_diario abre a lista e pausa")
	Diario.fechar()
	await _frames()
	_ok(not get_tree().paused, "fechar a lista despausa")

	_log("— Já pausado por outro sistema (menu de pausa) —")
	get_tree().paused = true
	Diario.abrir_diario()
	await _frames()
	Diario.fechar()
	await _frames()
	_ok(get_tree().paused, "se o jogo já estava pausado, continua pausado ao fechar o Diário")
	get_tree().paused = false

	_log("— Salvar e restaurar —")
	var json: Variant = JSON.parse_string(Diario.como_json())
	Diario.limpar()
	_ok(Diario.total_lidas() == 0, "limpar esvazia o diário")
	Diario.restaurar(json)
	_ok(Diario.total_lidas() == 3, "restaurar (via JSON) devolve as 3 notas")
	_ok(String(Diario.dados_de(&"teste_a").get("texto", "")) == "Texto da placa A.",
		"a nota definida na cena sobrevive ao salvar/restaurar")
	_ok(Diario.entradas().size() == 3, "a lista restaurada continua completa")

	_log("— Marca no mapa (por tentativa da fase) —")
	Diario.limpar()
	var marca := _nova_nota(&"teste_marca", "Marca", "Texto da marca.", 1)
	await _frames()
	_ok(not Diario.foi_marcada(&"teste_marca"), "antes de ler, a nota aparece não lida no mapa")
	marca.interagir()
	await _frames()
	Diario.fechar()
	await _frames()
	_ok(Diario.foi_marcada(&"teste_marca"), "depois de ler, aparece lida no mapa")
	Diario.descartar_tentativa()
	_ok(not Diario.foi_marcada(&"teste_marca"), "morrer: a nota volta a aparecer não lida no mapa")
	_ok(Diario.foi_lida(&"teste_marca") and Diario.total_lidas() == 1, "morrer: a entrada continua no Diário")
	marca.interagir()
	await _frames()
	Diario.fechar()
	await _frames()
	_ok(Diario.foi_marcada(&"teste_marca"), "ler de novo na nova tentativa marca de novo")
	Diario.confirmar_tentativa()
	Diario.descartar_tentativa()
	_ok(Diario.foi_marcada(&"teste_marca"), "concluir a fase: a marca fica e não some mais")
	var salvo: Variant = JSON.parse_string(Diario.como_json())
	Diario.limpar()
	_ok(not Diario.foi_marcada(&"teste_marca"), "limpar (jogo novo) apaga a marca")
	Diario.restaurar(salvo)
	_ok(Diario.foi_marcada(&"teste_marca"), "a marca confirmada sobrevive ao salvar/restaurar")


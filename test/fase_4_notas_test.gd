extends Node
## Teste dos fragmentos da Fase 4 virados NOTAS (Diário): as 7 notas estão nas áreas, a leitura vai para o Diário, o
## brilho da cena apaga ao ler e volta ao morrer, e o Eidolon reage (uma vez) às notas que têm fala no roteiro.
## Sai com código 1 se algo falhar.

const CenaFase4 := preload("res://fases/fase_4/fase_4.tscn")
const IDS := [&"frag_origem", &"frag_m1", &"frag_m2", &"frag_m3", &"frag_v1", &"frag_v2", &"frag_v3"]

var _falhas: int = 0
var _total: int = 0


func _ok(condicao: bool, descricao: String) -> void:
	_total += 1
	print(("  OK     " if condicao else "  FALHA  ") + descricao)
	if not condicao:
		_falhas += 1


func _frames(n: int = 4) -> void:
	for _i in range(n):
		await get_tree().process_frame


func _ready() -> void:
	var persistia: bool = Diario.persistir
	var diario_antes: Dictionary = Diario.estado()
	Diario.persistir = false
	await _testar()
	Diario.restaurar(diario_antes)
	Diario.persistir = persistia
	GameState.resetar_repositorio()
	print("[TESTE FASE 4 NOTAS] %d verificações, %d falhas" % [_total, _falhas])
	get_tree().quit(1 if _falhas > 0 else 0)


func _notas(raiz: Node) -> Dictionary:
	var achadas: Dictionary = {}
	for no in raiz.find_children("*", "Area2D", true, false):
		if no is Nota:
			achadas[(no as Nota).id_nota] = no
	return achadas


func _testar() -> void:
	GameState.resetar_repositorio()
	Diario.limpar()
	var fase := CenaFase4.instantiate()
	add_child(fase)
	await _frames(6)
	var notas := _notas(fase)

	print("— As notas estão nas áreas —")
	for id in IDS:
		_ok(notas.has(id), "a nota %s está na cena" % id)
		_ok(not NotasHistoria.obter(id).is_empty(), "e no catálogo (%s)" % id)
	_ok(fase.find_children("*", "Area2D", true, false).filter(func(n): return n.get_script() != null and "fragmento_memoria" in str(n.get_script().resource_path)).is_empty(), "não sobrou nenhum FragmentoMemoria")

	print("— Ler e brilho —")
	var nota: Nota = notas[&"frag_m1"]
	var brilho := nota.get_node_or_null(nota.visual) as CanvasItem
	_ok(brilho != null and brilho.modulate.a >= 0.99, "o brilho da cena começa aceso")
	_ok(not nota.desenhar_icone, "a nota usa a arte da própria fase (sem o ícone padrão)")
	nota.interagir()
	await _frames()
	_ok(Diario.foi_lida(&"frag_m1") and Diario.ocupado(), "ler abre a tela da nota e registra no Diário")
	_ok(brilho.modulate.a < 0.5, "depois de lida, o brilho da cena apaga")
	_ok(EidolonEstado.evidencias().has(&"frag_m1") or EidolonEstado.evidencias().has("frag_m1"), "a leitura vira evidência para o Eidolon")
	Diario.fechar()
	await get_tree().create_timer(1.8).timeout
	_ok(EidolonEstado.ja_disse(&"frag_m1"), "o Eidolon reage à nota (depois de fechar a tela)")

	print("— Nota sem fala do Eidolon —")
	var origem: Nota = notas[&"frag_origem"]
	origem.interagir()
	await _frames()
	_ok(Diario.foi_lida(&"frag_origem"), "o fragmento da Área 1 também vai para o Diário")
	_ok(not EidolonEstado.evidencias().has(&"frag_origem") and not EidolonEstado.evidencias().has("frag_origem"), "sem fala no roteiro, não vira evidência")
	Diario.fechar()
	await _frames()

	print("— Morrer: a nota volta a brilhar, o Diário continua —")
	Diario.descartar_tentativa()
	await _frames()
	_ok(brilho.modulate.a >= 0.99, "o brilho volta ao reiniciar a fase")
	_ok(Diario.foi_lida(&"frag_m1"), "a entrada continua no Diário")
	GameState.restaurar_checkpoint()
	_ok(not EidolonEstado.ja_disse(&"frag_m1"), "o Eidolon volta ao início da fase (poderá reagir de novo)")

	fase.queue_free()
	get_tree().paused = false
	await _frames()

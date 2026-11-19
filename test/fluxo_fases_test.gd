extends Node
## Teste do FLUXO entre fases: cada fase (1 a 5) leva à seguinte pelo caminho real de saída
## (FaseManager.concluir_fase_e_avancar, o mesmo que o botão "próxima fase" usa) e a última (6)
## só mostra a mensagem de fim de jogo. Rode a cena (F6) ou headless; o resultado também vai
## para %TEMP%/fluxo_fases_teste.txt. Sai com código 1 se algo falhar.

const ARQUIVO_SAIDA := "fluxo_fases_teste.txt"

var _falhas: int = 0
var _total: int = 0
var _saida: FileAccess


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


func _frames(n: int = 4) -> void:
	for _i in range(n):
		await get_tree().process_frame


func _ready() -> void:
	var pasta := OS.get_environment("TEMP") if OS.get_environment("TEMP") != "" else "/tmp"
	_saida = FileAccess.open(pasta.path_join(ARQUIVO_SAIDA), FileAccess.WRITE)
	await _testar()
	_log("[TESTE FLUXO DAS FASES] %d verificações, %d falhas" % [_total, _falhas])
	GameState.resetar_repositorio()
	get_tree().quit(1 if _falhas > 0 else 0)


## Abre a fase como cena ATUAL (filha direta da raiz), como o jogo faz ao trocar de fase.
func _abrir(caminho: String) -> Node:
	var cena := (load(caminho) as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(cena)
	await _frames(2)
	get_tree().current_scene = cena
	await _frames()
	return cena


func _testar() -> void:
	var fases := FaseManager.FASES
	_ok(fases.size() == 6, "a sequência tem 6 fases")
	for caminho in fases:
		_ok(ResourceLoader.exists(caminho), "existe " + caminho)

	# regras do FaseManager
	for i in range(fases.size()):
		FaseManager.current_level_index = i
		_ok(FaseManager.has_next_phase() == (i < fases.size() - 1), "Fase %d: has_next_phase correto" % (i + 1))
		_ok(FaseManager.is_last_phase() == (i == fases.size() - 1), "Fase %d: is_last_phase correto" % (i + 1))
		if i < fases.size() - 1:
			_ok(FaseManager.get_next_phase() == fases[i + 1], "Fase %d: a próxima é a Fase %d" % [i + 1, i + 2])
	FaseManager.current_level_index = 0
	_ok(not FaseManager.concluir_fase_e_avancar(), "fora da sequência (cena de teste) não avança nada")

	# cada fase 1 a 5 leva à seguinte, mesmo com o índice desalinhado (fase aberta direto)
	for k in range(fases.size() - 1):
		GameState.resetar_repositorio()
		var cena := await _abrir(fases[k])
		FaseManager.current_level_index = 0  # desalinha de propósito
		var avancou := FaseManager.concluir_fase_e_avancar()
		await _frames(6)
		var atual := get_tree().current_scene
		_ok(avancou and atual != null and atual.scene_file_path == fases[k + 1],
			"Fase %d -> Fase %d (entra na cena seguinte)" % [k + 1, k + 2])
		_ok(FaseManager.current_level_index == k + 1, "o índice acompanha: Fase %d" % (k + 2))
		_ok(not get_tree().paused, "a fase seguinte começa sem pausa")
		if atual != null:
			atual.queue_free()
		await _frames()

	# última fase: só a mensagem de fim de jogo
	GameState.resetar_repositorio()
	var ultima := await _abrir(fases[fases.size() - 1])
	FaseManager.current_level_index = 0
	var vitoria: CanvasLayer = ultima.get_node("VictoryScreen")
	vitoria.mostrar()
	await _frames()
	_ok(FaseManager.current_level_index == fases.size() - 1, "a tela de vitória alinha o índice com a última fase")
	_ok(vitoria.get_node("%TituloLabel").text == "PONTO DE RETORNO", "título da última fase")
	_ok("Nenhuma branch aponta" in vitoria.get_node("%MensagemLabel").text, "mensagem final, sem promessa de continuação")
	_ok(not vitoria.get_node("%ProximaFaseButton").visible, "sem botão de próxima fase")
	_ok(not vitoria.get_node("%ComandosLabel").visible, "sem resumo de comandos")
	_ok(not FaseManager.concluir_fase_e_avancar(), "a última fase não avança")
	get_tree().paused = false
	ultima.queue_free()

	# uma fase intermediária mostra o resumo e o botão
	var f3 := await _abrir(fases[2])
	var vitoria_3: CanvasLayer = f3.get_node("VictoryScreen")
	vitoria_3.mostrar()
	await _frames()
	_ok(vitoria_3.get_node("%TituloLabel").text == "FASE 3 CONCLUÍDA", "Fase 3: título normal")
	_ok(vitoria_3.get_node("%ProximaFaseButton").visible, "Fase 3: botão de próxima fase")
	get_tree().paused = false
	f3.queue_free()

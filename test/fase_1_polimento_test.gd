extends Node
## Teste da Fase 1 (polimento): começa sempre do zero (inclusive depois de morrer), corações de cura,
## notas no mapa, tela de controles do menu de pausa e menu inicial. Sai com código 1 se algo falhar.

const ARQUIVO_SAIDA := "fase_1_polimento_teste.txt"
const CenaFase1 := preload("res://fases/fase_1/fase_1.tscn")

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


func _frames(n: int = 3) -> void:
	for _i in range(n):
		await get_tree().process_frame


func _ready() -> void:
	var pasta := OS.get_environment("TEMP") if OS.get_environment("TEMP") != "" else "/tmp"
	_saida = FileAccess.open(pasta.path_join(ARQUIVO_SAIDA), FileAccess.WRITE)
	var persistia: bool = Diario.persistir
	Diario.persistir = false
	await _testar()
	Diario.persistir = persistia
	GameState.resetar_repositorio()
	_log("[TESTE FASE 1] %d verificações, %d falhas" % [_total, _falhas])
	get_tree().quit(1 if _falhas > 0 else 0)


func _abrir_fase() -> Node:
	var fase := CenaFase1.instantiate()
	add_child(fase)
	return fase


func _testar() -> void:
	_log("— Recomeço do zero —")
	# Estado "sujo", como ficaria depois de jogar a fase inteira e morrer.
	GameState.inicializar_repositorio()
	GameState.coletar_arquivo_no_mapa("main.gd")
	GameState.sincronizar_inventario_com_git()
	GameState.adicionar_todos_ao_stage()
	GameState.criar_commit("teste")
	_ok(not GameState.commits.is_empty(), "(preparo) o repositório tinha um commit")
	var fase := _abrir_fase()
	await _frames(5)
	_ok(GameState.commits.is_empty(), "entrar na Fase 1 apaga os commits")
	_ok(GameState.inventario_player.is_empty(), "entrar na Fase 1 esvazia o inventário")
	_ok(not GameState.git_inicializado, "o Git volta a não estar inicializado")
	_ok(get_tree().get_nodes_in_group(ItemColetavel.GRUPO_ARQUIVOS).size() == 3, "os 3 arquivos estão no mapa")

	_log("— Corações de cura —")
	var player: Player = PlayerManager.player
	var coracoes := get_tree().get_nodes_in_group("coracao_cura")
	_ok(coracoes.size() == 4, "há 4 corações no mapa")
	var espaco: PhysicsDirectSpaceState2D = fase.get_world_2d().direct_space_state
	for c in coracoes:
		var consulta := PhysicsPointQueryParameters2D.new()
		consulta.position = c.global_position
		consulta.collision_mask = 16  # Walls
		_ok(espaco.intersect_point(consulta, 1).is_empty(), "%s não está dentro de uma parede" % c.name)
	player.health_component.take_damage(3)
	var antes: int = player.health_component.current_health
	coracoes[0]._on_body_entered(player)
	_ok(player.health_component.current_health == antes + 1, "o coração cura 1 de vida")
	await _frames()
	_ok(not is_instance_valid(coracoes[0]) or coracoes[0].is_queued_for_deletion(), "o coração some depois de coletado")
	player.health_component.heal(10)
	coracoes[1]._on_body_entered(player)
	_ok(player.health_component.current_health == player.max_health, "com a vida cheia nada muda")
	await _frames()
	_ok(not is_instance_valid(coracoes[1]) or coracoes[1].is_queued_for_deletion(), "com a vida cheia o coração é coletado do mesmo jeito")

	_log("— Notas —")
	for id in [&"f1_placa_triagem", &"f1_carta_elian"]:
		_ok(not NotasHistoria.obter(id).is_empty(), "a nota %s existe no catálogo" % id)
	_ok(fase.get_node_or_null("NotaPlaca") != null and fase.get_node_or_null("NotaCarta") != null, "as 2 notas estão na cena")

	_log("— Menu de pausa: controles —")
	var pausa: Node = fase.get_node("PauseMenu")
	pausa.abrir()
	await _frames()
	_ok(pausa.painel_principal.visible and not pausa.painel_controles.visible, "o menu abre no painel principal")
	pausa.controles_button.pressed.emit()
	_ok(pausa.painel_controles.visible and not pausa.painel_principal.visible, "CONTROLES mostra a tela de controles")
	pausa.voltar_button.pressed.emit()
	_ok(pausa.painel_principal.visible and not pausa.painel_controles.visible, "VOLTAR retorna ao menu")
	pausa.continuar()
	await _frames()
	_ok(not get_tree().paused, "continuar despausa")

	_log("— Menu inicial e prólogo —")
	_ok(ProjectSettings.get_setting("application/run/main_scene") == "res://GeneralNodes/MenuInicial/menu_inicial.tscn",
		"a cena principal é o menu inicial")
	var menu := (load("res://GeneralNodes/MenuInicial/menu_inicial.tscn") as PackedScene).instantiate()
	add_child(menu)
	await _frames()
	_ok(menu.jogar_button != null and menu.sair_button != null, "o menu tem JOGAR e SAIR")
	_ok(menu.cena_jogar == "res://Dialogo/Prologo/CenaPrologo.tscn", "JOGAR leva ao prólogo")
	menu.queue_free()
	var prologo_src := FileAccess.get_file_as_string("res://Dialogo/Prologo/cena_prologo.gd")
	_ok(not prologo_src.contains("call_deferred() # TEMP"), "o prólogo não está mais desativado")

	fase.queue_free()
	await _frames()

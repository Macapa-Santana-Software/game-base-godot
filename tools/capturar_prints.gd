extends Node
## Ferramenta de documentação (não faz parte do jogo): joga cada fase por código e grava os prints do README em
## res://docs/img/. Precisa de janela (não roda com --headless). Para regerar os prints:
##   godot --path . --resolution 1280x720 res://tools/capturar_prints.tscn
## Cada print é um recorte do jogo de verdade (com a HUD), na resolução da janela. As cenas "limpas" recolhem o
## quadro da IA e escondem os balões para o cenário aparecer; algumas mantêm a HUD de propósito.

const SAIDA := "res://docs/img/"

var _atual: Node


func _ready() -> void:
	Diario.persistir = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	await _menu()
	await _fase_1()
	await _fase_2()
	await _fase_3()
	await _fase_4()
	await _fase_5()
	await _fase_6()
	await _notas_e_pausa()
	print("[Prints] pronto.")
	get_tree().quit()


# Utilidades ---------------------------------------------------------------------------------------------------
func _abrir(caminho: String) -> Node:
	if _atual and is_instance_valid(_atual):
		_atual.queue_free()
		await get_tree().process_frame
	get_tree().paused = false
	GameState.resetar_repositorio()
	Diario.limpar()
	_atual = (load(caminho) as PackedScene).instantiate()
	add_child(_atual)
	await _esperar(0.6)
	return _atual


func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos, true).timeout


func _jogador(posicao: Vector2, espera: float = 1.4) -> void:
	PlayerManager.player.global_position = posicao
	await _esperar(espera)


func _foto(nome: String, pausar: bool = true) -> void:
	if pausar:
		get_tree().paused = true
	await _esperar(0.15)
	await RenderingServer.frame_post_draw
	var imagem := get_viewport().get_texture().get_image()
	imagem.save_png(ProjectSettings.globalize_path(SAIDA + nome + ".png"))
	print("[Prints] ", nome, " ", imagem.get_size())
	if pausar:
		get_tree().paused = false


## Esconde o que cobre o cenário: o quadro da IA, os balões e o painel de Objetivos.
func _cenario_limpo() -> void:
	for filho in _atual.get_children():
		if filho is TutoraFase1:
			if filho._aberto:
				filho.alternar_quadro()
			if filho._balao_tween:
				filho._balao_tween.kill()
			filho._balao.hide()
		elif filho.name == "PainelObjetivos" and filho.has_method("alternar") and filho._aberto:
			filho.alternar()
	for hud in get_tree().get_nodes_in_group(MensagemHud.GRUPO):
		hud.painel.hide()
	await _esperar(0.5)


func _sem_dialogos(fase: Node) -> void:
	for filho in fase.get_children():
		if "Dialogo" in String(filho.name):
			filho.queue_free()


func _terminal() -> Node:
	return get_tree().get_first_node_in_group("terminal_ui")


func _digitar(comando: String) -> void:
	_terminal()._ao_digitar(comando)
	await _esperar(0.25)


# Prints ------------------------------------------------------------------------------------------------------------
func _menu() -> void:
	await _abrir("res://GeneralNodes/MenuInicial/menu_inicial.tscn")
	await _foto("00-menu", false)


func _fase_1() -> void:
	var fase := await _abrir("res://fases/fase_1/fase_1.tscn")
	_sem_dialogos(fase)
	await _jogador(Vector2(520, 250))
	await _foto("01-fase1-galeria")  # com a HUD completa (de propósito)
	await _cenario_limpo()
	await _jogador(Vector2(1440, 900), 1.2)
	await _foto("02-fase1-santuario")
	# Terminal: o primeiro registro (com o quadro da IA já recolhido)
	for nome in ["main.gd", "setup.gd", "README.md"]:
		GameState.coletar_arquivo_no_mapa(nome)
	_terminal().abrir()
	await _esperar(0.5)
	await _digitar("git init")
	GameState.sincronizar_inventario_com_git()
	await _digitar("git status")
	await _digitar("git add .")
	await _digitar("git commit -m \"primeiro registro\"")
	await _foto("03-terminal", false)
	_terminal().fechar()


func _fase_2() -> void:
	var fase := await _abrir("res://fases/fase_2/fase_2.tscn")
	await _jogador(Vector2(335, 128))
	await _cenario_limpo()
	await _foto("04-fase2-ponte-quebrada")
	GameState.criar_branch("ponte")
	GameState.trocar_branch("ponte")
	GameState.coletar_arquivo_no_mapa("ponte.tile")
	GameState.sincronizar_inventario_com_git()
	GameState.adicionar_ao_stage("ponte.tile")
	GameState.criar_commit("conserta a ponte")
	await _esperar(0.9)
	GameState.trocar_branch("main")
	await _esperar(0.3)
	GameState.mesclar("ponte")
	await _esperar(1.0)
	await _cenario_limpo()
	await _foto("05-fase2-ponte-montando")
	fase.get_node("Ponte/Inteira").acender(true)


func _fase_3() -> void:
	await _abrir("res://fases/fase_3/fase_3.tscn")
	var modelo: ModeloMural = ModeloMural.ativo()
	await _jogador(Vector2(190, 140))
	await _cenario_limpo()
	await _foto("06-fase3-mural")
	modelo.texto_status()
	modelo.texto_diff([] as Array[String])
	await _jogador(Vector2(560, 150))
	await _cenario_limpo()
	await _foto("07-fase3-oficina")


func _fase_4() -> void:
	var fase := await _abrir("res://fases/fase_4/fase_4.tscn")
	await _esperar(0.8)
	var caixa := fase.get_node("DialogoEidolon/CaixaDialogo")
	if caixa.visible:
		caixa.finalizar()
	get_tree().paused = false
	await _esperar(0.4)
	await _foto("08-fase4-arquivo")  # com os painéis de Objetivos e Conceitos (de propósito)
	await _cenario_limpo()
	# A realidade verde (vida-alternativa)
	GameState.criar_branch("vida-alternativa")
	GameState.trocar_branch("vida-alternativa")
	await _jogador(Vector2(1840, 1330), 1.6)
	await _cenario_limpo()
	await _foto("09-fase4-vida")
	GameState.coletar_arquivo_no_mapa("eco_vida.eco")
	GameState.sincronizar_inventario_com_git()
	GameState.adicionar_ao_stage("eco_vida.eco")
	GameState.criar_commit("registra o eco da vida")
	GameState.trocar_branch("main")
	await _esperar(2.2)  # a transição entre realidades reposiciona o jogador
	await _jogador(Vector2(300, 1770), 1.6)
	GameState.coletar_arquivo_no_mapa("eco_main.eco")
	GameState.sincronizar_inventario_com_git()
	GameState.adicionar_ao_stage("eco_main.eco")
	GameState.criar_commit("registra o eco de main")
	GameState.mesclar("vida-alternativa")
	await _esperar(0.4)
	var atlas := get_tree().get_first_node_in_group(AtlasUI.GRUPO) as AtlasUI
	if atlas:
		atlas.abrir()
		await _esperar(0.8)
		await _foto("10-fase4-atlas", false)
		atlas.fechar()
		await _esperar(0.3)


func _fase_5() -> void:
	var fase := await _abrir("res://fases/fase_5/fase_5.tscn")
	await _jogador(Vector2(300, 128))
	var modelo: ModeloConflito = fase.modelo
	modelo.texto_status()
	modelo.mesclar(["ajuste"] as Array[String])
	await _cenario_limpo()
	await _foto("11-fase5-conflito")
	modelo.texto_diff([] as Array[String])
	modelo.escolher("ambas")
	modelo.adicionar(["selo.runa"] as Array[String])
	modelo.commitar(["-m", "junta as duas linhas"] as Array[String])
	await _esperar(0.3)
	fase.caixa_dialogo.finalizar()
	get_tree().paused = false
	await _jogador(Vector2(420, 128), 0.4)
	await _cenario_limpo()
	await _esperar(0.3)
	await _foto("12-fase5-parede-rachando")


func _fase_6() -> void:
	await _abrir("res://fases/fase_6/fase_6.tscn")
	await _jogador(Vector2(340, 150))
	await _cenario_limpo()
	await _foto("13-fase6-ponte")
	await _jogador(Vector2(660, 150), 1.4)
	await _cenario_limpo()
	await _foto("14-fase6-corredor")


func _notas_e_pausa() -> void:
	await _abrir("res://fases/fase_3/fase_3.tscn")
	await _jogador(Vector2(190, 140), 0.6)
	for id in [&"f1_placa_triagem", &"f2_placa_conselho", &"f3_placa_escribas", &"f3_ata_corrupcao", &"f5_ata_unificacao", &"f6_carta_revert", &"frag_m1"]:
		Diario.ler(id)
		Diario.fechar()
	await _esperar(0.2)
	Diario.ler(&"frag_m3")
	await _esperar(0.6)
	await _foto("15-nota", false)
	Diario.fechar()
	await _esperar(0.3)
	Diario.abrir_diario()
	await _esperar(0.6)
	await _foto("16-diario", false)
	Diario.fechar()
	await _esperar(0.3)
	var pausa := _atual.get_node("PauseMenu")
	pausa.abrir()
	await _esperar(0.6)
	await _foto("17-pausa", false)
	pausa.continuar()

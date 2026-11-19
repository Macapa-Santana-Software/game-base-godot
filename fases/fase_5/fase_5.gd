extends Node2D
## Fase 5 — Tutorial: "Linhas Cruzadas" (merge com conflito).
##
## Uma sala só. Uma parede de glitch fecha a passagem para o portal. Para derrubá-la, o jogador
## faz `git merge ajuste`, que PARA com um conflito em `selo.runa`; lê o conflito (`git diff`),
## o resolve no mundo (pedestais: a sua versão, a deles ou as duas), marca com `git add` e
## fecha com `git commit`. `git merge --abort` desfaz a tentativa a qualquer momento.
##
## O GameState não conhece conflitos nem conteúdo de arquivos, então o mini-merge vive no
## ModeloConflito (ver modelo_conflito.gd). Esta cena só reage a ele: parede, portal e vitória.
## A IA é a da Fase 1 (TutoraFase1), com o roteiro desta fase (TutoraConflito).
##
## História: o Eidolon e a IA reagem a cada passo (ver roteiro_conflito.gd). Ao fechar o merge, o
## Eidolon sofre o primeiro abalo: um diálogo OBRIGATÓRIO (caixa de diálogo) que espera o terminal fechar.
## A escolha do jogador (minha/deles/ambas) fica em GameState.escolhas_historia para as fases seguintes.

@onready var modelo: ModeloConflito = $ModeloConflito
@onready var parede: PortaMural = $ParedeGlitch
@onready var portal: ExitArea = $PortalSaida
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var limite_sup_esq: Marker2D = $Limites/SupEsq
@onready var limite_inf_dir: Marker2D = $Limites/InfDir
@onready var caixa_dialogo: Control = $DialogoHistoria/CaixaDialogo
@onready var rachaduras: Sprite2D = $ParedeGlitch/Rachaduras
@onready var brilho_verde: Sprite2D = $ParedeGlitch/BrilhoVerde

## Arte da Fase 5 aplicada aos objetos compartilhados (Obelisco e portal): grafite neutro e prata.
@export var textura_plataforma: Texture2D
@export var textura_portal: Texture2D
@export var cor_luz: Color = Color("B8BCC4")

var fase_concluida: bool = false
var _parede_aberta: bool = false
var _terminal_aberto: bool = false
var _abalo_pendente: bool = false
var _inicial: bool = true


func _ready() -> void:
	_aplicar_tema()
	GameState.git_inicializado = true
	_configurar_camera()

	var tutora := TutoraConflito.new()
	add_child(tutora)

	modelo.mudou.connect(_atualizar_mundo)
	modelo.merge_concluido.connect(_on_merge_concluido)
	GameState.terminal_aberto.connect(func() -> void: _terminal_aberto = true)
	GameState.terminal_fechado.connect(_on_terminal_fechado)
	portal.unlocked_entered.connect(_on_portal_unlocked_entered)
	victory_screen.proxima_fase_pressed.connect(_on_proxima_fase_pressed)
	_atualizar_mundo()
	_inicial = false


## O merge foi fechado: o abalo do Eidolon acontece (assim que o terminal fechar).
func _on_merge_concluido() -> void:
	if modelo.abalo_dito():
		return
	_abalo_pendente = true
	_tentar_abalo()


func _on_terminal_fechado() -> void:
	_terminal_aberto = false
	_tentar_abalo.call_deferred()


func _tentar_abalo() -> void:
	if not _abalo_pendente or _terminal_aberto or get_tree().paused:
		return
	_abalo_pendente = false
	modelo.marcar_abalo()
	var falas: Array[String] = []
	falas.assign(RoteiroConflito.ABALO)
	caixa_dialogo.iniciar_dialogo(falas)


func _configurar_camera() -> void:
	var limites: Array[Vector2] = [limite_sup_esq.global_position, limite_inf_dir.global_position]
	LevelManager.ChangeTilemapsBounds(limites)


func _atualizar_mundo() -> void:
	var concluido := modelo.estado() == ModeloConflito.CONCLUIDO
	if concluido:
		_abrir_parede(not _inicial)
	if concluido and portal.locked:
		portal.unlock()


## A parede cai de um jeito conforme a escolha: nas versões "minha" e "deles" ela treme e cai; em "ambas"
## ela RACHA de dentro para fora e a luz que passa pelas fendas é verde-água (a cor do Walker).
func _abrir_parede(animado: bool) -> void:
	if _parede_aberta:
		return
	_parede_aberta = true
	if not animado:
		parede.definir_aberta(true)
		return
	if modelo.escolha() == ModeloConflito.LADO_AMBAS:
		_rachar_e_abrir()
	else:
		_tremer_e_abrir()


func _tremer_e_abrir() -> void:
	var visual: Control = parede.get_node("Visual")
	var origem := visual.position
	var tween := create_tween()
	for k in range(6):
		tween.tween_property(visual, "position", origem + Vector2(randf_range(-2.0, 2.0), 0.0), 0.05)
	tween.tween_property(visual, "position", origem, 0.05)
	tween.tween_callback(parede.definir_aberta.bind(true))


func _rachar_e_abrir() -> void:
	rachaduras.visible = true
	rachaduras.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_method(_revelar_rachaduras, 0.0, 1.0, 1.6)
	tween.parallel().tween_property(brilho_verde, "modulate:a", 0.9, 1.6)
	tween.tween_interval(0.4)
	tween.tween_callback(parede.definir_aberta.bind(true))
	tween.tween_property(rachaduras, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(brilho_verde, "modulate:a", 0.0, 1.2)


## As fendas crescem do centro da parede para as pontas (t de 0 a 1).
func _revelar_rachaduras(t: float) -> void:
	var altura := lerpf(8.0, 256.0, t)
	rachaduras.region_rect = Rect2(0.0, 128.0 - altura / 2.0, 16.0, altura)
	rachaduras.position = Vector2(-8.0, -altura / 2.0)


func _aplicar_tema() -> void:
	var obelisco := get_node_or_null("ObeliscoTerminal")
	if obelisco:
		var plataforma := obelisco.get_node_or_null("Plataforma") as Sprite2D
		if plataforma and textura_plataforma:
			plataforma.texture = textura_plataforma
		var luz := obelisco.get_node_or_null("Luz") as PointLight2D
		if luz:
			luz.color = cor_luz
	var visual_portal := $PortalSaida.get_node_or_null("Portal") as Sprite2D
	if visual_portal and textura_portal:
		visual_portal.texture = textura_portal
	var luz_portal := $PortalSaida.get_node_or_null("Luz") as PointLight2D
	if luz_portal:
		luz_portal.color = cor_luz


func _on_portal_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[Fase 5] CONDIÇÃO DE VITÓRIA ATINGIDA!")
	victory_screen.mostrar()


func _on_proxima_fase_pressed() -> void:
	# Sai pelo portal: o FaseManager limpa o temporário e abre a entrada da fase seguinte.
	FaseManager.concluir_fase_e_avancar()

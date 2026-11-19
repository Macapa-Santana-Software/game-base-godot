extends Node2D
## Fase 3 — Tutorial: "O Mural Corrompido" (comandos diff e restore).
##
## Três zonas em fila, separadas por portas que abrem conforme o jogador aprende:
##   1. Mural da Entrada  git status + git diff     (ver o que mudou e COMO mudou)
##   2. Oficina           git restore               (descartar a corrupção, salvar o trabalho bom)
##   3. Palco             git restore --staged      (tirar do Palco o que entrou por engano)
##
## O GameState não guarda o conteúdo dos arquivos, então as runas vivem no ModeloMural
## (ver modelo_mural.gd). Esta cena só reage a ele: portas, portal e vitória.
## A IA é a da Fase 1 (TutoraFase1), com o roteiro desta fase (TutoraMural).

## Arte da Fase 3 aplicada aos objetos compartilhados (Obelisco, plataforma e portal): pedra clara e ouro.
@export var textura_plataforma: Texture2D
@export var textura_portal: Texture2D
@export var cor_luz: Color = Color("E8B84A")

const MENSAGEM_PASSADO := "Mural original"
const AUTOR_PASSADO := "Os Escribas"
const TEXTO_LEI := "Registrar não é prender. É lembrar."
const COR_LEI := Color("E8B84A")

@onready var modelo: ModeloMural = $ModeloMural
@onready var porta_1: PortaMural = $Portas/Porta1
@onready var porta_2: PortaMural = $Portas/Porta2
@onready var portal: ExitArea = $PortalSaida
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var limite_sup_esq: Marker2D = $Limites/SupEsq
@onready var limite_inf_dir: Marker2D = $Limites/InfDir
@onready var lei: Label = $LeiOriginal
@onready var assinatura: Label = $AssinaturaW3

var fase_concluida: bool = false
var tutora: TutoraMural
var _inicial: bool = true
var _assinatura_revelada: bool = false
var _lei_revelada: bool = false


func _ready() -> void:
	_aplicar_tema()
	_garantir_repositorio()
	_configurar_camera()

	tutora = TutoraMural.new()
	add_child(tutora)

	modelo.mudou.connect(_atualizar_mundo)
	portal.unlocked_entered.connect(_on_portal_unlocked_entered)
	victory_screen.proxima_fase_pressed.connect(_on_proxima_fase_pressed)
	_atualizar_mundo()
	_inicial = false


func _aplicar_tema() -> void:
	for nome in ["ObeliscoZona1", "ObeliscoZona2", "ObeliscoZona3"]:
		var obelisco := get_node_or_null(nome)
		if obelisco == null:
			continue
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


## O GameState precisa de um repositório com histórico (as runas são os arquivos do commit).
func _garantir_repositorio() -> void:
	for commit in GameState.commits:
		if commit["mensagem"] == MENSAGEM_PASSADO:
			return
	GameState.git_inicializado = true
	GameState.branch_ativa = GameState.BRANCH_PADRAO
	for nome in modelo.nomes():
		GameState.staging_area.append(nome)
	GameState.criar_commit(MENSAGEM_PASSADO)
	GameState.commits.back()["autor"] = AUTOR_PASSADO


func _configurar_camera() -> void:
	var limites: Array[Vector2] = [limite_sup_esq.global_position, limite_inf_dir.global_position]
	LevelManager.ChangeTilemapsBounds(limites)


func _atualizar_mundo() -> void:
	porta_1.definir_aberta(modelo.flag("diff_visto"))
	porta_2.definir_aberta(modelo.zona_2_ok())
	# Zona 2 limpa com a mudança boa do mar preservada: a assinatura de quem a fez reaparece
	if modelo.zona_2_ok() and not _assinatura_revelada:
		_assinatura_revelada = true
		_revelar_assinatura(not _inicial)
	if modelo.zona_3_ok():
		if portal.locked:
			portal.unlock()
		if not _lei_revelada:
			_lei_revelada = true
			_revelar_lei(not _inicial)


## A assinatura "W-3" aparece ao lado da runa do mar (estava apagada pela Corrupção).
func _revelar_assinatura(animado: bool) -> void:
	if not animado:
		assinatura.modulate.a = 1.0
		return
	create_tween().tween_property(assinatura, "modulate:a", 1.0, 1.5)
	tutora.assinatura_revelada()


## O ruído recua e, por baixo dele, aparece a lei original.
func _revelar_lei(animado: bool) -> void:
	var escrever := func() -> void:
		lei.text = TEXTO_LEI
		lei.add_theme_color_override("font_color", COR_LEI)
	if not animado:
		escrever.call()
		return
	var tween := create_tween()
	tween.tween_property(lei, "modulate:a", 0.0, 0.8)
	tween.tween_callback(escrever)
	tween.tween_property(lei, "modulate:a", 1.0, 1.5)
	tutora.mural_limpo()


func _on_portal_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[Fase 3] CONDIÇÃO DE VITÓRIA ATINGIDA!")
	victory_screen.mostrar()


func _on_proxima_fase_pressed() -> void:
	# Sai pelo portal: o FaseManager limpa o temporário e abre a entrada da fase seguinte.
	FaseManager.concluir_fase_e_avancar()

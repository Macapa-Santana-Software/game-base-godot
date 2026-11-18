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

const MENSAGEM_PASSADO := "Mural original"

@onready var modelo: ModeloMural = $ModeloMural
@onready var porta_1: PortaMural = $Portas/Porta1
@onready var porta_2: PortaMural = $Portas/Porta2
@onready var portal: ExitArea = $PortalSaida
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var limite_sup_esq: Marker2D = $Limites/SupEsq
@onready var limite_inf_dir: Marker2D = $Limites/InfDir

var fase_concluida: bool = false


func _ready() -> void:
	_garantir_repositorio()
	_configurar_camera()

	var tutora := TutoraMural.new()
	add_child(tutora)

	modelo.mudou.connect(_atualizar_mundo)
	portal.unlocked_entered.connect(_on_portal_unlocked_entered)
	victory_screen.proxima_fase_pressed.connect(_on_proxima_fase_pressed)
	_atualizar_mundo()


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


func _configurar_camera() -> void:
	var limites: Array[Vector2] = [limite_sup_esq.global_position, limite_inf_dir.global_position]
	LevelManager.ChangeTilemapsBounds(limites)


func _atualizar_mundo() -> void:
	porta_1.definir_aberta(modelo.flag("diff_visto"))
	porta_2.definir_aberta(modelo.zona_2_ok())
	if modelo.zona_3_ok() and portal.locked:
		portal.unlock()


func _on_portal_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[Fase 3] CONDIÇÃO DE VITÓRIA ATINGIDA!")
	victory_screen.mostrar()


func _on_proxima_fase_pressed() -> void:
	# Sai pelo portal: o FaseManager limpa o temporário e abre a entrada da fase seguinte.
	FaseManager.concluir_fase_e_avancar()

extends Node2D
## Fase 6 — Tutorial: "Ponto de Retorno" (comandos revert, stash e reset).
##
## Três áreas em fila, um comando novo em cada, usando o repositório REAL (GameState):
##   1. A Ponte       git log + git revert      um commit ruim sabotou a ponte
##   2. O Corredor    git stash + stash pop     trabalho pela metade e uma emergência
##   3. A Câmara      git reset --soft / --hard dois commits apressados, dois destinos
##
## A fase NÃO fecha a história: ao fim, a linha do tempo mostra um commit fantasma que o jogador
## não criou e não consegue ler. O portal abre, mas a pergunta fica (assunto de fases futuras).
##
## Esta cena só reage: o progresso e os fatos moram em EstadoRetorno (lidos do GameState).
## A IA é a da Fase 1 (TutoraFase1), com o roteiro desta fase (TutoraRetorno).

## Emitido a cada mudança do repositório ou da jornada (os filhos redesenham/reavaliam).
signal mudou
## Momentos da história para a IA comentar: "z1_ok", "z2_ok", "soft_ok", "commit_ok",
## "z3b_setup", "hard_ok", "alavanca", "restaurou".
signal evento(nome: String)

## Flags que, ao virarem verdadeiras, geram um `evento` (uma vez cada).
const MARCOS: Array[String] = ["z1_ok", "z2_ok", "soft_ok", "commit_ok", "z3b_setup", "hard_ok"]

@onready var porta_inspecao: PortaMural = $Portas/PortaInspecao
@onready var porta_camara: PortaMural = $Portas/PortaCamara
@onready var portal: ExitArea = $PortalSaida
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var limite_sup_esq: Marker2D = $Limites/SupEsq
@onready var limite_inf_dir: Marker2D = $Limites/InfDir

var fase_concluida: bool = false
var _marcos_avisados: Dictionary = {}


func _enter_tree() -> void:
	add_to_group("fase_6")


func _ready() -> void:
	EstadoRetorno.construir()
	_configurar_camera()
	# Quem já estava concluído ao carregar (recarga por derrota) não dispara falas de novo.
	for marco in MARCOS:
		_marcos_avisados[marco] = EstadoRetorno.flag(marco)

	GameState.commit_realizado.connect(_on_repositorio_mudou.unbind(1))
	GameState.reset_realizado.connect(_on_repositorio_mudou.unbind(3))
	GameState.revert_realizado.connect(_on_repositorio_mudou.unbind(2))
	GameState.stash_guardado.connect(_on_repositorio_mudou.unbind(1))
	GameState.stash_aplicado.connect(_on_repositorio_mudou.unbind(1))
	GameState.arquivos_preparados.connect(_on_repositorio_mudou.unbind(1))
	GameState.arquivo_coletado.connect(_on_repositorio_mudou.unbind(1))
	GameState.log_consultado.connect(_on_log_consultado)

	var tutora := TutoraRetorno.new()
	add_child(tutora)

	portal.unlocked_entered.connect(_on_portal_unlocked_entered)
	victory_screen.proxima_fase_pressed.connect(_on_proxima_fase_pressed)
	notificar()


func _configurar_camera() -> void:
	var limites: Array[Vector2] = [limite_sup_esq.global_position, limite_inf_dir.global_position]
	LevelManager.ChangeTilemapsBounds(limites)


func _on_log_consultado(_branch: String) -> void:
	EstadoRetorno.marcar("log_visto")
	notificar()


func _on_repositorio_mudou() -> void:
	notificar()


## Reavalia a jornada, atualiza o mundo e avisa os filhos. Também é chamada pelas alavancas e altares.
func notificar() -> void:
	EstadoRetorno.avancar()
	_atualizar_mundo()
	mudou.emit()
	for marco in MARCOS:
		if EstadoRetorno.flag(marco) and not _marcos_avisados.get(marco, false):
			_marcos_avisados[marco] = true
			evento.emit(marco)


func _atualizar_mundo() -> void:
	porta_inspecao.definir_aberta(EstadoRetorno.flag("inspecao_ok"))
	porta_camara.definir_aberta(EstadoRetorno.flag("z2_ok"))
	if EstadoRetorno.flag("hard_ok") and portal.locked:
		portal.unlock()


func _on_portal_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[Fase 6] CONDIÇÃO DE VITÓRIA ATINGIDA!")
	victory_screen.mostrar()


func _on_proxima_fase_pressed() -> void:
	# Sai pelo portal: o FaseManager limpa o temporário e abre a entrada da fase seguinte.
	FaseManager.concluir_fase_e_avancar()

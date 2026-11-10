extends Node2D
## Fase 2 — "Ecos de Possibilidades".
##
## Independente da Fase 1: reaproveita HUD, ExitArea e VictoryScreen. O repositório Git
## (commits, branches, branch ativa) vem do GameState e já chega com o histórico da
## Fase 1. O progresso da fase vive no ProgressoFase2 (adaptador do GameState) e o mapa
## reage às branches pelo RealidadesFase2.
##
## Responsabilidades daqui: posicionar o jogador, limites da câmera e concluir a fase.

@onready var progresso: ProgressoFase2 = $Progresso
@onready var realidades: RealidadesFase2 = $Realidades
@onready var player: Player = $Mundo/Player
@onready var transicao: TransicaoRealidade = $Transicao
@onready var area_arquivo: AreaFase2 = $Mundo/Area1_Arquivo
@onready var area_registro: Area5Registro = $Mundo/Area5_Registro
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var limite_sup_esq: Marker2D = $Limites/SupEsq
@onready var limite_inf_dir: Marker2D = $Limites/InfDir

var fase_concluida: bool = false


func _ready() -> void:
	print("[FASE 2] Ecos de Possibilidades carregada. Branch ativa: %s" % GameState.branch_ativa)
	realidades.iniciar(player, transicao)
	_posicionar_jogador()
	_configurar_camera()
	area_registro.saida_alcancada.connect(_on_saida_alcancada)

	var debug := get_node_or_null("DebugFase2") as DebugFase2
	if debug:
		debug.configurar(player, progresso)


func _posicionar_jogador() -> void:
	var entrada := area_arquivo.get_node("Conexoes/Entrada_Fase") as Node2D
	player.global_position = realidades.posicao_inicial(entrada.global_position)


## Os limites vêm de dois Marker2D, não de uma TileMapLayer: o LevelManager só guarda
## os limites da última tilemap carregada, o que não serve a uma fase com várias áreas.
func _configurar_camera() -> void:
	var limites: Array[Vector2] = [limite_sup_esq.global_position, limite_inf_dir.global_position]
	LevelManager.ChangeTilemapsBounds(limites)


func _on_saida_alcancada() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[FASE 2] Fase concluída.")
	victory_screen.mostrar()

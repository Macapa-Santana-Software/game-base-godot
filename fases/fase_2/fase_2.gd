extends Node2D
## Fase 2 — Tutorial: "A Ponte Quebrada".
##
## Uma sala só: um abismo separa o jogador do portal e a ponte está quebrada. Para
## consertá-la, o jogador apresenta os comandos log, branch, switch e merge (e revê
## add/commit): cria a branch `ponte`, troca para ela, pega a peça, registra, volta para
## a `main` e faz o merge. A ponte e o portal reagem ao repositório Git REAL (GameState).
##
## A IA é a da Fase 1 (TutoraFase1), com o roteiro desta fase (TutoraPonte).
## Responsabilidades daqui: histórico inicial, câmera, tutora, saída e vitória.

## Commit do "passado" que o `git log` mostra. Só é criado se ainda não existir
## (a Fase 1 já deixa commits; ao abrir esta fase direto, ele garante um histórico).
const MENSAGEM_PASSADO := "Ponte intacta"
const ARQUIVO_PASSADO := "ponte_inteira.map"

@onready var ponte: PonteTutorial = $Ponte
@onready var portal: ExitArea = $PortalSaida
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var limite_sup_esq: Marker2D = $Limites/SupEsq
@onready var limite_inf_dir: Marker2D = $Limites/InfDir

var fase_concluida: bool = false


func _ready() -> void:
	_garantir_historico()
	_configurar_camera()

	var arquivos_requeridos: Array[String] = []
	for item in get_tree().get_nodes_in_group(ItemColetavel.GRUPO_ARQUIVOS):
		arquivos_requeridos.append(item.nome_do_item)
	var tutora := TutoraPonte.new()
	tutora.arquivos_requeridos = arquivos_requeridos
	add_child(tutora)

	ponte.ponte_concluida.connect(_liberar_saida)
	portal.unlocked_entered.connect(_on_portal_unlocked_entered)
	victory_screen.proxima_fase_pressed.connect(_on_proxima_fase_pressed)

	# Recarregar a cena (ex.: derrota) depois do merge: a saída já nasce liberada.
	if EstadoPonte.na_main():
		_liberar_saida()


## Garante um commit "Ponte intacta" na main para o `git log` ter um passado a mostrar.
func _garantir_historico() -> void:
	for commit in GameState.commits:
		if commit["mensagem"] == MENSAGEM_PASSADO:
			return
	GameState.git_inicializado = true
	GameState.branch_ativa = GameState.BRANCH_PADRAO
	GameState.staging_area.append(ARQUIVO_PASSADO)
	GameState.criar_commit(MENSAGEM_PASSADO)


## Os limites vêm de dois Marker2D (o LevelManager guarda os limites da câmera).
func _configurar_camera() -> void:
	var limites: Array[Vector2] = [limite_sup_esq.global_position, limite_inf_dir.global_position]
	LevelManager.ChangeTilemapsBounds(limites)


func _liberar_saida() -> void:
	if portal.locked:
		portal.unlock()


func _on_portal_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[Fase 2] CONDIÇÃO DE VITÓRIA ATINGIDA!")
	victory_screen.mostrar()


func _on_proxima_fase_pressed() -> void:
	# Sai pelo portal: o FaseManager limpa o temporário e abre a entrada da fase seguinte.
	FaseManager.concluir_fase_e_avancar()

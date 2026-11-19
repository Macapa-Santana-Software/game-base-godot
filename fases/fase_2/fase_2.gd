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
const ID_PASSADO := "c0e1f"
const AUTOR_PASSADO := "E."

@onready var ponte: PonteTutorial = $Ponte
@onready var portal: ExitArea = $PortalSaida
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var limite_sup_esq: Marker2D = $Limites/SupEsq
@onready var limite_inf_dir: Marker2D = $Limites/InfDir

## Arte da Fase 2 aplicada aos objetos compartilhados (obelisco e portal), na paleta do cânion.
@export var textura_plataforma: Texture2D
@export var textura_portal: Texture2D
@export var cor_luz: Color = Color("FF5A3C")

var fase_concluida: bool = false
var tutora: TutoraPonte
var _ponte_pisada: bool = false


func _ready() -> void:
	_aplicar_tema()
	_garantir_historico()
	_configurar_camera()

	var arquivos_requeridos: Array[String] = []
	for item in get_tree().get_nodes_in_group(ItemColetavel.GRUPO_ARQUIVOS):
		arquivos_requeridos.append(item.nome_do_item)
	tutora = TutoraPonte.new()
	tutora.arquivos_requeridos = arquivos_requeridos
	add_child(tutora)

	$Passagem.body_entered.connect(_on_passagem_body_entered)
	ponte.ponte_concluida.connect(_liberar_saida)
	portal.unlocked_entered.connect(_on_portal_unlocked_entered)
	victory_screen.proxima_fase_pressed.connect(_on_proxima_fase_pressed)

	# Recarregar a cena (ex.: derrota) depois do merge: a saída já nasce liberada.
	if EstadoPonte.na_main():
		_liberar_saida()


func _aplicar_tema() -> void:
	var plataforma := $ObjetoTerminal.get_node_or_null("Plataforma") as Sprite2D
	if plataforma and textura_plataforma:
		plataforma.texture = textura_plataforma
	var luz_obelisco := $ObjetoTerminal.get_node_or_null("Luz") as PointLight2D
	if luz_obelisco:
		luz_obelisco.color = cor_luz
	var visual_portal := $PortalSaida.get_node_or_null("Portal") as Sprite2D
	if visual_portal and textura_portal:
		visual_portal.texture = textura_portal
	var luz_portal := $PortalSaida.get_node_or_null("Luz") as PointLight2D
	if luz_portal:
		luz_portal.color = cor_luz


## Garante o commit "Ponte intacta" (autor "E.") no começo da história: o `git log` ganha um passado
## ANTERIOR aos commits da Fase 1, de um autor que o jogador não conhece. Não duplica ao recarregar.
func _garantir_historico() -> void:
	for commit in GameState.commits:
		if commit["mensagem"] == MENSAGEM_PASSADO:
			return
	var passado := {
		"id": ID_PASSADO,
		"mensagem": MENSAGEM_PASSADO,
		"arquivos": [ARQUIVO_PASSADO],
		"pai": "",
		"pais": [],
		"autor": AUTOR_PASSADO,
	}
	# Os commits que já existiam (raízes) passam a descender dele.
	for commit in GameState.commits:
		if commit["pais"].is_empty():
			commit["pai"] = ID_PASSADO
			commit["pais"] = [ID_PASSADO]
	GameState.commits.push_front(passado)
	GameState.git_inicializado = true
	if not GameState.branches.has(GameState.branch_ativa):
		GameState.branches[GameState.branch_ativa] = {"head": ID_PASSADO, "mundo": {}}


## O chão da ponte sustenta: a primeira vez que o jogador pisa nela (já sólida) a IA comenta.
func _on_passagem_body_entered(body: Node) -> void:
	if body is Player and not _ponte_pisada and EstadoPonte.na_main():
		_ponte_pisada = true
		tutora.pisou_na_ponte()


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

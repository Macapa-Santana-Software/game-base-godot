class_name AreaFase2 extends Node2D
## Base de cada uma das áreas da Fase 2.
##
## Estrutura padrão de filhos (todas as áreas seguem a mesma):
##   Piso (z -2)    ColorRects do chão  -> futura TileMapLayer de piso
##   Paredes (z -1) ParedeFase2/BarreiraFase2 -> futura TileMapLayer com colisão
##   Decor (z -1)   detalhes visuais sem colisão
##   Objetos        PropFase2 ordenados por Y (y_sort_enabled)
##   Interacoes     ZonaInteracao/FissuraFase2/ExitArea
##   Conexoes       ConexaoFase2: entradas, saídas, spawn de debug, slots
##   Iluminacao     Marker2D "SlotLuz_*" reservados; SEM luz implementada
##
## Y-SORT: esta raiz, `Objetos` e a raiz da fase têm y_sort_enabled. No Godot 4 a
## ordenação por Y atravessa toda a cadeia de nós com y_sort_enabled, então o Player
## (filho de `Mundo`) é ordenado junto com os props de TODAS as áreas, sem reparenting.

signal jogador_entrou(area: AreaFase2)
signal jogador_saiu(area: AreaFase2)

const GRUPO := &"area_fase2"
const TILE := 32
## Escurecimento de uma realidade que não é a branch ativa (provisório, só `modulate`).
const COR_INATIVA := Color(0.42, 0.42, 0.52, 1.0)

@export var id_area: StringName = &""
@export var nome_exibicao: String = ""
## Realidade (branch) a que a área pertence. "neutra" e "convergencia" não alteram a
## branch ativa.
@export_enum("neutra", "main", "vida-alternativa", "convergencia") var realidade: String = "neutra"
## Retângulo da área em tiles locais, usado para detectar a entrada do jogador.
@export var retangulo_tiles: Rect2i = Rect2i(0, 0, 10, 10)
## Retângulos adicionais (ex.: corredores de acesso) que também contam como parte da área.
## Numa realidade, os corredores até as portas fazem parte dela: quem está ali é "de
## dentro" e é reposicionado numa troca de branch.
@export var retangulos_extras: Array[Rect2i] = []


func _enter_tree() -> void:
	add_to_group(GRUPO)


func _ready() -> void:
	var deteccao := Area2D.new()
	deteccao.name = "Deteccao"
	deteccao.collision_layer = 0
	deteccao.collision_mask = 1
	deteccao.monitorable = false
	_adicionar_forma(deteccao, retangulo_tiles)
	for extra in retangulos_extras:
		_adicionar_forma(deteccao, extra)
	add_child(deteccao)
	deteccao.body_entered.connect(_on_deteccao_body_entered)
	deteccao.body_exited.connect(_on_deteccao_body_exited)


func _adicionar_forma(deteccao: Area2D, retangulo_em_tiles: Rect2i) -> void:
	var forma := CollisionShape2D.new()
	var retangulo := RectangleShape2D.new()
	retangulo.size = Vector2(retangulo_em_tiles.size) * TILE
	forma.shape = retangulo
	forma.position = (Vector2(retangulo_em_tiles.position) + Vector2(retangulo_em_tiles.size) / 2.0) * TILE
	deteccao.add_child(forma)


## Realidade ativa = visual normal; inativa = escurecida.
func definir_ativa(ativa: bool) -> void:
	modulate = Color.WHITE if ativa else COR_INATIVA


## Ponto de entrada da área (início da realidade), ou o spawn de debug como alternativa.
func entrada_global() -> Vector2:
	var ponto := get_node_or_null("Conexoes/Entrada_Ramificacao") as Node2D
	return ponto.global_position if ponto else ponto_spawn_debug()


## Ponto seguro para a ferramenta de debug teleportar o jogador.
func ponto_spawn_debug() -> Vector2:
	var ponto := get_node_or_null("Conexoes/PontoDebug") as Node2D
	return ponto.global_position if ponto else global_position


func _on_deteccao_body_entered(body: Node2D) -> void:
	if body is Player:
		jogador_entrou.emit(self)


func _on_deteccao_body_exited(body: Node2D) -> void:
	if body is Player:
		jogador_saiu.emit(self)

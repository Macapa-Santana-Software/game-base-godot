extends Node2D

## Porta trancada que abre quando o jogador está perto, com o slot da chave selecionado,
## e pressiona Enter (ui_accept).

# --- Camadas de física (valores bitmask, não o número da layer no inspetor) ---
const LAYER_PLAYER_BIT := 1
const LAYER_WALLS_BIT := 16

const NOME_INVENTARIO := "InventarioUI"
const NOME_PLAYER := "Player"
const NOME_CORPO_FISICO := "CorpoFisico"
const NOME_AREA_DETECCAO := "AreaDeteccao"

@export_group("Identificação da chave")
@export var textura_chave_referencia: Texture2D
@export var caminhos_textura_chave: PackedStringArray = PackedStringArray(["res://icon.svg"])

@onready var corpo_fisico: StaticBody2D = $CorpoFisico
@onready var area_deteccao: Area2D = $AreaDeteccao
@onready var balao_aviso_portao: Label = $Label

var _player_perto: bool = false
var _porta_aberta: bool = false
var _ultimo_estado_feedback: int = -1 # -1 = sem feedback | 0 = trancado | 1 = pode usar chave
var _textura_chave: Texture2D


func _ready() -> void:
	balao_aviso_portao.visible = false
	_configurar_textura_chave()
	_configurar_colisoes()
	_conectar_sinais_area()


func _configurar_textura_chave() -> void:
	if textura_chave_referencia:
		_textura_chave = textura_chave_referencia
	else:
		_textura_chave = load("res://icon.svg") as Texture2D


func _configurar_colisoes() -> void:
	corpo_fisico.collision_layer = LAYER_WALLS_BIT
	corpo_fisico.collision_mask = 0

	area_deteccao.collision_mask = LAYER_PLAYER_BIT
	area_deteccao.collision_layer = 0
	area_deteccao.monitoring = true


func _conectar_sinais_area() -> void:
	if not area_deteccao.body_entered.is_connected(_on_area_body_entered):
		area_deteccao.body_entered.connect(_on_area_body_entered)
	if not area_deteccao.body_exited.is_connected(_on_area_body_exited):
		area_deteccao.body_exited.connect(_on_area_body_exited)


func _process(_delta: float) -> void:
	if _porta_aberta or not _player_perto:
		return

	_atualizar_feedback_proximo()

	if Input.is_action_just_pressed("ui_accept"):
		_tentar_abrir_porta()


func _on_area_body_entered(body: Node2D) -> void:
	if body.name != NOME_PLAYER:
		return

	_player_perto = true
	_ultimo_estado_feedback = -1
	_atualizar_feedback_proximo()


func _on_area_body_exited(body: Node2D) -> void:
	if body.name != NOME_PLAYER:
		return

	_player_perto = false
	_ultimo_estado_feedback = -1


func _atualizar_feedback_proximo() -> void:
	var estado_atual := 1 if _slot_ativo_tem_chave() else 0
	if estado_atual == _ultimo_estado_feedback:
		return

	_ultimo_estado_feedback = estado_atual
	if estado_atual == 1:
		print("Use a chave apertando Enter")
	else:
		print("Portão trancado")


func _tentar_abrir_porta() -> void:
	if not _slot_ativo_tem_chave():
		print("Portão trancado")
		return

	print("[PORTA] Chave válida detectada! Abrindo...")
	_consumir_chave_do_slot_ativo()
	_abrir_porta()


func _obter_inventario() -> CanvasLayer:
	return get_tree().current_scene.find_child(NOME_INVENTARIO, true, false) as CanvasLayer


func _obter_slot_ativo(inventario: CanvasLayer) -> Panel:
	if not inventario or not inventario.get("slots"):
		return null

	for slot in inventario.slots:
		var highlight := slot.get_node_or_null("Highlight") as ColorRect
		if highlight and highlight.visible:
			return slot
	return null


func _slot_ativo_tem_chave() -> bool:
	var inventario := _obter_inventario()
	if inventario == null:
		return false

	var slot := _obter_slot_ativo(inventario)
	if slot == null:
		return false

	var icone := slot.get_node_or_null("Icone") as TextureRect
	if icone == null or icone.texture == null:
		# Removido o print repetitivo daqui para não poluir o console a cada frame
		return false

	return _textura_e_chave(icone.texture)


func _textura_e_chave(textura: Texture2D) -> bool:
	if textura == null:
		return false

	if _textura_chave and textura == _textura_chave:
		return true

	var path := textura.resource_path
	for caminho in caminhos_textura_chave:
		if path == caminho:
			return true

	var nome_arquivo := path.get_file().to_lower()
	if "chave" in nome_arquivo or "key" in nome_arquivo:
		return true

	return false


func _consumir_chave_do_slot_ativo() -> void:
	var inventario := _obter_inventario()
	if inventario == null:
		return

	var slot := _obter_slot_ativo(inventario)
	if slot == null:
		return

	var icone := slot.get_node("Icone") as TextureRect
	icone.texture = null
	icone.modulate = Color.WHITE


func _abrir_porta() -> void:
	if _porta_aberta:
		return

	_porta_aberta = true
	print("Porta aberta com sucesso!")

	if is_instance_valid(corpo_fisico):
		corpo_fisico.queue_free()

	area_deteccao.monitoring = false
	set_process(false)
	
	
	
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		balao_aviso_portao.visible = true
		_player_perto = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		balao_aviso_portao.visible = false
		_player_perto = false

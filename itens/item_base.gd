class_name ItemBase extends Area2D

@export var nome_do_item: String = "Item"
@export var cor_do_item: Color = Color.WHITE

func _ready():
	if has_node("Sprite2D"):
		$Sprite2D.modulate = cor_do_item
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if "Player" in body.name or body.is_in_group("player"):
		coletar()

func coletar():
	var inventario = get_tree().current_scene.find_child("InventarioUI", true, false)
	if not inventario:
		inventario = get_tree().get_first_node_in_group("inventario_ui")
	if inventario:
		inventario.adicionar_item(nome_do_item, $Sprite2D.texture if has_node("Sprite2D") else null, cor_do_item)
		ao_ser_coletado()  # hook para comportamento específico
		queue_free()
	else:
		push_error("Erro: InventarioUI não encontrado!")

# Método virtual – subclasses sobrescrevem se precisar de algo extra
func ao_ser_coletado():
	pass

extends Area2D

# Configurado no Inspetor de cada cópia: "main.gd" ou "setup.gd"
@export var nome_do_item: String = "main.gd"
@export var cor_do_item: Color = Color.AQUAMARINE

func _ready():
	# Modula a cor do Sprite filho
	if has_node("Sprite2D"):
		$Sprite2D.modulate = cor_do_item
	
	# Conecta o sinal de colisão nativo
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Correção 1: Detecta se o nome contém 'Player' ou se está no grupo 'player'
	if "Player" in body.name or body.is_in_group("player"):
		coletar()

func coletar():
	# Correção 2: Método mais robusto para achar o inventário caso ele esteja escondido em sub-nós
	var inventario = get_tree().current_scene.find_child("InventarioUI", true, false)
	
	# Se ainda assim não achar, tentamos buscar pelo grupo (Garantia Extra)
	if not inventario:
		inventario = get_tree().get_first_node_in_group("inventario_ui")
	
	if inventario:
		var textura = $Sprite2D.texture if has_node("Sprite2D") else null
		
		# Envia para o seu script do inventário
		inventario.adicionar_item(nome_do_item, textura, cor_do_item)
		
		# Faz o arquivo sumir do chão!
		queue_free()
	else:
		push_error("Erro crítico: O item não conseguiu encontrar o 'InventarioUI' na fase!")

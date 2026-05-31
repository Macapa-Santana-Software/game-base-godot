extends Area2D

# Aqui definimos o que esse item é. 
# Podemos mudar isso no Inspetor sem mexer no código!
@export var nome_do_item: String = "Chave"
@export var cor_do_item: Color = Color.AQUAMARINE

func _ready():
	# Muda a cor do ícone para podermos diferenciar os itens visualmente
	$Sprite2D.modulate = cor_do_item
	# Conecta o sinal de quando algo entra na área
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Verifica se quem encostou foi o jogador
	if body.name == "Player":
		coletar()

func coletar():
	# Procura a sua cena de Inventário que está na fase
	var inventario = get_tree().current_scene.find_child("InventarioUI")
	
	if inventario:
		# Chama uma função no inventário para ocupar um slot
		# (Vamos criar essa função no script do Inventário a seguir)
		inventario.adicionar_item(nome_do_item, $Sprite2D.texture, cor_do_item)
		queue_free() # O item some do mapae

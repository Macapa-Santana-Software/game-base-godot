class_name Chave extends ItemBase

func _ready():
	# Muda a cor do ícone para podermos diferenciar os itens visualmente
	nome_do_item = "Chave"
	cor_do_item = Color.AQUAMARINE
	super._ready()  # chama o _ready() da base

func _on_body_entered(body):
	# Verifica se quem encostou foi o jogador
	if body.name == "Player":
		coletar()

#func coletar():
	## Procura a sua cena de Inventário que está na fase
	#var inventario = get_tree().current_scene.find_child("InventarioUI")
	#
	#if inventario:
		## Chama uma função no inventário para ocupar um slot
		## (Vamos criar essa função no script do Inventário a seguir)
		#inventario.adicionar_item(nome_do_item, $Sprite2D.texture, cor_do_item)
		#queue_free() # O item some do mapae

func ao_ser_coletado():
	# Comportamento específico da chave, ex: abrir uma porta
	pass

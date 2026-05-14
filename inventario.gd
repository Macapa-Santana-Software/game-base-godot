extends CanvasLayer

# Pegamos os slots para o código conseguir "conversar" com eles
@onready var slots = [$HBoxContainer/Slot0, $HBoxContainer/Slot1, $HBoxContainer/Slot2]

func _ready():
	selecionar_slot(0) # Começa com o primeiro selecionado

func _input(event):
	# Se apertar a tecla 1, seleciona o slot 0
	if event.is_action_pressed("slot1"):
		selecionar_slot(0)
	# Se apertar a tecla 2, seleciona o slot 1
	if event.is_action_pressed("slot2"):
		selecionar_slot(1)
	# Se apertar a tecla 3, seleciona o slot 2
	if event.is_action_pressed("slot3"):
		selecionar_slot(2)

func selecionar_slot(indice):
	# Primeiro, apaga o brilho de todos os slots
	for s in slots:
		s.get_node("Highlight").visible = false
	
	# Agora, liga o brilho apenas no slot que a gente escolheu
	slots[indice].get_node("Highlight").visible = true
	print("Você selecionou o slot: ", indice + 1)

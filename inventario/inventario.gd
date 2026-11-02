extends CanvasLayer

# Pegamos os slots para o código conseguir "conversar" com eles
@onready var slots = [$HBoxContainer/Slot0, $HBoxContainer/Slot1, $HBoxContainer/Slot2]
@onready var nome_item_label = $NomeItemLabel

func _ready():
	# Quando um commit acontece, o nome exibido do item selecionado passa a indicar "versionado"
	GameState.commit_realizado.connect(_on_commit_realizado)
	selecionar_slot(0) # Começa com o primeiro selecionado

func _on_commit_realizado(_commit_info: Dictionary) -> void:
	for s in slots:
		if s.get_node("Highlight").visible:
			nome_item_label.text = _nome_exibido(s)

# Nome do item no rótulo; arquivos já commitados ganham o sufixo "(versionado)".
# O meta "nome_do_item" continua com o nome puro (a porta depende dele).
func _nome_exibido(slot: Node) -> String:
	if not slot.has_meta("nome_do_item"):
		return ""
	var nome: String = slot.get_meta("nome_do_item")
	if GameState.esta_versionado(nome):
		return nome + " (versionado)"
	return nome

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
	
	nome_item_label.text = _nome_exibido(slots[indice])
	
	
func adicionar_item(nome, textura, cor):
	for i in range(slots.size()):
		var icone_no_slot = slots[i].get_node("Icone")
		
		if icone_no_slot.texture == null:
			icone_no_slot.texture = textura
			icone_no_slot.modulate = cor
			# Garante que o ícone preencha o espaço corretamente via código (opcional)
			icone_no_slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icone_no_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			slots[i].set_meta("nome_do_item", nome)
			
			if slots[i].get_node("Highlight").visible:
				nome_item_label.text = nome
			
			GameState.coletar_arquivo_no_mapa(nome)
			
			print("Item ", nome, " adicionado ao slot ", i)
			return

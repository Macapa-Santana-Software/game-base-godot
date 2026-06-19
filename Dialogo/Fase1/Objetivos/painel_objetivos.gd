extends CanvasLayer

@onready var lista_objetivos = $Control/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ListaObjetivos
var font_file = preload("res://Dialogo/MonospacePixel.ttf")

func _ready():
	_carregar_objetivos_da_fase()

func _carregar_objetivos_da_fase():
	var root_node = get_tree().current_scene
	if root_node and root_node.has_meta("objetivos"):
		var objetivos = root_node.get_meta("objetivos")
		for obj in objetivos:
			_adicionar_objetivo(str(obj))

func _adicionar_objetivo(texto: String):
	var label = Label.new()
	label.text = "- " + texto
	label.add_theme_font_override("font", font_file)
	label.add_theme_font_size_override("font_size", 8)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lista_objetivos.add_child(label)

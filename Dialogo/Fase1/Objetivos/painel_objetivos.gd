extends CanvasLayer

const PREFIXO_COLETAR := "Coletar o arquivo: "

@onready var lista_objetivos = $Control/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ListaObjetivos
var font_file = preload("res://Dialogo/MonospacePixel.ttf")

var _labels_por_arquivo: Dictionary = {}
var _labels_por_commit: Array[RichTextLabel] = []

func _ready():
	_carregar_objetivos_da_fase()
	GameState.arquivo_coletado.connect(_on_arquivo_coletado)
	GameState.commit_realizado.connect(_on_commit_realizado)
	_aplicar_estado_ja_existente()

func _carregar_objetivos_da_fase():
	var root_node = get_tree().current_scene
	if root_node and root_node.has_meta("objetivos"):
		var objetivos = root_node.get_meta("objetivos")
		for obj in objetivos:
			_adicionar_objetivo(str(obj))

func _adicionar_objetivo(texto: String):
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.add_theme_font_override("normal_font", font_file)
	label.add_theme_font_size_override("normal_font_size", 6)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_meta("texto_original", "- " + texto)
	label.text = label.get_meta("texto_original")
	lista_objetivos.add_child(label)

	if texto.begins_with(PREFIXO_COLETAR):
		_labels_por_arquivo[texto.substr(PREFIXO_COLETAR.length())] = label
	elif "commit" in texto.to_lower():
		_labels_por_commit.append(label)

## Cobre o caso de reabrir/recarregar a fase com progresso ja feito antes do
## painel existir (ex.: apos reiniciar a fase depois de um commit anterior).
func _aplicar_estado_ja_existente() -> void:
	for nome_arquivo in _labels_por_arquivo.keys():
		if nome_arquivo in GameState.inventario_player:
			_marcar_concluido(_labels_por_arquivo[nome_arquivo])
	if not GameState.commits.is_empty():
		for label in _labels_por_commit:
			_marcar_concluido(label)

func _on_arquivo_coletado(nome_arquivo: String) -> void:
	if _labels_por_arquivo.has(nome_arquivo):
		_marcar_concluido(_labels_por_arquivo[nome_arquivo])

func _on_commit_realizado(_commit_info: Dictionary) -> void:
	for label in _labels_por_commit:
		_marcar_concluido(label)

func _marcar_concluido(label: RichTextLabel) -> void:
	if label.has_meta("concluido"):
		return
	label.set_meta("concluido", true)
	label.text = "[s]%s[/s]" % label.get_meta("texto_original")
	label.modulate = Color(0.6, 0.6, 0.6, 1)

extends CanvasLayer

const PROMPT := "[color=#3DFF9B]dev@central:~$[/color] "

@onready var painel_centralizador: Control = $PainelCentralizador
@onready var historico: RichTextLabel = $PainelCentralizador/TerminalPanel/MarginContainer/VBoxContainer/Output
@onready var campo_texto: LineEdit = $PainelCentralizador/TerminalPanel/MarginContainer/VBoxContainer/Input
@onready var close_button: Button = $PainelCentralizador/TerminalPanel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var terminal_panel: Panel = $PainelCentralizador/TerminalPanel
@onready var overlay: ColorRect = $Overlay

var _command_history: Array[String] = []
var _history_index: int = -1
var _interpreter: TerminalCommandInterpreter
var _opening_tween: Tween

func _ready() -> void:
	add_to_group("terminal_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	campo_texto.text_submitted.connect(_ao_digitar)
	close_button.pressed.connect(fechar)
	campo_texto.placeholder_text = "Digite um comando Git..."
	
	# Instancia o interpretador limpo
	_interpreter = TerminalCommandInterpreter.new()
	add_child(_interpreter)
	
	escrever_no_terminal(
		"SISTEMA CENTRAL DE TERMINAL - FASE 1\n"
		+ "Mecânicas de foco: git init, git status, git add e git commit.\n"
		+ "Digite 'git status' para analisar o ambiente."
	)

func abrir() -> void:
	show()
	get_tree().paused = true
	await get_tree().process_frame
	_update_layout()
	_play_open_fx()
	campo_texto.grab_focus()
	campo_texto.clear()

func fechar() -> void:
	hide()
	get_tree().paused = false

func _ao_digitar(texto: String) -> void:
	var clean_text := texto.strip_edges()
	if clean_text.is_empty(): return

	_command_history.append(clean_text)
	_history_index = _command_history.size()
	historico.append_text("\n%s%s" % [PROMPT, clean_text])

	if clean_text == "exit":
		fechar()
		campo_texto.clear()
		return

	var output := _interpreter.execute_command(clean_text)
	if not output.is_empty():
		escrever_no_terminal(output)
		
	campo_texto.clear()

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()

func escrever_no_terminal(mensagem: String) -> void:
	historico.append_text("\n" + mensagem)

func _notification(what: int) -> void:
	pass

func _on_viewport_size_changed() -> void:
	if visible:
		_update_layout()

func _update_layout() -> void:
	# Filhos de CanvasLayer precisam de um Control raiz com o tamanho do viewport;
	# âncoras sozinhas nem sempre recebem retângulo válido do pai.
	var vr := get_viewport().get_visible_rect()
	painel_centralizador.set_position(vr.position)
	painel_centralizador.set_size(vr.size)
	_refresh_terminal_panel_pivot()

func _refresh_terminal_panel_pivot() -> void:
	var sz := terminal_panel.size
	if sz.x >= 1.0 and sz.y >= 1.0:
		terminal_panel.pivot_offset = sz * 0.5
	else:
		var fallback := get_viewport().get_visible_rect().size * 0.7 * 0.5
		terminal_panel.pivot_offset = fallback

func _play_open_fx() -> void:
	if _opening_tween: _opening_tween.kill()
	overlay.modulate.a = 0.0
	terminal_panel.scale = Vector2(0.95, 0.95)
	terminal_panel.modulate.a = 0.0
	_opening_tween = create_tween().set_parallel(true)
	_opening_tween.tween_property(overlay, "modulate:a", 1.0, 0.15)
	_opening_tween.tween_property(terminal_panel, "scale", Vector2.ONE, 0.15)
	_opening_tween.tween_property(terminal_panel, "modulate:a", 1.0, 0.15)

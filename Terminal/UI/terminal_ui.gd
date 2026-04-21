extends Control

const PROMPT := "[color=#3DD86F]player@player:$[/color] "

@onready var historico: RichTextLabel = $CenterContainer/TerminalPanel/MarginContainer/VBoxContainer/Output
@onready var campo_texto: LineEdit = $CenterContainer/TerminalPanel/MarginContainer/VBoxContainer/Input
@onready var close_button: Button = $CenterContainer/TerminalPanel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var terminal_panel: Panel = $CenterContainer/TerminalPanel

var _command_history: Array[String] = []
var _history_index: int = -1
var _interpreter: TerminalCommandInterpreter


func _ready() -> void:
	hide()
	campo_texto.text_submitted.connect(_ao_digitar)
	close_button.pressed.connect(fechar)
	campo_texto.placeholder_text = "Digite um comando Git..."
	escrever_no_terminal("Terminal conectado. Digite comandos Git para manipular o mundo.")


func set_interpreter(interpreter: TerminalCommandInterpreter) -> void:
	_interpreter = interpreter


func abrir() -> void:
	_update_layout()
	show()
	_update_input_prompt()
	campo_texto.grab_focus()
	get_tree().paused = true


func fechar() -> void:
	hide()
	get_tree().paused = false


func _ao_digitar(texto: String) -> void:
	var clean_text := texto.strip_edges()
	if clean_text.is_empty():
		return

	_command_history.append(clean_text)
	_history_index = _command_history.size()
	historico.append_text("\n%s%s" % [PROMPT, clean_text])

	if clean_text == "exit":
		escrever_no_terminal("Sessão encerrada.")
		fechar()
		campo_texto.clear()
		return

	if _interpreter == null:
		escrever_no_terminal("Erro interno: interpretador de comandos não configurado.")
		campo_texto.clear()
		return

	var output := _interpreter.execute_command(clean_text)
	if not output.is_empty():
		escrever_no_terminal(output)
	campo_texto.clear()
	_update_input_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		fechar()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up"):
		_apply_history(-1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_down"):
		_apply_history(1)
		get_viewport().set_input_as_handled()


func _apply_history(step: int) -> void:
	if _command_history.is_empty():
		return

	_history_index = clamp(_history_index + step, 0, _command_history.size())
	if _history_index >= _command_history.size():
		campo_texto.text = ""
	else:
		campo_texto.text = _command_history[_history_index]
	campo_texto.caret_column = campo_texto.text.length()


func escrever_no_terminal(mensagem: String) -> void:
	historico.append_text("\n" + mensagem)


func _update_input_prompt() -> void:
	campo_texto.placeholder_text = "player@player:$ digite um comando"


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(terminal_panel):
		_update_layout()


func _update_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	terminal_panel.custom_minimum_size = viewport_size * Vector2(0.35, 0.35)

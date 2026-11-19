extends CanvasLayer

signal resumed
signal quit_requested

const GRUPO_SISTEMAS_PAUSAVEIS := "sistema_pausavel"

const DURACAO_FADE := 0.15

@onready var raiz: Control = %Control
@onready var continuar_button: Button = %ContinuarButton
@onready var diario_button: Button = %DiarioButton
@onready var controles_button: Button = %ControlesButton
@onready var sair_button: Button = %SairButton
@onready var painel_principal: Control = $Control/CenterContainer/Painel
@onready var painel_controles: Control = %PainelControles
@onready var voltar_button: Button = %VoltarButton

var _pausado_por_outro_sistema: bool = false

func _ready() -> void:
	hide()
	continuar_button.pressed.connect(continuar)
	diario_button.pressed.connect(Diario.abrir_diario)
	Diario.diario_fechado.connect(_on_diario_fechado)
	controles_button.pressed.connect(_mostrar_controles.bind(true))
	voltar_button.pressed.connect(_mostrar_controles.bind(false))
	sair_button.pressed.connect(sair)

## Alterna entre o menu e a tela de controles (só leitura).
func _mostrar_controles(mostrar: bool) -> void:
	painel_controles.visible = mostrar
	painel_principal.visible = not mostrar
	if mostrar:
		voltar_button.grab_focus()
	else:
		controles_button.grab_focus()

func _on_diario_fechado() -> void:
	# Ao fechar o Diário (aberto por este menu) o foco volta para o botão dele.
	if visible:
		diario_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible and painel_controles.visible:
			_mostrar_controles(false)  # Esc na tela de controles volta ao menu
		elif visible:
			continuar()
		else:
			abrir()
		get_viewport().set_input_as_handled()

func abrir() -> void:
	# Se algo (ex.: um diálogo) já tinha pausado a árvore, o menu não deve
	# despausar tudo sozinho ao ser fechado depois.
	_pausado_por_outro_sistema = get_tree().paused
	_avisar_sistemas_pausaveis(true)
	_mostrar_controles(false)
	show()
	get_tree().paused = true
	# Entrada suave e foco no primeiro botão (navegação por teclado/Enter)
	raiz.modulate.a = 0.0
	create_tween().tween_property(raiz, "modulate:a", 1.0, DURACAO_FADE)
	continuar_button.grab_focus()

func continuar() -> void:
	hide()
	_avisar_sistemas_pausaveis(false)
	if not _pausado_por_outro_sistema:
		get_tree().paused = false
	resumed.emit()

func _avisar_sistemas_pausaveis(pausar: bool) -> void:
	for sistema in get_tree().get_nodes_in_group(GRUPO_SISTEMAS_PAUSAVEIS):
		if sistema == self:
			continue
		if pausar and sistema.has_method("pausar"):
			sistema.pausar()
		elif not pausar and sistema.has_method("despausar"):
			sistema.despausar()

func sair() -> void:
	quit_requested.emit()
	get_tree().quit()

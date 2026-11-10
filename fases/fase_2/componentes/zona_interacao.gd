@tool
class_name ZonaInteracao extends Area2D
## Zona de interação genérica da Fase 2: detecta o Player (por tipo, não por nome),
## mostra o prompt e emite `interagido` quando a ação de interação é pressionada.
##
## Usa a ação JÁ EXISTENTE do Input Map `interagir_terminal` (tecla T); nenhuma ação
## nova foi criada. Troque `acao_input` na instância se algum dia for preciso.
##
## PLACEHOLDER: os "Efeitos de progresso" abaixo (flag, branch, mensagem) são o
## comportamento provisório da Parte 1. Nas próximas partes, os comandos Git reais
## passam a ligar essas mesmas flags no ProgressoFase2 e as zonas viram só gatilhos
## de abrir o terminal.

signal interagido(zona: ZonaInteracao)

const FONTE := preload("res://Dialogo/MonospacePixel.ttf")

@export var tamanho: Vector2 = Vector2(64, 64):
	set(valor):
		tamanho = valor
		_atualizar_forma()
@export var texto_prompt: String = "Interagir"
@export var acao_input: StringName = &"interagir_terminal"
## Se true, só pode ser usada uma vez.
@export var uma_vez: bool = true
## Flags que precisam estar ativas para a zona funcionar (vazio = sempre disponível).
@export var flags_requeridas: PackedStringArray = PackedStringArray()
## Dica mostrada ao se aproximar enquanto as `flags_requeridas` ainda não valem.
@export_multiline var texto_indisponivel: String = ""
## Arquivo REAL que o uso desta zona coloca no inventário (GameState). Depois ele precisa ser
## versionado com `git add` e `git commit`. Vazio = a zona não coleta nada.
@export var arquivo_que_coleta: String = ""

@export_group("Efeitos de progresso (PLACEHOLDER)")
@export var flag_que_define: StringName = &""
@export_multiline var mensagem: String = ""
## Nó (relativo a esta zona) escondido depois do uso. Ex.: o eco recolhido.
@export var esconder_ao_usar: NodePath = NodePath()

@onready var forma: CollisionShape2D = $Forma

var _jogador_dentro: bool = false
var _usada: bool = false
var _rotulo: Label


func _ready() -> void:
	_atualizar_forma()
	set_process(false)
	if Engine.is_editor_hint():
		return
	_criar_rotulo()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_restaurar_se_ja_usada()


## Se a flag que esta zona define já estava ativa ao carregar a cena (ex.: eco recolhido
## antes de uma derrota), a zona nasce usada e o objeto associado nasce escondido.
func _restaurar_se_ja_usada() -> void:
	if not uma_vez or flag_que_define == &"":
		return
	var progresso := ProgressoFase2.de(self)
	if progresso and progresso.obter(flag_que_define):
		_usada = true
		if not esconder_ao_usar.is_empty():
			var alvo := get_node_or_null(esconder_ao_usar)
			if alvo:
				alvo.hide()


## true enquanto o Player está dentro da zona.
func jogador_dentro() -> bool:
	return _jogador_dentro


func _atualizar_forma() -> void:
	if not is_node_ready():
		return
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho
	forma.shape = retangulo


func _criar_rotulo() -> void:
	_rotulo = Label.new()
	_rotulo.add_theme_font_override("font", FONTE)
	_rotulo.add_theme_font_size_override("font_size", 8)
	_rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_rotulo.add_theme_constant_override("outline_size", 3)
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.size = Vector2(220, 12)
	_rotulo.position = Vector2(-110, -tamanho.y / 2.0 - 16.0)
	_rotulo.z_index = 100
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.visible = false
	add_child(_rotulo)


## true quando a zona pode ser usada agora.
func disponivel() -> bool:
	if uma_vez and _usada:
		return false
	var progresso := ProgressoFase2.de(self)
	return progresso == null or progresso.todas_ativas(flags_requeridas)


func _process(_delta: float) -> void:
	_rotulo.visible = _jogador_dentro and disponivel()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not _jogador_dentro:
		return
	if event.is_action_pressed(acao_input) and disponivel():
		get_viewport().set_input_as_handled()
		interagir()


func interagir() -> void:
	_usada = true
	_aplicar_efeitos()
	interagido.emit(self)
	if _rotulo:
		_rotulo.visible = _jogador_dentro and disponivel()


## Pode ser sobrescrito (ex.: FissuraFase2 troca o efeito por um pedido de teleporte).
func _aplicar_efeitos() -> void:
	if arquivo_que_coleta != "":
		GameState.coletar_arquivo_no_mapa(arquivo_que_coleta)
	var progresso := ProgressoFase2.de(self)
	if progresso and flag_que_define != &"":
		progresso.definir(flag_que_define, true)
	if mensagem != "":
		# Resposta a uma ação do jogador: não pode ser engolida por um balão de fala (prioridade máxima).
		MensagemHud.mostrar_em(self, mensagem, 3)
	if not esconder_ao_usar.is_empty():
		var alvo := get_node_or_null(esconder_ao_usar)
		if alvo:
			alvo.hide()


func _nome_tecla() -> String:
	for evento in InputMap.action_get_events(acao_input):
		if evento is InputEventKey:
			return (evento as InputEventKey).as_text_physical_keycode()
	return "?"


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	_jogador_dentro = true
	_rotulo.text = "[%s] %s" % [_nome_tecla(), texto_prompt]
	set_process(true)
	if texto_indisponivel != "" and not _usada and not disponivel():
		MensagemHud.mostrar_em(self, texto_indisponivel)


func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	_jogador_dentro = false
	_rotulo.visible = false
	set_process(false)

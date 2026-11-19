@tool
class_name Nota extends Area2D
## Uma NOTA da história: carta, placa, ata, diário ou registro largado no cenário.
## O jogador chega perto, aperta a tecla de interagir (ENTER) e lê. É sempre OPCIONAL: não libera
## nada, não conta como objetivo e pode ser relida no Diário (menu de pausa).
##
## USO RÁPIDO: arraste este nó para a cena, escolha o `tipo` e preencha o `id_nota`. O texto vive
## em `NotasHistoria.NOTAS` (um só lugar para escrever a história). Se preferir, preencha
## `titulo`/`texto`/`autor` aqui mesmo: valem só quando o id não está no catálogo.
##
## O ícone é provisório (desenhado por código) e pulsa enquanto a nota não foi lida. Para usar arte
## própria, desmarque `desenhar_icone` e coloque um Sprite2D como filho.
##
## Estrutura: o próprio nó é a área de interação (um CollisionShape2D filho é criado se faltar).

## Emitido a cada leitura. `primeira_vez` é true só na primeira de verdade (a fase/Eidolon podem reagir).
signal lida(id: StringName, primeira_vez: bool)

const FONTE := preload("res://Dialogo/MonospacePixel.ttf")
const Catalogo := preload("res://GeneralNodes/Nota/notas_historia.gd")
const PERIODO_PULSO := 1.4

## Identificador único da nota (ex.: &"f2_placa_conselho"). Chave do catálogo e do Diário.
@export var id_nota: StringName = &""
@export_enum("carta", "placa", "ata", "diario", "registro") var tipo: String = "carta":
	set(valor):
		tipo = valor
		queue_redraw()
@export_group("Texto (só se o id não estiver no catálogo)")
@export var fase: int = 0
@export var titulo: String = ""
@export var autor: String = ""
@export_multiline var texto: String = ""
@export_group("Interação")
@export var texto_prompt: String = "Ler"
## Tamanho da área onde o jogador pode ler.
@export var tamanho: Vector2 = Vector2(40, 40):
	set(valor):
		tamanho = valor
		_atualizar_forma()
@export var acao_input: StringName = &"interagir_porta"
@export var desenhar_icone: bool = true:
	set(valor):
		desenhar_icone = valor
		queue_redraw()

var _jogador_dentro: bool = false
var _rotulo: Label
var _forma: CollisionShape2D


func _ready() -> void:
	_forma = get_node_or_null("Forma") as CollisionShape2D
	if _forma == null:
		for filho in get_children():
			if filho is CollisionShape2D:
				_forma = filho
				break
	if _forma == null:
		_forma = CollisionShape2D.new()
		_forma.name = "Forma"
		add_child(_forma)
	_atualizar_forma()
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 1
	_criar_rotulo()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if id_nota == &"":
		push_warning("Nota '%s' sem id_nota: ela não vai aparecer direito no Diário." % name)


## Abre a leitura. Público para poder ser chamado por outros sistemas (e pelos testes).
func interagir() -> void:
	var id := _id()
	var dados := {"titulo": titulo, "autor": autor, "tipo": tipo, "fase": fase, "texto": texto}
	if Catalogo.obter(id).is_empty() and texto.strip_edges() == "":
		push_warning("Nota '%s': sem texto no catálogo nem no nó." % id)
		return
	var primeira: bool = Diario.ler(id, dados)
	lida.emit(id, primeira)
	queue_redraw()


func jogador_dentro() -> bool:
	return _jogador_dentro


func _id() -> StringName:
	return id_nota if id_nota != &"" else StringName(name)


func _tipo_efetivo() -> String:
	return String(Catalogo.obter(id_nota).get("tipo", tipo))


func _ja_lida() -> bool:
	return not Engine.is_editor_hint() and Diario.foi_lida(_id())


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_rotulo.visible = _jogador_dentro and not Diario.ocupado()
	if desenhar_icone and not _ja_lida():
		queue_redraw()  # o pulso do ícone


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not _jogador_dentro or Diario.ocupado():
		return
	if event.is_action_pressed(acao_input):
		get_viewport().set_input_as_handled()
		interagir()


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(-tamanho / 2.0, tamanho), Color(1, 0.88, 0.54, 0.6), false, 1.0)
	if not desenhar_icone:
		return
	var cor: Color = Catalogo.tipo(_tipo_efetivo())["cor"]
	var lida_ja := _ja_lida()
	var alfa := 0.45 if lida_ja else 1.0
	var corpo := Color(cor, alfa)
	var tinta := Color(0.05, 0.07, 0.12, alfa)

	match _tipo_efetivo():
		"placa":
			draw_rect(Rect2(-8, -6, 16, 12), corpo)
			draw_rect(Rect2(-8, -6, 16, 12), tinta, false, 1.0)
			for ponto in [Vector2(-6, -4), Vector2(6, -4), Vector2(-6, 4), Vector2(6, 4)]:
				draw_circle(ponto, 1.0, tinta)
		"ata":
			draw_rect(Rect2(-6, -8, 12, 16), corpo)
			draw_rect(Rect2(-6, -8, 12, 16), tinta, false, 1.0)
			for y in [-4.0, 0.0, 4.0]:
				draw_line(Vector2(-3, y), Vector2(3, y), tinta, 1.0)
		"diario":
			draw_rect(Rect2(-6, -8, 12, 16), corpo)
			draw_rect(Rect2(-6, -8, 12, 16), tinta, false, 1.0)
			draw_line(Vector2(-3, -8), Vector2(-3, 8), tinta, 1.0)
			draw_rect(Rect2(3, -1, 2, 3), tinta)
		"registro":
			draw_rect(Rect2(-8, -7, 16, 11), corpo)
			draw_rect(Rect2(-8, -7, 16, 11), tinta, false, 1.0)
			draw_rect(Rect2(-3, 4, 6, 3), corpo)
			draw_line(Vector2(-5, -3), Vector2(-3, -1), tinta, 1.0)
			draw_line(Vector2(-3, -1), Vector2(-5, 1), tinta, 1.0)
			draw_line(Vector2(-1, 1), Vector2(3, 1), tinta, 1.0)
		_:  # carta (envelope)
			draw_rect(Rect2(-7, -5, 14, 10), corpo)
			draw_rect(Rect2(-7, -5, 14, 10), tinta, false, 1.0)
			draw_line(Vector2(-7, -5), Vector2(0, 1), tinta, 1.0)
			draw_line(Vector2(7, -5), Vector2(0, 1), tinta, 1.0)

	if not lida_ja and not Engine.is_editor_hint():
		var fase_pulso := fposmod(Time.get_ticks_msec() / 1000.0, PERIODO_PULSO) / PERIODO_PULSO
		draw_arc(Vector2.ZERO, 11.0 + fase_pulso * 4.0, 0.0, TAU, 24, Color(cor, 0.6 * (1.0 - fase_pulso)), 1.0)


func _atualizar_forma() -> void:
	if _forma == null or not is_instance_valid(_forma):
		return
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho
	_forma.shape = retangulo
	queue_redraw()


func _criar_rotulo() -> void:
	_rotulo = Label.new()
	_rotulo.add_theme_font_override("font", FONTE)
	_rotulo.add_theme_font_size_override("font_size", 8)
	_rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_rotulo.add_theme_constant_override("outline_size", 3)
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.size = Vector2(220, 12)
	_rotulo.position = Vector2(-110, -26)
	_rotulo.z_index = 100
	_rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rotulo.visible = false
	add_child(_rotulo)


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


func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	_jogador_dentro = false
	_rotulo.visible = false

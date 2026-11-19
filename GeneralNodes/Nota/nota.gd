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
## O ícone (arte em GeneralNodes/Nota/arte/, gerada por tools/gerar_arte_notas.gd) flutua, brilha e solta
## um anel enquanto a nota não foi lida; depois de lida fica apagado. Para usar arte própria, desmarque
## `desenhar_icone` e coloque um Sprite2D como filho.
##
## Estrutura: o próprio nó é a área de interação (um CollisionShape2D filho é criado se faltar).

## Emitido a cada leitura. `primeira_vez` é true só na primeira de verdade (a fase/Eidolon podem reagir).
signal lida(id: StringName, primeira_vez: bool)

const FONTE := preload("res://Dialogo/MonospacePixel.ttf")
const Catalogo := preload("res://GeneralNodes/Nota/notas_historia.gd")
const PERIODO_PULSO := 1.4
const BRILHO: Texture2D = preload("res://GeneralNodes/Nota/arte/nota_brilho.png")
const ICONES := {
	"carta": preload("res://GeneralNodes/Nota/arte/nota_carta.png"),
	"placa": preload("res://GeneralNodes/Nota/arte/nota_placa.png"),
	"ata": preload("res://GeneralNodes/Nota/arte/nota_ata.png"),
	"diario": preload("res://GeneralNodes/Nota/arte/nota_diario.png"),
	"registro": preload("res://GeneralNodes/Nota/arte/nota_registro.png"),
}

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
	Diario.diario_mudou.connect(queue_redraw)  # a nota se redesenha se o Diário mudar (lida/limpo)
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
	return not Engine.is_editor_hint() and Diario.foi_marcada(_id())


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
	var tipo_atual := _tipo_efetivo()
	var cor: Color = Catalogo.tipo(tipo_atual)["cor"]
	var lida_ja := _ja_lida()
	var agora := Time.get_ticks_msec() / 1000.0
	var animar := not lida_ja and not Engine.is_editor_hint()
	var flutua := sin(agora * 2.6) * 1.0 if animar else 0.0

	# Sombra no chão
	draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var icone: Texture2D = ICONES.get(tipo_atual, ICONES["carta"])
	if lida_ja:
		# Já lida: translúcida, como "aberta", com um visto verde no canto
		draw_texture(icone, Vector2(-8, -10), Color(1, 1, 1, 0.45))
		if not Engine.is_editor_hint():
			var v := Vector2(6, -11)
			draw_circle(v, 3.0, Color(0.1, 0.1, 0.12, 0.7))
			draw_polyline(PackedVector2Array([v + Vector2(-1.5, 0), v + Vector2(-0.5, 1.0), v + Vector2(1.5, -1.0)]), Color("53D69A", 0.9), 1.0)
		return

	# Não lida: cor cheia, com um brilho quente por trás e um anel discreto
	var pulso_brilho := 0.38 + 0.12 * sin(agora * 3.0) if animar else 0.38
	draw_texture_rect(BRILHO, Rect2(-14, -22 + flutua, 28, 28), false, Color(1.0, 0.88, 0.5, pulso_brilho))
	draw_texture(icone, Vector2(-8, -10 + flutua), Color.WHITE)
	if animar:
		var fase_pulso := fposmod(agora, PERIODO_PULSO) / PERIODO_PULSO
		draw_arc(Vector2(0, -3), 8.0 + fase_pulso * 4.0, 0.0, TAU, 24, Color(cor, 0.8 * (1.0 - fase_pulso)), 1.0)
		var e := 0.5 + 0.5 * sin(agora * 5.0)
		var c := Vector2(6, -12 + flutua)
		var tam := 0.5 + 1.5 * e
		var branco := Color(1, 1, 1, 0.6 + 0.4 * e)
		draw_line(c + Vector2(-tam, 0), c + Vector2(tam, 0), branco, 1.0)
		draw_line(c + Vector2(0, -tam), c + Vector2(0, tam), branco, 1.0)


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

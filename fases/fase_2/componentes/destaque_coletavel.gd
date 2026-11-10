class_name DestaqueColetavel extends Node2D
## Destaque VISUAL de um coletável (eco principal ou fragmento de memória), para que não se perca
## no cenário. Filho do prop (PropFase2): acompanha a posição dele e some junto com ele quando o
## item é recolhido (o prop é escondido); quando um fragmento é lido, o prop esmaece e o destaque
## esmaece também.
##
## Só desenha (halo aditivo que pulsa, faíscas orbitando, feixe de luz no eco e leve flutuação do
## sprite). Não colide, não interage e não altera nenhum estado do jogo.
##
## ECO         halo grande + feixe de luz vertical + 5 faíscas  (item de progresso: precisa se ver de longe)
## FRAGMENTO   halo pequeno + 2 faíscas                         (opcional: discreto, mas visível)

const TIPO_ECO := 0
const TIPO_FRAGMENTO := 1

@export_enum("eco", "fragmento") var tipo: int = TIPO_ECO
@export var cor: Color = Color(0.55, 0.42, 1.0)

static var _textura_radial: GradientTexture2D
static var _textura_feixe: GradientTexture2D
static var _material_aditivo: CanvasItemMaterial

var _t: float = 0.0
var _centro: Vector2 = Vector2(0, -12)
var _escala_halo: float = 1.0
var _flutuacao: float = 2.0
var _sprite_do_prop: Sprite2D
var _halo: Sprite2D
var _feixe: Sprite2D
var _faiscas: Array[Sprite2D] = []
var _raio_faiscas: float = 12.0


func _ready() -> void:
	_t = randf() * TAU
	var prop := get_parent()
	_sprite_do_prop = prop.get_node_or_null("Sprite") as Sprite2D
	var altura := 16.0
	if _sprite_do_prop and _sprite_do_prop.texture:
		altura = float(_sprite_do_prop.texture.get_height())
	_centro = Vector2(0, -altura * 0.5)

	if tipo == TIPO_ECO:
		_escala_halo = 1.25
		_flutuacao = 2.5
		_raio_faiscas = 15.0
	else:
		_escala_halo = 0.62
		_flutuacao = 1.5
		_raio_faiscas = 10.0

	_halo = _criar_sprite(_obter_radial(), 0.8)
	_halo.position = _centro
	_halo.modulate = Color(cor.r, cor.g, cor.b, 0.7)
	add_child(_halo)

	if tipo == TIPO_ECO:
		_feixe = _criar_sprite(_obter_feixe(), 1.0)
		_feixe.centered = false
		_feixe.position = Vector2(-7.0, -altura - 56.0)
		_feixe.modulate = Color(cor.r, cor.g, cor.b, 0.55)
		add_child(_feixe)

	var quantidade := 5 if tipo == TIPO_ECO else 2
	for i in quantidade:
		var faisca := _criar_sprite(_obter_radial(), 0.09)
		faisca.modulate = Color(1, 1, 1, 0.95)
		add_child(faisca)
		_faiscas.append(faisca)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	var flutua := sin(_t * 2.2) * _flutuacao
	if _sprite_do_prop:
		_sprite_do_prop.offset.y = flutua  # offset (e não position): não briga com o PropFase2

	var pulso := 0.5 + 0.5 * sin(_t * 3.0)
	_halo.position = _centro + Vector2(0, flutua)
	_halo.scale = Vector2.ONE * _escala_halo * lerpf(0.9, 1.15, pulso)
	_halo.modulate.a = lerpf(0.45, 0.9, pulso)
	if _feixe:
		_feixe.modulate.a = lerpf(0.3, 0.6, 0.5 + 0.5 * sin(_t * 1.7 + 1.0))

	for i in _faiscas.size():
		var ang := _t * 1.6 + TAU * float(i) / float(_faiscas.size())
		var raio := _raio_faiscas * (0.8 + 0.25 * sin(_t * 2.0 + float(i)))
		_faiscas[i].position = _centro + Vector2(cos(ang) * raio, sin(ang) * raio * 0.55 + flutua)
		_faiscas[i].modulate.a = 0.5 + 0.5 * sin(_t * 4.0 + float(i) * 1.3)


func _criar_sprite(textura: Texture2D, escala: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura
	s.material = _obter_material()
	s.scale = Vector2.ONE * escala
	s.z_index = 1
	return s


static func _obter_material() -> CanvasItemMaterial:
	if _material_aditivo == null:
		_material_aditivo = CanvasItemMaterial.new()
		_material_aditivo.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _material_aditivo


static func _obter_radial() -> GradientTexture2D:
	if _textura_radial == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
		_textura_radial = GradientTexture2D.new()
		_textura_radial.gradient = g
		_textura_radial.width = 64
		_textura_radial.height = 64
		_textura_radial.fill = GradientTexture2D.FILL_RADIAL
		_textura_radial.fill_from = Vector2(0.5, 0.5)
		_textura_radial.fill_to = Vector2(1.0, 0.5)
	return _textura_radial


static func _obter_feixe() -> GradientTexture2D:
	if _textura_feixe == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.9)])
		_textura_feixe = GradientTexture2D.new()
		_textura_feixe.gradient = g
		_textura_feixe.width = 14
		_textura_feixe.height = 56
		_textura_feixe.fill = GradientTexture2D.FILL_LINEAR
		_textura_feixe.fill_from = Vector2(0.0, 0.0)  # topo transparente ...
		_textura_feixe.fill_to = Vector2(0.0, 1.0)    # ... base opaca
	return _textura_feixe

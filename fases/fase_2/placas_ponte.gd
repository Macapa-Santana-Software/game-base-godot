class_name PlacasPonte extends Node2D
## A ponte inteira: uma fileira de placas hexagonais de luz entre dois trilhos de cobre.
## Cada placa tem um grau de "acesa" (0 = fantasma/translúcida, 1 = acesa em brasa).
## `acender()` liga as placas uma a uma, da margem esquerda para a direita (o merge);
## `apagar()` volta ao aspecto de fantasma. A arte vem de fases/fase_2/arte/.

signal montada

const TEX_FANTASMA: Texture2D = preload("res://fases/fase_2/arte/ponte_placa_fantasma.png")
const TEX_ACESA: Texture2D = preload("res://fases/fase_2/arte/ponte_placa_acesa.png")
const TEX_TRILHO_APAGADO: Texture2D = preload("res://fases/fase_2/arte/ponte_trilho_apagado.png")
const TEX_TRILHO_ACESO: Texture2D = preload("res://fases/fase_2/arte/ponte_trilho_aceso.png")
const TEX_BRILHO: Texture2D = preload("res://fases/fase_2/arte/brilho_brasa.png")

@export var placas: int = 6
@export var largura: float = 160.0
@export var altura: float = 64.0
## Atraso entre uma placa e a seguinte ao acender, e duração de cada uma.
@export var atraso_entre_placas: float = 0.16
@export var duracao_placa: float = 0.3

var _acesas: Array[Sprite2D] = []
var _fantasmas: Array[Sprite2D] = []
var _brilhos: Array[Sprite2D] = []
var _valores: Array[float] = []
var _trilhos_acesos: Array[Sprite2D] = []
var _tween: Tween


func _ready() -> void:
	_montar()


func _montar() -> void:
	var soma := CanvasItemMaterial.new()
	soma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	# Trilhos: o apagado fica embaixo e o aceso aparece por cima conforme as placas acendem
	for y in [0.0, altura - 4.0]:
		_trilho(TEX_TRILHO_APAGADO, y, false)
		_trilhos_acesos.append(_trilho(TEX_TRILHO_ACESO, y, true))
	var passo := largura / float(placas)
	for i in range(placas):
		var cx := passo * (float(i) + 0.5)
		var brilho := Sprite2D.new()
		brilho.texture = TEX_BRILHO
		brilho.material = soma
		brilho.position = Vector2(cx, altura * 0.5)
		brilho.scale = Vector2(0.9, 1.5)
		brilho.modulate.a = 0.0
		add_child(brilho)
		_brilhos.append(brilho)
		var fantasma := Sprite2D.new()
		fantasma.texture = TEX_FANTASMA
		fantasma.position = Vector2(cx, altura * 0.5)
		add_child(fantasma)
		_fantasmas.append(fantasma)
		var acesa := Sprite2D.new()
		acesa.texture = TEX_ACESA
		acesa.position = Vector2(cx, altura * 0.5)
		acesa.modulate.a = 0.0
		add_child(acesa)
		_acesas.append(acesa)
		_valores.append(0.0)


func _trilho(textura: Texture2D, y: float, comeca_invisivel: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = textura
	s.centered = false
	s.position = Vector2(0, y)
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, largura, 4)
	if comeca_invisivel:
		s.modulate.a = 0.0
	add_child(s)
	return s


## Liga as placas em sequência. `instantaneo` pula a animação.
func acender(instantaneo: bool = false) -> void:
	_parar()
	if instantaneo:
		_definir_todas(1.0)
		montada.emit()
		return
	_tween = create_tween()
	for i in range(placas):
		_tween.parallel().tween_method(_definir.bind(i), 0.0, 1.0, duracao_placa).set_delay(float(i) * atraso_entre_placas)
	_tween.finished.connect(montada.emit)


func apagar() -> void:
	_parar()
	_definir_todas(0.0)


func esta_acesa() -> bool:
	for v in _valores:
		if v < 1.0:
			return false
	return not _valores.is_empty()


func _parar() -> void:
	if _tween:
		_tween.kill()


func _definir(valor: float, indice: int) -> void:
	_valores[indice] = valor
	# A placa "assenta" com um pequeno salto enquanto acende
	var y := altura * 0.5 - sin(valor * PI) * 3.0
	_acesas[indice].modulate.a = valor
	_acesas[indice].position.y = y
	_fantasmas[indice].position.y = y
	_brilhos[indice].modulate.a = valor * 0.5
	var media := 0.0
	for v in _valores:
		media += v
	media /= float(_valores.size())
	for t in _trilhos_acesos:
		t.modulate.a = media


func _definir_todas(valor: float) -> void:
	for i in range(placas):
		_definir(valor, i)

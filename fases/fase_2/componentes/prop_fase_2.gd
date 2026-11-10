@tool
class_name PropFase2 extends Node2D
## Objeto de cenário do blockout, preparado para receber sprite.
##
## COMO SUBSTITUIR POR SPRITE: preencha `textura` no Inspetor. O Sprite2D aparece
## (alinhado pela base, centralizado no eixo X) e o ColorRect provisório some. Colisão,
## ponto de interação e slot de luz permanecem exatamente onde estão.
##
## A origem do nó é a BASE do objeto (onde ele "pisa"), que é o ponto usado pelo Y-sort.

@export var textura: Texture2D:
	set(valor):
		textura = valor
		_atualizar()
## Tamanho do ColorRect provisório, em pixels.
@export var tamanho_visual: Vector2 = Vector2(32, 48):
	set(valor):
		tamanho_visual = valor
		_atualizar()
## Tamanho da colisão na base do objeto. Vector2.ZERO = objeto sem colisão.
@export var tamanho_colisao: Vector2 = Vector2(24, 10):
	set(valor):
		tamanho_colisao = valor
		_atualizar()
@export var cor: Color = Color(0.4, 0.3, 0.7, 1.0):
	set(valor):
		cor = valor
		_atualizar()

@onready var visual: ColorRect = $Visual
@onready var sprite: Sprite2D = $Sprite
@onready var forma: CollisionShape2D = $Colisao/Forma
@onready var ponto_interacao: Marker2D = $PontoInteracao
@onready var slot_luz: Marker2D = $SlotLuz


func _ready() -> void:
	_atualizar()


func _atualizar() -> void:
	if not is_node_ready():
		return

	visual.position = Vector2(-tamanho_visual.x / 2.0, -tamanho_visual.y)
	visual.size = tamanho_visual
	visual.color = cor
	visual.visible = textura == null

	sprite.visible = textura != null
	if textura:
		sprite.texture = textura
		sprite.centered = false
		sprite.position = Vector2(-textura.get_width() / 2.0, -textura.get_height())

	var sem_colisao := tamanho_colisao == Vector2.ZERO
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho_colisao
	forma.shape = retangulo
	forma.position = Vector2(0, -tamanho_colisao.y / 2.0)
	forma.set_deferred("disabled", sem_colisao)

	ponto_interacao.position = Vector2(0, -tamanho_visual.y - 8.0)
	slot_luz.position = Vector2(0, -tamanho_visual.y * 0.5)

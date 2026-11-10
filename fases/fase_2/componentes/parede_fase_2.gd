@tool
class_name ParedeFase2 extends StaticBody2D
## Bloco sólido do blockout (parede, abismo, muro, espinheiro...). Origem no canto
## superior esquerdo. Colide na layer 16 ("Walls"), a mesma que o Player já respeita.
##
## Substituição futura: trocar o conteúdo do nó `Paredes` de cada área por uma
## TileMapLayer com colisão; este componente some junto com o blockout.

@export var tamanho: Vector2 = Vector2(32, 32):
	set(valor):
		tamanho = valor
		_atualizar()
@export var cor: Color = Color(0.24, 0.17, 0.4, 1.0):
	set(valor):
		cor = valor
		_atualizar()
@export var colisao_ativa: bool = true:
	set(valor):
		colisao_ativa = valor
		_atualizar()

@onready var visual: ColorRect = $Visual
@onready var forma: CollisionShape2D = $Forma


func _ready() -> void:
	_atualizar()


func _atualizar() -> void:
	if not is_node_ready():
		return
	visual.position = Vector2.ZERO
	visual.size = tamanho
	visual.color = cor
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho
	forma.shape = retangulo
	forma.position = tamanho / 2.0
	forma.set_deferred("disabled", not colisao_ativa)

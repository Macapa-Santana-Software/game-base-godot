class_name PortaMural extends StaticBody2D
## Barreira que separa as zonas do mural. Abre quando a fase manda (não volta a fechar).
## Estrutura esperada: filhos `Forma` (CollisionShape2D) e `Visual` (qualquer nó 2D/Control; hoje a barreira de ruído).

@onready var _forma: CollisionShape2D = $Forma
@onready var _visual: CanvasItem = $Visual

var aberta: bool = false
var _tremor: Tween


func _ready() -> void:
	# A barreira de ruído pisca enquanto está fechada
	_tremor = create_tween().set_loops()
	_tremor.tween_property(_visual, "modulate:a", 0.72, 0.18)
	_tremor.tween_property(_visual, "modulate:a", 1.0, 0.11)
	_tremor.tween_property(_visual, "modulate:a", 0.85, 0.07)
	_tremor.tween_property(_visual, "modulate:a", 1.0, 0.25)


func definir_aberta(valor: bool) -> void:
	if aberta or not valor:
		return
	aberta = true
	if _tremor:
		_tremor.kill()
	_forma.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_visual.hide)

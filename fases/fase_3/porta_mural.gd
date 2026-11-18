class_name PortaMural extends StaticBody2D
## Barreira que separa as zonas do mural. Abre quando a fase manda (não volta a fechar).
## Estrutura esperada: filhos `Forma` (CollisionShape2D) e `Visual` (ColorRect).

@onready var _forma: CollisionShape2D = $Forma
@onready var _visual: ColorRect = $Visual

var aberta: bool = false


func definir_aberta(valor: bool) -> void:
	if aberta or not valor:
		return
	aberta = true
	_forma.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_visual.hide)

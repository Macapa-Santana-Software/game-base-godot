class_name PortalSaida extends ExitArea

## Portal de pedra: apagado até o commit completo; ao liberar a saída, acende e ganha luz.

@onready var animador: AnimationPlayer = $AnimationPlayer
@onready var luz: PointLight2D = $Luz


func _ready() -> void:
	super._ready()
	luz.energy = 0.0
	desbloqueada.connect(_on_desbloqueada)


func _on_desbloqueada() -> void:
	animador.play("ativo")
	luz.energy = 1.0

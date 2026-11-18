class_name PecaPonte extends ItemColetavel
## A peça da ponte só existe na realidade da branch `ponte`: nas outras branches ela
## fica invisível e não pode ser coletada (o que impede consertar direto na main).

@export var branch_visivel: StringName = &"ponte"


func _ready() -> void:
	super._ready()
	GameState.branch_ativa_mudou.connect(_atualizar.unbind(2))
	_atualizar()


func _atualizar() -> void:
	var presente: bool = GameState.branch_ativa == String(branch_visivel)
	visible = presente
	set_deferred("monitoring", presente)

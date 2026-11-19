class_name PecaPonte extends ItemColetavel
## A peça da ponte só existe na realidade da branch `ponte`: nas outras branches ela
## fica invisível e não pode ser coletada (o que impede consertar direto na main).

const P := preload("res://fases/fase_2/paleta_canion.gd")

@export var branch_visivel: StringName = &"ponte"


func _ready() -> void:
	super._ready()
	_estilizar()
	GameState.branch_ativa_mudou.connect(_atualizar.unbind(2))
	_atualizar()


func _atualizar() -> void:
	var presente: bool = GameState.branch_ativa == String(branch_visivel)
	visible = presente
	set_deferred("monitoring", presente)


## O ícone da peça (placa hexagonal de brasa, também usado no inventário) vem da cena. Aqui o brilho e
## a luz que vêm da cena de arquivo passam de ciano para brasa.
func _estilizar() -> void:
	if has_node("Luz"):
		$Luz.color = P.BRASA
	if has_node("Brilho"):
		$Brilho.modulate = P.BRASA_CLARA

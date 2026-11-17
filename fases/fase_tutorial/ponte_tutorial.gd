class_name PonteTutorial extends Node2D
## A ponte sobre o abismo. O visual e a passagem seguem o repositório Git:
##
##   quebrada  o arquivo da ponte ainda não está na main (nem na branch ativa)
##   fantasma  o conserto já foi commitado na branch `ponte`, mas a main ainda não o tem
##             (a ponte aparece inteira e translúcida, porém NÃO dá para atravessar)
##   sólida    a main tem o conserto (merge feito): a passagem abre para sempre
##
## O bloqueio só cai quando a main tem a ponte; assim o jogador nunca fica preso em cima
## dela ao trocar de branch.

signal ponte_concluida

const ALFA_FANTASMA := 0.45

@onready var quebrada: Node2D = $Quebrada
@onready var inteira: Node2D = $Inteira
@onready var forma_bloqueio: CollisionShape2D = $Bloqueio/Forma

var _solida: bool = false
var _tween: Tween


func _ready() -> void:
	GameState.commit_realizado.connect(_atualizar.unbind(1))
	GameState.merge_realizado.connect(_atualizar.unbind(4))
	GameState.branch_ativa_mudou.connect(_atualizar.unbind(2))
	_atualizar(true)


func _atualizar(instantaneo: bool = false) -> void:
	if _solida:
		return
	if EstadoPonte.na_main():
		_solida = true
		_mostrar(false, 1.0, instantaneo)
		forma_bloqueio.set_deferred("disabled", true)
		if not instantaneo:
			ponte_concluida.emit()
	elif EstadoPonte.versionada_em(GameState.branch_ativa):
		_mostrar(true, ALFA_FANTASMA, instantaneo)
	else:
		_mostrar(true, 0.0, instantaneo)


func _mostrar(com_tocos: bool, alfa_inteira: float, instantaneo: bool) -> void:
	quebrada.visible = com_tocos
	inteira.visible = alfa_inteira > 0.0
	if _tween:
		_tween.kill()
	if instantaneo:
		inteira.modulate.a = alfa_inteira
		return
	_tween = create_tween()
	_tween.tween_property(inteira, "modulate:a", alfa_inteira, 0.4)

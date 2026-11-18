class_name PonteRetorno extends Node2D
## A ponte da Área 1. O visual segue o repositório real:
##
##   quebrada  só os tocos nas margens (o reforço ou a base não estão no histórico)
##   ruim      as tábuas do commit ruim aparecem em glitch magenta (e NÃO dá para atravessar)
##   sólida    o commit ruim foi desfeito (revert): a ponte fica inteira e a passagem abre
##
## A passagem, uma vez aberta (flag z1_ok), nunca volta a fechar: o jogador nunca fica preso.
## Estrutura esperada: filhos `Quebrada`, `Ruim`, `Solida` (Node2D) e `Bloqueio/Forma`.

@onready var _quebrada: Node2D = $Quebrada
@onready var _ruim: Node2D = $Ruim
@onready var _solida: Node2D = $Solida
@onready var _forma: CollisionShape2D = $Bloqueio/Forma


func _ready() -> void:
	EstadoRetorno.conectar_mudancas(_atualizar)
	_atualizar()


func _atualizar() -> void:
	var concluida := EstadoRetorno.flag("z1_ok")
	_solida.visible = concluida
	_quebrada.visible = not concluida
	_ruim.visible = not concluida and EstadoRetorno.versionado(EstadoRetorno.ARQ_RUIM)
	_forma.set_deferred("disabled", concluida)

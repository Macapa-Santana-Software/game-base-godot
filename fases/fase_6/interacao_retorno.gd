class_name InteracaoRetorno extends Area2D
## Pontos de interação da Fase 6 (ENTER perto deles):
##
##   alavanca  a emergência do Corredor. Fica atrás do portão de inspeção (que só abre com a
##             pasta limpa, ou seja, depois do `git stash`) e só pode ser puxada uma vez.
##   altar     o Altar de Retorno: rede de segurança da Câmara do Reset. Se um `reset` deixou a
##             câmara sem saída (ex.: um --hard destruiu a planta), ele a recoloca como estava.
##
## Estrutura esperada: filhos `Marca` (Sprite2D: a alavanca tem 2 quadros, erguida e puxada) e `Aviso` (Label).

@export_enum("alavanca", "altar") var tipo: String = "alavanca"
@export var texto_aviso: String = "ENTER"

@onready var _aviso: Label = $Aviso
@onready var _marca: CanvasItem = $Marca

var _player_perto: bool = false


func _ready() -> void:
	body_entered.connect(_on_entrou)
	body_exited.connect(_on_saiu)
	_aviso.text = texto_aviso
	EstadoRetorno.conectar_mudancas(_atualizar)
	_atualizar()


func _on_entrou(corpo: Node2D) -> void:
	if corpo.name == "Player":
		_player_perto = true
		_atualizar()


func _on_saiu(corpo: Node2D) -> void:
	if corpo.name == "Player":
		_player_perto = false
		_atualizar()


func _ativo() -> bool:
	if tipo == "alavanca":
		return EstadoRetorno.flag("inspecao_ok") and not EstadoRetorno.flag("emergencia")
	return EstadoRetorno.precisa_restaurar()


func _atualizar() -> void:
	var ativo := _ativo()
	_aviso.visible = _player_perto and ativo
	_marca.modulate = Color(1, 1, 1, 1.0 if ativo else 0.35)
	if tipo == "alavanca" and EstadoRetorno.flag("emergencia") and _marca is Sprite2D:
		(_marca as Sprite2D).frame = 1  # alavanca puxada


func _process(_delta: float) -> void:
	if not _player_perto or not Input.is_action_just_pressed("interagir_porta") or not _ativo():
		return
	var fase := get_tree().get_first_node_in_group("fase_6")
	if tipo == "alavanca":
		EstadoRetorno.marcar("emergencia")
		if fase:
			fase.evento.emit("alavanca")
			fase.notificar()
	elif EstadoRetorno.restaurar_camara() and fase:
		fase.evento.emit("restaurou")
		fase.notificar()

class_name PedestalEscolha extends Area2D
## Pedestal onde o jogador RESOLVE o conflito no mundo (ENTER): escolhe a versão da main,
## a da outra equipe, ou junta as duas. Só funciona com o conflito aberto e antes do `git add`
## (depois do `merge --abort` volta a ficar inativo).
##
## Estrutura esperada: filhos `Pedra` (Sprite2D ou qualquer nó visual) e `Aviso` (Label).

@export_enum("minha", "deles", "ambas") var lado: String = "minha"
@export var texto_aviso: String = "ENTER: escolher"

@onready var _aviso: Label = $Aviso
@onready var _pedra: CanvasItem = $Pedra

var _player_perto: bool = false


func _ready() -> void:
	body_entered.connect(_on_entrou)
	body_exited.connect(_on_saiu)
	_aviso.text = texto_aviso
	var modelo := ModeloConflito.ativo()
	if modelo:
		modelo.mudou.connect(_atualizar)
	_atualizar()


func _on_entrou(corpo: Node2D) -> void:
	if corpo.name == "Player":
		_player_perto = true
		_atualizar()


func _on_saiu(corpo: Node2D) -> void:
	if corpo.name == "Player":
		_player_perto = false
		_atualizar()


func _atualizar() -> void:
	var modelo := ModeloConflito.ativo()
	var ativo := modelo != null and modelo.pode_escolher()
	var escolhido := modelo != null and modelo.escolha() == lado and modelo.estado() != ModeloConflito.PRE
	_aviso.visible = _player_perto and ativo
	_pedra.modulate = Color(1, 1, 1, 1.0 if (ativo or escolhido) else 0.3)
	scale = Vector2.ONE * (1.25 if escolhido else 1.0)


func _process(_delta: float) -> void:
	if not _player_perto or not Input.is_action_just_pressed("interagir_porta"):
		return
	var modelo := ModeloConflito.ativo()
	if modelo and modelo.pode_escolher():
		modelo.escolher(lado)

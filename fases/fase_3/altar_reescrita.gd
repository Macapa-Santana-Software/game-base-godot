class_name AltarReescrita extends Area2D
## Rede de segurança da fase: `git restore` apaga mudanças SEM volta. Se o jogador descartar
## por engano uma mudança BOA (mar.runa ou aurora.runa), este altar a reescreve (ENTER) para
## ninguém ficar preso. Só aparece quando há algo perdido.

@onready var _aviso: Label = $Aviso

var _player_perto: bool = false


func _ready() -> void:
	body_entered.connect(_on_entrou)
	body_exited.connect(_on_saiu)
	var modelo := ModeloMural.ativo()
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
	var modelo := ModeloMural.ativo()
	var perdido := modelo != null and modelo.alguma_boa_perdida()
	_aviso.visible = perdido and _player_perto
	$Pedra.modulate = Color(1, 1, 1, 1.0 if perdido else 0.35)


func _process(_delta: float) -> void:
	if not _player_perto or not Input.is_action_just_pressed("interagir_porta"):
		return
	var modelo := ModeloMural.ativo()
	if modelo and modelo.alguma_boa_perdida():
		modelo.refazer_boas()

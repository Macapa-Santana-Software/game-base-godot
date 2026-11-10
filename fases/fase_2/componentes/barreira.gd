@tool
class_name BarreiraFase2 extends StaticBody2D
## Passagem bloqueada. Origem no canto superior esquerdo. Colide na layer 16 ("Walls").
##
## Fica ABERTA enquanto TODAS as condições valem:
##   * todas as `flags_requeridas` ativas, e
##   * se `branch_requerida` estiver preenchida, essa é a branch ativa.
## É reversível: quando a condição deixa de valer, ela fecha de novo. Se o jogador
## estiver em cima dela nessa hora, o fechamento espera ele sair (nunca o prende).
##
## É assim que uma realidade inativa fica inacessível: as portas dela só abrem enquanto
## a branch correspondente está ativa.

@export var tamanho: Vector2 = Vector2(64, 96):
	set(valor):
		tamanho = valor
		_atualizar()
@export var cor: Color = Color(0.45, 0.3, 0.85, 0.85):
	set(valor):
		cor = valor
		_atualizar()
@export var flags_requeridas: PackedStringArray = PackedStringArray()
## Branch que precisa estar ativa para a passagem abrir (vazio = qualquer uma).
@export var branch_requerida: StringName = &""
## Dica mostrada quando o jogador se aproxima com a barreira fechada.
@export_multiline var texto_bloqueada: String = ""

@onready var visual: ColorRect = $Visual
@onready var forma: CollisionShape2D = $Forma
@onready var proximidade: Area2D = $Proximidade
@onready var forma_proximidade: CollisionShape2D = $Proximidade/Forma

var aberta: bool = false

var _tween: Tween
var _fechamento_pendente: bool = false


func _ready() -> void:
	_atualizar()
	set_physics_process(false)
	if Engine.is_editor_hint():
		return
	proximidade.body_entered.connect(_on_proximidade_body_entered)
	var progresso := ProgressoFase2.de(self)
	if progresso:
		progresso.flag_alterada.connect(_on_estado_mudou.unbind(2))
		progresso.branch_ativa_mudou.connect(_on_estado_mudou.unbind(2))
		_avaliar(true)


func _atualizar() -> void:
	if not is_node_ready():
		return
	visual.position = Vector2.ZERO
	visual.size = tamanho
	visual.color = cor
	var retangulo := RectangleShape2D.new()
	retangulo.size = tamanho
	forma.shape = retangulo
	forma.position = tamanho / 2.0
	var area := RectangleShape2D.new()
	area.size = tamanho + Vector2(48, 48)
	forma_proximidade.shape = area
	forma_proximidade.position = tamanho / 2.0


func condicao_atendida() -> bool:
	var progresso := ProgressoFase2.de(self)
	if progresso == null:
		return false
	if not progresso.todas_ativas(flags_requeridas):
		return false
	return branch_requerida == &"" or progresso.branch_ativa() == branch_requerida


func _avaliar(instantaneo: bool) -> void:
	var deve_abrir := condicao_atendida()
	if deve_abrir:
		_fechamento_pendente = false
		set_physics_process(false)
		if not aberta:
			_abrir(instantaneo)
	elif aberta:
		_fechar(instantaneo)


func _abrir(instantaneo: bool) -> void:
	aberta = true
	forma.set_deferred("disabled", true)
	if _tween:
		_tween.kill()
	if instantaneo:
		visual.hide()
		return
	_tween = create_tween()
	_tween.tween_property(visual, "modulate:a", 0.0, 0.5)
	_tween.tween_callback(visual.hide)


func _fechar(instantaneo: bool) -> void:
	if _jogador_em_cima():
		# Espera o jogador sair; o _physics_process tenta de novo.
		_fechamento_pendente = true
		set_physics_process(true)
		return
	_fechamento_pendente = false
	set_physics_process(false)
	aberta = false
	forma.set_deferred("disabled", false)
	if _tween:
		_tween.kill()
	visual.show()
	if instantaneo:
		visual.modulate.a = 1.0
		return
	_tween = create_tween()
	_tween.tween_property(visual, "modulate:a", 1.0, 0.3)


func _jogador_em_cima() -> bool:
	var retangulo := Rect2(global_position, tamanho).grow(14.0)
	for corpo in proximidade.get_overlapping_bodies():
		if corpo is Player and retangulo.has_point(corpo.global_position):
			return true
	return false


func _physics_process(_delta: float) -> void:
	if _fechamento_pendente:
		_avaliar(false)


func _on_estado_mudou() -> void:
	_avaliar(false)


func _on_proximidade_body_entered(body: Node2D) -> void:
	if body is Player and not aberta and texto_bloqueada != "":
		MensagemHud.mostrar_em(self, texto_bloqueada)

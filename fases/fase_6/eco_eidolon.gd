class_name EcoEidolon extends Sprite2D
## O Eidolon na Fase 6: só um ECO (um vulto ciano translúcido), sem voz, que EVITA o jogador desde a cena do
## selo (Fase 5). Quando o jogador chega perto, o vulto some e reaparece num dos `pontos`, o mais longe dele.
##
## No fim da fase a cena o chama com `aparecer_em()` (ele fica parado, vê o commit fantasma) e depois `sumir()`.

signal fugiu

@export var pontos: PackedVector2Array = PackedVector2Array()
## Distância (em pixels) a partir da qual ele foge do jogador.
@export var distancia_fuga: float = 72.0
@export var alfa: float = 0.6

var _fugindo: bool = false
var _parado: bool = false
var _tempo: float = 0.0
var _tween: Tween


func _ready() -> void:
	modulate.a = alfa


func _process(delta: float) -> void:
	_tempo += delta
	offset.y = -16.0 + sin(_tempo * 2.0) * 1.5
	if _parado or _fugindo or pontos.size() < 2 or not visible:
		return
	var jogador := PlayerManager.player
	if jogador and jogador.global_position.distance_to(global_position) < distancia_fuga:
		_fugir(jogador.global_position)


func _fugir(do_jogador: Vector2) -> void:
	_fugindo = true
	fugiu.emit()
	var destino := global_position
	var melhor := -1.0
	for ponto in pontos:
		var dist := ponto.distance_to(do_jogador)
		if ponto.distance_to(global_position) > 8.0 and dist > melhor:
			melhor = dist
			destino = ponto
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(func() -> void: global_position = destino)
	_tween.tween_interval(0.5)
	_tween.tween_property(self, "modulate:a", alfa, 0.5)
	_tween.tween_callback(func() -> void: _fugindo = false)


## Para de fugir e aparece num ponto (o momento em que ele vê o commit fantasma).
func aparecer_em(posicao: Vector2) -> void:
	_parado = true
	if _tween:
		_tween.kill()
	global_position = posicao
	visible = true
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alfa + 0.15, 1.0)


func sumir() -> void:
	_parado = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 1.4)
	_tween.tween_callback(hide)

class_name PrateleiraStash extends Node2D
## A prateleira do Corredor: acende quando há trabalho guardado no stash (um brilho por item).
## Só lê o GameState.

const LARGURA := 56.0
const ALTURA := 22.0


func _ready() -> void:
	EstadoRetorno.conectar_mudancas(queue_redraw)  # inclui o stash_guardado e o stash_aplicado
	queue_redraw()


func _draw() -> void:
	var guardados := GameState.stash_pilha.size()
	var caixa := Rect2(-LARGURA / 2.0, -ALTURA / 2.0, LARGURA, ALTURA)
	draw_rect(caixa, Color(0.16, 0.14, 0.22))
	draw_rect(caixa, Color(0.6, 0.45, 0.9) if guardados > 0 else Color(0.35, 0.33, 0.45), false, 1.5)
	for i in range(guardados):
		var x := caixa.position.x + 6.0 + i * 12.0
		draw_rect(Rect2(x, -5.0, 9.0, 9.0), Color(0.93, 0.78, 0.35))
	var fonte := ThemeDB.fallback_font
	var texto := "STASH: %d" % guardados
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	draw_string(fonte, Vector2(-largura / 2.0, ALTURA / 2.0 + 10.0), texto,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.8, 0.72, 0.95) if guardados > 0 else Color(0.55, 0.55, 0.65))

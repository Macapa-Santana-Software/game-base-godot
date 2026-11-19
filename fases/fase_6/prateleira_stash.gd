class_name PrateleiraStash extends Node2D
## A prateleira do Corredor: acende quando há trabalho guardado no stash (um brilho por item).
## Só lê o GameState.

const LARGURA := 56.0
const ALTURA := 22.0
const PRATELEIRA: Texture2D = preload("res://fases/fase_6/arte/prateleira_stash.png")
const CAIXOTE: Texture2D = preload("res://fases/fase_6/arte/caixa_stash.png")


func _ready() -> void:
	EstadoRetorno.conectar_mudancas(queue_redraw)  # inclui o stash_guardado e o stash_aplicado
	queue_redraw()


func _draw() -> void:
	var guardados := GameState.stash_pilha.size()
	draw_texture(PRATELEIRA, Vector2(-32.0, -14.0))
	# Cada item guardado é um caixote na prateleira de cima (e o brilho acende quando há trabalho guardado)
	for i in range(mini(guardados, 4)):
		draw_texture(CAIXOTE, Vector2(-25.0 + i * 13.0, -2.0))
	if guardados > 0:
		draw_rect(Rect2(-30.0, -13.0, 60.0, 1.0), Color(0.95, 0.76, 0.19, 0.8))
	var fonte := ThemeDB.fallback_font
	var texto := "STASH: %d" % guardados
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	var pos := Vector2(-largura / 2.0, ALTURA / 2.0 + 14.0)
	draw_string_outline(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, 3, Color(0.93, 0.9, 0.82))
	draw_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.1, 0.09, 0.08))

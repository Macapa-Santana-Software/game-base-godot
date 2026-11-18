class_name LinhaDoTempo extends CanvasLayer
## Camada que hospeda a FaixaTempo no centro inferior da tela (entre o Manual, à esquerda, e o
## painel de objetivos, no canto inferior direito).

const MARGEM_ESQUERDA := 150.0
const MARGEM_DIREITA := 135.0
const ALTURA := 40.0
const BASE := 6.0

var _faixa: FaixaTempo


func _ready() -> void:
	layer = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	_faixa = FaixaTempo.new()
	add_child(_faixa)
	get_viewport().size_changed.connect(_ajustar)
	_ajustar()


func _ajustar() -> void:
	var tela := get_viewport().get_visible_rect().size
	_faixa.size = Vector2(maxf(150.0, tela.x - MARGEM_ESQUERDA - MARGEM_DIREITA), ALTURA)
	_faixa.position = Vector2(MARGEM_ESQUERDA, tela.y - ALTURA - BASE)

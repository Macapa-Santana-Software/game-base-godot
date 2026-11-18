class_name FaixaTempo extends Control
## A LINHA DO TEMPO de commits (o visual principal da Fase 6). Só LÊ o GameState:
##
##   nó verde      commit alcançável a partir do HEAD (faz parte do histórico atual)
##   nó ciano      commit criado por um `git revert` (um marco que desfaz outro)
##   nó fantasma   commit que nenhuma branch alcança mais (ficou para trás num `reset`)
##   nó magenta    um fantasma que o jogador não criou e cuja mensagem não dá para ler
##   HEAD          o ponteiro, sobre o commit atual
##   STASH         quantos trabalhos estão guardados na prateleira (stash)
##
## Mostra os últimos commits que couberem na largura disponível.

const FONTE := preload("res://Dialogo/MonospacePixel.ttf")
const ESPACO := 27.0
const COR_VIVO := Color("3DDB7B")
const COR_REVERT := Color("36D6E9")
const COR_FANTASMA := Color(0.7, 0.72, 0.8, 0.4)
const COR_MISTERIO := Color("FF2BD6")
const COR_HEAD := Color("FFE08A")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EstadoRetorno.conectar_mudancas(_agendar)
	GameState.branch_ativa_mudou.connect(_agendar.unbind(2))
	_agendar()


func _agendar() -> void:
	queue_redraw.call_deferred()


func _draw() -> void:
	var fundo := Rect2(Vector2.ZERO, size)
	draw_rect(fundo, Color(0, 0, 0, 0.72))
	draw_rect(fundo, Color.WHITE, false, 1.0)
	_texto("LINHA DO TEMPO", Vector2(5.0, 8.0), 5, Color(0.7, 0.9, 1.0))

	var stash := GameState.stash_pilha.size()
	var texto_stash := "STASH: %d" % stash
	var cor_stash := Color(0.95, 0.8, 0.4) if stash > 0 else Color(0.55, 0.55, 0.65)
	_texto(texto_stash, Vector2(size.x - 5.0 - _largura(texto_stash, 5), 8.0), 5, cor_stash)

	var todos := GameState.commits
	if todos.is_empty():
		return
	var vivos := {}
	for commit in GameState.historico():
		vivos[commit["id"]] = true
	var head := GameState.obter_head()

	var cabem := maxi(1, int((size.x - 12.0) / ESPACO))
	var inicio := maxi(0, todos.size() - cabem)
	var y := size.y * 0.62
	var posicoes := {}
	for i in range(inicio, todos.size()):
		posicoes[todos[i]["id"]] = Vector2(14.0 + (i - inicio) * ESPACO, y)

	# fios (do pai para o filho)
	for i in range(inicio, todos.size()):
		var commit: Dictionary = todos[i]
		var ligacao_viva: bool = vivos.has(commit["id"])
		for pai in GameState.pais_de(commit):
			if posicoes.has(pai):
				var cor_fio := Color(0.55, 0.6, 0.7, 0.9) if ligacao_viva else Color(0.55, 0.6, 0.7, 0.3)
				draw_line(posicoes[pai], posicoes[commit["id"]], cor_fio, 1.0)

	# nós
	for i in range(inicio, todos.size()):
		var commit: Dictionary = todos[i]
		var id := str(commit["id"])
		var p: Vector2 = posicoes[id]
		var vivo := vivos.has(id)
		var cor := COR_FANTASMA
		if commit.get("misterio", false):
			cor = COR_MISTERIO
		elif vivo:
			cor = COR_REVERT if commit.has("reverte") else COR_VIVO
		if vivo or commit.get("misterio", false):
			draw_circle(p, 4.0, cor)
		else:
			draw_arc(p, 4.0, 0.0, TAU, 14, cor, 1.0)
		var rotulo := "???" if commit.get("misterio", false) else id.substr(0, 5)
		_texto(rotulo, p + Vector2(-_largura(rotulo, 5) / 2.0, 12.0), 5, Color(cor.r, cor.g, cor.b, maxf(cor.a, 0.6)))
		if id == head:
			var topo := p + Vector2(0.0, -7.0)
			draw_colored_polygon(PackedVector2Array([topo, topo + Vector2(-3.0, -5.0), topo + Vector2(3.0, -5.0)]), COR_HEAD)
			_texto("HEAD", topo + Vector2(-_largura("HEAD", 5) / 2.0, -7.0), 5, COR_HEAD)


func _texto(texto: String, posicao: Vector2, tamanho: int, cor: Color) -> void:
	draw_string(FONTE, posicao, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)


func _largura(texto: String, tamanho: int) -> float:
	return FONTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x

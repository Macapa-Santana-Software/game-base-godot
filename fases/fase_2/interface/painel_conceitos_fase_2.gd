class_name PainelConceitosFase2 extends CanvasLayer
## Painel de CONCEITOS DO GIT da Fase 2 (lateral direita, recolhível).
##
## Resumo consultável durante toda a fase: repositório, commit, branch, HEAD, switch, merge e log.
## Independe dos objetivos: todos os conceitos ficam disponíveis desde o início e continuam
## disponíveis depois de apresentados (não depende do terminal, do Eidolon nem do progresso).
##
## - Tecla C ou aba "CONCEITOS" abre/recolhe. Também funciona com o terminal aberto.
## - Só consulta: nada aqui executa comandos nem altera o repositório.
## - Não pausa o jogo; compacto para deixar o cenário visível. Começa recolhido.

const TEMA := preload("res://GeneralNodes/UI/tema_santuario.tres")
const Dados := preload("res://fases/fase_2/interface/conceitos_fase_2.gd")

const LARGURA := 186.0
const ALTURA := 196.0
const TOPO := 34.0
const Y_ABA := 34.0
const LARGURA_ABA := 52.0
const DURACAO := 0.18

const COR_CIANO := Color("36D6E9")
const COR_VIOLETA := Color("8964D8")
const COR_TEXTO := Color("E4F2F5")
const COR_DISCRETA := Color(0.357, 0.408, 0.498)
const BB_TITULO := "#36D6E9"
const BB_CMD := "#FFE08A"
const BB_JOGO := "#B79BFF"

## Lembra o conceito aberto e o estado (aberto/recolhido) ao recarregar a cena na mesma sessão.
static var _selecionado_na_sessao: String = "repositorio"
static var _aberto_na_sessao: bool = false

var _aberto: bool = false
var _terminal_aberto: bool = false
var _selecionado: String = "repositorio"

var _raiz: Control
var _painel: Panel
var _aba: Button
var _caixa_abas: HFlowContainer
var _grupo_abas := ButtonGroup.new()
var _rolagem: ScrollContainer
var _texto: RichTextLabel
var _tween: Tween


func _ready() -> void:
	layer = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	_selecionado = _selecionado_na_sessao
	_aberto = _aberto_na_sessao
	_montar()
	GameState.terminal_aberto.connect(_on_terminal_aberto)
	GameState.terminal_fechado.connect(_on_terminal_fechado)
	get_viewport().size_changed.connect(_ajustar_raiz)
	_reconstruir_abas()
	_renderizar()
	_aplicar_posicao(false)
	_fixar_tamanhos.call_deferred()


func _exit_tree() -> void:
	if GameState.terminal_aberto.is_connected(_on_terminal_aberto):
		GameState.terminal_aberto.disconnect(_on_terminal_aberto)
	if GameState.terminal_fechado.is_connected(_on_terminal_fechado):
		GameState.terminal_fechado.disconnect(_on_terminal_fechado)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
			return
		# Diálogo/menu pausam a árvore: o painel fica quieto. O terminal também pausa, mas ali ele ajuda.
		if get_tree().paused and not _terminal_aberto:
			return
		alternar()
		get_viewport().set_input_as_handled()


func alternar() -> void:
	_aberto = not _aberto
	_aberto_na_sessao = _aberto
	_aplicar_posicao(true)


func _on_terminal_aberto() -> void:
	_terminal_aberto = true


func _on_terminal_fechado() -> void:
	_terminal_aberto = false


# ---------------------------------------------------------------- interface

func _largura_tela() -> float:
	return _raiz.size.x


func _fixar_tamanhos() -> void:
	_aba.size = Vector2(LARGURA_ABA, 28)
	_painel.size = Vector2(LARGURA, ALTURA)
	_aplicar_posicao(false)


func _ajustar_raiz() -> void:
	_raiz.position = Vector2.ZERO
	_raiz.size = get_viewport().get_visible_rect().size
	if _painel and _aba:  # ainda não existem durante a montagem inicial
		_aplicar_posicao(false)


func _aplicar_posicao(animar: bool) -> void:
	var vw := _largura_tela()
	var x_painel := vw - LARGURA if _aberto else vw + 4.0
	var x_aba := vw - LARGURA - LARGURA_ABA if _aberto else vw - LARGURA_ABA
	if _tween:
		_tween.kill()
	if not animar:
		_painel.position.x = x_painel
		_aba.position.x = x_aba
		return
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_painel, "position:x", x_painel, DURACAO)
	_tween.tween_property(_aba, "position:x", x_aba, DURACAO)


func _montar() -> void:
	_raiz = Control.new()
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.theme = TEMA
	add_child(_raiz)
	_ajustar_raiz()

	# Panel (não PanelContainer): tamanho fixo; o conteúdo rola dentro dele em vez de esticá-lo
	_painel = Panel.new()
	_painel.add_theme_stylebox_override("panel", TEMA.get_stylebox("panel", "PanelContainer"))
	_painel.size = Vector2(LARGURA, ALTURA)
	_painel.position = Vector2(_largura_tela() + 4.0, TOPO)
	_painel.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(_painel)

	var margem := MarginContainer.new()
	margem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 8)
	_painel.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 5)
	margem.add_child(coluna)
	coluna.add_child(_montar_cabecalho())

	_caixa_abas = HFlowContainer.new()
	_caixa_abas.add_theme_constant_override("h_separation", 3)
	_caixa_abas.add_theme_constant_override("v_separation", 3)
	coluna.add_child(_caixa_abas)
	coluna.add_child(HSeparator.new())

	_rolagem = ScrollContainer.new()
	_rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolagem.custom_minimum_size = Vector2(0, 40)
	coluna.add_child(_rolagem)
	_rolagem.get_v_scroll_bar().custom_minimum_size.x = 4.0

	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.fit_content = true
	_texto.scroll_active = false
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto.custom_minimum_size = Vector2(LARGURA - 38.0, 0)
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto.add_theme_font_size_override("normal_font_size", 8)
	_texto.add_theme_color_override("default_color", COR_TEXTO)
	_rolagem.add_child(_texto)

	_aba = Button.new()
	_aba.text = "CONCEITOS\n[C]"
	_aba.focus_mode = Control.FOCUS_NONE
	_aba.custom_minimum_size = Vector2(LARGURA_ABA, 28)
	_aba.size = _aba.custom_minimum_size
	_aba.position = Vector2(_largura_tela() - LARGURA_ABA, Y_ABA)
	_aba.add_theme_font_size_override("font_size", 7)
	_estilizar_botao(_aba, 4, 3)
	_aba.pressed.connect(alternar)
	_raiz.add_child(_aba)


func _montar_cabecalho() -> Control:
	var faixa := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.11, 0.153, 0.259)
	estilo.border_width_bottom = 2
	estilo.border_color = COR_VIOLETA
	estilo.content_margin_left = 6.0
	estilo.content_margin_right = 3.0
	estilo.content_margin_top = 3.0
	estilo.content_margin_bottom = 3.0
	faixa.add_theme_stylebox_override("panel", estilo)

	var linha := HBoxContainer.new()
	faixa.add_child(linha)

	var titulo := Label.new()
	titulo.text = "CONCEITOS DO GIT"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titulo.add_theme_font_size_override("font_size", 9)
	titulo.add_theme_color_override("font_color", COR_VIOLETA.lightened(0.35))
	linha.add_child(titulo)

	var fechar_botao := Button.new()
	fechar_botao.text = "X"
	fechar_botao.focus_mode = Control.FOCUS_NONE
	fechar_botao.custom_minimum_size = Vector2(16, 16)
	fechar_botao.add_theme_font_size_override("font_size", 8)
	_estilizar_botao(fechar_botao, 2, 1)
	fechar_botao.pressed.connect(func() -> void:
		if _aberto:
			alternar())
	linha.add_child(fechar_botao)
	return faixa


func _estilo(fundo: Color, borda: Color, margem_x: float, margem_y: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.set_border_width_all(2)
	s.border_color = borda
	s.content_margin_left = margem_x
	s.content_margin_right = margem_x
	s.content_margin_top = margem_y
	s.content_margin_bottom = margem_y
	return s


func _estilizar_botao(botao: Button, margem_x: float, margem_y: float) -> void:
	var normal := _estilo(Color(0.094, 0.133, 0.227), Color(0.227, 0.29, 0.439), margem_x, margem_y)
	var destaque := _estilo(Color(0.125, 0.173, 0.282), COR_CIANO, margem_x, margem_y)
	var ativo := _estilo(Color(0.2, 0.16, 0.37), COR_VIOLETA, margem_x, margem_y)
	botao.add_theme_stylebox_override("normal", normal)
	botao.add_theme_stylebox_override("hover", destaque)
	botao.add_theme_stylebox_override("focus", destaque)
	botao.add_theme_stylebox_override("pressed", ativo)
	botao.add_theme_stylebox_override("hover_pressed", ativo)


func _reconstruir_abas() -> void:
	for filho in _caixa_abas.get_children():
		filho.queue_free()
	for c in Dados.ORDEM:
		var aba := Button.new()
		aba.text = str(Dados.ENTRADAS[c]["rotulo"])
		aba.toggle_mode = true
		aba.button_group = _grupo_abas
		aba.focus_mode = Control.FOCUS_NONE
		aba.add_theme_font_size_override("font_size", 7)
		aba.add_theme_color_override("font_pressed_color", COR_CIANO)
		aba.add_theme_color_override("font_hover_pressed_color", COR_CIANO)
		_estilizar_botao(aba, 4, 2)
		aba.pressed.connect(_selecionar.bind(c))
		_caixa_abas.add_child(aba)
		if c == _selecionado:
			aba.set_pressed_no_signal(true)


func _selecionar(conceito: String) -> void:
	_selecionado = conceito
	_selecionado_na_sessao = conceito
	_renderizar()
	_rolagem.scroll_vertical = 0


# ---------------------------------------------------------------- conteúdo

func _renderizar() -> void:
	var e: Dictionary = Dados.ENTRADAS.get(_selecionado, {})
	if e.is_empty():
		_texto.text = ""
		return
	var t := "[color=%s]%s[/color]\n\n" % [BB_TITULO, str(e["titulo"]).to_upper()]
	t += _secao("O QUE É", BB_TITULO) + str(e["faz"]) + "\n\n"
	t += _secao("NA FASE 2", BB_JOGO) + "[color=%s]%s[/color]\n\n" % [BB_JOGO, str(e["jogo"])]
	if not (e["comando"] as Array).is_empty():
		t += _secao("COMANDO", BB_TITULO)
		for linha in e["comando"]:
			t += "[color=%s]%s[/color]\n" % [BB_CMD, str(linha)]
	_texto.text = t


func _secao(titulo: String, cor: String) -> String:
	return "[color=%s]%s[/color]\n" % [cor, titulo]

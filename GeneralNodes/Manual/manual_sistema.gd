class_name ManualSistema extends CanvasLayer
## Manual do Sistema: referência permanente dos comandos Git, num menu recolhível na lateral esquerda.
##
## - Só consulta: não executa comandos nem altera o repositório (lê apenas o que o GameState libera).
## - Os comandos aparecem conforme a IA os apresenta (GameState.comandos_liberados) e, uma vez
##   liberados, continuam disponíveis (inclusive depois de recarregar a cena).
## - Abre/fecha pela aba "MANUAL" (mouse) ou pela tecla M. Também funciona com o terminal aberto,
##   quando a consulta é mais útil; nesse caso a aba é clicável e a digitação continua no terminal.
## - Não pausa o jogo: o painel é compacto para deixar o cenário visível.

const TEMA := preload("res://GeneralNodes/UI/tema_santuario.tres")
const Dados := preload("res://GeneralNodes/Manual/manual_comandos.gd")

const LARGURA_PAINEL := 186.0
const ALTURA_PAINEL := 190.0
const TOPO_PAINEL := 40.0
const Y_ABA := 122.0
const DURACAO := 0.18
## Chave em GameState.progresso_tutoria: comandos cujo verbete o jogador já abriu.
const CHAVE_VISTOS := "manual_visto"

const COR_CIANO := Color("36D6E9")
const COR_VIOLETA := Color("8964D8")
const COR_MAGENTA := Color("D94C91")
const COR_TEXTO := Color("E4F2F5")
const COR_DISCRETA := Color(0.357, 0.408, 0.498)
const BBCODE_TITULO := "#36D6E9"
const BBCODE_CMD := "#FFE08A"
const BBCODE_JOGO := "#B79BFF"

## Comandos que esta fase apresenta (na ordem em que aparecem nas abas).
@export var comandos: Array[String] = ["init", "status", "add", "commit"]

var _aberto: bool = false
var _terminal_aberto: bool = false
var _selecionado: String = ""
var _disponiveis: Array[String] = []

var _raiz: Control
var _painel: Panel
var _aba: Button
var _selo: ColorRect
var _caixa_abas: HBoxContainer
var _grupo_abas := ButtonGroup.new()
var _rolagem: ScrollContainer
var _texto: RichTextLabel
var _nota: Label
var _tween: Tween
var _tween_selo: Tween


func _ready() -> void:
	layer = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()

	GameState.comandos_atualizados.connect(_atualizar_disponiveis)
	GameState.terminal_aberto.connect(_on_terminal_aberto)
	GameState.terminal_fechado.connect(_on_terminal_fechado)
	get_viewport().size_changed.connect(_ajustar_raiz)
	# Adiado: a tutora da fase ainda está preparando a lista de comandos liberados neste frame.
	_atualizar_disponiveis.call_deferred()
	_fixar_tamanhos.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		# Pausa de diálogo/menu: o manual fica quieto. O terminal também pausa o jogo, mas ali ele é útil.
		if get_tree().paused and not _terminal_aberto:
			return
		alternar()
		get_viewport().set_input_as_handled()


func alternar() -> void:
	if _aberto:
		fechar()
	else:
		abrir()


func abrir() -> void:
	if _aberto or _disponiveis.is_empty():
		return
	_aberto = true
	# Abre no verbete mais recente que o jogador ainda não leu (o que a IA acabou de apresentar)
	var novos := _nao_vistos()
	if not novos.is_empty():
		_selecionado = novos[-1]
	_marcar_visto(_selecionado)
	_reconstruir_abas()
	_renderizar()

	_fixar_tamanhos()
	_painel.visible = true
	_mover(0.0, LARGURA_PAINEL)
	_atualizar_selo()


func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	_mover(-LARGURA_PAINEL, 0.0)
	_tween.finished.connect(_ao_terminar_de_fechar, CONNECT_ONE_SHOT)
	_atualizar_selo()


func _ao_terminar_de_fechar() -> void:
	if not _aberto:
		_painel.visible = false


func _mover(x_painel: float, x_aba: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_painel, "position:x", x_painel, DURACAO)
	_tween.tween_property(_aba, "position:x", x_aba, DURACAO)


# ---------------------------------------------------------------- estado

func _liberado(comando: String) -> bool:
	# Sem liberação progressiva (fases futuras), tudo que a fase apresenta está disponível.
	return not GameState.liberacao_progressiva or comando in GameState.comandos_liberados


func _atualizar_disponiveis() -> void:
	_disponiveis = []
	for c in comandos:
		if _liberado(c) and Dados.ENTRADAS.has(c):
			_disponiveis.append(c)
	if _selecionado == "" or not _selecionado in _disponiveis:
		_selecionado = _disponiveis[-1] if not _disponiveis.is_empty() else ""
	_reconstruir_abas()
	_renderizar()
	_atualizar_selo()
	_atualizar_nota()


func _vistos() -> Array:
	var tutoria := GameState.progresso_tutoria
	if not tutoria.has(CHAVE_VISTOS):
		tutoria[CHAVE_VISTOS] = []
	return tutoria[CHAVE_VISTOS]


func _nao_vistos() -> Array[String]:
	var lista: Array[String] = []
	var vistos := _vistos()
	for c in _disponiveis:
		if not c in vistos:
			lista.append(c)
	return lista


func _marcar_visto(comando: String) -> void:
	if comando != "" and not comando in _vistos():
		_vistos().append(comando)


func _on_terminal_aberto() -> void:
	_terminal_aberto = true


func _on_terminal_fechado() -> void:
	_terminal_aberto = false


# ---------------------------------------------------------------- interface

## Ao entrar na árvore os controles crescem até o mínimo calculado com o tema padrão e não
## encolhem sozinhos: reaplica o tamanho compacto desejado depois que o tema da fase valeu.
func _fixar_tamanhos() -> void:
	_aba.size = Vector2(40, 28)
	_painel.size = Vector2(LARGURA_PAINEL, ALTURA_PAINEL)
	_selo.position = Vector2(_aba.size.x - 3.0, -3.0)


func _ajustar_raiz() -> void:
	_raiz.position = Vector2.ZERO
	_raiz.size = get_viewport().get_visible_rect().size


func _montar() -> void:
	_raiz = Control.new()
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.theme = TEMA
	add_child(_raiz)
	_ajustar_raiz()

	# --- painel expansível
	# Panel (não PanelContainer): tamanho fixo, o conteúdo rola dentro dele em vez de esticá-lo
	_painel = Panel.new()
	_painel.add_theme_stylebox_override("panel", TEMA.get_stylebox("panel", "PanelContainer"))
	_painel.size = Vector2(LARGURA_PAINEL, ALTURA_PAINEL)
	_painel.position = Vector2(-LARGURA_PAINEL, TOPO_PAINEL)
	_painel.mouse_filter = Control.MOUSE_FILTER_STOP
	_painel.visible = false
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

	_caixa_abas = HBoxContainer.new()
	_caixa_abas.add_theme_constant_override("separation", 3)
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
	# Largura mínima fixa: sem ela, com o painel oculto, o texto quebraria letra por letra e o painel cresceria
	_texto.custom_minimum_size = Vector2(LARGURA_PAINEL - 38.0, 0)
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texto.add_theme_font_size_override("normal_font_size", 8)
	_texto.add_theme_color_override("default_color", COR_TEXTO)
	_rolagem.add_child(_texto)

	_nota = Label.new()
	_nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nota.add_theme_font_size_override("font_size", 6)
	_nota.add_theme_color_override("font_color", COR_DISCRETA)
	coluna.add_child(_nota)

	# --- aba na borda esquerda (acompanha o painel ao abrir)
	_aba = Button.new()
	_aba.text = "MANUAL\n[M]"
	_aba.focus_mode = Control.FOCUS_NONE        # não rouba o foco do campo de texto do terminal
	_aba.custom_minimum_size = Vector2(40, 28)
	_aba.size = _aba.custom_minimum_size
	_aba.position = Vector2(0, Y_ABA)
	_aba.add_theme_font_size_override("font_size", 7)
	_estilizar_botao(_aba, 4, 3)
	_aba.pressed.connect(alternar)
	_raiz.add_child(_aba)

	_selo = ColorRect.new()
	_selo.color = COR_MAGENTA
	_selo.size = Vector2(6, 6)
	_selo.position = Vector2(_aba.size.x - 3.0, -3.0)
	_selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selo.visible = false
	_aba.add_child(_selo)


func _montar_cabecalho() -> Control:
	var faixa := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.11, 0.153, 0.259)
	estilo.border_width_bottom = 2
	estilo.border_color = COR_CIANO
	estilo.content_margin_left = 6.0
	estilo.content_margin_right = 3.0
	estilo.content_margin_top = 3.0
	estilo.content_margin_bottom = 3.0
	faixa.add_theme_stylebox_override("panel", estilo)

	var linha := HBoxContainer.new()
	faixa.add_child(linha)

	var titulo := Label.new()
	titulo.text = "MANUAL DO SISTEMA"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titulo.add_theme_font_size_override("font_size", 9)
	titulo.add_theme_color_override("font_color", COR_CIANO)
	linha.add_child(titulo)

	var fechar_botao := Button.new()
	fechar_botao.text = "X"
	fechar_botao.focus_mode = Control.FOCUS_NONE
	fechar_botao.custom_minimum_size = Vector2(16, 16)
	fechar_botao.add_theme_font_size_override("font_size", 8)
	_estilizar_botao(fechar_botao, 2, 1)
	fechar_botao.pressed.connect(fechar)
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
	var vistos := _vistos()
	for c in _disponiveis:
		var aba := Button.new()
		aba.text = c
		aba.toggle_mode = true
		aba.button_group = _grupo_abas
		aba.focus_mode = Control.FOCUS_NONE
		aba.add_theme_font_size_override("font_size", 8)
		_estilizar_botao(aba, 4, 2)
		# Verbete ainda não lido: texto em magenta (convite discreto, sem som nem pausa)
		if not c in vistos:
			aba.add_theme_color_override("font_color", COR_MAGENTA)
			aba.add_theme_color_override("font_hover_color", COR_MAGENTA)
		else:
			aba.add_theme_color_override("font_pressed_color", COR_CIANO)
			aba.add_theme_color_override("font_hover_pressed_color", COR_CIANO)
		aba.pressed.connect(_selecionar.bind(c))
		_caixa_abas.add_child(aba)
		if c == _selecionado:
			aba.set_pressed_no_signal(true)


func _selecionar(comando: String) -> void:
	_selecionado = comando
	_marcar_visto(comando)
	_renderizar()
	_rolagem.scroll_vertical = 0
	_reconstruir_abas()
	_atualizar_selo()


func _atualizar_selo() -> void:
	var mostrar := not _aberto and not _nao_vistos().is_empty()
	_selo.visible = mostrar
	if _tween_selo:
		_tween_selo.kill()
	_selo.modulate.a = 1.0
	if mostrar:
		_tween_selo = create_tween().set_loops()
		_tween_selo.tween_property(_selo, "modulate:a", 0.25, 0.6)
		_tween_selo.tween_property(_selo, "modulate:a", 1.0, 0.6)


func _atualizar_nota() -> void:
	var nota := "Só consulta: nada aqui executa comandos."
	if _disponiveis.size() < comandos.size():
		nota += "\nNovos comandos aparecem quando a IA os apresenta."
	_nota.text = nota


# ---------------------------------------------------------------- conteúdo

func _renderizar() -> void:
	var e: Dictionary = Dados.ENTRADAS.get(_selecionado, {})
	if e.is_empty():
		_texto.text = ""
		return
	var t := ""
	t += _secao("SINTAXE", BBCODE_TITULO) + _comandos(e["sintaxe"])
	t += _secao("O QUE FAZ", BBCODE_TITULO) + str(e["faz"]) + "\n\n"
	t += _secao("PARA QUE SERVE", BBCODE_TITULO) + str(e["serve"]) + "\n\n"
	t += _secao("EXEMPLO", BBCODE_TITULO) + _comandos(e["exemplo"])
	t += _secao("RESULTADO ESPERADO", BBCODE_TITULO) + str(e["resultado"]) + "\n\n"
	t += _secao("NO JOGO", BBCODE_JOGO) + "[color=%s]%s[/color]" % [BBCODE_JOGO, str(e["jogo"])]
	_texto.text = t


func _secao(titulo: String, cor: String) -> String:
	return "[color=%s]%s[/color]\n" % [cor, titulo]


func _comandos(linhas: Array) -> String:
	var t := ""
	for l in linhas:
		t += "[color=%s]%s[/color]\n" % [BBCODE_CMD, str(l)]
	return t + "\n"

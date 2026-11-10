class_name PainelObjetivosFase2 extends CanvasLayer
## Painel de OBJETIVOS da Fase 2 (lateral esquerda, recolhível).
##
## Mostra a jornada em ordem pedagógica e o que já foi realizado. NÃO guarda progresso próprio:
## cada objetivo é uma flag do ProgressoFase2, que por sua vez é derivada do GameState (fatos reais
## do repositório) ou ligada pela exploração. Abrir o terminal ou digitar um comando não conclui
## nada; só o RESULTADO da ação (a flag) conclui.
##
## - Tecla O ou aba "OBJETIVOS" abre/recolhe. Funciona com o terminal aberto, como o Manual da Fase 1.
## - Não pausa o jogo e é compacto para deixar o cenário visível.
## - Nunca altera o repositório nem as flags (somente leitura).

const TEMA := preload("res://GeneralNodes/UI/tema_santuario.tres")

const LARGURA := 132.0
const TOPO := 34.0
const Y_ABA := 34.0
const LARGURA_ABA := 52.0
const DURACAO := 0.18

const COR_CIANO := Color("36D6E9")
const COR_VIOLETA := Color("8964D8")
const COR_MAGENTA := Color("D94C91")
const COR_VERDE := Color("53E08A")
const COR_DISCRETA := Color(0.357, 0.408, 0.498)
const BB_ATUAL := "#36D6E9"
const BB_DESC := "#9FB4C8"
const BB_FEITO := "#5F8A72"
const BB_PENDENTE := "#7C8AA5"
const BB_CMD := "#FFE08A"

## A jornada, na ordem da progressão real. `flag` é lida do ProgressoFase2. Em `desc`, o que está entre
## crases é um comando do TERMINAL e aparece destacado. Os objetivos do eco usam `_descricao()`, que
## muda conforme a branch ativa (o caminho até o eco exige trocar de realidade pelas fissuras).
const OBJETIVOS: Array[Dictionary] = [
	{"flag": ProgressoFase2.LOG_CONSULTADO, "curto": "Investigar o histórico",
		"desc": "No terminal do Atlas (tecla T), digite `git log` para ler o histórico."},
	{"flag": ProgressoFase2.BRANCH_CRIADA, "curto": "Abrir uma nova linha",
		"desc": "No terminal, digite `git branch vida-alternativa`. Você continua em main."},
	{"flag": ProgressoFase2.ECO_VIDA, "curto": "Explorar a nova linha",
		"desc": ""},
	{"flag": ProgressoFase2.COMMIT_VIDA, "curto": "Registrar o eco da Vida",
		"desc": "No terminal: `git add eco_vida.eco` e depois `git commit -m \"mensagem\"`."},
	{"flag": ProgressoFase2.ECO_MAIN, "curto": "Voltar à realidade main",
		"desc": ""},
	{"flag": ProgressoFase2.COMMIT_MAIN, "curto": "Registrar o eco de main",
		"desc": "No terminal: `git add eco_main.eco` e depois `git commit -m \"mensagem\"`."},
	{"flag": ProgressoFase2.CONVERGENCIA_CONCLUIDA, "curto": "Reunir as duas linhas",
		"desc": "Em main, no terminal da Convergência, digite `git merge vida-alternativa`."},
	{"flag": ProgressoFase2.MERGE_INSPECIONADO, "curto": "Examinar o resultado",
		"desc": "Abra o Atlas (tecla T no artefato) e inspecione o nó de merge, o de dois fios."},
	{"flag": ProgressoFase2.REGISTRO_OBSERVADO, "curto": "Registrar o estado final",
		"desc": "Atravesse a porta selada até a última câmara e examine o registro final."},
]

## Lembra a escolha (aberto/recolhido) ao recarregar a cena na mesma sessão.
static var _recolhido_na_sessao: bool = false

var _progresso: ProgressoFase2
var _aberto: bool = true
var _terminal_aberto: bool = false
var _concluidos_antes: int = -1

var _raiz: Control
var _painel: PanelContainer
var _aba: Button
var _selo: ColorRect
var _titulo: Label
var _contador: Label
var _barra: ProgressBar
var _lista: VBoxContainer
var _tween: Tween
var _tween_selo: Tween
var _tween_marca: Tween


func _ready() -> void:
	layer = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	_aberto = not _recolhido_na_sessao
	_montar()
	_progresso = ProgressoFase2.de(self)
	if _progresso:
		_progresso.flag_alterada.connect(_on_flag_alterada)
		_progresso.branch_ativa_mudou.connect(func(_anterior: StringName, _nova: StringName) -> void: _atualizar())
	GameState.terminal_aberto.connect(_on_terminal_aberto)
	GameState.terminal_fechado.connect(_on_terminal_fechado)
	get_viewport().size_changed.connect(_ajustar_raiz)
	_atualizar()
	_aplicar_posicao(false)
	_fixar_tamanhos.call_deferred()


func _exit_tree() -> void:
	if GameState.terminal_aberto.is_connected(_on_terminal_aberto):
		GameState.terminal_aberto.disconnect(_on_terminal_aberto)
	if GameState.terminal_fechado.is_connected(_on_terminal_fechado):
		GameState.terminal_fechado.disconnect(_on_terminal_fechado)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_O:
		# Diálogo/menu pausam a árvore: o painel fica quieto. O terminal também pausa, mas ali ele ajuda.
		if get_tree().paused and not _terminal_aberto:
			return
		alternar()
		get_viewport().set_input_as_handled()


func alternar() -> void:
	_aberto = not _aberto
	_recolhido_na_sessao = not _aberto
	_aplicar_posicao(true)
	_atualizar_selo()


# ---------------------------------------------------------------- estado (somente leitura)

func _concluido(flag: StringName) -> bool:
	return _progresso != null and _progresso.obter(flag)


func _indice_atual() -> int:
	for i in OBJETIVOS.size():
		if not _concluido(OBJETIVOS[i]["flag"]):
			return i
	return -1


## Texto de apoio do objetivo atual. Só lê o estado real (branch ativa); nunca altera nada.
func _descricao(o: Dictionary) -> String:
	var na_vida := _progresso != null and _progresso.branch_ativa() == ProgressoFase2.BRANCH_VIDA
	var t: String = o["desc"]
	var flag: StringName = o["flag"]
	if flag == ProgressoFase2.ECO_VIDA:
		if na_vida:
			t = "Cruze a ponte de raízes. O espinheiro bloqueia o caminho: na fissura da ponte use `git switch main`, contorne e volte com `git switch vida-alternativa` na fissura do espinheiro. O eco brilha no sudeste."
		else:
			t = "No terminal, entre na nova linha: `git switch vida-alternativa`. O eco dela fica no sudeste, além do espinheiro."
	elif flag == ProgressoFase2.ECO_MAIN:
		if na_vida:
			t = "No terminal, volte à realidade principal: `git switch main`. O eco dela fica no sudoeste, ao sul da ponte quebrada."
		else:
			t = "Colha o eco de main: ele brilha no sudoeste, ao sul da ponte quebrada."
	return _destacar_comandos(t)


## `texto entre crases` vira comando destacado.
func _destacar_comandos(t: String) -> String:
	var re := RegEx.create_from_string("`([^`]+)`")
	return re.sub(t, "[color=%s]$1[/color]" % BB_CMD, true)


func _contar_concluidos() -> int:
	var n := 0
	for o in OBJETIVOS:
		if _concluido(o["flag"]):
			n += 1
	return n


func _on_flag_alterada(_nome: StringName, _valor: bool) -> void:
	_atualizar()


func _on_terminal_aberto() -> void:
	_terminal_aberto = true


func _on_terminal_fechado() -> void:
	_terminal_aberto = false


# ---------------------------------------------------------------- interface

func _fixar_tamanhos() -> void:
	_aba.size = Vector2(LARGURA_ABA, 28)
	_selo.position = Vector2(_aba.size.x - 3.0, -3.0)
	_painel.reset_size()
	_aplicar_posicao(false)


func _ajustar_raiz() -> void:
	_raiz.position = Vector2.ZERO
	_raiz.size = get_viewport().get_visible_rect().size


func _aplicar_posicao(animar: bool) -> void:
	var x_painel := 0.0 if _aberto else -LARGURA - 4.0
	var x_aba := LARGURA if _aberto else 0.0
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

	_painel = PanelContainer.new()
	_painel.add_theme_stylebox_override("panel", TEMA.get_stylebox("panel", "PanelContainer"))
	_painel.custom_minimum_size = Vector2(LARGURA, 0)
	_painel.position = Vector2(0, TOPO)
	_painel.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(_painel)

	var margem := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 7)
	_painel.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 4)
	margem.add_child(coluna)
	coluna.add_child(_montar_cabecalho())

	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.min_value = 0.0
	_barra.max_value = float(OBJETIVOS.size())
	_barra.custom_minimum_size = Vector2(0, 4)
	_barra.add_theme_stylebox_override("background", _estilo(Color(0.07, 0.09, 0.14), Color(0.16, 0.2, 0.3), 0, 0, 1))
	_barra.add_theme_stylebox_override("fill", _estilo(COR_CIANO, COR_CIANO, 0, 0, 0))
	coluna.add_child(_barra)

	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 3)
	coluna.add_child(_lista)

	_aba = Button.new()
	_aba.text = "OBJETIVOS\n[O]"
	_aba.focus_mode = Control.FOCUS_NONE
	_aba.custom_minimum_size = Vector2(LARGURA_ABA, 28)
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
	estilo.content_margin_left = 5.0
	estilo.content_margin_right = 3.0
	estilo.content_margin_top = 2.0
	estilo.content_margin_bottom = 2.0
	faixa.add_theme_stylebox_override("panel", estilo)

	var linha := HBoxContainer.new()
	faixa.add_child(linha)

	_titulo = Label.new()
	_titulo.text = "OBJETIVOS"
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_titulo.add_theme_font_size_override("font_size", 8)
	_titulo.add_theme_color_override("font_color", COR_CIANO)
	linha.add_child(_titulo)

	_contador = Label.new()
	_contador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_contador.add_theme_font_size_override("font_size", 7)
	_contador.add_theme_color_override("font_color", COR_DISCRETA)
	linha.add_child(_contador)

	var fechar_botao := Button.new()
	fechar_botao.text = "X"
	fechar_botao.focus_mode = Control.FOCUS_NONE
	fechar_botao.custom_minimum_size = Vector2(14, 14)
	fechar_botao.add_theme_font_size_override("font_size", 7)
	_estilizar_botao(fechar_botao, 2, 1)
	fechar_botao.pressed.connect(func() -> void:
		if _aberto:
			alternar())
	linha.add_child(fechar_botao)
	return faixa


func _estilo(fundo: Color, borda: Color, margem_x: float, margem_y: float, borda_largura: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.set_border_width_all(borda_largura)
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


# ---------------------------------------------------------------- conteúdo

func _atualizar() -> void:
	var feitos := _contar_concluidos()
	var atual := _indice_atual()
	_contador.text = "%d/%d" % [feitos, OBJETIVOS.size()]
	_barra.value = float(feitos)
	_titulo.text = "JORNADA CONCLUÍDA" if atual == -1 else "OBJETIVOS"
	_titulo.add_theme_color_override("font_color", COR_VERDE if atual == -1 else COR_CIANO)

	for filho in _lista.get_children():
		_lista.remove_child(filho)  # sai da árvore já, para o painel recalcular o tamanho sem eles
		filho.queue_free()
	if _tween_marca:
		_tween_marca.kill()

	for i in OBJETIVOS.size():
		var o := OBJETIVOS[i]
		var feito := _concluido(o["flag"])
		var eh_atual := i == atual
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 4)

		var marca := Panel.new()
		marca.custom_minimum_size = Vector2(7, 7)
		marca.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		marca.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if feito:
			marca.add_theme_stylebox_override("panel", _estilo(COR_VERDE, COR_VERDE, 0, 0, 1))
		elif eh_atual:
			marca.add_theme_stylebox_override("panel", _estilo(COR_VIOLETA, COR_CIANO, 0, 0, 1))
			_tween_marca = create_tween().set_loops()
			_tween_marca.tween_property(marca, "modulate:a", 0.35, 0.7)
			_tween_marca.tween_property(marca, "modulate:a", 1.0, 0.7)
		else:
			marca.add_theme_stylebox_override("panel", _estilo(Color(0, 0, 0, 0), Color(0.227, 0.29, 0.439), 0, 0, 1))
		linha.add_child(marca)

		var texto := RichTextLabel.new()
		texto.bbcode_enabled = true
		texto.fit_content = true
		texto.scroll_active = false
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texto.custom_minimum_size = Vector2(LARGURA - 36.0, 0)
		texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texto.add_theme_font_size_override("normal_font_size", 6)
		if feito:
			texto.text = "[color=%s][s]%s[/s][/color]" % [BB_FEITO, o["curto"]]
		elif eh_atual:
			texto.text = "[color=%s]%s[/color]\n[font_size=5][color=%s]%s[/color][/font_size]" % [BB_ATUAL, o["curto"], BB_DESC, _descricao(o)]
		else:
			texto.text = "[color=%s]%s[/color]" % [BB_PENDENTE, o["curto"]]
		linha.add_child(texto)
		_lista.add_child(linha)

	# Avisa, com um selo na aba, quando algo foi concluído com o painel recolhido.
	if _concluidos_antes >= 0 and feitos > _concluidos_antes and not _aberto:
		_selo_pendente = true
	_concluidos_antes = feitos
	_atualizar_selo()
	_painel.reset_size.call_deferred()


var _selo_pendente: bool = false


func _atualizar_selo() -> void:
	if _aberto:
		_selo_pendente = false
	_selo.visible = _selo_pendente and not _aberto
	if _tween_selo:
		_tween_selo.kill()
	_selo.modulate.a = 1.0
	if _selo.visible:
		_tween_selo = create_tween().set_loops()
		_tween_selo.tween_property(_selo, "modulate:a", 0.25, 0.6)
		_tween_selo.tween_property(_selo, "modulate:a", 1.0, 0.6)

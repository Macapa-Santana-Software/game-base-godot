class_name PainelObjetivosPonte extends CanvasLayer
## Quadro de OBJETIVOS da fase tutorial (checklist riscado conforme o jogador avança).
## Cada objetivo é uma condição lida do GameState/EstadoPonte, então o quadro nunca perde
## o progresso ao recarregar a cena. Fica no canto inferior direito; o quadro da IA fica no
## superior direito e o Manual (M) na lateral esquerda.

const FONTE := preload("res://Dialogo/MonospacePixel.ttf")
const COR_BORDA := "#FFFFFF"
const LARGURA := 118.0
const MARGEM := 6.0
const TAMANHO_FONTE := 6

var _raiz: Control
var _lista: VBoxContainer
## Cada item: { "texto": String, "label": RichTextLabel, "feito": Callable }
var _itens: Array[Dictionary] = []


func _ready() -> void:
	layer = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()

	_adicionar("Ler o histórico (git log)", func() -> bool: return EstadoPonte.log_visto())
	_adicionar("Criar a branch ponte", func() -> bool: return GameState.branch_existe(EstadoPonte.BRANCH))
	_adicionar("Entrar na branch ponte", func() -> bool: return EstadoPonte.entrou_na_ponte())
	_adicionar("Pegar a peça ponte.tile", func() -> bool: return EstadoPonte.coletada())
	_adicionar("Registrar a peça (add + commit)", func() -> bool: return EstadoPonte.na_ponte())
	_adicionar("Voltar para a main", func() -> bool: return EstadoPonte.na_ponte() and GameState.branch_ativa == GameState.BRANCH_PADRAO)
	_adicionar("Trazer a ponte (git merge)", func() -> bool: return EstadoPonte.na_main())

	GameState.log_consultado.connect(_agendar.unbind(1))
	GameState.branch_criada.connect(_agendar.unbind(2))
	GameState.branch_ativa_mudou.connect(_agendar.unbind(2))
	GameState.arquivo_coletado.connect(_agendar.unbind(1))
	GameState.arquivos_preparados.connect(_agendar.unbind(1))
	GameState.commit_realizado.connect(_agendar.unbind(1))
	GameState.merge_realizado.connect(_agendar.unbind(4))
	_agendar()


func _montar() -> void:
	_raiz = Control.new()
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	get_viewport().size_changed.connect(_ajustar_raiz)
	_ajustar_raiz()

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.784)
	estilo.border_color = Color(COR_BORDA)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(4)
	estilo.set_content_margin_all(5)

	var painel := PanelContainer.new()
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_theme_stylebox_override("panel", estilo)
	painel.anchor_left = 1.0
	painel.anchor_right = 1.0
	painel.anchor_top = 1.0
	painel.anchor_bottom = 1.0
	painel.offset_left = -(LARGURA + MARGEM)
	painel.offset_right = -MARGEM
	painel.offset_top = -MARGEM
	painel.offset_bottom = -MARGEM
	painel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	painel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_raiz.add_child(painel)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 3)
	painel.add_child(coluna)

	var titulo := Label.new()
	titulo.text = "OBJETIVOS"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", FONTE)
	titulo.add_theme_font_size_override("font_size", 5)
	coluna.add_child(titulo)
	coluna.add_child(HSeparator.new())

	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 2)
	coluna.add_child(_lista)


func _adicionar(texto: String, feito: Callable) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size.x = LARGURA - 10.0
	label.add_theme_font_override("normal_font", FONTE)
	label.add_theme_font_size_override("normal_font_size", TAMANHO_FONTE)
	_lista.add_child(label)
	_itens.append({"texto": texto, "label": label, "feito": feito})


# Adiado: a tutora atualiza as flags no mesmo sinal; aqui lemos o estado já consolidado.
func _agendar() -> void:
	_atualizar.call_deferred()


func _atualizar() -> void:
	for item in _itens:
		var label: RichTextLabel = item["label"]
		var texto := "- " + str(item["texto"])
		if (item["feito"] as Callable).call():
			label.text = "[s]%s[/s]" % texto
			label.modulate = Color(0.6, 0.6, 0.6, 1)
		else:
			label.text = texto
			label.modulate = Color.WHITE


func _ajustar_raiz() -> void:
	_raiz.position = Vector2.ZERO
	_raiz.size = get_viewport().get_visible_rect().size

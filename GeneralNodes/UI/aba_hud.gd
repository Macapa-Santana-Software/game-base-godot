class_name AbaHud extends RefCounted
## Comportamento comum das ABAS dos painéis recolhíveis da HUD (Manual, IA, Objetivos e Conceitos).
##
## Regra: com o painel RECOLHIDO ("para dentro") a aba fica translúcida para não atrapalhar o jogo, e ainda
## mais dentro do terminal. Ela volta a ficar opaca ao passar o mouse ou enquanto o painel está aberto, e
## fica um pouco mais visível (sem ficar opaca) quando há um aviso pendente (o selo piscando).

const ALFA_RECOLHIDA := 0.4
const ALFA_NO_TERMINAL := 0.28
## Com um aviso pendente (selo piscando) a aba aparece um pouco mais, mas continua translúcida.
const ALFA_AVISO := 0.65
const ALFA_AVISO_NO_TERMINAL := 0.5
const DURACAO := 0.15

const COR_CIANO := Color("36D6E9")
const COR_VIOLETA := Color("8964D8")


## Liga o efeito de "passar o mouse" na aba. Chame uma vez ao montar a aba.
static func configurar(aba: Button) -> void:
	aba.set_meta(&"hud_hover", false)
	aba.mouse_entered.connect(func() -> void:
		aba.set_meta(&"hud_hover", true)
		_atualizar(aba))
	aba.mouse_exited.connect(func() -> void:
		aba.set_meta(&"hud_hover", false)
		_atualizar(aba))


## Informa o estado do painel e aplica a transparência da aba.
static func aplicar(aba: Button, aberto: bool, terminal_aberto: bool, chamando: bool = false) -> void:
	if aba == null or not is_instance_valid(aba):
		return
	aba.set_meta(&"hud_aberto", aberto)
	aba.set_meta(&"hud_terminal", terminal_aberto)
	aba.set_meta(&"hud_chamando", chamando)
	_atualizar(aba)


static func alfa_da_aba(aberto: bool, terminal_aberto: bool, chamando: bool, hover: bool) -> float:
	if aberto or hover:
		return 1.0
	if chamando:
		return ALFA_AVISO_NO_TERMINAL if terminal_aberto else ALFA_AVISO
	return ALFA_NO_TERMINAL if terminal_aberto else ALFA_RECOLHIDA


static func _atualizar(aba: Button) -> void:
	if not is_instance_valid(aba) or not aba.is_inside_tree():
		return
	var alfa := alfa_da_aba(
		bool(aba.get_meta(&"hud_aberto", false)),
		bool(aba.get_meta(&"hud_terminal", false)),
		bool(aba.get_meta(&"hud_chamando", false)),
		bool(aba.get_meta(&"hud_hover", false)))
	if aba.has_meta(&"hud_tween"):
		var anterior: Variant = aba.get_meta(&"hud_tween")
		if anterior is Tween and (anterior as Tween).is_valid():
			(anterior as Tween).kill()
	var tween := aba.create_tween()
	tween.tween_property(aba, "modulate:a", alfa, DURACAO)
	aba.set_meta(&"hud_tween", tween)


## Estilo padrão das abas (o mesmo dos painéis da Fase 4).
static func estilizar(botao: Button, margem_x: float, margem_y: float) -> void:
	botao.add_theme_stylebox_override("normal", _estilo(Color(0.094, 0.133, 0.227), Color(0.227, 0.29, 0.439), margem_x, margem_y))
	var destaque := _estilo(Color(0.125, 0.173, 0.282), COR_CIANO, margem_x, margem_y)
	var ativo := _estilo(Color(0.2, 0.16, 0.37), COR_VIOLETA, margem_x, margem_y)
	botao.add_theme_stylebox_override("hover", destaque)
	botao.add_theme_stylebox_override("focus", destaque)
	botao.add_theme_stylebox_override("pressed", ativo)
	botao.add_theme_stylebox_override("hover_pressed", ativo)


static func _estilo(fundo: Color, borda: Color, margem_x: float, margem_y: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.set_border_width_all(2)
	s.border_color = borda
	s.content_margin_left = margem_x
	s.content_margin_right = margem_x
	s.content_margin_top = margem_y
	s.content_margin_bottom = margem_y
	return s

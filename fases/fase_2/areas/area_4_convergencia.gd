class_name Area4Convergencia extends AreaFase2
## Ponto de Convergência. O cenário só muda DEPOIS que o GameState confirma um merge real.
##
## `CONVERGENCIA_CONCLUIDA` é derivada do GameState: só liga quando existe, de verdade, um commit
## de merge de vida-alternativa em main. Esta área apenas reage visualmente à flag.
##
##   ANTES  duas metades distintas (violeta = main, verde = vida-alternativa), separadas por uma
##          fenda; os elementos de cada realidade esmaecidos nos seus slots.
##   DEPOIS a fenda some, os elementos das DUAS realidades acendem e surgem os que passam a
##          COEXISTIR (pedra e raízes, ponte e raízes, os dois ecos), sempre com as duas cores
##          lado a lado. Nenhuma metade é coberta ou apagada: a convergência preserva as duas.
##
## Placeholders de cor lisa (substituíveis por arte).

const ALFA_ESMAECIDO := 0.55
const DURACAO := 1.4

@onready var _fenda: CanvasItem = $Decor/Fenda_Divisoria
@onready var _fusao: CanvasItem = $Decor/Fusao_Resultado
@onready var _itens_main: CanvasItem = $Decor/Itens_Main
@onready var _itens_vida: CanvasItem = $Decor/Itens_Vida
@onready var _coexistencia: CanvasItem = $Decor/Coexistencia


func _ready() -> void:
	super()
	var progresso := ProgressoFase2.de(self)
	if progresso == null:
		return
	_aplicar(progresso.obter(ProgressoFase2.CONVERGENCIA_CONCLUIDA), false)
	progresso.flag_alterada.connect(_on_flag_alterada)


func _on_flag_alterada(nome: StringName, valor: bool) -> void:
	if nome == ProgressoFase2.CONVERGENCIA_CONCLUIDA:
		_aplicar(valor, true)


func _aplicar(convergiu: bool, animar: bool) -> void:
	_fenda.visible = not convergiu
	_fusao.visible = convergiu
	_coexistencia.visible = convergiu
	var alfa := 1.0 if convergiu else ALFA_ESMAECIDO
	if not animar:
		_itens_main.modulate.a = alfa
		_itens_vida.modulate.a = alfa
		_coexistencia.modulate.a = 1.0
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_itens_main, "modulate:a", alfa, DURACAO)
	tween.tween_property(_itens_vida, "modulate:a", alfa, DURACAO)
	if convergiu:
		_coexistencia.modulate.a = 0.0
		tween.tween_property(_coexistencia, "modulate:a", 1.0, DURACAO)

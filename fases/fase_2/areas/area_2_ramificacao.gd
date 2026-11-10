class_name Area2Ramificacao extends AreaFase2
## Câmara da Ramificação (hub neutro). As trilhas refletem o estado REAL do repositório:
##
##   * a trilha verde (vida-alternativa) só existe depois que a branch existe; ao surgir com a
##     área carregada, acende com um fade;
##   * a trilha da branch ativa fica em destaque e a outra, esmaecida (o HEAD, no cenário).
##
## Só lê o ProgressoFase2 (que repassa o GameState): criar a branch NÃO muda a branch ativa, então
## a trilha verde acende, mas o destaque continua em main até um `git switch`.

const ALFA_ATIVA := 1.0
const ALFA_INATIVA := 0.55
const DURACAO_FADE := 1.2

@onready var _trilhas_vida: Array[CanvasItem] = [
	$Decor/Trilha_Vida, $Decor/Trilha_Convergencia_Vida]
@onready var _trilhas_main: Array[CanvasItem] = [
	$Decor/Trilha_Main, $Decor/Trilha_Convergencia_Main]

var _progresso: ProgressoFase2
var _vida_visivel: bool = false


func _ready() -> void:
	super()
	_progresso = ProgressoFase2.de(self)
	if _progresso == null:
		return
	_atualizar(false)
	_progresso.branch_criada.connect(func(_nome: StringName) -> void: _atualizar(true))
	_progresso.branch_ativa_mudou.connect(func(_a: StringName, _b: StringName) -> void: _atualizar(false))


func _atualizar(animar: bool) -> void:
	var existe := _progresso.branch_existe(ProgressoFase2.BRANCH_VIDA)
	var vida_ativa := _progresso.branch_ativa() == ProgressoFase2.BRANCH_VIDA
	for trilha in _trilhas_main:
		trilha.modulate.a = ALFA_ATIVA if (not existe or not vida_ativa) else ALFA_INATIVA
	for trilha in _trilhas_vida:
		trilha.visible = existe
		var alfa := ALFA_ATIVA if vida_ativa else ALFA_INATIVA
		if existe and animar and not _vida_visivel:
			trilha.modulate.a = 0.0
			create_tween().tween_property(trilha, "modulate:a", alfa, DURACAO_FADE)
		else:
			trilha.modulate.a = alfa
	_vida_visivel = existe

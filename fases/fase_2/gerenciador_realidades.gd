class_name RealidadesFase2 extends Node
## Faz o MAPA reagir às mudanças de branch. Não conhece comandos Git: escuta os sinais
## repassados pelo ProgressoFase2 (que vêm do GameState) e nunca altera o repositório.
##
## Reações:
##   * branch criada       -> a realidade correspondente passa a existir (fica visível);
##   * branch ativa mudou  -> realidades inativas escurecem; se o jogador estava DENTRO de
##                            uma realidade, ele é reposicionado na realidade de destino;
##   * o tempo todo        -> guarda a posição do jogador na realidade em que ele está.
##
## Destino do reposicionamento (nesta ordem):
##   1. a fissura-par, se o jogador estava sobre uma fissura (ponto de ancoragem);
##   2. a última posição conhecida na realidade de destino;
##   3. a entrada dessa realidade (primeira visita).
## Por isso trocar de branch longe de uma fissura NÃO permite contornar obstáculos.
##
## Estado por realidade, guardado em GameState.branches[nome].mundo (via ProgressoFase2):
##   "posicao": Vector2 (local à área)   "visitada": bool   "eco_coletado": bool

## Cor do fade ao entrar em cada realidade.
const COR_TROCA := {
	"main": Color("7a58d6"),
	"vida-alternativa": Color("52e08a"),
}
const MUNDOS: Array[String] = ["main", "vida-alternativa"]

@onready var progresso: ProgressoFase2 = $"../Progresso"

var _player: Player
var _transicao: TransicaoRealidade
var _mundos: Dictionary = {}   # realidade -> AreaFase2
var _mundo_atual: String = ""  # realidade em que o jogador está agora ("" = área neutra)
var _troca_pendente: bool = false  # branch trocada com o jogo pausado (terminal aberto)


## Chamado pela fase quando todos os nós já estão prontos.
func iniciar(player: Player, transicao: TransicaoRealidade) -> void:
	_player = player
	_transicao = transicao
	for no in get_tree().get_nodes_in_group(AreaFase2.GRUPO):
		var area := no as AreaFase2
		if area.realidade in MUNDOS:
			_mundos[area.realidade] = area
			area.jogador_entrou.connect(_on_jogador_entrou)
			area.jogador_saiu.connect(_on_jogador_saiu)
	progresso.branch_criada.connect(_on_branch_criada)
	progresso.branch_ativa_mudou.connect(_on_branch_ativa_mudou)
	GameState.terminal_fechado.connect(_on_terminal_fechado)
	_atualizar_visual()


func _exit_tree() -> void:
	if GameState.terminal_fechado.is_connected(_on_terminal_fechado):
		GameState.terminal_fechado.disconnect(_on_terminal_fechado)


## Onde o jogador deve nascer: na última posição da realidade ativa, se ele já esteve
## nela (ex.: depois de uma derrota); senão, em `entrada_padrao`.
func posicao_inicial(entrada_padrao: Vector2) -> Vector2:
	var realidade := String(progresso.branch_ativa())
	var area: AreaFase2 = _mundos.get(realidade)
	var mundo := progresso.mundo_de(StringName(realidade))
	if area and mundo.get("visitada", false) and mundo.has("posicao"):
		return area.to_global(mundo["posicao"])
	return entrada_padrao


func _physics_process(_delta: float) -> void:
	if _player == null or _mundo_atual == "":
		return
	var area: AreaFase2 = _mundos.get(_mundo_atual)
	if area:
		progresso.guardar_mundo(StringName(_mundo_atual), "posicao", area.to_local(_player.global_position))


func _on_jogador_entrou(area: AreaFase2) -> void:
	_mundo_atual = area.realidade
	progresso.guardar_mundo(StringName(area.realidade), "visitada", true)


func _on_jogador_saiu(area: AreaFase2) -> void:
	if _mundo_atual == area.realidade:
		_mundo_atual = ""


func _on_branch_criada(nome: StringName) -> void:
	_atualizar_visual()
	MensagemHud.mostrar_em(self, "Uma nova realidade surgiu: '%s'." % nome)


func _on_branch_ativa_mudou(_anterior: StringName, nova: StringName) -> void:
	_atualizar_visual()
	MensagemHud.mostrar_em(self, "Branch ativa: '%s'." % nova)
	if get_tree().paused:
		# Troca feita com o terminal aberto (o jogo está pausado): o reposicionamento espera
		# o terminal fechar, para o fade acontecer à vista do jogador.
		_troca_pendente = true
		return
	await _reposicionar_para_branch_ativa()


func _on_terminal_fechado() -> void:
	if not _troca_pendente:
		return
	_troca_pendente = false
	await _reposicionar_para_branch_ativa()


## Leva o jogador à realidade da branch ATIVA no GameState, se ele estiver numa realidade
## diferente. Lê o estado atual (e não o do sinal), então várias trocas seguidas com o
## terminal aberto resultam só no destino final.
func _reposicionar_para_branch_ativa() -> void:
	var nova := String(progresso.branch_ativa())
	if _mundo_atual == "" or _mundo_atual == nova:
		return  # jogador numa área neutra (ou já na realidade certa): nada a mover
	var destino: Variant = _destino_para(nova)
	if destino == null:
		return
	var cor: Color = COR_TROCA.get(nova, Color.WHITE)
	await _transicao.transitar(cor, _reposicionar.bind(nova, destino as Vector2))


func _destino_para(nova: String) -> Variant:
	var ancora := _ancora_sob_o_jogador()
	if ancora:
		var par := _achar_par(ancora, nova)
		if par:
			return par.global_position
	var area: AreaFase2 = _mundos.get(nova)
	if area == null:
		return null
	var mundo := progresso.mundo_de(StringName(nova))
	if mundo.has("posicao"):
		return area.to_global(mundo["posicao"])
	return area.entrada_global()


func _ancora_sob_o_jogador() -> FissuraFase2:
	for no in get_tree().get_nodes_in_group(FissuraFase2.GRUPO_FISSURAS):
		var fissura := no as FissuraFase2
		if fissura.realidade == _mundo_atual and fissura.jogador_dentro():
			return fissura
	return null


func _achar_par(origem: FissuraFase2, realidade_destino: String) -> FissuraFase2:
	for no in get_tree().get_nodes_in_group(FissuraFase2.GRUPO_FISSURAS):
		var candidata := no as FissuraFase2
		if candidata.id_par == origem.id_par and candidata.realidade == realidade_destino:
			return candidata
	return null


func _reposicionar(realidade_destino: String, posicao: Vector2) -> void:
	_player.global_position = posicao
	_player.velocity = Vector2.ZERO
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.reset_smoothing()
	_mundo_atual = realidade_destino


## Uma realidade só existe se a sua branch existe (main sempre existe); a ativa fica
## normal e as demais ficam escurecidas.
func _atualizar_visual() -> void:
	for realidade in _mundos:
		var area: AreaFase2 = _mundos[realidade]
		area.visible = realidade == "main" or progresso.branch_existe(StringName(realidade))
		area.definir_ativa(StringName(realidade) == progresso.branch_ativa())

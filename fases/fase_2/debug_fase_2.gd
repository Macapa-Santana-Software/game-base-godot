class_name DebugFase2 extends CanvasLayer
## ============================================================================
##  FERRAMENTA DE DESENVOLVIMENTO — NÃO FAZ PARTE DO JOGO
## ============================================================================
## Atalhos para testar a Fase 2 sem o terminal (que só chega na Parte 3).
##
## COMO DESATIVAR (qualquer um):
##   1. desmarcar `habilitado` no Inspetor deste nó, ou
##   2. apagar o nó `DebugFase2` da cena da fase (nada mais depende dele), ou
##   3. nada a fazer em builds exportadas: com `apenas_em_build_debug` o nó se
##      desliga sozinho fora de builds de debug.
##
## Só age quando uma das teclas abaixo é pressionada; o painel começa escondido. Não usa
## o Input Map (teclas lidas direto do evento). Teclas de função, iguais em qualquer layout.
##
## ATENÇÃO: os atalhos abaixo (exceto HOME) só funcionam com o painel de debug aberto (HOME).
## Quem joga a fase usa o TERMINAL (`git branch`, `git switch`...): é a didática da fase.
##
##   N         executa `git branch vida-alternativa`   (GameState.criar_branch)
##   B         executa `git switch` para a outra branch (GameState.trocar_branch)
##   HOME      mostra/esconde o painel de estado
##   PAGE DOWN teleporta para a próxima área   (PAGE UP: anterior)  — ignora as regras
##   END       liga a próxima flag de exploração/placeholder (as do Git são derivadas)
##   INSERT    zera as flags de exploração/placeholder (NÃO mexe no repositório)
##
## N/B chamam as operações REAIS do GameState; nada aqui altera flags de branch.
## Não use teclas de função (F5–F12): o editor do Godot as reserva (ex.: pausa) e congela o
## jogo quando ele roda embutido. N e B não estão no Input Map; só valem sem modificadores
## (Ctrl/Alt/Shift/Meta) e com o nó habilitado. Com a árvore pausada (terminal, diálogo,
## menu de pausa) este nó não recebe entrada, e campos de texto consomem a tecla antes.
##
## CONVENIÊNCIA DE DESENVOLVIMENTO: ao rodar a Fase 2 sozinha (F6) o GameState chega
## vazio, sem o commit da Fase 1. Se (e somente se) não houver nenhum commit, este nó
## cria um repositório simulado usando as próprias operações do GameState. Na progressão
## normal já existe o commit da Fase 1 e nada disso acontece.

const FONTE := preload("res://Dialogo/MonospacePixel.ttf")
const BRANCH_ALTERNATIVA := "vida-alternativa"

@export var habilitado: bool = true
@export var apenas_em_build_debug: bool = true

var _player: Player
var _progresso: ProgressoFase2
var _areas: Array[AreaFase2] = []
var _indice_area: int = -1
var _area_atual: String = "-"
var _ultimo_resultado: String = ""
var _rotulo: Label


func _ativo() -> bool:
	return habilitado and (OS.is_debug_build() or not apenas_em_build_debug)


func _enter_tree() -> void:
	# No _enter_tree: precisa rodar antes dos _ready dos nós que leem o GameState.
	if _ativo() and GameState.commits.is_empty():
		_semear_repositorio_de_desenvolvimento()


func _ready() -> void:
	layer = 50
	if not _ativo():
		set_process_unhandled_input(false)
		hide()
		return
	_rotulo = Label.new()
	_rotulo.add_theme_font_override("font", FONTE)
	_rotulo.add_theme_font_size_override("font_size", 7)
	_rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_rotulo.add_theme_constant_override("outline_size", 3)
	_rotulo.position = Vector2(6, 40)
	_rotulo.visible = false
	add_child(_rotulo)


## Chamado pela fase depois que tudo está pronto.
func configurar(player: Player, progresso: ProgressoFase2) -> void:
	_player = player
	_progresso = progresso
	for no in get_tree().get_nodes_in_group(AreaFase2.GRUPO):
		var area := no as AreaFase2
		_areas.append(area)
		area.jogador_entrou.connect(_on_jogador_entrou)
	_progresso.flag_alterada.connect(func(_n: StringName, _v: bool) -> void: _atualizar_painel())
	_progresso.branch_ativa_mudou.connect(func(_a: StringName, _b: StringName) -> void: _atualizar_painel())
	_progresso.branch_criada.connect(func(_n: StringName) -> void: _atualizar_painel())
	_atualizar_painel()


func _semear_repositorio_de_desenvolvimento() -> void:
	GameState.inicializar_repositorio()
	GameState.coletar_arquivo_no_mapa("fase_1.dev")
	GameState.sincronizar_inventario_com_git()
	GameState.adicionar_ao_stage("fase_1.dev")
	GameState.criar_commit("[dev] histórico simulado da Fase 1")
	GameState.reset_fase()  # limpa só o temporário; o repositório fica
	print("[DEBUG FASE 2] Repositório simulado criado (execução isolada da fase).")


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or not (event is InputEventKey):
		return
	var tecla := event as InputEventKey
	if not tecla.pressed or tecla.echo:
		return
	if tecla.ctrl_pressed or tecla.alt_pressed or tecla.shift_pressed or tecla.meta_pressed:
		return
	# Os atalhos (N, B, PgUp/PgDn, End, Insert) só valem com o painel de debug ABERTO (HOME). Assim uma
	# tecla apertada por engano não cria/troca branch nem liga flags: o jogador usa o terminal.
	if tecla.keycode != KEY_HOME and not _rotulo.visible:
		return
	match tecla.keycode:
		KEY_N:
			_mostrar_resultado(GameState.criar_branch(BRANCH_ALTERNATIVA))
		KEY_B:
			var alvo := BRANCH_ALTERNATIVA if GameState.branch_ativa == GameState.BRANCH_PADRAO \
				else GameState.BRANCH_PADRAO
			_mostrar_resultado(GameState.trocar_branch(alvo))
		KEY_HOME:
			_rotulo.visible = not _rotulo.visible
		KEY_PAGEDOWN:
			_teleportar(1)
		KEY_PAGEUP:
			_teleportar(-1)
		KEY_END:
			_ligar_proxima_flag()
		KEY_INSERT:
			_progresso.resetar()


func _mostrar_resultado(resultado: Dictionary) -> void:
	var texto := RegEx.create_from_string("\\[/?[a-z]+(=[^\\]]*)?\\]").sub(
		str(resultado["mensagem"]), "", true)
	_ultimo_resultado = "%s %s" % ["OK" if resultado["ok"] else "ERRO", texto]
	print("[DEBUG FASE 2] ", _ultimo_resultado)
	MensagemHud.mostrar_em(self, texto)
	_atualizar_painel()


func _teleportar(passo: int) -> void:
	if _areas.is_empty():
		return
	_indice_area = wrapi(_indice_area + passo, 0, _areas.size())
	_player.global_position = _areas[_indice_area].ponto_spawn_debug()
	_player.velocity = Vector2.ZERO
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.reset_smoothing()


func _ligar_proxima_flag() -> void:
	for flag in ProgressoFase2.ORDEM_FLAGS:
		if flag in ProgressoFase2.FLAGS_DERIVADAS:
			continue
		if not _progresso.obter(flag):
			_progresso.definir(flag, true)
			return


func _on_jogador_entrou(area: AreaFase2) -> void:
	_area_atual = area.nome_exibicao
	_indice_area = _areas.find(area)
	_atualizar_painel()


func _atualizar_painel() -> void:
	if _rotulo == null:
		return
	var texto := "[DEBUG FASE 2 — só para testes; no jogo use o terminal]  N criar branch · B trocar\nárea: %s\nbranch ativa: %s\nbranches: %s\n" % [
		_area_atual, GameState.branch_ativa, ", ".join(GameState.listar_branches())]
	for flag in ProgressoFase2.ORDEM_FLAGS:
		var marca := "[x]" if _progresso.obter(flag) else "[ ]"
		var origem := " (git)" if flag in ProgressoFase2.FLAGS_DERIVADAS else ""
		texto += "%s %s%s\n" % [marca, flag, origem]
	if _ultimo_resultado != "":
		texto += "último: %s\n" % _ultimo_resultado
	_rotulo.text = texto

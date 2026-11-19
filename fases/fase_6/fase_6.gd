extends Node2D
## Fase 6 — Tutorial: "Ponto de Retorno" (comandos revert, stash e reset).
##
## Três áreas em fila, um comando novo em cada, usando o repositório REAL (GameState):
##   1. A Ponte       git log + git revert      um commit ruim sabotou a ponte
##   2. O Corredor    git stash + stash pop     trabalho pela metade e uma emergência
##   3. A Câmara      git reset --soft / --hard dois commits apressados, dois destinos
##
## A fase NÃO fecha a história: ao fim, a linha do tempo mostra um commit fantasma que o jogador
## não criou e não consegue ler. O portal abre, mas a pergunta fica (assunto de fases futuras).
##
## Esta cena só reage: o progresso e os fatos moram em EstadoRetorno (lidos do GameState).
## A IA é a da Fase 1 (TutoraFase1), com o roteiro desta fase (TutoraRetorno).

## Emitido a cada mudança do repositório ou da jornada (os filhos redesenham/reavaliam).
signal mudou
## Momentos da história para a IA comentar: "z1_ok", "z2_ok", "soft_ok", "commit_ok",
## "z3b_setup", "hard_ok", "alavanca", "restaurou".
signal evento(nome: String)

## Flags que, ao virarem verdadeiras, geram um `evento` (uma vez cada).
const MARCOS: Array[String] = ["z1_ok", "z2_ok", "soft_ok", "commit_ok", "z3b_setup", "hard_ok"]

@onready var porta_inspecao: PortaMural = $Portas/PortaInspecao
@onready var porta_camara: PortaMural = $Portas/PortaCamara
@onready var portal: ExitArea = $PortalSaida
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var limite_sup_esq: Marker2D = $Limites/SupEsq
@onready var limite_inf_dir: Marker2D = $Limites/InfDir
@onready var caixa_dialogo: Control = $DialogoHistoria/CaixaDialogo
@onready var eco: EcoEidolon = $EcoEidolon

## Arte da Fase 6 aplicada aos objetos compartilhados (Obelisco e portal): concreto e sinalização.
@export var textura_plataforma: Texture2D
@export var textura_portal: Texture2D
@export var cor_luz: Color = Color("F2C230")
## Onde o Eidolon aparece no fim, do outro lado, vendo o commit fantasma.
@export var posicao_final_eidolon: Vector2 = Vector2(1180, 170)

var fase_concluida: bool = false
var _terminal_aberto: bool = false
var _final_pendente: bool = false
var _marcos_avisados: Dictionary = {}


func _enter_tree() -> void:
	add_to_group("fase_6")


func _ready() -> void:
	_aplicar_tema()
	EstadoRetorno.construir()
	_configurar_camera()
	# Quem já estava concluído ao carregar (recarga por derrota) não dispara falas de novo.
	for marco in MARCOS:
		_marcos_avisados[marco] = EstadoRetorno.flag(marco)

	GameState.commit_realizado.connect(_on_repositorio_mudou.unbind(1))
	GameState.reset_realizado.connect(_on_repositorio_mudou.unbind(3))
	GameState.revert_realizado.connect(_on_repositorio_mudou.unbind(2))
	GameState.stash_guardado.connect(_on_repositorio_mudou.unbind(1))
	GameState.stash_aplicado.connect(_on_repositorio_mudou.unbind(1))
	GameState.arquivos_preparados.connect(_on_repositorio_mudou.unbind(1))
	GameState.arquivo_coletado.connect(_on_repositorio_mudou.unbind(1))
	GameState.log_consultado.connect(_on_log_consultado)
	GameState.terminal_aberto.connect(func() -> void: _terminal_aberto = true)
	GameState.terminal_fechado.connect(_on_terminal_fechado)

	var tutora := TutoraRetorno.new()
	add_child(tutora)

	portal.unlocked_entered.connect(_on_portal_unlocked_entered)
	victory_screen.proxima_fase_pressed.connect(_on_proxima_fase_pressed)
	notificar()


## O fim da fase: o Eidolon, do outro lado do corredor, vê o commit fantasma e diz uma única frase, sem emoção.
## Espera o terminal fechar (o diálogo pausa o jogo).
func _on_terminal_fechado() -> void:
	_terminal_aberto = false
	_tentar_final.call_deferred()


func _tentar_final() -> void:
	if not _final_pendente or _terminal_aberto or get_tree().paused:
		return
	_final_pendente = false
	eco.aparecer_em(posicao_final_eidolon)
	var falas: Array[String] = ["Eidolon: Esse hash... eu o conheço."]
	caixa_dialogo.dialogo_finalizado.connect(eco.sumir, CONNECT_ONE_SHOT)
	caixa_dialogo.iniciar_dialogo(falas)


func _aplicar_tema() -> void:
	for nome in ["ObeliscoArea1", "ObeliscoArea2", "ObeliscoArea2B", "ObeliscoArea3"]:
		var obelisco := get_node_or_null(nome)
		if obelisco == null:
			continue
		var plataforma := obelisco.get_node_or_null("Plataforma") as Sprite2D
		if plataforma and textura_plataforma:
			plataforma.texture = textura_plataforma
		var luz := obelisco.get_node_or_null("Luz") as PointLight2D
		if luz:
			luz.color = cor_luz
	var visual_portal := $PortalSaida.get_node_or_null("Portal") as Sprite2D
	if visual_portal and textura_portal:
		visual_portal.texture = textura_portal
	var luz_portal := $PortalSaida.get_node_or_null("Luz") as PointLight2D
	if luz_portal:
		luz_portal.color = cor_luz


func _configurar_camera() -> void:
	var limites: Array[Vector2] = [limite_sup_esq.global_position, limite_inf_dir.global_position]
	LevelManager.ChangeTilemapsBounds(limites)


func _on_log_consultado(_branch: String) -> void:
	EstadoRetorno.marcar("log_visto")
	notificar()


func _on_repositorio_mudou() -> void:
	notificar()


## Reavalia a jornada, atualiza o mundo e avisa os filhos. Também é chamada pelas alavancas e altares.
func notificar() -> void:
	EstadoRetorno.avancar()
	_atualizar_mundo()
	mudou.emit()
	for marco in MARCOS:
		if EstadoRetorno.flag(marco) and not _marcos_avisados.get(marco, false):
			_marcos_avisados[marco] = true
			evento.emit(marco)
			if marco == "hard_ok":
				_final_pendente = true
				_tentar_final()


func _atualizar_mundo() -> void:
	porta_inspecao.definir_aberta(EstadoRetorno.flag("inspecao_ok"))
	porta_camara.definir_aberta(EstadoRetorno.flag("z2_ok"))
	if EstadoRetorno.flag("hard_ok") and portal.locked:
		portal.unlock()


func _on_portal_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[Fase 6] CONDIÇÃO DE VITÓRIA ATINGIDA!")
	victory_screen.mostrar()


func _on_proxima_fase_pressed() -> void:
	# Sai pelo portal: o FaseManager limpa o temporário e abre a entrada da fase seguinte.
	FaseManager.concluir_fase_e_avancar()

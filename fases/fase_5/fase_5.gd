extends Node2D
## Fase 5 — Tutorial: "Linhas Cruzadas" (merge com conflito).
##
## Uma sala só. Uma parede de glitch fecha a passagem para o portal. Para derrubá-la, o jogador
## faz `git merge ajuste`, que PARA com um conflito em `selo.runa`; lê o conflito (`git diff`),
## o resolve no mundo (pedestais: a sua versão, a deles ou as duas), marca com `git add` e
## fecha com `git commit`. `git merge --abort` desfaz a tentativa a qualquer momento.
##
## O GameState não conhece conflitos nem conteúdo de arquivos, então o mini-merge vive no
## ModeloConflito (ver modelo_conflito.gd). Esta cena só reage a ele: parede, portal e vitória.
## A IA é a da Fase 1 (TutoraFase1), com o roteiro desta fase (TutoraConflito).
##
## Observação: a cena ainda não está na sequência do FaseManager (a Fase 4 está em standby);
## abra-a direto (F6) para jogar.

@onready var modelo: ModeloConflito = $ModeloConflito
@onready var parede: PortaMural = $ParedeGlitch
@onready var portal: ExitArea = $PortalSaida
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var limite_sup_esq: Marker2D = $Limites/SupEsq
@onready var limite_inf_dir: Marker2D = $Limites/InfDir

var fase_concluida: bool = false


func _ready() -> void:
	GameState.git_inicializado = true
	_configurar_camera()

	var tutora := TutoraConflito.new()
	add_child(tutora)

	modelo.mudou.connect(_atualizar_mundo)
	portal.unlocked_entered.connect(_on_portal_unlocked_entered)
	victory_screen.proxima_fase_pressed.connect(_on_proxima_fase_pressed)
	_atualizar_mundo()


func _configurar_camera() -> void:
	var limites: Array[Vector2] = [limite_sup_esq.global_position, limite_inf_dir.global_position]
	LevelManager.ChangeTilemapsBounds(limites)


func _atualizar_mundo() -> void:
	var concluido := modelo.estado() == ModeloConflito.CONCLUIDO
	parede.definir_aberta(concluido)
	if concluido and portal.locked:
		portal.unlock()


func _on_portal_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[Fase 5] CONDIÇÃO DE VITÓRIA ATINGIDA!")
	victory_screen.mostrar()


func _on_proxima_fase_pressed() -> void:
	# Sai pelo portal: o FaseManager limpa o temporário e abre a entrada da fase seguinte.
	FaseManager.concluir_fase_e_avancar()

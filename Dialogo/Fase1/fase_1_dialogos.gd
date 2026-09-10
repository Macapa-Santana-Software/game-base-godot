extends CanvasLayer

# Usamos caminhos flexíveis e checagem de segurança para não travar o jogo se sumirem
var panel: Panel
var text_label: RichTextLabel
var text_timer: Timer

@export var velocidade_normal: float = 0.03
@export var velocidade_rapida: float = 0.005

var falas_fase_1: Array[String] = [
	"🤖 [color=#51CF66][IA]:[/color] Bip... bop... Conexão estabelecida!",
	#"🤖 [color=#51CF66][IA]:[/color] Alguém aí? Ah, oi, Walker! Sou a IA assistente deste fragmento... ou o que sobrou de mim.",
	#"🤖 [color=#51CF66][IA]:[/color] O sistema central entrou em colapso total. Tá uma bagunça completa por aqui.",
	#"🤖 [color=#51CF66][IA]:[/color] Eu vi alguns pedaços de código importantes jogados pelo chão da sala (`main.gd` e `player.gd`).",
	#"🤖 [color=#51CF66][IA]:[/color] Pegue eles no chão do mapa e depois interaja com o Terminal Central para começarmos a arrumar isso!"
]

var indice_atual: int = 0
var texto_completo: bool = false

func _ready() -> void:
	print("[SISTEMA] Script 'fase_1_dialogos.gd' FOI CARREGADO com sucesso!")
	
	# Configuração do modo de processamento global da UI
	process_mode = PROCESS_MODE_ALWAYS
	
	# Vinculação segura dos nós para descobrir se o Claude Code mudou os nomes deles
	panel = find_child("Panel", true, false) as Panel
	text_label = find_child("RichTextLabel", true, false) as RichTextLabel
	text_timer = find_child("TimerTexto", true, false)
	
	# Se algum nó estiver faltando, o jogo não vai mais travar em silêncio! Ele vai gritar no log:
	if not panel:
		print("[ERRO CRÍTICO] O nó 'Panel' não foi encontrado na CenaFase1!")
		return
	if not text_label:
		print("[ERRO CRÍTICO] O nó 'RichTextLabel' não foi encontrado dentro do Panel!")
		return
	if not text_timer:
		# Se ele não achou com o nome 'TimerTexto', vamos tentar criar um por código para salvar a cena!
		print("[AVISO] Nó 'TimerTexto' não encontrado. Criando um via código...")
		text_timer = Timer.new()
		panel.add_child(text_timer)
	
	# Configurações iniciais seguras
	panel.hide()
	text_timer.process_mode = PROCESS_MODE_ALWAYS
	text_timer.one_shot = true # Evita bugs de loop infinito no Godot 4
	if not text_timer.timeout.is_connected(_on_text_timer_timeout):
		text_timer.timeout.connect(_on_text_timer_timeout)
	
	print("[IA FASE 1]: Iniciando contagem regressiva de 3 segundos...")
	var start_timer = Timer.new()
	start_timer.wait_time = 3.0
	start_timer.one_shot = true
	start_timer.process_mode = PROCESS_MODE_PAUSABLE # Trava se o player pausar o jogo antes
	start_timer.timeout.connect(_on_start_dialog_timeout)
	add_child(start_timer)
	start_timer.start()

func _on_start_dialog_timeout() -> void:
	print("[IA FASE 1]: 3 segundos se passaram! Chamando iniciar_dialogo()...")
	iniciar_dialogo()

func iniciar_dialogo() -> void:
	indice_atual = 0
	panel.show()
	get_tree().paused = true # Congela o resto do jogo
	exibir_linha()

func exibir_linha() -> void:
	texto_completo = false
	text_timer.stop() # Para o timer anterior por segurança
	text_timer.wait_time = velocidade_normal
	text_label.text = falas_fase_1[indice_atual]
	text_label.visible_characters = 0
	text_timer.start()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and panel and panel.visible:
		get_viewport().set_input_as_handled()
		if not texto_completo:
			text_timer.wait_time = velocidade_rapida
		else:
			proxima_linha()

func proxima_linha() -> void:
	indice_atual += 1
	if indice_atual < falas_fase_1.size():
		exibir_linha()
	else:
		finalizar_dialogo()

func finalizar_dialogo() -> void:
	print("[IA FASE 1]: Diálogo concluído! Despausando o jogo.")
	panel.hide()
	get_tree().paused = false # Devolve o controle ao jogador

func _on_text_timer_timeout() -> void:
	if text_label.visible_characters < text_label.text.length():
		text_label.visible_characters += 1
		text_timer.start() # Reinicia o timer para a próxima letra de forma limpa
	else:
		texto_completo = true

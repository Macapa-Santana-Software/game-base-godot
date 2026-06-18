extends Control

# Sinal emitido quando todo o diálogo terminar
signal dialogo_finalizado

@onready var text_label: RichTextLabel = $Panel/MarginContainer/RichTextLabel
@onready var timer: Timer = $Panel/Timer # Se ele estiver dentro do Panel

@export var velocidade_normal: float = 0.03
@export var velocidade_rapida: float = 0.005 # Velocidade ao segurar/apertar Enter

var falas: Array[String] = []
var indice_atual: int = 0
var texto_completo: bool = false

func _ready() -> void:
	# CORREÇÃO NO GODOT 4: O modo correto de atribuição direta é PROCESS_MODE_ALWAYS
	process_mode = PROCESS_MODE_ALWAYS
	
	if timer:
		timer.process_mode = PROCESS_MODE_ALWAYS
		if not timer.timeout.is_connected(_on_timer_timeout):
			timer.timeout.connect(_on_timer_timeout)
	else:
		print("[ERRO CAIXA DIALOGO]: Nó 'Timer' não foi encontrado em $Panel/Timer")
		
	hide() # Começa escondida e invisível


# Função principal: chame isso para iniciar um diálogo de qualquer lugar do jogo
func iniciar_dialogo(novas_falas: Array[String]) -> void:
	if novas_falas.is_empty():
		print("[AVISO CAIXA DIALOGO]: Lista de falas vazia.")
		return
		
	falas = novas_falas
	indice_atual = 0
	show() # Mostra a caixinha
	get_tree().paused = true # Pausa o jogo (congelando física e player)
	exibir_linha()


func exibir_linha() -> void:
	texto_completo = false
	timer.wait_time = velocidade_normal
	text_label.text = falas[indice_atual]
	text_label.visible_characters = 0
	timer.start()
	

func _input(event: InputEvent) -> void:
	# "ui_accept" é o Enter ou Espaço
	if event.is_action_pressed("ui_accept") and visible:
		get_viewport().set_input_as_handled() # Consome o input para o player não atacar atrás do diálogo
		
		if not texto_completo:
			# Se o texto ainda está sendo digitado, acelera
			timer.wait_time = velocidade_rapida
		else:
			# Se o texto já terminou, passa para o próximo
			proxima_linha()


func proxima_linha() -> void:
	indice_atual += 1
	if indice_atual < falas.size():
		exibir_linha()
	else:
		finalizar()


func finalizar() -> void:
	hide() # Esconde a caixinha
	get_tree().paused = false # Despausa o mundo do jogo
	dialogo_finalizado.emit() # Avisa que acabou


func _on_timer_timeout() -> void:
	if text_label.visible_characters < text_label.text.length():
		text_label.visible_characters += 1
		timer.start()
	else:
		texto_completo = true
		timer.stop()

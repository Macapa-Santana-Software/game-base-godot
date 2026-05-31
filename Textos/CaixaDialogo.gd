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
	timer.timeout.connect(_on_timer_timeout)
	hide() # Começa escondida e invisível

# Função principal: chame isso para iniciar um diálogo de qualquer lugar do jogo
func iniciar_dialogo(novas_falas: Array[String]) -> void:
	falas = novas_falas
	indice_atual = 0
	show() # Mostra a caixinha
	exibir_linha()

func exibir_linha() -> void:
	texto_completo = false
	timer.wait_time = velocidade_normal # <- Corrigido aqui (com 'e' no final)
	text_label.text = falas[indice_atual]
	text_label.visible_characters = 0
	timer.start()
	
func _input(event: InputEvent) -> void:
	# "ui_accept" é o Enter, Espaço ou botão de confirmação do controle por padrão
	if event.is_action_pressed("ui_accept") and visible:
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
	dialogo_finalizado.emit() # Avisa que acabou

func _on_timer_timeout() -> void:
	if text_label.visible_characters < text_label.text.length():
		text_label.visible_characters += 1
		timer.start()
	else:
		texto_completo = true
		timer.stop()

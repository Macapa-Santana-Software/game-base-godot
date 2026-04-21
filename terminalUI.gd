extends Control

@onready var historico = $ColorRect/RichTextLabel
@onready var campo_texto = $ColorRect/LineEdit

signal comando_enviado(comando, args)

func _ready():
	hide() # Esconde o terminal ao iniciar
	campo_texto.text_submitted.connect(_ao_digitar)

func abrir():
	show()
	campo_texto.grab_focus() # Coloca o cursor no campo
	get_tree().paused = true # Pausa o jogo

func fechar():
	hide()
	get_tree().paused = false # Despausa o jogo

func _ao_digitar(texto):
	if texto.strip_edges() == "": return
	
	historico.append_text("\n> " + texto)
	var partes = texto.split(" ", false)
	
	if partes.size() > 0 and partes[0] == "git":
		var cmd = partes[1] if partes.size() > 1 else ""
		var args = partes.slice(2)
		comando_enviado.emit(cmd, args)
	else:
		historico.append_text("\nErro: Use comandos que começam com 'git'")
	
	campo_texto.clear() # Limpa o campo
	
	# Se digitar 'exit', fecha o terminal
	if texto == "exit": fechar()

func escrever_no_terminal(mensagem):
	historico.append_text("\n" + mensagem)

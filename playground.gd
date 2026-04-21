extends Node2D

@onready var terminal = $CanvasLayer/TerminalUI

func _ready():
	# Conecta o sinal do terminal com a lógica da fase
	terminal.comando_enviado.connect(_processar_git)

func _processar_git(comando, args):
	if comando == "init":
		terminal.escrever_no_terminal("Repositório inicializado em /fase1/")
	elif comando == "add":
		terminal.escrever_no_terminal("Arquivos adicionados ao Stage!")
	elif comando == "commit":
		terminal.escrever_no_terminal("Commit realizado: 'primeira versão'. Porta aberta!")
		# Aqui você colocaria o código para sumir com a parede da saída
	else:
		terminal.escrever_no_terminal("Comando desconhecido ou não disponível nesta fase.")

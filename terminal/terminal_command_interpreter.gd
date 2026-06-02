class_name TerminalCommandInterpreter extends Node

var _handlers: Dictionary = {}
var _foco_fase: Array[String] = ["init", "add", "commit", "status"]

func _ready() -> void:
	# Carrega os comandos diretamente pelos arquivos, evitando o cache problemático do Godot
	_handlers = {
		"init": GitCommand_Init.new(),
		"add": GitCommand_Add.new(),
		"commit": GitCommand_Commit.new(),
		"status": GitCommand_Status.new()
	}

func execute_command(raw_input: String) -> String:
	var parsed := _parse(raw_input)
	if not parsed.get("ok", false):
		return "[color=#FF6B6B]Erro: Comando inválido. Os comandos devem começar com 'git'.[/color]"

	var command_name: String = parsed.get("command", "")
	
	if not _handlers.has(command_name):
		return "[color=#FFCC00]git: comando '%s' não disponível nesta fase.[/color]" % command_name

	var args: Array[String] = parsed.get("args", [])
	var handler = _handlers[command_name]
	return handler.execute(args, raw_input)

func _parse(raw_input: String) -> Dictionary:
	var input := raw_input.strip_edges()
	if input.is_empty(): return {"ok": false}
	
	var tokens := _tokenize(input)
	if tokens.is_empty() or tokens[0] != "git" or tokens.size() < 2: 
		return {"ok": false}
		
	return {
		"ok": true,
		"command": tokens[1],
		"args": tokens.slice(2)
	}

func _tokenize(text: String) -> Array[String]:
	var tokens: Array[String] = []
	var current := ""
	var in_quotes := false
	
	for char in text:
		if char == "\"":
			in_quotes = not in_quotes
			continue
		if char == " " and not in_quotes:
			if not current.is_empty():
				tokens.append(current)
				current = ""
		else:
			current += char
			
	if not current.is_empty(): 
		tokens.append(current)
		
	return tokens

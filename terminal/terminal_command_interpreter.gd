class_name TerminalCommandInterpreter extends Node

# Registro Geral: Todos os comandos que existem no seu jogo inteiro ficam aqui.
# Como você usou 'class_name', a Godot já reconhece essas classes automaticamente!
var _todos_os_comandos: Dictionary = {
	"init": GitCommand_Init,
	"add": GitCommand_Add,
	"commit": GitCommand_Commit,
	"status": GitCommand_Status
}

# Guarda apenas os comandos instanciados e liberados para a fase atual
var _handlers: Dictionary = {}

# A interface chama essa função passando o que está liberado
func configurar_comandos(comandos_permitidos: Array[String]) -> void:
	_handlers.clear()
	
	for cmd in comandos_permitidos:
		if _todos_os_comandos.has(cmd):
			# Cria a instância do comando em tempo de execução
			var classe_do_comando = _todos_os_comandos[cmd]
			_handlers[cmd] = classe_do_comando.new()
		else:
			push_error("O comando '" + cmd + "' não foi registrado no dicionário _todos_os_comandos.")

func execute_command(raw_input: String) -> String:
	var parsed := _parse(raw_input)
	if not parsed.get("ok", false):
		return "[color=#FF6B6B]Erro: Comando inválido. Os comandos devem começar com 'git'.[/color]"

	var command_name: String = parsed.get("command", "")

	# Se o comando não estiver na array da fase, ele barra aqui!
	if not _handlers.has(command_name):
		return "[color=#FFCC00]git: comando '%s' não disponível ou bloqueado nesta fase.[/color]" % command_name

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

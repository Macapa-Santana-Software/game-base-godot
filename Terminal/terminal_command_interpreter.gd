extends Node
class_name TerminalCommandInterpreter

var _handlers: Dictionary = {}


func _ready() -> void:
	_register_handlers()


func execute_command(raw_input: String) -> String:
	var parsed := _parse(raw_input)
	if not parsed.get("ok", false):
		return parsed.get("message", "Comando inválido.")

	var command_name: String = parsed.get("command", "")
	if not _handlers.has(command_name):
		return "Comando git desconhecido: %s" % command_name

	var context := {
		"raw_input": raw_input,
		"args": parsed.get("args", [])
	}
	var handler: GitCommand = _handlers[command_name]
	return handler.execute(context)


func _register_handlers() -> void:
	_handlers = {
		"add": GitAddCommand.new(),
		"commit": GitCommitCommand.new(),
		"log": GitLogCommand.new(),
		"checkout": GitCheckoutCommand.new(),
		"branch": GitBranchCommand.new(),
		"merge": GitMergeCommand.new(),
		"push": GitPushCommand.new(),
		"pull": GitPullCommand.new(),
		"status": GitStatusCommand.new()
	}


func _parse(raw_input: String) -> Dictionary:
	var input := raw_input.strip_edges()
	if input.is_empty():
		return {"ok": false, "message": ""}

	var tokens := _tokenize(input)
	if tokens.is_empty():
		return {"ok": false, "message": "Comando vazio."}
	if tokens[0] != "git":
		return {"ok": false, "message": "Erro: use comandos iniciando com 'git'."}
	if tokens.size() < 2:
		return {"ok": false, "message": "Uso: git <comando> [argumentos]"}

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

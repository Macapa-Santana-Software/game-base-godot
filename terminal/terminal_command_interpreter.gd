class_name TerminalCommandInterpreter extends Node

# Registro Geral: Todos os comandos que existem no seu jogo inteiro ficam aqui.
# Como você usou 'class_name', a Godot já reconhece essas classes automaticamente!
var _todos_os_comandos: Dictionary = {
	"init": GitCommand_Init,
	"add": GitCommand_Add,
	"commit": GitCommand_Commit,
	"status": GitCommand_Status,
	"help": GitCommand_Help
}

# Comandos reais do Git que ainda não foram implementados no jogo
# (para não chamá-los de "inexistentes" quando o jogador tentar usá-los).
const COMANDOS_GIT_CONHECIDOS: Array[String] = [
	"log", "diff", "branch", "checkout", "switch", "merge", "rebase", "clone",
	"fetch", "pull", "push", "remote", "reset", "restore", "rm", "mv", "stash",
	"tag", "config", "show", "revert", "cherry-pick"
]

# Máximo de edições para ainda sugerir "Você quis dizer ...?"
const DISTANCIA_MAXIMA_SUGESTAO := 2

# Guarda apenas os comandos instanciados e liberados para a fase atual
var _handlers: Dictionary = {}

# A interface chama essa função passando o que está liberado
func configurar_comandos(comandos_permitidos: Array[String]) -> void:
	_handlers.clear()
	
	for cmd in comandos_permitidos:
		if _todos_os_comandos.has(cmd):
			# Cria a instância do comando em tempo de execução
			var classe_do_comando = _todos_os_comandos[cmd]
			var handler = classe_do_comando.new()
			if handler is GitCommand_Help:
				handler.comandos_da_fase = comandos_permitidos
			_handlers[cmd] = handler
		else:
			push_error("O comando '" + cmd + "' não foi registrado no dicionário _todos_os_comandos.")

func execute_command(raw_input: String) -> String:
	var parsed := _parse(raw_input)
	if not parsed.get("ok", false):
		return GameState.registrar_falha("", GameState.FALHA_NAO_E_GIT,
			"[color=#FF6B6B]Erro: Comando inválido. Os comandos devem começar com 'git'.[/color]")

	var command_name: String = parsed.get("command", "")

	# Se o comando não estiver na array da fase, ele barra aqui!
	if not _handlers.has(command_name):
		return _mensagem_comando_indisponivel(command_name)

	# Liberação progressiva: o comando é da fase, mas a IA ainda não o apresentou
	if not GameState.comando_liberado(command_name):
		return GameState.registrar_falha(command_name, GameState.FALHA_COMANDO_BLOQUEADO,
			"[color=#FFCC00]git: o comando '%s' ainda não foi apresentado. Vamos um de cada vez; siga o passo da IA.[/color]" % command_name)

	var args: Array[String] = parsed.get("args", [])
	var handler = _handlers[command_name]
	return handler.execute(args, raw_input)

# Distingue "comando que existe no Git mas ainda não foi liberado" de "comando que não existe (typo)"
func _mensagem_comando_indisponivel(nome: String) -> String:
	if _todos_os_comandos.has(nome) or nome in COMANDOS_GIT_CONHECIDOS:
		return GameState.registrar_falha(nome, GameState.FALHA_COMANDO_INDISPONIVEL,
			"[color=#FFCC00]git: o comando '%s' existe, mas ainda não está disponível nesta fase.[/color]" % nome)

	GameState.registrar_falha(nome, GameState.FALHA_COMANDO_INEXISTENTE)
	var mensagem := "[color=#FF6B6B]git: '%s' não é um comando git.[/color]" % nome.replace("[", "[lb]")
	var sugestao := _sugerir_comando(nome)
	if not sugestao.is_empty():
		mensagem += "\n[color=#FFCC00]Você quis dizer '%s'?[/color]" % sugestao
	return mensagem

# Sugere, entre os comandos liberados na fase, o mais parecido com o digitado
func _sugerir_comando(nome: String) -> String:
	var melhor := ""
	var menor_distancia := DISTANCIA_MAXIMA_SUGESTAO + 1
	for candidato in _handlers.keys():
		var d := _distancia_edicao(nome, candidato)
		if d < menor_distancia:
			menor_distancia = d
			melhor = candidato
	return melhor

# Distância de Levenshtein (quantas edições separam duas palavras)
func _distancia_edicao(a: String, b: String) -> int:
	var anterior: Array[int] = []
	for j in range(b.length() + 1):
		anterior.append(j)
	for i in range(1, a.length() + 1):
		var atual: Array[int] = [i]
		for j in range(1, b.length() + 1):
			var custo := 0 if a[i - 1] == b[j - 1] else 1
			atual.append(mini(mini(anterior[j] + 1, atual[j - 1] + 1), anterior[j - 1] + custo))
		anterior = atual
	return anterior[b.length()]

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

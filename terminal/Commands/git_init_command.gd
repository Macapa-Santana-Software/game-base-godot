extends "res://Terminal/Commands/git_command.gd"

func execute(args: Array[String], _raw_input: String) -> String:
	return GameState.inicializar_repositorio()

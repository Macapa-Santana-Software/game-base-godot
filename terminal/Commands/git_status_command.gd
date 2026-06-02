extends "res://Terminal/Commands/git_command.gd"

func execute(_args: Array[String], _raw_input: String) -> String:
	return GameState.obter_status()

class_name GitCommand_Status extends GitCommand

func execute(_args: Array[String], _raw_input: String) -> String:
	return GameState.obter_status()

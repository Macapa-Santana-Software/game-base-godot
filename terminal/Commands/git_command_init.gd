class_name GitCommand_Init extends GitCommand

func execute(args: Array[String], _raw_input: String) -> String:
	return GameState.inicializar_repositorio()

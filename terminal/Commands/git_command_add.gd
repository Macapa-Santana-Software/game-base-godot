class_name GitCommand_Add extends GitCommand

func execute(args: Array[String], _raw_input: String) -> String:
	if args.is_empty():
		return "[color=#FF6B6B]Erro: Uso correto: git add <nome_do_arquivo>[/color]"
	return GameState.adicionar_ao_stage(args[0])

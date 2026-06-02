class_name GitCommand_Commit extends GitCommand

func execute(args: Array[String], _raw_input: String) -> String:
	# Como o seu tokenizador separa por espaços, se o comando for: git commit -m "minha mensagem"
	# args[0] será "-m" e args[1] será "minha mensagem"
	if args.size() < 2 or args[0] != "-m":
		return "[color=#FF6B6B]Erro: Uso correto: git commit -m \"sua mensagem aqui\"[/color]"
	return GameState.criar_commit(args[1])

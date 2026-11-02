class_name GitCommand_Commit extends GitCommand

func execute(args: Array[String], _raw_input: String) -> String:
	# O tokenizador separa por espaços e respeita aspas duplas. Para: git commit -m "minha mensagem"
	# args[0] será "-m" e args[1] será "minha mensagem"
	if args.size() < 2 or args[0] != "-m":
		return GameState.registrar_falha("commit", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git commit -m \"sua mensagem aqui\"[/color]")
	# Mensagem com espaços sem aspas viraria vários argumentos: erro em vez de truncar em silêncio
	if args.size() > 2:
		return GameState.registrar_falha("commit", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: argumentos demais. A mensagem do commit deve estar entre aspas duplas: git commit -m \"sua mensagem aqui\"[/color]")
	return GameState.criar_commit(args[1])

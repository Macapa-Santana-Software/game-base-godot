class_name GitCommand_Add extends GitCommand

func execute(args: Array[String], _raw_input: String) -> String:
	if args.is_empty():
		return GameState.registrar_falha("add", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git add <arquivo> [<arquivo> ...]  ou  git add .[/color]")

	# git add . (ou -A / --all): tudo que ainda não está rastreado
	if "." in args or "-A" in args or "--all" in args:
		return GameState.adicionar_todos_ao_stage()

	# Sem repositório, uma única mensagem basta (evita repetir o mesmo erro por arquivo)
	if not GameState.git_inicializado:
		return GameState.adicionar_ao_stage(args[0])

	var respostas: Array[String] = []
	for arquivo in args:
		respostas.append(GameState.adicionar_ao_stage(arquivo))
	return "\n".join(respostas)

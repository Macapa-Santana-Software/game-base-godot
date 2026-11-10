class_name GitCommand_Switch extends GitCommand
## `git switch <branch>`: troca a branch ativa (HEAD). O mapa e o Atlas reagem sozinhos.

func execute(args: Array[String], _raw_input: String) -> String:
	if args.size() != 1:
		return GameState.registrar_falha("switch", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git switch <branch>[/color]")
	return GameState.trocar_branch(args[0])["mensagem"]

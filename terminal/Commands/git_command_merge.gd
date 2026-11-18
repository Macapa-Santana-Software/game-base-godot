class_name GitCommand_Merge extends GitCommand
## `git merge <branch>`: integra <branch> na branch ATIVA (o destino).

func execute(args: Array[String], _raw_input: String) -> String:
	# Fase 5: o merge com conflito acontece no modelo da fase (ModeloConflito).
	var conflito := ModeloConflito.ativo()
	if conflito != null:
		return conflito.mesclar(args)
	if args.size() != 1:
		return GameState.registrar_falha("merge", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git merge <branch>[/color]")
	return GameState.mesclar(args[0])["mensagem"]

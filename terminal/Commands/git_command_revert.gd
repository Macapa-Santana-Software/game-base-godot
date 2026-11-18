class_name GitCommand_Revert extends GitCommand
## `git revert <commit>`: cria um commit NOVO que desfaz o efeito de <commit>, sem apagar a
## história (ao contrário do reset). Aceita HEAD, HEAD~N, branch ou o id do commit.

func execute(args: Array[String], _raw_input: String) -> String:
	var alvos: Array[String] = []
	for arg in args:
		if arg == "--no-edit":
			continue  # o jogo nunca abre editor de mensagem
		if arg.begins_with("-"):
			return GameState.registrar_falha("revert", GameState.FALHA_USO_INCORRETO,
				"[color=#FF6B6B]Erro: opção '%s' não reconhecida. Uso: git revert <commit>  (ex.: git revert HEAD)[/color]" % arg.replace("[", "[lb]"))
		alvos.append(arg)
	if alvos.size() != 1:
		return GameState.registrar_falha("revert", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git revert <commit>  (ex.: git revert HEAD)[/color]")
	return GameState.reverter(alvos[0])["mensagem"]

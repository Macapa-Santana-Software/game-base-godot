class_name GitCommand_Stash extends GitCommand
## `git stash`: guarda o trabalho em andamento (caixa + arquivos soltos) e limpa a pasta.
##   git stash / git stash push [-m "msg"]   guarda
##   git stash pop / git stash apply          devolve o último trabalho guardado
##   git stash list                           lista o que está guardado

func execute(args: Array[String], _raw_input: String) -> String:
	var sub := "push" if args.is_empty() else args[0]
	match sub:
		"push":
			var mensagem := ""
			if args.size() >= 3 and args[1] == "-m":
				mensagem = args[2]
			elif args.size() > 1:
				return _uso()
			return GameState.guardar_stash(mensagem)["mensagem"]
		"pop", "apply":
			if args.size() > 1:
				return _uso()
			return GameState.aplicar_stash()["mensagem"]
		"list":
			if GameState.stash_pilha.is_empty():
				return "[color=#8AA0B8]O stash está vazio.[/color]"
			var linhas: Array[String] = []
			for i in range(GameState.stash_pilha.size() - 1, -1, -1):
				var item: Dictionary = GameState.stash_pilha[i]
				linhas.append("stash@{%d}: %s (%s)" % [GameState.stash_pilha.size() - 1 - i,
					str(item["mensagem"]).replace("[", "[lb]"), ", ".join(item["staging"] + item["soltos"])])
			return "\n".join(linhas)
	return _uso()


func _uso() -> String:
	return GameState.registrar_falha("stash", GameState.FALHA_USO_INCORRETO,
		"[color=#FF6B6B]Erro: Uso correto: git stash  |  git stash pop  |  git stash list[/color]")

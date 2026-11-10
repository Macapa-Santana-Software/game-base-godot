class_name GitCommand_Log extends GitCommand
## `git log` [--oneline]: histórico da branch ativa, do mais recente ao mais antigo.
## A lógica (e o aviso `log_consultado`) está no GameState.

func execute(args: Array[String], _raw_input: String) -> String:
	var resumido := false
	for arg in args:
		if arg == "--oneline":
			resumido = true
		else:
			return GameState.registrar_falha("log", GameState.FALHA_USO_INCORRETO,
				"[color=#FF6B6B]Erro: Uso correto: git log [--oneline][/color]")
	return GameState.formatar_log(resumido)["mensagem"]

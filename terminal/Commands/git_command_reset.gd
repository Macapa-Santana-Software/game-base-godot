class_name GitCommand_Reset extends GitCommand
## `git reset [--soft|--mixed|--hard] [<commit>]`: move o HEAD da branch ativa para <commit>
## (padrão: HEAD, no modo --mixed). Aceita HEAD~N, branch ou o id do commit.
##   --soft   só volta o ponteiro; o trabalho dos commits descartados fica na caixa (staging)
##   --mixed  volta e esvazia a caixa; o trabalho fica solto na pasta
##   --hard   volta e DESTRÓI o trabalho dos commits descartados

func execute(args: Array[String], _raw_input: String) -> String:
	var modo := "mixed"
	var alvo := ""
	for arg in args:
		if arg in ["--soft", "--mixed", "--hard"]:
			modo = arg.trim_prefix("--")
		elif arg.begins_with("-"):
			return GameState.registrar_falha("reset", GameState.FALHA_USO_INCORRETO,
				"[color=#FF6B6B]Erro: opção '%s' não reconhecida. Uso: git reset [--soft|--mixed|--hard] <commit>[/color]" % arg.replace("[", "[lb]"))
		elif alvo.is_empty():
			alvo = arg
		else:
			return GameState.registrar_falha("reset", GameState.FALHA_USO_INCORRETO,
				"[color=#FF6B6B]Erro: informe um único commit. Uso: git reset [--soft|--mixed|--hard] <commit>[/color]")
	return GameState.resetar_para(alvo if not alvo.is_empty() else "HEAD", modo)["mensagem"]

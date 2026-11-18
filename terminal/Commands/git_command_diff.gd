class_name GitCommand_Diff extends GitCommand
## `git diff [--staged] [<arquivo>]`: mostra o que MUDOU (só lê, não altera nada).
## Hoje só existe onde há um mural de runas (Fase 3): o conteúdo dos arquivos vive em
## ModeloMural, porque o GameState ainda não guarda conteúdo.

func execute(args: Array[String], _raw_input: String) -> String:
	var mural := ModeloMural.ativo()
	if mural == null:
		return GameState.registrar_falha("diff", GameState.FALHA_COMANDO_INDISPONIVEL,
			"[color=#FFCC00]git: o 'diff' ainda não tem o que comparar aqui.[/color]")
	return mural.texto_diff(args)

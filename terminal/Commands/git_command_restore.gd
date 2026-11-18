class_name GitCommand_Restore extends GitCommand
## `git restore <arquivo>` descarta a mudança da Oficina (não volta!);
## `git restore --staged <arquivo>` tira do Palco (a mudança continua na Oficina).
## Hoje só existe onde há um mural de runas (Fase 3); ver ModeloMural.

func execute(args: Array[String], _raw_input: String) -> String:
	var mural := ModeloMural.ativo()
	if mural == null:
		return GameState.registrar_falha("restore", GameState.FALHA_COMANDO_INDISPONIVEL,
			"[color=#FFCC00]git: o 'restore' ainda não tem o que restaurar aqui.[/color]")
	return mural.restaurar(args)

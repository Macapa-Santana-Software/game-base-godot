class_name GitCommand_Status extends GitCommand

func execute(_args: Array[String], _raw_input: String) -> String:
	# Fase 3: o estado dos arquivos (Oficina / Palco) vem do mural de runas.
	var mural := ModeloMural.ativo()
	if mural != null:
		return mural.texto_status()
	var conflito := ModeloConflito.ativo()
	if conflito != null:
		return conflito.texto_status()
	return GameState.obter_status()

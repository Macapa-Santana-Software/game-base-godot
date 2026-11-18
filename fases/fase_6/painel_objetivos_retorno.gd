class_name PainelObjetivosRetorno extends PainelObjetivosPonte
## Quadro de OBJETIVOS da Fase 6. Reaproveita o visual do quadro da Fase 2 e só troca a lista.
## Cada objetivo é uma flag da fase (EstadoRetorno), então nunca perde o progresso.


func _ready() -> void:
	layer = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()

	_adicionar("Ler o histórico (git log)", func() -> bool: return EstadoRetorno.flag("log_visto"))
	_adicionar("Desfazer o commit ruim (git revert)", func() -> bool: return EstadoRetorno.flag("z1_ok"))
	_adicionar("Guardar o trabalho (git stash)", func() -> bool: return EstadoRetorno.flag("stash_usado"))
	_adicionar("Puxar a alavanca (ENTER)", func() -> bool: return EstadoRetorno.flag("emergencia"))
	_adicionar("Recuperar o trabalho (stash pop)", func() -> bool: return EstadoRetorno.flag("z2_ok"))
	_adicionar("Voltar mantendo o trabalho (reset --soft)", func() -> bool: return EstadoRetorno.flag("soft_ok"))
	_adicionar("Registrar a planta (git commit)", func() -> bool: return EstadoRetorno.flag("commit_ok"))
	_adicionar("Descartar o experimento (reset --hard)", func() -> bool: return EstadoRetorno.flag("hard_ok"))

	EstadoRetorno.conectar_mudancas(_agendar)
	_agendar()

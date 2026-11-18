class_name PainelObjetivosMural extends PainelObjetivosPonte
## Quadro de OBJETIVOS da Fase 3. Reaproveita todo o visual do quadro da Fase 2 e só
## troca a lista. Cada objetivo é lido do ModeloMural, então nunca perde o progresso.


func _ready() -> void:
	layer = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()

	var m := ModeloMural.ativo()
	if m == null:
		return
	_adicionar("Ver o estrago (git status)", func() -> bool: return m.flag("status_visto"))
	_adicionar("Ver o que mudou (git diff)", func() -> bool: return m.flag("diff_visto"))
	_adicionar("Descartar a corrupção e salvar o mar (git restore)", func() -> bool: return m.zona_2_ok())
	_adicionar("Ver o Palco (git status)", func() -> bool: return m.flag("status_palco"))
	_adicionar("Tirar a eclipse do Palco (restore --staged)", func() -> bool: return m.flag("restore_staged_feito") and m.zona_2_ok())
	_adicionar("Descartar a eclipse e manter a aurora", func() -> bool: return m.zona_3_ok())

	m.mudou.connect(_agendar)
	_agendar()

class_name PainelObjetivosConflito extends PainelObjetivosPonte
## Quadro de OBJETIVOS da Fase 5. Reaproveita o visual do quadro da Fase 2 e só troca a
## lista. Cada objetivo é lido do ModeloConflito, então nunca perde o progresso.


func _ready() -> void:
	layer = 0
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()

	var m := ModeloConflito.ativo()
	if m == null:
		return
	_adicionar("Olhar o terreno (git status)", func() -> bool: return m.flag("status_visto"))
	_adicionar("Juntar a outra linha (git merge ajuste)", func() -> bool: return m.flag("merge_tentado"))
	_adicionar("Ver onde há conflito (git diff)", func() -> bool: return m.flag("diff_conflito"))
	_adicionar("Escolher o lado num pedestal", func() -> bool: return m.flag("escolheu"))
	_adicionar("Marcar como resolvido (git add)", func() -> bool: return m.flag("add_feito"))
	_adicionar("Fechar o merge (git commit)", func() -> bool: return m.estado() == ModeloConflito.CONCLUIDO)

	m.mudou.connect(_agendar)
	_agendar()

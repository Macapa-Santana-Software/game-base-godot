class_name LiberadorComandosFase2 extends Node
## Decide QUAIS comandos Git o terminal oferece em cada momento da Fase 2, a partir de
## fatos reais do repositório (flags derivadas do ProgressoFase2). Não guarda estado
## próprio: recalcula a cada mudança. O terminal só recebe a lista.
##
## Ordem pedagógica:
##   status, log            sempre
##   branch                 depois de consultar o histórico (git log)
##   switch                 depois que vida-alternativa existe
##   add, commit            com vida-alternativa existindo, enquanto se está nela ou
##                          depois que ela já recebeu seu commit (para registrar o de main)
##   merge                  em main, depois que as duas linhas receberam commits próprios

@onready var progresso: ProgressoFase2 = $"../Progresso"


func _ready() -> void:
	progresso.flag_alterada.connect(func(_nome: StringName, _valor: bool) -> void: _atualizar())
	progresso.branch_ativa_mudou.connect(func(_anterior: StringName, _nova: StringName) -> void: _atualizar())
	_atualizar()


func comandos_liberados() -> Array[String]:
	var lista: Array[String] = ["status", "log"]
	if progresso.obter(ProgressoFase2.LOG_CONSULTADO):
		lista.append("branch")
	if progresso.obter(ProgressoFase2.BRANCH_CRIADA):
		lista.append("switch")
		if progresso.obter(ProgressoFase2.NA_VIDA_ALTERNATIVA) or progresso.obter(ProgressoFase2.COMMIT_VIDA):
			lista.append("add")
			lista.append("commit")
	if progresso.branch_ativa() == ProgressoFase2.BRANCH_MAIN \
			and progresso.obter(ProgressoFase2.COMMIT_VIDA) and progresso.obter(ProgressoFase2.COMMIT_MAIN):
		lista.append("merge")
	return lista


func _atualizar() -> void:
	progresso.publicar_comandos(comandos_liberados())

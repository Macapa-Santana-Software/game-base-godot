class_name Area5Registro extends AreaFase2
## Registro Final. Dona do portal de saída da fase.
##
## O portal (ExitArea, da Fase 1, reaproveitado) só é liberado quando:
##   * o registro final foi observado (e ele só pode ser observado depois do merge real e da
##     reflexão no Atlas; ver RegistroFinalFase2), e
##   * o fechamento do Eidolon terminou (ou já tinha terminado antes de um reload). Assim ninguém
##     sai da fase sem ouvi-lo, e a recuperação do EidolonFase2 garante que o fechamento volte
##     depois de uma derrota.
## `REGISTRO_OBSERVADO` é uma observação narrativa, não uma operação Git.

signal saida_alcancada

@onready var saida: ExitArea = $Interacoes/SaidaFase

var _progresso: ProgressoFase2
var _fechamento_concluido: bool = false


func _ready() -> void:
	super()
	saida.unlocked_entered.connect(func() -> void: saida_alcancada.emit())
	_progresso = ProgressoFase2.de(self)
	if _progresso == null:
		return
	var eidolon := get_tree().get_first_node_in_group(EidolonFase2.GRUPO) as EidolonFase2
	# Sem Eidolon (área isolada) não há fechamento a esperar.
	_fechamento_concluido = eidolon == null or EidolonEstado.ja_disse(&"fechamento")
	if eidolon:
		eidolon.fechamento_concluido.connect(_on_fechamento_concluido)
	_progresso.flag_alterada.connect(func(_nome: StringName, _valor: bool) -> void: _tentar_liberar())
	_tentar_liberar()


func _on_fechamento_concluido() -> void:
	_fechamento_concluido = true
	_tentar_liberar()


func _tentar_liberar() -> void:
	if saida.locked and _progresso.obter(ProgressoFase2.REGISTRO_OBSERVADO) and _fechamento_concluido:
		saida.unlock()

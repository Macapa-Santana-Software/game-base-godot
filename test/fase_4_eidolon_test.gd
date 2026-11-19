extends Node
## Teste do Eidolon e da HUD da Fase 4: estado persistido (etapa só avança, evidências sem repetição), fala única do despertar
## (diálogo bloqueante), diálogo que ESPERA o terminal fechar, reinício do zero e os painéis recolhíveis/botão de reiniciar.
## Sai com código 1 se algo falhar.

const CenaFase4 := preload("res://fases/fase_4/fase_4.tscn")

var _falhas: int = 0
var _total: int = 0


func _ok(condicao: bool, descricao: String) -> void:
	_total += 1
	print(("  OK     " if condicao else "  FALHA  ") + descricao)
	if not condicao:
		_falhas += 1


func _frames(n: int = 4) -> void:
	for _i in range(n):
		await get_tree().process_frame


func _ready() -> void:
	var persistia: bool = Diario.persistir
	Diario.persistir = false
	await _testar()
	Diario.persistir = persistia
	GameState.resetar_repositorio()
	print("[TESTE FASE 4 EIDOLON] %d verificações, %d falhas" % [_total, _falhas])
	get_tree().quit(1 if _falhas > 0 else 0)


func _abrir_fase() -> Node:
	GameState.resetar_repositorio()
	var fase := CenaFase4.instantiate()
	add_child(fase)
	return fase


func _testar() -> void:
	print("— Estado do Eidolon —")
	var fase := _abrir_fase()
	await _frames(6)
	_ok(EidolonEstado.etapa() == EidolonEstado.ETAPA_INICIAL, "o arco começa na etapa inicial")
	EidolonEstado.avancar_etapa(EidolonEstado.ETAPA_DUVIDA)
	EidolonEstado.avancar_etapa(EidolonEstado.ETAPA_DESCONFORTO)
	_ok(EidolonEstado.etapa() == EidolonEstado.ETAPA_DUVIDA, "a etapa só avança, nunca volta")
	GameState.restaurar_checkpoint()
	_ok(EidolonEstado.etapa() == EidolonEstado.ETAPA_INICIAL, "reiniciar a fase volta o arco ao começo")
	EidolonEstado.registrar_evidencia(&"frag_m1")
	EidolonEstado.registrar_evidencia(&"frag_m1")
	_ok(EidolonEstado.evidencias().size() == 1, "a mesma evidência não conta duas vezes")
	EidolonEstado.registrar_evidencia(&"frag_v1")
	_ok(EidolonEstado.etapa() >= EidolonEstado.ETAPA_DUVIDA, "duas evidências levam o Eidolon à dúvida")

	print("— HUD da fase —")
	_ok(fase.get_node_or_null("PainelObjetivos") is PainelObjetivosFase4, "painel de Objetivos (recolhível) está na cena")
	_ok(fase.get_node_or_null("PainelConceitos") is PainelConceitosFase4, "painel de Conceitos (recolhível) está na cena")
	_ok(fase.get_node("PauseMenu").reiniciar_button != null, "o menu de pausa tem REINICIAR FASE")
	var aba: Button = fase.get_node("PainelConceitos")._aba
	await get_tree().create_timer(0.4).timeout
	_ok(aba.modulate.a < 0.5, "com o painel de Conceitos recolhido, a aba fica translúcida")
	fase.queue_free()
	await _frames()

	print("— Despertar: diálogo obrigatório, uma vez só —")
	fase = _abrir_fase()
	await _frames(6)
	var eidolon: Node = fase.get_node("Eidolon")
	var caixa: Control = fase.get_node("DialogoEidolon/CaixaDialogo")
	eidolon.solicitar(&"despertar")
	await get_tree().create_timer(1.8).timeout
	_ok(caixa.visible and EidolonEstado.ja_disse(&"despertar"), "o diálogo do despertar abre e fica registrado")
	caixa.finalizar()
	await _frames()
	_ok(not get_tree().paused, "ao terminar, o jogo volta ao normal")
	eidolon.solicitar(&"despertar")
	await get_tree().create_timer(1.8).timeout
	_ok(not caixa.visible, "a fala única não se repete")
	fase.queue_free()
	await _frames()

	print("— Diálogo espera o terminal fechar —")
	fase = _abrir_fase()
	await _frames(6)
	eidolon = fase.get_node("Eidolon")
	caixa = fase.get_node("DialogoEidolon/CaixaDialogo")
	GameState.terminal_aberto.emit()
	await _frames()
	eidolon.solicitar(&"despertar")
	await get_tree().create_timer(2.0).timeout
	_ok(not caixa.visible, "com o terminal aberto, o diálogo não abre")
	GameState.terminal_fechado.emit()
	await get_tree().create_timer(2.5).timeout
	_ok(caixa.visible, "ao fechar o terminal, o diálogo pendente abre")
	caixa.finalizar()
	get_tree().paused = false
	fase.queue_free()
	await _frames()

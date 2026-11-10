extends Node
## Teste de PROGRESSÃO da Fase 2: percorre a jornada inteira pelas operações REAIS do GameState
## (log, branch, switch, coleta, add, commit, merge) e confere, em cada passo, as flags do
## ProgressoFase2, a disponibilidade das zonas de interação e o estado (aberta/fechada) de cada porta.
## Rode a cena (F6) e leia o Output: "OK"/"FALHA" por verificação e um resumo no fim.
## Não usa o terminal nem o debug (N/B): é exatamente o caminho que o jogador deve fazer.

var _fase: Node
var _progresso: ProgressoFase2
var _falhas: int = 0
var _total: int = 0
var _saida: FileAccess

## Além do Output, grava o resultado em %TEMP%/fase2_progressao_teste.txt (útil para ler fora do editor).
const ARQUIVO_SAIDA := "fase2_progressao_teste.txt"


func _log(linha: String) -> void:
	print(linha)
	if _saida:
		_saida.store_line(linha)
		_saida.flush()


func _ready() -> void:
	var pasta := OS.get_environment("TEMP") if OS.get_environment("TEMP") != "" else "/tmp"
	_saida = FileAccess.open(pasta.path_join(ARQUIVO_SAIDA), FileAccess.WRITE)
	GameState.resetar_repositorio()
	_fase = (load("res://fases/fase_2/fase_2.tscn") as PackedScene).instantiate()
	add_child(_fase)
	await get_tree().process_frame
	await get_tree().process_frame
	_progresso = _fase.get_node("Progresso")
	_rodar()
	_log("[TESTE FASE 2] %d verificações, %d falhas" % [_total, _falhas])
	GameState.resetar_repositorio()
	get_tree().quit(1 if _falhas > 0 else 0)


func _porta(caminho: String) -> BarreiraFase2:
	return _fase.get_node(caminho) as BarreiraFase2


func _zona(caminho: String) -> ZonaInteracao:
	return _fase.get_node(caminho) as ZonaInteracao


func _check(nome: String, condicao: bool) -> void:
	_total += 1
	if not condicao:
		_falhas += 1
	_log("%s  %s" % ["OK   " if condicao else "FALHA", nome])


func _flag(nome: StringName) -> bool:
	return _progresso.obter(nome)


func _rodar() -> void:
	var a1 := _porta("Mundo/Area1_Arquivo/Paredes/Barreira_Passagem")
	var limiar_main := _porta("Mundo/Area3_Main/Paredes/Barreira_Limiar")
	var limiar_vida := _porta("Mundo/Area3_Vida/Paredes/Barreira_Limiar")
	var oeste := _porta("Mundo/Area4_Convergencia/Paredes/Barreira_Oeste")
	var leste := _porta("Mundo/Area4_Convergencia/Paredes/Barreira_Leste")
	var norte := _porta("Mundo/Area4_Convergencia/Paredes/Barreira_Norte")
	var selo := _porta("Mundo/Area5_Registro/Paredes/Barreira_Selo")
	var eco_vida := _zona("Mundo/Area3_Vida/Interacoes/Coleta_Eco_Vida")
	var eco_main := _zona("Mundo/Area3_Main/Interacoes/Coleta_Eco_Main")
	var registro := _zona("Mundo/Area5_Registro/Interacoes/Interacao_Registro")

	_log("--- início: main ativa, só o repositório da Fase 1 ---")
	_check("branch ativa é main", GameState.branch_ativa == "main")
	_check("A1: porta fechada até o git log", not a1.aberta)
	_check("A3 main: limiar aberto (main ativa)", limiar_main.aberta)
	_check("A3 vida: limiar fechado (realidade adormecida)", not limiar_vida.aberta)
	_check("A4 oeste/leste/norte fechadas", not oeste.aberta and not leste.aberta and not norte.aberta)
	_check("A5 selo fechado", not selo.aberta)
	_check("eco de main indisponível antes do commit da vida", not eco_main.disponivel())

	_log("--- git log ---")
	GameState.formatar_log()
	_check("flag log_consultado", _flag(ProgressoFase2.LOG_CONSULTADO))
	_check("A1: porta abre depois do git log", a1.aberta)
	_check("comando branch liberado", GameState.comando_liberado("branch"))
	_check("comando switch ainda não liberado", not GameState.comando_liberado("switch"))

	_log("--- git branch vida-alternativa ---")
	var r := GameState.criar_branch("vida-alternativa")
	_check("branch criada (ok)", r.get("ok", false))
	_check("flag branch_criada", _flag(ProgressoFase2.BRANCH_CRIADA))
	_check("continua em main", GameState.branch_ativa == "main")
	_check("comando switch liberado", GameState.comando_liberado("switch"))
	_check("add/commit ainda não liberados em main", not GameState.comando_liberado("commit"))

	_log("--- git switch vida-alternativa ---")
	r = GameState.trocar_branch("vida-alternativa")
	_check("switch ok", r.get("ok", false))
	_check("flag na_vida_alternativa", _flag(ProgressoFase2.NA_VIDA_ALTERNATIVA))
	_check("A3 vida: limiar abre", limiar_vida.aberta)
	_check("A3 main: limiar fecha", not limiar_main.aberta)
	_check("add e commit liberados", GameState.comando_liberado("add") and GameState.comando_liberado("commit"))
	_check("eco da vida disponível", eco_vida.disponivel())

	_log("--- coletar eco da vida, git add, git commit ---")
	eco_vida.interagir()
	_check("flag eco_vida", _flag(ProgressoFase2.ECO_VIDA))
	_check("arquivo eco_vida.eco no inventário", "eco_vida.eco" in GameState.inventario_player)
	_check("A4: oeste ainda fechada (falta o eco de main)", not oeste.aberta)
	GameState.sincronizar_inventario_com_git()  # o terminal faz isto ao abrir
	var ra := GameState.adicionar_ao_stage("eco_vida.eco")
	_check("git add eco_vida.eco aceito", ra.begins_with("[color=#3DFF9B]"))
	var rc := GameState.criar_commit("Registra o eco da vida")
	_check("git commit na vida aceito", rc.begins_with("[color=#3DFF9B]"))
	_check("flag commit_vida", _flag(ProgressoFase2.COMMIT_VIDA))

	_log("--- git switch main ---")
	r = GameState.trocar_branch("main")
	_check("switch para main ok", r.get("ok", false))
	_check("A3 main: limiar abre de novo", limiar_main.aberta)
	_check("A3 vida: limiar fecha de novo", not limiar_vida.aberta)
	_check("eco de main disponível depois do commit da vida", eco_main.disponivel())
	_check("merge ainda NÃO liberado (main sem commit próprio)", not GameState.comando_liberado("merge"))

	_log("--- coletar eco de main, git add, git commit ---")
	eco_main.interagir()
	_check("flag eco_main", _flag(ProgressoFase2.ECO_MAIN))
	_check("arquivo eco_main.eco no inventário", "eco_main.eco" in GameState.inventario_player)
	_check("A4 oeste abre (os dois ecos + main ativa)", oeste.aberta)
	_check("A4 leste fechada (exige a vida ativa)", not leste.aberta)
	_check("A4 norte abre (os dois ecos)", norte.aberta)
	GameState.sincronizar_inventario_com_git()
	ra = GameState.adicionar_ao_stage("eco_main.eco")
	_check("git add eco_main.eco aceito", ra.begins_with("[color=#3DFF9B]"))
	rc = GameState.criar_commit("Registra o eco de main")
	_check("git commit em main aceito", rc.begins_with("[color=#3DFF9B]"))
	_check("flag commit_main", _flag(ProgressoFase2.COMMIT_MAIN))
	_check("comando merge liberado em main", GameState.comando_liberado("merge"))
	_check("A5 selo ainda fechado antes do merge", not selo.aberta)

	_log("--- git merge vida-alternativa ---")
	var rm := GameState.mesclar("vida-alternativa")
	_check("merge ok", rm.get("ok", false))
	_check("flag convergencia_concluida", _flag(ProgressoFase2.CONVERGENCIA_CONCLUIDA))
	_check("A5 selo abre depois do merge", selo.aberta)
	_check("registro final indisponível sem inspecionar o merge no Atlas", not registro.disponivel())

	_log("--- inspecionar o commit de merge no Atlas ---")
	_progresso.definir(ProgressoFase2.MERGE_INSPECIONADO, true)
	_check("registro final disponível", registro.disponivel())

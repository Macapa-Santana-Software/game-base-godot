extends Node

## Controla apenas a progressao entre fases.
## O estado do Git de cada fase continua sob responsabilidade do GameState.

## Lista ordenada de fases. O indice 0 representa a Fase 1.
## Fase 1 = res://fases/fase_1/fase_1.tscn (antigo playground.tscn).
const FASES: Array[String] = [
	"res://fases/fase_1/fase_1.tscn",  # indice 0 -> Fase 1
	"res://fases/fase_2/fase_2.tscn",  # indice 1 -> Fase 2 (tutorial: a ponte quebrada)
	"res://fases/fase_3/fase_3.tscn",  # indice 2 -> Fase 3 (tutorial: o mural corrompido; diff e restore)
	"res://fases/fase_4/fase_4.tscn",  # indice 3 -> Fase 4 (elevada: Ecos de Possibilidades, antiga Fase 2)
	"res://fases/fase_5/fase_5.tscn",  # indice 4 -> Fase 5 (tutorial: Linhas Cruzadas, merge com conflito)
	"res://fases/fase_6/fase_6.tscn",  # indice 5 -> Fase 6 (tutorial: Ponto de Retorno; revert, stash, reset)
]

## Indice da fase atual dentro de FASES (0 = Fase 1).
var current_level_index: int = 0

## Caminho da cena da fase atual.
func get_current_phase() -> String:
	return FASES[current_level_index]

## Numero da fase atual para exibicao (Fase 1 = 1).
func get_current_phase_number() -> int:
	return current_level_index + 1

## Existe uma fase depois da atual?
func has_next_phase() -> bool:
	return current_level_index + 1 < FASES.size()

## Caminho da proxima fase, ou "" se nao existir.
func get_next_phase() -> String:
	if not has_next_phase():
		return ""
	return FASES[current_level_index + 1]

## Avanca para a proxima fase, se existir. Retorna false quando nao ha proxima.
func advance_to_next_phase() -> bool:
	if not has_next_phase():
		return false
	current_level_index += 1
	get_tree().paused = false
	get_tree().change_scene_to_file(FASES[current_level_index])
	return true

## Alinha o índice com a cena que está rodando. Serve para quando uma fase é aberta direto
## (editor/F6) em vez de chegar pela sequência: a tela de vitória e o "próximo" passam a valer
## para ela. Cenas fora da lista (testes, ferramentas) não mudam nada.
func sincronizar_com_cena_atual() -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return
	var indice := FASES.find(cena.scene_file_path)
	if indice >= 0:
		current_level_index = indice

## Recomeça a fase atual do zero (menu de pausa e tela de derrota): o Git, o inventário e o progresso
## voltam ao que eram ao entrar nela, e as notas lidas nesta tentativa voltam a aparecer não lidas.
func reiniciar_fase_atual() -> void:
	GameState.restaurar_checkpoint()
	Diario.descartar_tentativa()
	get_tree().paused = false
	get_tree().reload_current_scene()

## A fase atual é a última da sequência?
func is_last_phase() -> bool:
	return current_level_index == FASES.size() - 1

## Chamado quando o jogador conclui a fase (botão da tela de vitória): limpa o estado temporário
## (o repositório é preservado) e entra na entrada da fase seguinte. Devolve false se não há
## próxima fase ou se a cena atual não faz parte da sequência.
func concluir_fase_e_avancar() -> bool:
	var cena := get_tree().current_scene
	if cena != null and FASES.find(cena.scene_file_path) < 0:
		return false
	sincronizar_com_cena_atual()
	Diario.confirmar_tentativa()  # as notas lidas nesta fase ficam marcadas para sempre
	if not has_next_phase():
		return false
	GameState.reset_fase()
	return advance_to_next_phase()

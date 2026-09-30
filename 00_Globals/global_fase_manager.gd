extends Node

## Controla apenas a progressao entre fases.
## O estado do Git de cada fase continua sob responsabilidade do GameState.

## Lista ordenada de fases. O indice 0 representa a Fase 1.
## Fase 1 = res://fases/fase_1/fase_1.tscn (antigo playground.tscn).
const FASES: Array[String] = [
	"res://fases/fase_1/fase_1.tscn",  # indice 0 -> Fase 1
	# "res://fases/fase_2/fase_2.tscn",  # indice 1 -> Fase 2 (futuro)
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

class_name ItemColetavel extends ItemBase

## Grupo usado por diálogos e objetivos para descobrir, a partir do próprio mapa,
## quais arquivos existem na fase (fonte única de verdade: o nome_do_item do nó).
const GRUPO_ARQUIVOS := "arquivo_coletavel"

func _ready():
	add_to_group(GRUPO_ARQUIVOS)
	super._ready()

func _on_body_entered(body):
	# Correção 1: Detecta se o nome contém 'Player' ou se está no grupo 'player'
	if "Player" in body.name or body.is_in_group("player"):
		coletar()

func ao_ser_coletado():
	pass  # Adicione aqui qualquer comportamento extra, se precisar

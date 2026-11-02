class_name ItemColetavel extends ItemBase

## Grupo usado por diálogos e objetivos para descobrir, a partir do próprio mapa,
## quais arquivos existem na fase (fonte única de verdade: o nome_do_item do nó).
const GRUPO_ARQUIVOS := "arquivo_coletavel"

## Ícone próprio deste arquivo (também é o ícone mostrado no inventário). Vazio = textura da cena.
@export var textura_icone: Texture2D

func _ready():
	add_to_group(GRUPO_ARQUIVOS)
	if textura_icone and has_node("Sprite2D"):
		$Sprite2D.texture = textura_icone
	super._ready()

func _on_body_entered(body):
	# Correção 1: Detecta se o nome contém 'Player' ou se está no grupo 'player'
	if "Player" in body.name or body.is_in_group("player"):
		coletar()

func ao_ser_coletado():
	pass  # Adicione aqui qualquer comportamento extra, se precisar

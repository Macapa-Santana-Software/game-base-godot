class_name ItemColetavel extends ItemBase

func _ready():
	super._ready()

func _on_body_entered(body):
	# Correção 1: Detecta se o nome contém 'Player' ou se está no grupo 'player'
	if "Player" in body.name or body.is_in_group("player"):
		coletar()

func ao_ser_coletado():
	pass  # Adicione aqui qualquer comportamento extra, se precisar

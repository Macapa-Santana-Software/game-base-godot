class_name AtlasArtefato extends ZonaInteracao
## O artefato físico do Atlas das Ramificações (Área 1). Interagir com ele (tecla de
## interação, a mesma dos terminais) abre o Atlas. Reutiliza a ação já existente do Input
## Map; não cria nenhuma nova.
##
## PLACEHOLDER visual: o corpo do artefato é um prop de cor lisa na cena da área.


func _aplicar_efeitos() -> void:
	var atlas := get_tree().get_first_node_in_group(AtlasUI.GRUPO) as AtlasUI
	if atlas:
		atlas.abrir()

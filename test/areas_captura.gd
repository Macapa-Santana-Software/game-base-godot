extends Node
## Ferramenta de verificação visual (não faz parte do jogo): renderiza cada área da Fase 2 num SubViewport
## fora da tela e grava PNGs em %TEMP% (fase2_area_<id>.png), sem depender de qual janela está em foco.
## Também grava %TEMP%\fase2_areas_captura.txt com o resultado de cada carga.

const ALVOS := [
	{"id": "1", "cena": "res://fases/fase_2/areas/area_1_arquivo.tscn", "caixa": Rect2(-128, -96, 960, 680)},
	{"id": "2", "cena": "res://fases/fase_2/areas/area_2_ramificacao.tscn", "caixa": Rect2(-48, -48, 672, 736)},
	{"id": "3m", "cena": "res://fases/fase_2/areas/area_3_main.tscn", "caixa": Rect2(0, -200, 900, 900)},
	{"id": "3v", "cena": "res://fases/fase_2/areas/area_3_vida.tscn", "caixa": Rect2(0, -200, 900, 900)},
	{"id": "4", "cena": "res://fases/fase_2/areas/area_4_convergencia.tscn", "caixa": Rect2(-48, -220, 560, 860)},
	{"id": "5", "cena": "res://fases/fase_2/areas/area_5_registro.tscn", "caixa": Rect2(-180, -48, 880, 640)},
]

var _log: PackedStringArray = []


func _ready() -> void:
	var pasta := OS.get_environment("TEMP")
	for alvo in ALVOS:
		var caixa: Rect2 = alvo["caixa"]
		var vp := SubViewport.new()
		vp.size = Vector2i(caixa.size)
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.disable_3d = true
		add_child(vp)
		var cena := load(alvo["cena"]) as PackedScene
		if cena == null:
			_log.append("FALHA ao carregar %s" % alvo["cena"])
			continue
		var area := cena.instantiate()
		vp.add_child(area)
		var camera := Camera2D.new()
		camera.position = caixa.get_center()
		vp.add_child(camera)
		camera.make_current()
		for _i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var imagem := vp.get_texture().get_image()
		var caminho := "%s/fase2_area_%s.png" % [pasta, alvo["id"]]
		var erro := imagem.save_png(caminho)
		_log.append("%s  %s -> %dx%d (%s)" % ["OK" if erro == OK else "ERRO", alvo["cena"], imagem.get_width(), imagem.get_height(), caminho])
		vp.queue_free()
	var arq := FileAccess.open(pasta + "/fase2_areas_captura.txt", FileAccess.WRITE)
	arq.store_string("\n".join(_log) + "\n")
	arq.close()
	print("\n".join(_log))
	get_tree().quit()

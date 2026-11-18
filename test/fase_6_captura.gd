extends Node
## Ferramenta de verificação visual (não faz parte do jogo): renderiza a Fase 6 inteira num
## SubViewport largo e grava PNGs em %TEMP% (fase6_captura_<momento>.png) em 3 momentos da jornada.
## Precisa de janela (não roda com --headless).

const LARGURA := 1400
const ALTURA := 270


func _ready() -> void:
	var pasta := OS.get_environment("TEMP") if OS.get_environment("TEMP") != "" else "/tmp"
	GameState.resetar_repositorio()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(LARGURA, ALTURA)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var fase := (load("res://fases/fase_6/fase_6.tscn") as PackedScene).instantiate()
	viewport.add_child(fase)
	var camera := Camera2D.new()
	camera.position = Vector2(670, 128)
	viewport.add_child(camera)
	camera.make_current()
	var terminal := TerminalCommandInterpreter.new()
	add_child(terminal)
	terminal.configurar_comandos(["help", "status", "log", "add", "commit", "revert", "stash", "reset"])
	await _frames()
	_salvar(viewport, pasta, "1_inicio")

	terminal.execute_command("git log")
	terminal.execute_command("git revert HEAD")
	await _frames()
	terminal.execute_command("git stash")
	await _frames()
	_salvar(viewport, pasta, "2_corredor")

	EstadoRetorno.marcar("emergencia")
	fase.notificar()
	terminal.execute_command("git stash pop")
	await _frames()
	terminal.execute_command("git reset --soft HEAD~1")
	await _frames()
	_salvar(viewport, pasta, "3_camara")

	terminal.execute_command("git commit -m \"planta\"")
	await _frames()
	terminal.execute_command("git reset --hard HEAD~1")
	await _frames()
	_salvar(viewport, pasta, "4_fim")
	GameState.resetar_repositorio()
	get_tree().quit()


func _frames() -> void:
	for _i in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _salvar(viewport: SubViewport, pasta: String, nome: String) -> void:
	var imagem := viewport.get_texture().get_image()
	imagem.save_png(pasta.path_join("fase6_captura_%s.png" % nome))
	print("[captura] %s" % nome)

class_name AtlasUI extends CanvasLayer
## O Atlas das Ramificações: artefato Codex que mostra o repositório REAL (GameState) como
## linhas de realidade. Repositório = o Atlas inteiro; commit = nó de memória; histórico =
## fios; branch = linha de realidade; HEAD = marcador da branch ativa.
##
## Aberto pelo artefato físico da Área 1 (AtlasArtefato) com `abrir()`. Pausa o jogo
## enquanto está aberto e devolve o estado anterior ao fechar. Reage aos sinais do GameState
## (commit, branch criada, troca de branch, merge) redesenhando o grafo.
##
## A moldura e os textos são provisórios, desenhados por código (placeholder), para a arte
## futura entrar via AtlasEstilo sem mexer na lógica. Esc fecha; setas navegam; clique seleciona.

const GRUPO := &"atlas_ui"
const FONTE := preload("res://Dialogo/MonospacePixel.ttf")

signal aberto
signal fechado
## O jogador inspecionou um nó do grafo (dados reais do GameState, ver AtlasLayout).
signal no_inspecionado(no: Dictionary)

@export var estilo: AtlasEstilo

var _grafo: AtlasGrafo
var _detalhes: RichTextLabel
var _dica: Label
var _pausado_antes: bool = false


func _enter_tree() -> void:
	add_to_group(GRUPO)


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	if estilo == null:
		estilo = AtlasEstilo.new()
	_construir()
	hide()
	GameState.commit_realizado.connect(_on_commit_realizado)
	GameState.branch_criada.connect(_on_branch_criada)
	GameState.branch_ativa_mudou.connect(_on_branch_ativa_mudou)
	GameState.merge_realizado.connect(_on_merge_realizado)


func _exit_tree() -> void:
	# O GameState é autoload e sobrevive à cena: solta as ligações.
	if GameState.commit_realizado.is_connected(_on_commit_realizado):
		GameState.commit_realizado.disconnect(_on_commit_realizado)
	if GameState.branch_criada.is_connected(_on_branch_criada):
		GameState.branch_criada.disconnect(_on_branch_criada)
	if GameState.branch_ativa_mudou.is_connected(_on_branch_ativa_mudou):
		GameState.branch_ativa_mudou.disconnect(_on_branch_ativa_mudou)
	if GameState.merge_realizado.is_connected(_on_merge_realizado):
		GameState.merge_realizado.disconnect(_on_merge_realizado)


func abrir() -> void:
	if visible:
		return
	_pausado_antes = get_tree().paused
	get_tree().paused = true
	_grafo.atualizar(true)
	show()
	aberto.emit()


func fechar() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = _pausado_antes
	fechado.emit()


func _unhandled_input(evento: InputEvent) -> void:
	if not visible:
		return
	if evento.is_action_pressed("ui_cancel"):
		fechar()
	elif evento.is_action_pressed("ui_left"):
		_grafo.mover_selecao(-1)
	elif evento.is_action_pressed("ui_right"):
		_grafo.mover_selecao(1)
	elif evento.is_action_pressed("ui_accept"):
		_grafo.inspecionar_selecao()
	else:
		return
	get_viewport().set_input_as_handled()


# --- Reação ao GameState ----------------------------------------------------------------
func _on_commit_realizado(_commit: Dictionary) -> void:
	_on_repositorio_mudou()


func _on_branch_criada(_nome: String, _commit_id: String) -> void:
	_on_repositorio_mudou()


func _on_branch_ativa_mudou(_anterior: String, _nova: String) -> void:
	_on_repositorio_mudou()


func _on_merge_realizado(_origem: String, _destino: String, _commit_id: String, _ff: bool) -> void:
	_on_repositorio_mudou()


func _on_repositorio_mudou() -> void:
	if visible:
		_grafo.atualizar(true)


# --- Construção (placeholder visual) ------------------------------------------------------
func _construir() -> void:
	var cortina := ColorRect.new()
	cortina.color = Color(0, 0, 0, 0.78)
	cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cortina)

	var moldura := Panel.new()
	moldura.position = Vector2(18, 10)
	moldura.size = Vector2(444, 250)
	moldura.add_theme_stylebox_override("panel", _caixa(estilo.cor_fundo, estilo.cor_moldura, 2))
	add_child(moldura)
	var interno := Panel.new()
	interno.position = Vector2(22, 14)
	interno.size = Vector2(436, 242)
	interno.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interno.add_theme_stylebox_override("panel", _caixa(Color(0, 0, 0, 0), Color(estilo.cor_holograma, 0.25), 1))
	add_child(interno)
	if estilo.textura_moldura:
		var arte := TextureRect.new()
		arte.texture = estilo.textura_moldura
		arte.position = moldura.position
		arte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(arte)

	_rotulo("ATLAS DAS RAMIFICAÇÕES", Vector2(32, 18), 10, estilo.cor_holograma)
	_rotulo("artefato Codex :: linhas de realidade (lê o repositório real)", Vector2(32, 32), 7, estilo.cor_texto_fraco)

	_grafo = AtlasGrafo.new()
	_grafo.estilo = estilo
	_grafo.position = Vector2(30, 46)
	_grafo.size = Vector2(420, 104)
	_grafo.no_selecionado.connect(_on_no_selecionado)
	_grafo.no_inspecionado.connect(_on_no_inspecionado)
	add_child(_grafo)

	_detalhes = RichTextLabel.new()
	_detalhes.bbcode_enabled = true
	_detalhes.scroll_active = false
	_detalhes.position = Vector2(32, 156)
	_detalhes.size = Vector2(416, 58)
	_detalhes.add_theme_font_override("normal_font", FONTE)
	_detalhes.add_theme_font_size_override("normal_font_size", 8)
	_detalhes.add_theme_color_override("default_color", estilo.cor_texto)
	_detalhes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_detalhes)

	_dica = _rotulo("", Vector2(32, 218), 7, estilo.cor_holograma)
	_dica.size = Vector2(416, 22)
	_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rotulo("SETAS navegam  |  ENTER ou CLIQUE inspecionam o nó  |  ESC fecha", Vector2(32, 243), 7, estilo.cor_texto_fraco)


func _rotulo(texto: String, posicao: Vector2, tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.position = posicao
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_font_override("font", FONTE)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	add_child(rotulo)
	return rotulo


func _caixa(fundo: Color, borda: Color, largura: int) -> StyleBoxFlat:
	var caixa := StyleBoxFlat.new()
	caixa.bg_color = fundo
	caixa.border_color = borda
	caixa.set_border_width_all(largura)
	return caixa


# --- Textos que explicam o que se vê (provisórios) ------------------------------------------
func _on_no_inspecionado(no: Dictionary) -> void:
	no_inspecionado.emit(no)


func _on_no_selecionado(no: Dictionary) -> void:
	_detalhes.text = _texto_do_no(no)
	_dica.text = _texto_da_dica()


func _texto_do_no(no: Dictionary) -> String:
	if no.is_empty():
		return "[color=#8f84b8]O Atlas está vazio: nenhuma memória foi registrada ainda.[/color]"
	var cor := "#" + estilo.cor_da_branch(no["branch"]).to_html(false)
	var linhas: Array[String] = []
	linhas.append("[color=#ffe08a]MEMÓRIA %s[/color]   linha: [color=%s]%s[/color]%s" % [
		no["id"], cor, no["branch"], "   [color=#7fe8ff](HEAD está aqui)[/color]" if no["head"] else ""])
	linhas.append("\"%s\"" % str(no["mensagem"]).replace("[", "[lb]"))
	if no["merge"]:
		linhas.append("Convergência: este nó tem DOIS pais: %s (linha %s) e %s (linha %s)." % [
			no["pais"][0], _linha_do_no(no["pais"][0]), no["pais"][1], _linha_do_no(no["pais"][1])])
	elif no["pais"].is_empty():
		linhas.append("Primeira memória: não tem pai.")
	else:
		linhas.append("Pai: %s" % no["pais"][0])
	var arquivos: Array = no["arquivos"]
	linhas.append("Arquivos: %s" % (", ".join(PackedStringArray(arquivos)) if not arquivos.is_empty() else "nenhum novo"))
	return "\n".join(linhas)


## Linha (branch) em que o Atlas desenha o nó `id` (vem do AtlasLayout, que lê o GameState).
func _linha_do_no(id: String) -> String:
	for no in _grafo.dados().get("nos", []):
		if no["id"] == id:
			return str(no["branch"])
	return "?"


func _texto_da_dica() -> String:
	var dados := _grafo.dados()
	if dados.is_empty() or dados["nos"].is_empty():
		return ""
	var ativa: String = dados["branch_ativa"]
	for no in dados["nos"]:
		if no["merge"]:
			return "As duas linhas convergiram: o nó de merge guarda a história de ambas."
	for tag in dados["tags"]:
		if tag["fantasma"]:
			return "A linha '%s' nasceu neste ponto e ainda não tem memórias próprias. O HEAD continua em '%s': criar uma branch não troca de branch." % [tag["branch"], ativa]
	if dados["tags"].size() > 1:
		return "As linhas divergiram: cada uma guarda memórias que a outra não tem. O HEAD mostra em qual você está."
	return "Cada nó é um commit. Os fios ligam cada memória à anterior. O HEAD marca a linha em que você está."

class_name AtlasGrafo extends Control
## Desenha o grafo do Atlas: nós de memória (commits), fios (histórico), linhas de
## realidade (branches) e o marcador HEAD. SÓ desenha o que o AtlasLayout calculou a
## partir do GameState; não guarda histórico próprio.
##
## Tudo é procedural (placeholder). As texturas do AtlasEstilo, quando atribuídas,
## substituem os desenhos de nó, nó de merge e HEAD.

signal no_selecionado(no: Dictionary)
## O JOGADOR escolheu um nó (setas ou clique). Diferente de `no_selecionado`, não é emitido
## quando o Atlas se reconstrói e seleciona o HEAD sozinho.
signal no_inspecionado(no: Dictionary)

const FONTE := preload("res://Dialogo/MonospacePixel.ttf")
const TAMANHO_FONTE := 8
const DURACAO_PULSO := 0.9
const RAIO_CLIQUE := 14.0
const MARGEM_ESQUERDA := 66.0  # espaço para o nome das linhas

@export var estilo: AtlasEstilo

var _dados: Dictionary = {}
var _selecionado: String = ""
var _ids_conhecidos: Dictionary = {}
var _pulsos: Dictionary = {}  # id do nó (ou "tag:<branch>") -> tempo restante do pulso
var _deslocamento: float = 0.0
var _tempo: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if estilo == null:
		estilo = AtlasEstilo.new()
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)


## Reconstrói a partir do GameState. Nós e branches que não existiam antes recebem um
## pulso curto (é como o jogador percebe o efeito do comando que acabou de usar).
func atualizar(animar: bool = true) -> void:
	if estilo == null:
		estilo = AtlasEstilo.new()
	_dados = AtlasLayout.calcular()
	var novos: Dictionary = {}
	for no in _dados["nos"]:
		novos[no["id"]] = true
		if animar and not _ids_conhecidos.is_empty() and not _ids_conhecidos.has(no["id"]):
			_pulsos[no["id"]] = DURACAO_PULSO
	for tag in _dados["tags"]:
		var chave: String = "tag:" + tag["branch"]
		novos[chave] = true
		if animar and not _ids_conhecidos.is_empty() and not _ids_conhecidos.has(chave):
			_pulsos[chave] = DURACAO_PULSO
	_ids_conhecidos = novos
	if not _selecionado.is_empty() and _indice_do_no(_selecionado) < 0:
		_selecionado = ""
	if _selecionado.is_empty():
		_selecionado = str(_dados["head_no"])  # começa olhando o HEAD
	_emitir_selecao()
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_tempo += delta
	for chave in _pulsos.keys():
		_pulsos[chave] -= delta
		if _pulsos[chave] <= 0.0:
			_pulsos.erase(chave)
	queue_redraw()  # o marcador HEAD flutua devagar (holograma discreto)


# --- Seleção ---------------------------------------------------------------------------
func mover_selecao(passo: int) -> void:
	var nos: Array = _dados.get("nos", [])
	if nos.is_empty():
		return
	var indice := clampi(_indice_do_no(_selecionado) + passo, 0, nos.size() - 1)
	_selecionado = nos[indice]["id"]
	_emitir_selecao()
	no_inspecionado.emit(no_selecionado_dados())
	queue_redraw()


## Inspeção explícita do nó selecionado (ENTER). Necessária porque, logo depois de um merge, o Atlas
## já abre com o commit de merge (o HEAD) selecionado: só olhar para ele não é inspecioná-lo.
func inspecionar_selecao() -> void:
	var no := no_selecionado_dados()
	if no.is_empty():
		return
	_pulsos[no["id"]] = DURACAO_PULSO  # retorno visual da inspeção
	no_inspecionado.emit(no)
	queue_redraw()


func no_selecionado_dados() -> Dictionary:
	var indice := _indice_do_no(_selecionado)
	return _dados["nos"][indice] if indice >= 0 else {}


func dados() -> Dictionary:
	return _dados


func _indice_do_no(id: String) -> int:
	var nos: Array = _dados.get("nos", [])
	for i in nos.size():
		if nos[i]["id"] == id:
			return i
	return -1


func _emitir_selecao() -> void:
	no_selecionado.emit(no_selecionado_dados())


func _gui_input(evento: InputEvent) -> void:
	var clique := evento as InputEventMouseButton
	if clique == null or not clique.pressed or clique.button_index != MOUSE_BUTTON_LEFT:
		return
	var melhor := ""
	var menor := RAIO_CLIQUE
	for no in _dados.get("nos", []):
		var distancia := _posicao_no(no).distance_to(clique.position)
		if distancia < menor:
			menor = distancia
			melhor = no["id"]
	if not melhor.is_empty():
		_selecionado = melhor
		_emitir_selecao()
		no_inspecionado.emit(no_selecionado_dados())
		queue_redraw()


# --- Posições ----------------------------------------------------------------------------
func _posicao_no(no: Dictionary) -> Vector2:
	return _posicao(no["coluna"], no["faixa"])


func _posicao(coluna: float, faixa: int) -> Vector2:
	return Vector2(
		MARGEM_ESQUERDA + 14.0 + coluna * estilo.espaco_colunas - _deslocamento,
		38.0 + faixa * estilo.espaco_faixas)


func _ajustar_deslocamento() -> void:
	# Mantém o nó selecionado à vista quando o histórico fica mais largo que o painel.
	var indice := _indice_do_no(_selecionado)
	if indice < 0:
		_deslocamento = 0.0
		return
	var largura_total: float = 28.0 + _dados["nos"].size() * estilo.espaco_colunas
	var area := size.x - MARGEM_ESQUERDA
	if largura_total <= area:
		_deslocamento = 0.0
		return
	var alvo: float = indice * estilo.espaco_colunas - area * 0.5
	_deslocamento = clampf(alvo, 0.0, largura_total - area)


# --- Desenho ------------------------------------------------------------------------------
func _draw() -> void:
	if _dados.is_empty():
		return
	_ajustar_deslocamento()
	_desenhar_grade()
	_desenhar_faixas()
	_desenhar_ligacoes()
	_desenhar_nos()
	_desenhar_tags_e_head()


func _desenhar_grade() -> void:
	var cor := Color(estilo.cor_holograma, 0.05)
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), cor, 1.0)
		y += 4.0


func _desenhar_faixas() -> void:
	for faixa in _dados["faixas"]:
		var nome: String = faixa["branch"]
		var ativa: bool = nome == _dados["branch_ativa"]
		var y := _posicao(0, faixa["indice"]).y
		var cor := estilo.cor_da_branch(nome)
		draw_line(Vector2(MARGEM_ESQUERDA - 4.0, y), Vector2(size.x, y), Color(cor, 0.30 if ativa else 0.12), 1.0)
		draw_string(FONTE, Vector2(2, y + 3), _abreviar(nome, 10), HORIZONTAL_ALIGNMENT_LEFT,
			MARGEM_ESQUERDA - 8.0, TAMANHO_FONTE, Color(cor, 1.0 if ativa else 0.55))


func _desenhar_ligacoes() -> void:
	var por_id: Dictionary = _nos_por_id()
	for ligacao in _dados["ligacoes"]:
		var pai: Dictionary = por_id[ligacao["de"]]
		var filho: Dictionary = por_id[ligacao["para"]]
		var primeiro_pai: bool = filho["pais"][0] == pai["id"]
		# O fio do primeiro pai herda a cor do filho; o do segundo pai (merge) traz a cor
		# da linha que está sendo integrada.
		var branch_fio: String = filho["branch"] if primeiro_pai else pai["branch"]
		var cor := Color(estilo.cor_da_branch(branch_fio), 0.9)
		var a := _posicao_no(pai)
		var b := _posicao_no(filho)
		if pai["faixa"] == filho["faixa"]:
			draw_line(a, b, cor, 2.0)
		else:
			# Divergência/convergência: segue na horizontal e muda de faixa na diagonal.
			var quina := Vector2(b.x - estilo.espaco_colunas * 0.5, a.y) if primeiro_pai \
				else Vector2(a.x + estilo.espaco_colunas * 0.5, a.y)
			draw_polyline(PackedVector2Array([a, quina, b]), cor, 2.0)


func _desenhar_nos() -> void:
	for no in _dados["nos"]:
		var centro := _posicao_no(no)
		var cor := estilo.cor_da_branch(no["branch"])
		var raio: float = estilo.raio_no * (1.4 if no["merge"] else 1.0)
		var pulso: float = float(_pulsos.get(no["id"], 0.0)) / DURACAO_PULSO
		if pulso > 0.0:
			draw_arc(centro, raio + 4.0 + 10.0 * (1.0 - pulso), 0.0, TAU, 20, Color(estilo.cor_holograma, pulso), 1.0)
		var textura := estilo.textura_no_merge if no["merge"] else estilo.textura_no
		if textura:
			draw_texture(textura, centro - textura.get_size() * 0.5)
		else:
			_losango(centro, raio, cor, cor.lightened(0.45))
			if no["merge"]:
				_losango(centro, raio * 0.5, estilo.cor_fundo, estilo.cor_destaque)
		if no["id"] == _selecionado:
			draw_arc(centro, raio + 4.0, 0.0, TAU, 20, estilo.cor_holograma, 1.0)
		draw_string(FONTE, centro + Vector2(-20, raio + 12.0), no["id"], HORIZONTAL_ALIGNMENT_CENTER, 40.0,
			TAMANHO_FONTE - 1, estilo.cor_texto_fraco)


func _losango(centro: Vector2, raio: float, preenchimento: Color, contorno: Color) -> void:
	var pontos := PackedVector2Array([
		centro + Vector2(0, -raio), centro + Vector2(raio, 0),
		centro + Vector2(0, raio), centro + Vector2(-raio, 0)])
	draw_colored_polygon(pontos, preenchimento)
	pontos.append(pontos[0])
	draw_polyline(pontos, contorno, 1.0)


func _desenhar_tags_e_head() -> void:
	var por_id: Dictionary = _nos_por_id()
	for tag in _dados["tags"]:
		var nome: String = tag["branch"]
		var cor := estilo.cor_da_branch(nome)
		var no: Dictionary = por_id.get(tag["no"], {})
		if no.is_empty():
			continue  # branch sem commit nenhum ainda: não há onde ancorar
		var ancora := _posicao_no(no)
		var abaixo := false
		if tag["fantasma"]:
			# Branch recém-criada: aponta para um nó de outra linha. A etiqueta fica na
			# SUA linha, ligada ao nó por um fio tracejado, e ainda sem commit próprio.
			var base := ancora
			ancora = Vector2(base.x + estilo.espaco_colunas * 0.8, _posicao(0, tag["faixa"]).y)
			draw_dashed_line(base, ancora, Color(cor, 0.8), 1.0, 3.0)
			_losango(ancora, estilo.raio_no * 0.8, Color(cor, 0.0), cor)
			abaixo = tag["faixa"] > 0
		var pulso: float = float(_pulsos.get("tag:" + nome, 0.0)) / DURACAO_PULSO
		var y_texto: float = (estilo.raio_no + 17.0) if abaixo else -(estilo.raio_no + 6.0)
		var posicao_texto := ancora + Vector2(-26, y_texto)
		draw_string(FONTE, posicao_texto, _abreviar(nome, 12), HORIZONTAL_ALIGNMENT_CENTER, 52.0,
			TAMANHO_FONTE, cor.lightened(0.3 * pulso))
		if tag["ativa"]:
			_desenhar_head(ancora, posicao_texto)


func _desenhar_head(ancora: Vector2, posicao_texto: Vector2) -> void:
	# Marcador holográfico da branch ativa, flutuando acima da etiqueta dela.
	var bob := sin(_tempo * 3.0) * 1.5
	var topo := Vector2(ancora.x, posicao_texto.y - 12.0 + bob)
	if estilo.textura_head:
		draw_texture(estilo.textura_head, topo - estilo.textura_head.get_size() * 0.5)
		return
	draw_string(FONTE, topo + Vector2(-16, -2), "HEAD", HORIZONTAL_ALIGNMENT_CENTER, 32.0,
		TAMANHO_FONTE, estilo.cor_holograma)
	draw_colored_polygon(PackedVector2Array([
		topo + Vector2(-3, 2), topo + Vector2(3, 2), topo + Vector2(0, 6)]), estilo.cor_holograma)


func _nos_por_id() -> Dictionary:
	var por_id: Dictionary = {}
	for no in _dados["nos"]:
		por_id[no["id"]] = no
	return por_id


func _abreviar(texto: String, maximo: int) -> String:
	return texto if texto.length() <= maximo else texto.substr(0, maximo - 1) + "."

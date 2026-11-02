class_name TutoraFase1 extends CanvasLayer
## A "IA" da Fase 1: personagem tutora do jogo (roteirizada, não é uma IA real).
##
## Faz três coisas, todas guiadas pelo que o jogador FEZ (sinais do GameState):
##   1. Reage no terminal a cada comando (explica o conceito na 1ª vez, resume nas seguintes).
##   2. Mantém o "Quadro da IA" na tela: próximo passo + cola dos comandos já apresentados.
##   3. Percebe dificuldade (falhas seguidas) e passa de uma pista conceitual para a resposta.
##
## Metáfora usada em todas as falas: a pasta é uma SALA (arquivos soltos no chão),
## a staging area é uma CAIXA onde se separa o que vai ser registrado, e o commit
## é uma FOTO (save point). Os termos reais do Git são sempre ditos junto da metáfora.
##
## O estado pedagógico fica em GameState.progresso_tutoria (sobrevive a recarregar a cena).

const FONTE := preload("res://Dialogo/MonospacePixel.ttf")

const COR_IA := "#51CF66"
const COR_CMD := "#FFE08A"
const COR_CONCEITO := "#9AD1FF"
const PREFIXO_TERMINAL := "[color=#51CF66][IA][/color] "

const LARGURA_QUADRO := 130.0
const MARGEM := 6.0
const TAMANHO_FONTE := 6
## Falhas seguidas a partir das quais a IA deixa de dar pista e entrega o comando.
const FALHAS_PARA_AJUDA_DIRETA := 2
const LARGURA_BALAO := 200.0
const DURACAO_MINIMA_BALAO := 3.5
const CARACTERES_POR_SEGUNDO := 16.0

## Nomes dos arquivos que precisam ser versionados para concluir a fase.
## Preenchido pela fase antes de entrar na árvore.
var arquivos_requeridos: Array[String] = []

var _raiz: Control
var _painel: PanelContainer
var _texto_passo: RichTextLabel
var _separador_comandos: HSeparator
var _titulo_comandos: Label
var _texto_comandos: RichTextLabel
var _estado_anterior: String = ""
var _piscar_tween: Tween
var _balao: PanelContainer
var _texto_balao: RichTextLabel
var _balao_tween: Tween
var _terminal_aberto: bool = false

func _ready() -> void:
	# Camada abaixo do terminal: quando o terminal abre, ele cobre o quadro.
	layer = 0
	process_mode = Node.PROCESS_MODE_ALWAYS

	_montar_quadro()

	GameState.arquivo_coletado.connect(_on_arquivo_coletado)
	GameState.terminal_aberto.connect(_on_terminal_aberto)
	GameState.terminal_fechado.connect(_on_terminal_fechado)
	GameState.ajuda_pedida.connect(_on_ajuda_pedida)
	GameState.repositorio_inicializado.connect(_on_repositorio_inicializado)
	GameState.status_consultado.connect(_on_status_consultado)
	GameState.arquivos_preparados.connect(_on_arquivos_preparados)
	GameState.commit_realizado.connect(_on_commit_realizado)
	GameState.comando_falhou.connect(_on_comando_falhou)

	_atualizar_quadro()

# ---------------------------------------------------------------------------
# Estado do jogador -> etapa pedagógica
# ---------------------------------------------------------------------------

func _estado() -> String:
	var faltam := _faltam_coletar()
	var pendentes := GameState.arquivos_pendentes(arquivos_requeridos)

	if not GameState.commits.is_empty() and pendentes.is_empty():
		return "concluido"
	if not GameState.staging_area.is_empty():
		return "commit"
	if not GameState.commits.is_empty():
		return "coletar_resto" if not faltam.is_empty() else "add_resto"
	if not arquivos_requeridos.is_empty() and faltam.size() == arquivos_requeridos.size():
		return "coletar"
	if not GameState.git_inicializado:
		return "init"
	if not GameState.progresso_tutoria["status_visto"]:
		return "status"
	return "add"

func _faltam_coletar() -> Array[String]:
	var faltam: Array[String] = []
	for arquivo in arquivos_requeridos:
		if not arquivo in GameState.inventario_player:
			faltam.append(arquivo)
	return faltam

# Primeiro arquivo que o jogador ainda pode adicionar (usado nos exemplos de comando)
func _arquivo_exemplo() -> String:
	if not GameState.working_directory.is_empty():
		return GameState.working_directory[0]
	var pendentes := GameState.arquivos_pendentes(arquivos_requeridos)
	if not pendentes.is_empty():
		return pendentes[0]
	return "arquivo"

# Retirada gradual do apoio: depois do 1º ciclo completo (add -> commit) a IA passa a dizer
# só o objetivo, não o comando. Volta a detalhar se o jogador errar em sequência ou pedir `git help`.
func _detalhado() -> bool:
	if GameState.progresso_tutoria["nivel_explicacao"] != "breve":
		return true
	return GameState.progresso_tutoria["erros_consecutivos"] >= FALHAS_PARA_AJUDA_DIRETA

# Libera os comandos um de cada vez, conforme o jogador avança (comandos novos só depois do anterior)
func _sincronizar_comandos() -> void:
	var tem_staging := not GameState.staging_area.is_empty()
	var tem_commit := not GameState.commits.is_empty()
	var liberados: Array[String] = ["init"]
	if GameState.git_inicializado:
		liberados.append("status")
	if GameState.progresso_tutoria["status_visto"] or tem_staging or tem_commit:
		liberados.append("add")
	if tem_staging or tem_commit:
		liberados.append("commit")
	var mudou := not GameState.liberacao_progressiva or liberados != GameState.comandos_liberados
	GameState.liberacao_progressiva = true
	GameState.comandos_liberados = liberados
	if mudou:
		GameState.comandos_atualizados.emit()

# true só na primeira vez que a chave é consultada (marca como explicada)
func _primeira_vez(chave: String) -> bool:
	var explicados: Dictionary = GameState.progresso_tutoria["explicados"]
	if explicados.has(chave):
		return false
	explicados[chave] = true
	return true

# ---------------------------------------------------------------------------
# Formatação
# ---------------------------------------------------------------------------

func _cmd(texto: String) -> String:
	return "[color=%s]%s[/color]" % [COR_CMD, texto]

func _conceito(texto: String) -> String:
	return "[color=%s]%s[/color]" % [COR_CONCEITO, texto]

func _lista(nomes: Array) -> String:
	var itens: Array[String] = []
	for nome in nomes:
		itens.append(_cmd(str(nome)))
	return ", ".join(itens)

# ---------------------------------------------------------------------------
# Fala no terminal
# ---------------------------------------------------------------------------

# Adia a escrita para depois que o terminal imprimir a saída do próprio comando
func _falar(linhas: Array) -> void:
	_escrever_no_terminal.bind(linhas).call_deferred()

func _escrever_no_terminal(linhas: Array) -> void:
	var ui = get_tree().get_first_node_in_group("terminal_ui")
	if ui == null:
		return
	for linha in linhas:
		ui.escrever_no_terminal(PREFIXO_TERMINAL + str(linha))

# Frase curta com o próximo passo, no formato de fala do terminal
func _proximo_passo_terminal(estado: String, forcar_comando: bool = false) -> String:
	var faltam := _faltam_coletar()
	var detalhado := forcar_comando or _detalhado()
	match estado:
		"coletar":
			return "Ainda não há nada para registrar: faltam os arquivos %s. Pegue-os no mapa e volte aqui (T)." % _lista(faltam)
		"init":
			return "Para começar, digite %s." % _cmd("git init")
		"status":
			return "Agora olhe a sala: digite %s." % _cmd("git status")
		"add":
			return "Separe um arquivo na caixa: %s." % _cmd("git add " + _arquivo_exemplo())
		"commit":
			if not detalhado:
				return "A caixa está pronta. Lembra como se tira a foto?"
			return "Hora de tirar a foto: %s." % _cmd("git commit -m \"minha mensagem\"")
		"coletar_resto":
			if not detalhado:
				return "Ainda faltam os arquivos %s. Pegue-os no mapa e repita o ciclo que você já conhece." % _lista(faltam)
			return "Ainda faltam os arquivos %s. Pegue-os no mapa, volte aqui e repita %s e %s." % [_lista(faltam), _cmd("git add"), _cmd("git commit")]
		"add_resto":
			if not detalhado:
				return "Há arquivos novos na sala. Você já sabe o que fazer: separe-os na caixa e registre. (Em dúvida, %s.)" % _cmd("git help")
			return "Há arquivos novos na sala. Repita o ciclo: %s e depois %s." % [_cmd("git add ."), _cmd("git commit -m \"mensagem\"")]
		"concluido":
			return "Tudo registrado! Saia do terminal e vá até o portal de saída (ele acendeu)."
	return ""

# ---------------------------------------------------------------------------
# Reações aos eventos do jogo
# ---------------------------------------------------------------------------

func _on_arquivo_coletado(nome: String) -> void:
	_atualizar_quadro()
	# Itens que não fazem parte do repositório (ex.: a chave) não geram fala da IA
	if not nome in arquivos_requeridos:
		return

	var faltam := _faltam_coletar()
	if faltam.is_empty():
		if GameState.commits.is_empty():
			_dizer("Achou todos os arquivos! Agora vá até o Obelisco de Dados e aperte T.")
		else:
			_dizer("Achou o %s! Leve-o ao terminal (T) para registrá-lo." % _cmd(nome))
	else:
		_dizer("Achou o %s! Ainda falta: %s." % [_cmd(nome), _lista(faltam)])

func _on_terminal_aberto() -> void:
	_terminal_aberto = true
	if _balao_tween:
		_balao_tween.kill()
	_balao.hide()

	var linhas: Array = []
	if _primeira_vez("terminal"):
		linhas.append("Este é o terminal: é por aqui que a gente \"conversa\" com o Git, digitando comandos.")
		linhas.append("Ele funciona como um caderno que guarda o histórico do projeto. Vamos preenchê-lo juntos, um passo de cada vez.")
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()

# Ao sair do terminal a fala não pausa nada: um balão curto lembra do próximo passo
func _on_terminal_fechado() -> void:
	_terminal_aberto = false
	_dizer(_texto_balao_para(_estado()))

# `git help`: conta como dica pedida e a IA devolve o próximo passo com o comando completo
func _on_ajuda_pedida() -> void:
	var tutoria := GameState.progresso_tutoria
	tutoria["dicas_usadas"] += 1
	_falar(["Essa é a lista. E agora? " + _proximo_passo_terminal(_estado(), true)])
	_atualizar_quadro()

func _on_repositorio_inicializado() -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	_falar([
		"Boa! O %s criou o %s: o caderno de registros desta pasta. Daqui em diante o Git passa a observar o que acontece aqui." % [_cmd("git init"), _conceito("repositório")],
		"Mas ele ainda não registrou nada. Para ver como está a sala, digite %s." % _cmd("git status"),
	])
	_atualizar_quadro()

func _on_status_consultado(tinha_staging: bool, tinha_nao_rastreados: bool) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	GameState.progresso_tutoria["status_visto"] = true
	var primeira := _primeira_vez("status")
	var linhas: Array = []

	if tinha_nao_rastreados and not tinha_staging:
		if primeira:
			linhas.append("O %s é o seu olhar sobre a sala. Em vermelho estão os arquivos %s: eles estão na pasta, mas o Git ainda não sabe deles." % [_cmd("git status"), _conceito("não rastreados (untracked)")])
			linhas.append("Para o Git registrá-los, primeiro separe-os numa caixa chamada %s: %s." % [_conceito("staging area"), _cmd("git add " + _arquivo_exemplo())])
		else:
			linhas.append("Em vermelho: arquivos não rastreados. Separe-os com %s." % _cmd("git add " + _arquivo_exemplo()))
	elif tinha_staging:
		if primeira:
			linhas.append("Em verde, em \"prontas para o commit\", estão os arquivos que já estão na caixa (%s)." % _conceito("staging area"))
		if tinha_nao_rastreados:
			linhas.append("Ainda há arquivos em vermelho, fora da caixa. Adicione-os também, ou registre só o que já está pronto.")
		linhas.append("Quando a caixa estiver como você quer, tire a foto: %s." % _cmd("git commit -m \"mensagem\""))
	else:
		if GameState.commits.is_empty():
			linhas.append("Não há nada para registrar: a sala está vazia. O terminal só enxerga arquivos que você já coletou no mapa. Pegue-os e volte aqui.")
		else:
			linhas.append("%s: tudo o que o Git acompanha já está registrado. É assim que a sala deve ficar no fim." % _conceito("working tree limpa"))
			var proxima := _proximo_passo_terminal(_estado())
			if not proxima.is_empty():
				linhas.append(proxima)

	_falar(linhas)
	_atualizar_quadro()

func _on_arquivos_preparados(nomes: Array[String]) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("add"):
		linhas.append("Feito! %s agora está na %s: a caixa onde você separa o que vai entrar no próximo registro." % [_lista(nomes), _conceito("staging area")])
		linhas.append("Rode %s de novo: o que estava em vermelho agora aparece em verde." % _cmd("git status"))
	else:
		linhas.append("Na caixa: %s." % _lista(nomes))

	if not GameState.working_directory.is_empty():
		linhas.append("Ainda restam fora da caixa: %s. Adicione-os também, ou use %s para todos de uma vez." % [_lista(GameState.working_directory), _cmd("git add .")])
	else:
		linhas.append("Quando estiver pronto, tire a foto: %s." % _cmd("git commit -m \"mensagem\""))

	_falar(linhas)
	_atualizar_quadro()

func _on_commit_realizado(info: Dictionary) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var arquivos: Array = info.get("arquivos", [])
	var linhas: Array = []

	if _primeira_vez("commit"):
		linhas.append("Pronto! Você tirou a foto: o %s é um save point permanente com os arquivos que estavam na caixa (%s)." % [_conceito("commit"), _lista(arquivos)])
		linhas.append("A mensagem \"%s\" diz o que essa foto guarda. Mensagens claras ajudam a lembrar, mais tarde, por que o registro foi feito." % str(info.get("mensagem", "")).replace("[", "[lb]"))
	else:
		linhas.append("Novo save point criado com %s." % _lista(arquivos))

	var pendentes := GameState.arquivos_pendentes(arquivos_requeridos)
	if pendentes.is_empty():
		linhas.append("Todos os arquivos estão registrados: a sala está consertada! A saída foi liberada. Saia do terminal (Esc) e vá até ela.")
	else:
		linhas.append("Mas a saída só abre quando TODOS os arquivos estiverem registrados. Faltam: %s." % _lista(pendentes))
		linhas.append(_proximo_passo_terminal(_estado()))

	# Primeiro ciclo completo: a partir daqui a IA retira o apoio e fala só o objetivo
	GameState.progresso_tutoria["nivel_explicacao"] = "breve"

	_falar(linhas)
	_atualizar_quadro()

func _on_comando_falhou(comando: String, motivo: String) -> void:
	var tutoria := GameState.progresso_tutoria
	tutoria["erros_consecutivos"] += 1

	var linhas: Array = [_explicar_falha(comando, motivo)]

	if motivo == GameState.FALHA_COMANDO_BLOQUEADO:
		# Não é erro de compreensão: o comando só ainda não foi apresentado. Redireciona direto.
		linhas.append(_proximo_passo_terminal(_estado(), true))
		tutoria["erros_consecutivos"] = 0
	elif tutoria["erros_consecutivos"] >= FALHAS_PARA_AJUDA_DIRETA:
		# Andaime: 1ª falha = pista conceitual; falhas seguidas = resposta direta
		tutoria["ajudas_automaticas"] += 1
		linhas.append("Calma, vamos juntos. " + _proximo_passo_terminal(_estado(), true))

	_falar(linhas)
	_atualizar_quadro()

func _explicar_falha(comando: String, motivo: String) -> String:
	# if/elif em vez de match: as constantes FALHA_* vêm do autoload, que não vale como padrão de match
	if motivo == GameState.FALHA_SEM_REPOSITORIO:
		return "O Git ainda não está acompanhando esta pasta. Antes de qualquer outro comando, ele precisa ser iniciado."
	if motivo == GameState.FALHA_ARQUIVO_INEXISTENTE:
		return "Esse nome não está entre os arquivos soltos da sala. O %s lista os nomes certos (e só mostra o que você já coletou no mapa)." % _cmd("git status")
	if motivo == GameState.FALHA_JA_NA_STAGING:
		return "Esse arquivo já está na caixa (staging area). Use %s para ver o que ainda falta." % _cmd("git status")
	if motivo == GameState.FALHA_JA_VERSIONADO:
		return "Esse arquivo já foi registrado num commit. O Git só pede um novo %s se ele mudar ou se aparecerem arquivos novos." % _cmd("git add")
	if motivo == GameState.FALHA_NADA_PARA_ADICIONAR:
		return "Não há arquivos soltos para adicionar: tudo o que você coletou já está na caixa ou já foi registrado. Confira com %s." % _cmd("git status")
	if motivo == GameState.FALHA_STAGING_VAZIA:
		return "O commit tira a foto só do que está na caixa (staging area), e ela está vazia. Primeiro separe arquivos com %s." % _cmd("git add")
	if motivo == GameState.FALHA_USO_INCORRETO:
		if comando == "add":
			return "O %s precisa saber o que separar: o nome do arquivo (ou um ponto, para todos)." % _cmd("git add")
		if comando == "commit":
			return "O %s precisa de uma mensagem entre aspas dizendo o que a foto guarda: %s." % [_cmd("git commit"), _cmd("-m \"texto\"")]
		return "Esse comando precisa de mais informações. Veja o exemplo no quadro."
	if motivo == GameState.FALHA_COMANDO_BLOQUEADO:
		return "Calma, o %s ainda não entrou na história. Um passo de cada vez para ficar bem entendido." % _cmd("git " + comando)
	if motivo == GameState.FALHA_COMANDO_INDISPONIVEL:
		return "Esse comando existe no Git, mas ainda não é hora dele. Foque nos passos do quadro."
	if motivo == GameState.FALHA_COMANDO_INEXISTENTE:
		return "Não reconheci esse comando. Veja no quadro os que já usamos."
	if motivo == GameState.FALHA_NAO_E_GIT:
		return "Aqui só funcionam comandos do Git, e todos começam com a palavra %s." % _cmd("git")
	return "Algo não saiu como esperado. Veja o quadro para o próximo passo."

# ---------------------------------------------------------------------------
# Quadro da IA (HUD)
# ---------------------------------------------------------------------------

func _montar_quadro() -> void:
	_raiz = Control.new()
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	get_viewport().size_changed.connect(_ajustar_raiz)
	_ajustar_raiz()

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.784)
	estilo.border_color = Color(COR_IA)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(4)
	estilo.set_content_margin_all(5)

	_painel = PanelContainer.new()
	_painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_painel.add_theme_stylebox_override("panel", estilo)
	_painel.anchor_left = 1.0
	_painel.anchor_right = 1.0
	_painel.offset_left = -(LARGURA_QUADRO + MARGEM)
	_painel.offset_right = -MARGEM
	_painel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_raiz.add_child(_painel)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 3)
	_painel.add_child(coluna)

	coluna.add_child(_criar_titulo("IA - PRÓXIMO PASSO"))
	coluna.add_child(HSeparator.new())
	_texto_passo = _criar_texto()
	coluna.add_child(_texto_passo)

	_separador_comandos = HSeparator.new()
	coluna.add_child(_separador_comandos)
	_titulo_comandos = _criar_titulo("COMANDOS")
	coluna.add_child(_titulo_comandos)
	_texto_comandos = _criar_texto()
	coluna.add_child(_texto_comandos)

	_montar_balao()

	_reposicionar()

# Balão de fala não bloqueante: aparece no topo, some sozinho e não pausa o jogo
func _montar_balao() -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.85)
	estilo.border_color = Color(COR_IA)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(4)
	estilo.set_content_margin_all(4)

	_balao = PanelContainer.new()
	_balao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balao.add_theme_stylebox_override("panel", estilo)
	_balao.anchor_left = 0.5
	_balao.anchor_right = 0.5
	_balao.offset_left = -LARGURA_BALAO / 2.0
	_balao.offset_right = LARGURA_BALAO / 2.0
	_balao.offset_top = MARGEM
	_balao.offset_bottom = MARGEM
	_balao.hide()
	_raiz.add_child(_balao)

	_texto_balao = _criar_texto()
	_texto_balao.custom_minimum_size.x = LARGURA_BALAO - 8.0
	_balao.add_child(_texto_balao)

func _dizer(texto: String) -> void:
	# Com o terminal aberto, a fala vai para o histórico do terminal (não para o balão)
	if _terminal_aberto or texto.is_empty():
		return
	_texto_balao.text = "[color=%s]IA:[/color] %s" % [COR_IA, texto]
	_balao.modulate.a = 1.0
	_balao.show()
	if _balao_tween:
		_balao_tween.kill()
	_balao_tween = create_tween()
	_balao_tween.tween_interval(maxf(DURACAO_MINIMA_BALAO, texto.length() / CARACTERES_POR_SEGUNDO))
	_balao_tween.tween_property(_balao, "modulate:a", 0.0, 0.5)
	_balao_tween.tween_callback(_balao.hide)

func _texto_balao_para(estado: String) -> String:
	match estado:
		"coletar":
			return "Pegue os arquivos soltos pela sala. Faltam: %s." % _lista(_faltam_coletar())
		"coletar_resto":
			return "Faltam arquivos: %s. Pegue-os no mapa." % _lista(_faltam_coletar())
		"concluido":
			return "Saída liberada! Vá até o portal de saída, que acendeu."
	return "O próximo passo está no quadro. Volte ao Obelisco (T) quando quiser."

func _criar_titulo(texto: String) -> Label:
	var titulo := Label.new()
	titulo.text = texto
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", FONTE)
	titulo.add_theme_font_size_override("font_size", 5)
	titulo.add_theme_color_override("font_color", Color(COR_IA))
	return titulo

func _criar_texto() -> RichTextLabel:
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.scroll_active = false
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.custom_minimum_size.x = LARGURA_QUADRO - 10.0
	texto.add_theme_font_override("normal_font", FONTE)
	texto.add_theme_font_size_override("normal_font_size", TAMANHO_FONTE)
	return texto

# Filhos de CanvasLayer precisam de um Control raiz com o tamanho do viewport
func _ajustar_raiz() -> void:
	_raiz.position = Vector2.ZERO
	_raiz.size = get_viewport().get_visible_rect().size

# O quadro fica no canto superior direito (o painel de objetivos antigo foi removido)
func _reposicionar() -> void:
	_painel.offset_top = MARGEM
	_painel.offset_bottom = MARGEM

func _atualizar_quadro() -> void:
	_sincronizar_comandos()
	var estado := _estado()
	_texto_passo.text = _texto_do_quadro(estado)

	var comandos := _comandos_revelados(estado)
	var tem_comandos := not comandos.is_empty()
	_separador_comandos.visible = tem_comandos
	_titulo_comandos.visible = tem_comandos
	_texto_comandos.visible = tem_comandos
	_texto_comandos.text = "\n".join(comandos)

	if _estado_anterior != "" and estado != _estado_anterior:
		_piscar()
	_estado_anterior = estado
	_reposicionar.call_deferred()

func _texto_do_quadro(estado: String) -> String:
	var faltam := _faltam_coletar()
	var pendentes := GameState.arquivos_pendentes(arquivos_requeridos)
	match estado:
		"coletar":
			return "Colete os arquivos soltos pela sala:\n%s\nDepois aperte T perto do Obelisco de Dados." % _lista(faltam)
		"init":
			var texto := "Vá ao terminal (T) e digite:\n%s\nEle abre o caderno de registros." % _cmd("git init")
			if not faltam.is_empty():
				texto += "\n(Ainda faltam: %s)" % _lista(faltam)
			return texto
		"status":
			return "Veja como está a sala:\n%s" % _cmd("git status")
		"add":
			return "Separe um arquivo na caixa:\n%s\nOu %s para todos." % [_cmd("git add " + _arquivo_exemplo()), _cmd("git add .")]
		"commit":
			if not _detalhado():
				return "A caixa está pronta.\nFalta tirar a foto."
			return "Tire a foto (save point):\n%s" % _cmd("git commit -m \"mensagem\"")
		"coletar_resto":
			if not _detalhado():
				return "Faltam arquivos: %s\nPegue-os e repita o ciclo." % _lista(faltam)
			return "Faltam arquivos: %s\nPegue-os e repita add + commit." % _lista(faltam)
		"add_resto":
			if not _detalhado():
				return "Há arquivos novos: %s\nRegistre-os no terminal. (git help ajuda)" % _lista(pendentes)
			return "Há arquivos novos: %s\nNo terminal: %s e %s." % [_lista(pendentes), _cmd("git add ."), _cmd("git commit")]
		"concluido":
			return "Tudo registrado!\nVá até o portal de saída, que acendeu."
	return ""

# Cola dos comandos: só os que já foram liberados (menos para memorizar)
func _comandos_revelados(estado: String) -> Array[String]:
	var linhas: Array[String] = []
	if "init" in GameState.comandos_liberados and estado != "coletar":
		linhas.append("%s: abre o caderno" % _cmd("git init"))
	if "status" in GameState.comandos_liberados:
		linhas.append("%s: mostra a sala e a caixa" % _cmd("git status"))
	if "add" in GameState.comandos_liberados:
		linhas.append("%s: põe na caixa" % _cmd("git add nome"))
	if "commit" in GameState.comandos_liberados:
		linhas.append("%s: tira a foto" % _cmd("git commit -m \"msg\""))
	if not linhas.is_empty():
		linhas.append("%s: lista os comandos" % _cmd("git help"))
	return linhas

func _piscar() -> void:
	if _piscar_tween:
		_piscar_tween.kill()
	_painel.modulate = Color(1.7, 1.7, 1.0)
	_piscar_tween = create_tween()
	_piscar_tween.tween_property(_painel, "modulate", Color.WHITE, 0.6)

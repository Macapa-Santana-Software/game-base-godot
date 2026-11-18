class_name ModeloConflito extends Node
## Fase 5 — "Linhas Cruzadas": o merge COM CONFLITO.
##
## O GameState ainda não guarda o conteúdo dos arquivos nem sabe o que é um conflito, e ele
## não deve ser alterado agora. Por isso esta fase tem o seu próprio mini-merge, no mesmo
## espírito do ModeloMural (Fase 3): a cena tem este nó e os comandos do terminal (merge,
## status, diff, add, commit) falam com ele através de ModeloConflito.ativo(). Sem ele na
## cena (as outras fases) os comandos seguem o GameState como sempre.
##
## Cenário: a main (a linha do jogador) e a branch `ajuste` (outra equipe) partiram da mesma
## versão. As duas mudaram `selo.runa` para cores diferentes (CONFLITO) e só a `ajuste`
## mudou `porta.runa` (o Git junta sozinho).
##
## Estados (um só fluxo): pre -> conflito -> resolvido -> preparado -> concluido
##   pre         nada foi tentado ainda
##   conflito    `git merge ajuste` parou: selo.runa tem marcadores <<<<<<< ======= >>>>>>>
##   resolvido   o jogador escolheu o lado (no mundo); o arquivo está limpo, mas o Git não sabe
##   preparado   `git add selo.runa` marcou o conflito como resolvido
##   concluido   `git commit` fechou o merge
## `git merge --abort` volta para `pre` de qualquer estado intermediário.
##
## O estado fica em GameState.progresso_tutoria["conflito"] (sobrevive a recarregar a cena
## por derrota e é zerado junto com o resto da fase em reset_fase()).

signal mudou
signal status_executado
signal merge_tentado
signal diff_executado
signal escolha_feita(lado: String)
signal conflito_preparado
signal merge_concluido
signal merge_abortado

const GRUPO := &"conflito_modelo"
const CHAVE := "conflito"

const BRANCH := "ajuste"
const ARQUIVO := "selo.runa"
const ARQUIVO_AUTO := "porta.runa"

const COR_BASE := "prata"
const COR_MAIN := "dourado"
const COR_AJUSTE := "azul"

const LADO_MINHA := "minha"
const LADO_DELES := "deles"
const LADO_AMBAS := "ambas"

const PRE := "pre"
const CONFLITO := "conflito"
const RESOLVIDO := "resolvido"
const PREPARADO := "preparado"
const CONCLUIDO := "concluido"

const FALHA_MERGE_EM_ANDAMENTO := "merge_em_andamento"
const FALHA_SEM_MERGE := "sem_merge"
const FALHA_CONFLITO_ABERTO := "conflito_aberto"

var _estado: Dictionary = {}


## O modelo da cena atual, ou null se a fase não tem conflito (todas as outras).
static func ativo() -> ModeloConflito:
	var arvore := Engine.get_main_loop() as SceneTree
	if arvore == null:
		return null
	return arvore.get_first_node_in_group(GRUPO) as ModeloConflito


func _enter_tree() -> void:
	add_to_group(GRUPO)
	if not GameState.progresso_tutoria.has(CHAVE):
		GameState.progresso_tutoria[CHAVE] = {"estado": PRE, "escolha": "", "flags": {}}
	_estado = GameState.progresso_tutoria[CHAVE]


# ---------------------------------------------------------------------------
# Consultas
# ---------------------------------------------------------------------------

func estado() -> String:
	return str(_estado["estado"])


func escolha() -> String:
	return str(_estado["escolha"])


func flag(chave: String) -> bool:
	return bool(_estado["flags"].get(chave, false))


func _marcar(chave: String) -> void:
	_estado["flags"][chave] = true


func em_merge() -> bool:
	return estado() in [CONFLITO, RESOLVIDO, PREPARADO]


## O jogador pode (re)escolher o lado agora? Só com o conflito aberto e antes do `git add`.
func pode_escolher() -> bool:
	return estado() in [CONFLITO, RESOLVIDO]


func porta_mesclada() -> bool:
	return estado() != PRE


## Nome da cor do arquivo resolvido ("" se ainda não escolheu).
func texto_resultado() -> String:
	match escolha():
		LADO_MINHA:
			return COR_MAIN
		LADO_DELES:
			return COR_AJUSTE
		LADO_AMBAS:
			return "%s + %s" % [COR_MAIN, COR_AJUSTE]
	return ""


# ---------------------------------------------------------------------------
# Escolha feita no mundo (pedestais)
# ---------------------------------------------------------------------------

func escolher(lado: String) -> void:
	if not pode_escolher():
		return
	_estado["escolha"] = lado
	_estado["estado"] = RESOLVIDO
	_marcar("escolheu")
	escolha_feita.emit(lado)
	mudou.emit()


# ---------------------------------------------------------------------------
# Comandos
# ---------------------------------------------------------------------------

func texto_status() -> String:
	var linhas: Array[String] = ["[color=#3DA9FF]## No branch %s[/color]" % GameState.branch_ativa]
	match estado():
		PRE:
			linhas.append("\nNada para atualizar, working tree limpa.")
			linhas.append("[color=#8AA0B8]A outra equipe tem novidades na branch '%s'. Para trazê-las: git merge %s[/color]" % [BRANCH, BRANCH])
		CONFLITO, RESOLVIDO:
			linhas.append("\n[color=#FFCC00]Você está no meio de um merge (há caminhos não mesclados).[/color]")
			linhas.append("[color=#8AA0B8]  (corrija os conflitos e depois git add e git commit; ou desista com git merge --abort)[/color]")
			linhas.append("\nMudanças prontas para o commit:")
			linhas.append("\t[color=#3DFF9B]modified:   %s[/color]" % ARQUIVO_AUTO)
			linhas.append("\nCaminhos não mesclados (unmerged paths):")
			linhas.append("\t[color=#FF6B6B]both modified:   %s[/color]" % ARQUIVO)
			if estado() == RESOLVIDO:
				linhas.append("\n[color=#8AA0B8]Você já escolheu o lado, mas o Git ainda não sabe: git add %s[/color]" % ARQUIVO)
		PREPARADO:
			linhas.append("\n[color=#FFCC00]Todos os conflitos foram resolvidos, mas o merge ainda não foi concluído.[/color]")
			linhas.append("\nMudanças prontas para o commit:")
			linhas.append("\t[color=#3DFF9B]modified:   %s[/color]" % ARQUIVO_AUTO)
			linhas.append("\t[color=#3DFF9B]modified:   %s[/color]" % ARQUIVO)
		CONCLUIDO:
			linhas.append("\nNada para atualizar, working tree limpa.")
			linhas.append("[color=#8AA0B8]O merge foi concluído: a '%s' está integrada na main.[/color]" % BRANCH)
	_marcar("status_visto")
	status_executado.emit()
	mudou.emit()
	return "\n".join(linhas)


func texto_diff(args: Array[String]) -> String:
	for arg in args:
		if arg == "--staged" or arg == "--cached":
			continue
		if arg.begins_with("-"):
			return GameState.registrar_falha("diff", GameState.FALHA_USO_INCORRETO,
				"[color=#FF6B6B]Erro: opção '%s' não reconhecida. Use: git diff [<arquivo>][/color]" % arg.replace("[", "[lb]"))
		if arg != ARQUIVO and arg != ARQUIVO_AUTO and arg != ARQUIVO.get_basename() and arg != ARQUIVO_AUTO.get_basename():
			return GameState.registrar_falha("diff", GameState.FALHA_ARQUIVO_INEXISTENTE,
				"[color=#FFCC00]Erro: '%s' não é uma runa daqui. Veja os nomes com git status.[/color]" % arg.replace("[", "[lb]"))

	var linhas: Array[String] = []
	match estado():
		PRE:
			return "[color=#8AA0B8]Nenhuma diferença: ainda não há merge em andamento.[/color]"
		CONFLITO:
			linhas.append("[color=#FFE08A]diff --cc %s[/color]" % ARQUIVO)
			linhas.append("[color=#FF2BD6]<<<<<<< HEAD (main, a sua versão)[/color]")
			linhas.append("[color=#E8B84A]cor: %s[/color]" % COR_MAIN)
			linhas.append("[color=#FF2BD6]=======[/color]")
			linhas.append("[color=#6FA0FF]cor: %s[/color]" % COR_AJUSTE)
			linhas.append("[color=#FF2BD6]>>>>>>> %s (a versão da outra equipe)[/color]" % BRANCH)
			linhas.append("\n[color=#8AA0B8]Entre <<<<<<< e ======= está a SUA versão; entre ======= e >>>>>>> está a DELES. O Git não decide por você.[/color]")
			_marcar("diff_conflito")
		RESOLVIDO, PREPARADO:
			linhas.append("[color=#FFE08A]diff --cc %s[/color]" % ARQUIVO)
			linhas.append("[color=#FF6B6B]-<<<<<<< HEAD / ======= / >>>>>>> %s (marcadores removidos)[/color]" % BRANCH)
			linhas.append("[color=#3DFF9B]+cor: %s[/color]" % texto_resultado())
			_marcar("diff_conflito")
		CONCLUIDO:
			return "[color=#8AA0B8]Nenhuma diferença: o merge já foi concluído.[/color]"
	diff_executado.emit()
	mudou.emit()
	return "\n".join(linhas)


func mesclar(args: Array[String]) -> String:
	if args.size() != 1:
		return GameState.registrar_falha("merge", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git merge <branch>   ou   git merge --abort[/color]")

	if args[0] == "--abort":
		if not em_merge():
			return GameState.registrar_falha("merge", FALHA_SEM_MERGE,
				"[color=#FFCC00]merge: não há nenhum merge em andamento para abortar.[/color]")
		_estado["estado"] = PRE
		_estado["escolha"] = ""
		_marcar("abortou")
		merge_abortado.emit()
		mudou.emit()
		return "[color=#3DFF9B]Merge abortado: tudo voltou ao estado de antes de 'git merge %s'. Nada foi perdido.[/color]" % BRANCH

	if args[0] != BRANCH:
		if args[0] == GameState.branch_ativa:
			return GameState.registrar_falha("merge", GameState.FALHA_MESMA_BRANCH,
				"[color=#FF6B6B]merge: não dá para integrar a branch '%s' nela mesma.[/color]" % args[0].replace("[", "[lb]"))
		return GameState.registrar_falha("merge", GameState.FALHA_BRANCH_INEXISTENTE,
			"[color=#FF6B6B]merge: '%s' não é algo que possamos integrar. A branch da outra equipe se chama '%s'.[/color]" % [args[0].replace("[", "[lb]"), BRANCH])

	match estado():
		CONCLUIDO:
			return "Already up to date. '%s' já está integrada na main." % BRANCH
		CONFLITO, RESOLVIDO, PREPARADO:
			return GameState.registrar_falha("merge", FALHA_MERGE_EM_ANDAMENTO,
				"[color=#FFCC00]merge: você já está no meio de um merge. Resolva o conflito (ou use git merge --abort).[/color]")

	_estado["estado"] = CONFLITO
	_marcar("merge_tentado")
	merge_tentado.emit()
	mudou.emit()
	return "Auto-merging %s\n[color=#3DFF9B]%s mesclado sozinho (só a outra equipe mexeu nele).[/color]\nAuto-merging %s\n[color=#FF6B6B]CONFLICT (content): Merge conflict in %s[/color]\n[color=#FFCC00]Automatic merge failed; fix conflicts and then commit the result.[/color]" % [ARQUIVO_AUTO, ARQUIVO_AUTO, ARQUIVO, ARQUIVO]


func adicionar(args: Array[String]) -> String:
	if args.is_empty():
		return GameState.registrar_falha("add", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git add <arquivo>   ou   git add .[/color]")
	for arg in args:
		if arg in [".", "-A", "--all", ARQUIVO, ARQUIVO.get_basename()]:
			continue
		if arg == ARQUIVO_AUTO or arg == ARQUIVO_AUTO.get_basename():
			continue
		return GameState.registrar_falha("add", GameState.FALHA_ARQUIVO_INEXISTENTE,
			"[color=#FFCC00]Erro: '%s' não é uma runa daqui. Veja os nomes com git status.[/color]" % arg.replace("[", "[lb]"))

	match estado():
		PRE, CONCLUIDO:
			return GameState.registrar_falha("add", GameState.FALHA_NADA_PARA_ADICIONAR,
				"[color=#FFCC00]Nada para adicionar: não há conflito para marcar como resolvido.[/color]")
		CONFLITO:
			return GameState.registrar_falha("add", FALHA_CONFLITO_ABERTO,
				"[color=#FF6B6B]%s ainda tem marcadores de conflito (<<<<<<<). Escolha como resolver, nos pedestais do mundo, e só depois use git add.[/color]" % ARQUIVO)
		PREPARADO:
			return GameState.registrar_falha("add", GameState.FALHA_JA_NA_STAGING,
				"[color=#FFCC00]%s já está marcado como resolvido. Falta o git commit.[/color]" % ARQUIVO)

	_estado["estado"] = PREPARADO
	_marcar("add_feito")
	conflito_preparado.emit()
	mudou.emit()
	return "[color=#3DFF9B]Conflito resolvido em %s (cor: %s). Pronto para o commit.[/color]" % [ARQUIVO, texto_resultado()]


func commitar(args: Array[String]) -> String:
	if args.size() < 2 or args[0] != "-m":
		return GameState.registrar_falha("commit", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git commit -m \"sua mensagem aqui\"[/color]")
	if args.size() > 2:
		return GameState.registrar_falha("commit", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: argumentos demais. A mensagem do commit deve estar entre aspas duplas.[/color]")

	match estado():
		PRE, CONCLUIDO:
			return GameState.registrar_falha("commit", GameState.FALHA_STAGING_VAZIA,
				"Nada para fazer commit: não há merge em andamento.")
		CONFLITO, RESOLVIDO:
			return GameState.registrar_falha("commit", FALHA_CONFLITO_ABERTO,
				"[color=#FF6B6B]Não dá para fechar o merge: ainda há caminhos não mesclados (%s). Resolva e marque com git add.[/color]" % ARQUIVO)

	# Registra também no repositório real (o histórico do jogo), sem tocar na lógica dele.
	GameState.git_inicializado = true
	GameState.staging_area.append(ARQUIVO_AUTO)
	GameState.staging_area.append(ARQUIVO)
	var resposta := GameState.criar_commit(args[1], {
		ARQUIVO: "cor: %s" % texto_resultado(),
		ARQUIVO_AUTO: "mesclado automaticamente",
	})
	_estado["estado"] = CONCLUIDO
	_marcar("concluido")
	merge_concluido.emit()
	mudou.emit()
	return "[color=#3DFF9B]Merge '%s' concluído na main.[/color]\n%s" % [BRANCH, resposta]

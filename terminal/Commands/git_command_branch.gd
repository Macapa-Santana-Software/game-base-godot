class_name GitCommand_Branch extends GitCommand
## `git branch`          lista as branches (a ativa marcada com `*`).
## `git branch <nome>`   cria a branch no commit atual. NÃO troca de branch.

const COR_ATIVA := "#3DFF9B"

func execute(args: Array[String], _raw_input: String) -> String:
	if args.size() > 1:
		return GameState.registrar_falha("branch", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git branch [<nome>][/color]")
	if args.is_empty():
		return _listar()
	var resultado := GameState.criar_branch(args[0])
	if resultado["ok"]:
		return "%s\nVocê continua em '%s'. Use 'git switch %s' para mudar de branch." % [
			resultado["mensagem"], GameState.branch_ativa, args[0]]
	return resultado["mensagem"]

func _listar() -> String:
	if not GameState.git_inicializado:
		return GameState.registrar_falha("branch", GameState.FALHA_SEM_REPOSITORIO, GameState.MSG_NAO_E_REPOSITORIO)
	var linhas: Array[String] = []
	var nomes := GameState.listar_branches()
	if GameState.branch_ativa not in nomes:
		nomes.push_front(GameState.branch_ativa)  # ainda sem commits: existe, mas não nasceu
	for nome in nomes:
		if nome == GameState.branch_ativa:
			linhas.append("[color=%s]* %s[/color]" % [COR_ATIVA, nome])
		else:
			linhas.append("  %s" % nome)
	return "\n".join(linhas)

class_name AtlasLayout extends RefCounted
## Calcula o desenho do Atlas A PARTIR DO GameState. Não guarda nem inventa histórico:
## recebe os dados reais e devolve posições lógicas (coluna, faixa). Sem nenhum desenho,
## para poder ser testado sozinho.
##
## Resultado de `calcular()`:
##   nos         [ { id, mensagem, arquivos, pais, coluna, faixa, branch, merge, head } ]
##   faixas      [ { branch, indice, tem_commits_proprios } ]   (uma por branch, main primeiro)
##   ligacoes    [ { de, para } ]  de = pai, para = filho (o merge tem duas)
##   tags        [ { branch, no, faixa, fantasma, ativa } ]  etiqueta de cada branch; `fantasma`
##               = a branch ainda não tem commit próprio (aponta para um nó de outra faixa)
##   branch_ativa, head_no
##
## Faixa de cada commit: segue a cadeia do PRIMEIRO pai a partir do head de cada branch,
## começando por `main` e depois pelas demais na ordem de criação. Como o commit não sabe
## a que branch pertence, é isso que mantém os commits de vida-alternativa na faixa dela
## mesmo depois que o merge faz `main` alcançá-los.


static func calcular() -> Dictionary:
	var nomes: Array[String] = GameState.listar_branches()
	# main sempre primeiro; as demais na ordem de criação.
	if GameState.BRANCH_PADRAO in nomes:
		nomes.erase(GameState.BRANCH_PADRAO)
		nomes.push_front(GameState.BRANCH_PADRAO)

	# Commits visíveis: todos os alcançáveis de alguma branch, em ordem de criação.
	var visiveis: Dictionary = {}
	for nome in nomes:
		for commit in GameState.historico(nome):
			visiveis[commit["id"]] = commit
	var colunas: Dictionary = {}
	var ordenados: Array[Dictionary] = []
	for commit in GameState.commits:
		if visiveis.has(commit["id"]):
			colunas[commit["id"]] = ordenados.size()
			ordenados.append(commit)

	# Faixa de cada commit pela cadeia do primeiro pai.
	var faixa_de: Dictionary = {}
	var dono: Dictionary = {}
	for indice in nomes.size():
		var id := GameState.obter_head(nomes[indice])
		while not id.is_empty() and not faixa_de.has(id) and visiveis.has(id):
			faixa_de[id] = indice
			dono[id] = nomes[indice]
			var pais := GameState.pais_de(visiveis[id])
			id = pais[0] if not pais.is_empty() else ""

	var nos: Array[Dictionary] = []
	var ligacoes: Array[Dictionary] = []
	for commit in ordenados:
		var id: String = commit["id"]
		var pais := GameState.pais_de(commit)
		nos.append({
			"id": id, "mensagem": commit["mensagem"], "arquivos": commit["arquivos"],
			"pais": pais, "coluna": colunas[id], "faixa": faixa_de.get(id, 0),
			"branch": dono.get(id, GameState.BRANCH_PADRAO), "merge": pais.size() > 1,
			"head": id == GameState.obter_head(),
		})
		for pai in pais:
			if visiveis.has(pai):
				ligacoes.append({"de": pai, "para": id})

	var faixas: Array[Dictionary] = []
	var tags: Array[Dictionary] = []
	for indice in nomes.size():
		var nome := nomes[indice]
		var head := GameState.obter_head(nome)
		var proprios := false
		for no in nos:
			if no["faixa"] == indice:
				proprios = true
				break
		faixas.append({"branch": nome, "indice": indice, "tem_commits_proprios": proprios})
		tags.append({
			"branch": nome, "no": head, "faixa": indice,
			"fantasma": faixa_de.get(head, indice) != indice,
			"ativa": nome == GameState.branch_ativa,
		})

	# A branch ativa pode ainda não ter nascido (sem commits): sem nó para o HEAD.
	return {
		"nos": nos, "faixas": faixas, "ligacoes": ligacoes, "tags": tags,
		"branch_ativa": GameState.branch_ativa, "head_no": GameState.obter_head(),
	}

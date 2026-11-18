extends Node

# Sinal que avisa os scripts de fase quando um commit foi concluído
signal commit_realizado(commit_info: Dictionary)

# Sinal que avisa quando o jogador coleta um arquivo no mapa (ex.: objetivos)
signal arquivo_coletado(nome_arquivo: String)

# Sinais "semânticos" para a tutora (IA) reagir ao que o jogador FEZ no terminal.
# Só são emitidos quando o comando tem efeito real; erros não geram sinal.
# Emitido apenas no primeiro `git init` bem-sucedido.
signal repositorio_inicializado
# Emitido por `git status` com repositório ativo. Informa o que o status mostrou.
signal status_consultado(tinha_staging: bool, tinha_nao_rastreados: bool)
# Emitido quando `git add` realmente move arquivos para a staging.
signal arquivos_preparados(nomes: Array[String])
# Emitido quando um comando falha (uso incorreto, sem repositório etc.). É a única
# exceção à regra acima: a tutora precisa disso para perceber dificuldade.
# `motivo` é uma das constantes FALHA_* abaixo.
signal comando_falhou(comando: String, motivo: String)
# Emitido toda vez que o jogador abre o terminal.
signal terminal_aberto
signal terminal_fechado
# Emitido por `git help`: o jogador pediu ajuda (a tutora conta como dica usada).
signal ajuda_pedida

## Emitido quando a lista de comandos liberados muda (ouvido pelo Manual do Sistema).
signal comandos_atualizados

# Sinais do modelo de branches (Fases 2 e 4). Só a lógica Git os emite; quem reage (mapa, Atlas,
# terminal) apenas escuta. `commit_id` é o commit para o qual a nova branch aponta.
signal branch_criada(nome: String, commit_id: String)
signal branch_ativa_mudou(anterior: String, nova: String)
## `git log` foi executado (consultou o histórico de `branch`).
signal log_consultado(branch: String)
## `git merge` integrou `origem` em `destino`. `commit_id` é o novo head de `destino`
## (o commit de merge, ou o commit de `origem` se foi fast-forward).
signal merge_realizado(origem: String, destino: String, commit_id: String, fast_forward: bool)

# Operações de "desfazer" e "recuperar" (fases futuras). Só a lógica Git as emite.
## `git reset` moveu o HEAD da branch ativa de `de` para `para` (ids de commit).
signal reset_realizado(modo: String, de: String, para: String)
## `git revert` criou `novo_commit`, que desfaz `commit_original` sem apagar a história.
signal revert_realizado(commit_original: String, novo_commit: String)
## `git cherry-pick` copiou `origem` para a branch ativa como `novo_commit`.
signal cherry_pick_realizado(origem: String, novo_commit: String)
signal stash_guardado(arquivos: Array)
signal stash_aplicado(arquivos: Array)
## `git reflog` foi executado.
signal reflog_consultado

const FALHA_SEM_REPOSITORIO := "sem_repositorio"
const FALHA_ARQUIVO_INEXISTENTE := "arquivo_inexistente"
const FALHA_JA_NA_STAGING := "ja_na_staging"
const FALHA_JA_VERSIONADO := "ja_versionado"
const FALHA_NADA_PARA_ADICIONAR := "nada_para_adicionar"
const FALHA_STAGING_VAZIA := "staging_vazia"
const FALHA_USO_INCORRETO := "uso_incorreto"
const FALHA_COMANDO_INDISPONIVEL := "comando_indisponivel"
const FALHA_COMANDO_INEXISTENTE := "comando_inexistente"
const FALHA_NAO_E_GIT := "nao_e_git"
const FALHA_COMANDO_BLOQUEADO := "comando_bloqueado"
const FALHA_NOME_INVALIDO := "nome_invalido"
const FALHA_BRANCH_JA_EXISTE := "branch_ja_existe"
const FALHA_BRANCH_INEXISTENTE := "branch_inexistente"
const FALHA_SEM_COMMITS := "sem_commits"
const FALHA_JA_NA_BRANCH := "ja_na_branch"
const FALHA_MESMA_BRANCH := "mesma_branch"
const FALHA_STAGING_PENDENTE := "staging_pendente"
const FALHA_COMMIT_INEXISTENTE := "commit_inexistente"
const FALHA_MODO_INVALIDO := "modo_invalido"
const FALHA_STASH_VAZIO := "stash_vazio"
const FALHA_NADA_PARA_GUARDAR := "nada_para_guardar"
const FALHA_MERGE_COMMIT := "merge_commit"

## Nome da branch inicial de todo repositório.
const BRANCH_PADRAO := "main"

# Progresso pedagógico da fase (lido/escrito pela tutora). Fica aqui, e não na
# tutora, para sobreviver ao recarregamento da cena; é zerado em reset_fase().
const PROGRESSO_INICIAL := {
	"conhecimento_previo": "",       # "sim" | "nao" | "incerto" (sondagem inicial)
	"nivel_explicacao": "completo",  # "completo" | "breve"
	"explicados": {},                # comando -> true, após a 1ª explicação pós-ação
	"reflexao_resposta": -1,         # índice da alternativa escolhida (-1 = ainda não respondeu)
	"desafio_ativo": false,
	"desafio_arquivo_coletado": false,
	"desafio_status_consultado": false, # `git status` DEPOIS de coletar o novo arquivo
	"desafio_concluido": false,
	"dicas_usadas": 0,               # dicas pedidas pelo jogador no desafio
	"desafio_sem_assistencia": false, # concluído com 0 dicas
	"status_visto": false,           # o jogador já rodou `git status` ao menos uma vez
	"erros_consecutivos": 0,         # falhas seguidas, sem nenhum acerto no meio
	"ajudas_automaticas": 0          # vezes em que a tutora ajudou por perceber dificuldade
}
var progresso_tutoria: Dictionary = PROGRESSO_INICIAL.duplicate(true)

# Liberação progressiva de comandos (apresentar um por vez). Fica desligada por padrão:
# quem quiser esse efeito (a tutora da fase) liga a flag e mantém a lista atualizada.
# O comando `help` está sempre liberado.
var liberacao_progressiva: bool = false
var comandos_liberados: Array[String] = []

var git_inicializado: bool = false
var working_directory: Array[String] = [] 
var staging_area: Array[String] = []      

## "Object store": todos os commits já criados, em ordem de criação. Cada commit é
## { id, mensagem, arquivos, pai, pais }. `pais` é a lista de ids dos commits anteriores
## ([] no commit raiz, 1 id num commit comum, 2 ids num commit de merge: [destino, origem]).
## `pai` é o PRIMEIRO pai ("" no commit raiz), mantido por compatibilidade: commits antigos
## só têm `pai` e são lidos por `pais_de()`.
## O commit NÃO sabe a que branch pertence: um commit pode ser alcançado por várias
## branches. O histórico de uma branch se obtém seguindo TODOS os pais a partir do seu head.
var commits: Array[Dictionary] = []

## Diário dos movimentos do HEAD (como `git reflog`), do mais antigo ao mais novo. Cada entrada é
## { indice, acao, branch, de, para, detalhe } (`de`/`para` são ids de commit). Os commits que
## um `reset` deixa para trás continuam em `commits` (o "object store"): o reflog os acha.
## Vive com o repositório: sobrevive a reset_fase() e some em resetar_repositorio().
var reflog: Array[Dictionary] = []

## Pilha do `git stash`: cada item { mensagem, branch, staging, soltos }. É estado temporário
## (como a staging area): reset_fase() a esvazia.
var stash_pilha: Array[Dictionary] = []

## Ponteiros de branch: nome -> { "head": id do último commit, "mundo": {} }.
## `mundo` é um dicionário OPACO reservado para o jogo (ex.: estado da realidade da
## Fase 4); a lógica Git nunca o lê nem o interpreta.
## Antes do primeiro commit a branch ainda "não nasceu": existe `branch_ativa`, mas não
## há entrada aqui (como no Git real).
var branches: Dictionary = {}

## Nome da branch selecionada (o HEAD).
var branch_ativa: String = BRANCH_PADRAO

# Lista que guarda fisicamente o que o jogador pegou no mapa
var inventario_player: Array[String] = []

# Arquivos que podem existir no inventário, mas não fazem parte do repositório
var arquivos_ignorados: Array[String] = [
	"Chave"
]

const MSG_NAO_E_REPOSITORIO := "[color=#FF6B6B]Erro: fatal: not a git repository (or any of the parent directories): .git[/color]"

func _ready() -> void:
	inventario_player = []
	working_directory = []

# Chamado quando o player coleta um item no chão do mapa
func coletar_arquivo_no_mapa(nome_arquivo: String) -> void:
	if not nome_arquivo in inventario_player:
		inventario_player.append(nome_arquivo)
		arquivo_coletado.emit(nome_arquivo)

# Sincroniza o inventário do jogador com o Git ao entrar no computador.
# working_directory guarda só os arquivos NÃO RASTREADOS: o que já está na
# staging ou já foi commitado continua no inventário (como no Git real, o
# arquivo segue existindo na pasta), mas não volta a aparecer como novo.
func sincronizar_inventario_com_git() -> void:
	working_directory = []

	for arquivo in inventario_player:
		if arquivo in arquivos_ignorados:
			continue
		if arquivo in staging_area or esta_versionado(arquivo):
			continue
		if _versionado_so_em_outra_branch(arquivo):
			continue  # o arquivo só existe no histórico de outra branch: não está nesta pasta
		working_directory.append(arquivo)

# true se o arquivo foi commitado em outra branch e NÃO no histórico da branch ativa.
# Como no Git real, um arquivo commitado só em outra branch não existe na pasta desta
# (por isso não aparece como "não rastreado"). Com uma única branch (Fase 1) é sempre false.
func _versionado_so_em_outra_branch(arquivo: String) -> bool:
	if esta_versionado(arquivo):
		return false
	for nome in branches.keys():
		if nome == branch_ativa:
			continue
		for commit in historico(str(nome)):
			if arquivo in commit["arquivos"]:
				return true
	return false

# Arquivos que existem na pasta da branch ativa: os coletados que ainda não foram commitados
# (soltos ou na staging) mais os versionados no histórico desta branch. Os commitados só em
# outra branch ficam de fora. O inventário (`inventario_player`) continua sendo o que o
# jogador carrega no mundo; esta é a visão coerente com o HEAD.
func arquivos_na_pasta() -> Array[String]:
	var resultado: Array[String] = []
	for arquivo in inventario_player:
		if arquivo in arquivos_ignorados or arquivo in resultado:
			continue
		if not _versionado_so_em_outra_branch(arquivo):
			resultado.append(arquivo)
	for arquivo in _arquivos_versionados():
		if arquivo not in resultado:
			resultado.append(arquivo)
	return resultado

# true se o arquivo já entrou em algum commit
func esta_versionado(arquivo: String) -> bool:
	# Do commit mais novo para o mais antigo: o primeiro que cita o arquivo decide. Um commit de
	# `revert` o lista em `removidos` (campo opcional; sem ele o resultado é o de sempre).
	for commit in historico():
		if arquivo in commit.get("removidos", []):
			return false
		if arquivo in commit["arquivos"]:
			return true
	return false

func _arquivos_versionados() -> Array[String]:
	var resultado: Array[String] = []
	var linha_do_tempo := historico()
	linha_do_tempo.reverse()  # do commit mais antigo para o mais novo
	for commit in linha_do_tempo:
		for arquivo in commit.get("removidos", []):
			resultado.erase(str(arquivo))
		for arquivo in commit["arquivos"]:
			if str(arquivo) not in resultado:
				resultado.append(str(arquivo))
	return resultado

# true se o comando pode ser usado agora (sempre true quando a liberação progressiva está desligada)
func comando_liberado(nome: String) -> bool:
	return not liberacao_progressiva or nome == "help" or nome in comandos_liberados

# Dos arquivos pedidos, quais ainda não entraram em nenhum commit
func arquivos_pendentes(requeridos: Array[String]) -> Array[String]:
	var pendentes: Array[String] = []
	for arquivo in requeridos:
		if not esta_versionado(arquivo):
			pendentes.append(arquivo)
	return pendentes

# Avisa a tutora de que um comando falhou e devolve a mensagem para o terminal
func registrar_falha(comando: String, motivo: String, mensagem: String = "") -> String:
	comando_falhou.emit(comando, motivo)
	return mensagem

func inicializar_repositorio() -> String:
	if git_inicializado:
		return "O repositório Git já foi inicializado."
	git_inicializado = true
	branch_ativa = BRANCH_PADRAO
	repositorio_inicializado.emit()
	return "[color=#3DFF9B]Repositório Git vazio inicializado nesta fase.[/color]"

func adicionar_ao_stage(arquivo: String) -> String:
	if not git_inicializado:
		return registrar_falha("add", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	if arquivo in staging_area:
		return registrar_falha("add", FALHA_JA_NA_STAGING, "O arquivo '%s' já está na Staging Area." % arquivo)
	if esta_versionado(arquivo):
		return registrar_falha("add", FALHA_JA_VERSIONADO, "O arquivo '%s' já está versionado e não tem alterações para adicionar." % arquivo)
	if not arquivo in working_directory:
		return registrar_falha("add", FALHA_ARQUIVO_INEXISTENTE, "[color=#FFCC00]Erro: o arquivo '%s' não existe no Working Directory.[/color]" % arquivo)

	staging_area.append(arquivo)
	working_directory.erase(arquivo)
	var nomes: Array[String] = [arquivo]
	arquivos_preparados.emit(nomes)
	return "[color=#3DFF9B]Adicionado '%s' à Staging Area (Pronto para Commit).[/color]" % arquivo

# git add . (ou -A): adiciona todos os arquivos não rastreados de uma vez
func adicionar_todos_ao_stage() -> String:
	if not git_inicializado:
		return registrar_falha("add", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	if working_directory.is_empty():
		return registrar_falha("add", FALHA_NADA_PARA_ADICIONAR, "Nada novo para adicionar (nenhum arquivo não rastreado).")

	var adicionados: Array[String] = working_directory.duplicate()
	for arquivo in adicionados:
		staging_area.append(arquivo)
	working_directory.clear()
	arquivos_preparados.emit(adicionados)
	return "[color=#3DFF9B]Adicionados à Staging Area (%d): %s[/color]" % [adicionados.size(), ", ".join(adicionados)]

func criar_commit(mensagem: String, conteudos: Dictionary = {}) -> String:
	if not git_inicializado:
		return registrar_falha("commit", FALHA_SEM_REPOSITORIO, "[color=#FF6B6B]Erro: fatal: not a git repository[/color]")
	if staging_area.is_empty():
		return registrar_falha("commit", FALHA_STAGING_VAZIA, "Nada para fazer commit (staging area vazia). Use 'git add'.")

	var pai := obter_head()
	var primeiro_commit := pai.is_empty()
	var novo_commit = {
		"id": "c" + str(commits.size() + 1) + "a" + str(randi() % 90 + 10),
		"mensagem": mensagem, # mantém o padrão do seu dicionário
		"arquivos": staging_area.duplicate(),
		"pai": pai,
		"pais": [] if pai.is_empty() else [pai],
	}
	# Opcional: texto de cada arquivo neste commit (base de diff/restore/conflito no futuro).
	if not conteudos.is_empty():
		novo_commit["conteudos"] = conteudos.duplicate()
	commits.append(novo_commit)
	# A branch ativa avança para o novo commit; é ela (e não o commit) que "pertence" ao histórico.
	_registro_branch(branch_ativa)["head"] = novo_commit["id"]
	_registrar_reflog("commit", pai, novo_commit["id"], mensagem)

	# Os arquivos continuam no inventário/pasta: commit grava um snapshot, não consome os arquivos.
	staging_area.clear()

	# GATILHO DA VITÓRIA: Avisa o jogo que um commit válido aconteceu
	commit_realizado.emit(novo_commit)

	var cabecalho := branch_ativa + (" (root-commit) %s" if primeiro_commit else " %s")
	return ("[color=#3DFF9B][" + cabecalho + "] %s\n Comitados com sucesso![/color]") % [novo_commit.id, novo_commit.mensagem]

# Limpa SÓ o estado temporário da fase (arquivos soltos, staging, inventário, tutoria e
# liberação de comandos). O REPOSITÓRIO É PRESERVADO: commits, branches e branch ativa
# sobrevivem, pois a Fase 1 chama isto ao avançar e as fases seguintes precisam do histórico.
# Não emite sinais e não é chamado automaticamente.
func reset_fase() -> void:
	working_directory.clear()
	staging_area.clear()
	inventario_player.clear()
	liberacao_progressiva = false
	comandos_liberados.clear()
	stash_pilha.clear()
	progresso_tutoria = PROGRESSO_INICIAL.duplicate(true)

# Reset COMPLETO e DESTRUTIVO: apaga também o repositório (commits, branches, branch ativa).
# Para "novo jogo" e testes; nunca use ao avançar de fase.
func resetar_repositorio() -> void:
	reset_fase()
	git_inicializado = false
	commits.clear()
	branches.clear()
	reflog.clear()
	branch_ativa = BRANCH_PADRAO

func obter_status() -> String:
	if not git_inicializado:
		return registrar_falha("status", FALHA_SEM_REPOSITORIO, "[color=#FF6B6B]fatal: not a git repository (or any of the parent directories): .git[/color]\nDigite 'git init' para começar.")

	var retorno = "[color=#3DA9FF]## No branch %s[/color]\n" % branch_ativa

	if not staging_area.is_empty():
		retorno += "\nMudanças prontas para o commit:\n"
		for item in staging_area:
			retorno += "\t[color=#3DFF9B]new file:   %s[/color]\n" % item

	if not working_directory.is_empty():
		retorno += "\nArquivos não monitorados (coletados ou no chão):\n"
		for item in working_directory:
			retorno += "\t[color=#FF6B6B]untracked:  %s[/color]\n" % item

	if staging_area.is_empty() and working_directory.is_empty():
		retorno += "\nNada para atualizar, working tree limpa."

	var versionados := _arquivos_versionados()
	if not versionados.is_empty():
		retorno += "\n\n[color=#8AA0B8]Já versionados (no histórico): %s[/color]" % ", ".join(versionados)

	status_consultado.emit(not staging_area.is_empty(), not working_directory.is_empty())
	return retorno


# ======================================================================================
# Branches e histórico (Fases 2 e 4)
# As operações devolvem { ok: bool, erro: String (FALHA_* ou ""), mensagem: String (BBCode) }.
# O terminal só precisa exibir `mensagem`; testes e o jogo conferem `ok`/`erro`.
# ======================================================================================

# Id do commit para o qual a branch aponta ("" se ela ainda não tem commits).
func obter_head(branch: String = "") -> String:
	var nome := branch if not branch.is_empty() else branch_ativa
	if not branches.has(nome):
		return ""
	return str(branches[nome]["head"])

func obter_commit(id: String) -> Dictionary:
	for commit in commits:
		if commit["id"] == id:
			return commit
	return {}

# Ids dos pais de um commit. Commits antigos (só com `pai`) continuam funcionando.
func pais_de(commit: Dictionary) -> Array[String]:
	var resultado: Array[String] = []
	if commit.has("pais"):
		for id in commit["pais"]:
			resultado.append(str(id))
	elif not str(commit.get("pai", "")).is_empty():
		resultado.append(str(commit["pai"]))
	return resultado

# Conjunto (id -> true) de todos os commits alcançáveis a partir de `head`, incluindo ele.
# Segue TODOS os pais, então os dois lados de um merge entram, cada commit uma só vez.
func _alcancaveis(head: String) -> Dictionary:
	var vistos := {}
	var pendentes: Array[String] = []
	if not head.is_empty():
		pendentes.append(head)
	while not pendentes.is_empty():
		var id: String = pendentes.pop_back()
		if vistos.has(id):
			continue
		var commit := obter_commit(id)
		if commit.is_empty():
			continue
		vistos[id] = true
		for pai in pais_de(commit):
			pendentes.append(pai)
	return vistos

# Commits cujos ids estão em `ids`, do mais recente para o mais antigo. A ordem de criação
# (posição em `commits`) é uma ordem topológica válida: todo pai nasce antes dos filhos.
func _em_ordem_de_criacao(ids: Dictionary) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for i in range(commits.size() - 1, -1, -1):
		if ids.has(commits[i]["id"]):
			resultado.append(commits[i])
	return resultado

# Histórico da branch (como `git log`): todos os ancestrais do head, sem repetições, do
# commit mais recente para o mais antigo. Num histórico linear equivale a seguir os `pai`.
func historico(branch: String = "") -> Array[Dictionary]:
	return _em_ordem_de_criacao(_alcancaveis(obter_head(branch)))

# true se `ancestral` está no histórico de `descendente` (um commit é ancestral de si mesmo).
func eh_ancestral(ancestral: String, descendente: String) -> bool:
	return _alcancaveis(descendente).has(ancestral)

# Commits que `branch` tem e `outra` não (mais recentes primeiro). É o que "divergiu".
func commits_exclusivos(branch: String, outra: String) -> Array[Dictionary]:
	if not branches.has(branch) or not branches.has(outra):
		return []
	return commits_sem(obter_head(branch), obter_head(outra))

# Commits alcançáveis a partir de `id_a` que NÃO são alcançáveis a partir de `id_b`
# (mais recentes primeiro). Com os dois pais de um merge, dá cada "linha" que convergiu.
func commits_sem(id_a: String, id_b: String) -> Array[Dictionary]:
	var meus := _alcancaveis(id_a)
	for id in _alcancaveis(id_b).keys():
		meus.erase(id)
	return _em_ordem_de_criacao(meus)

# Commit de merge presente no histórico de `destino` que trouxe `origem` (segundo pai
# dentro do histórico de `origem`). {} se `origem` ainda não foi integrada por merge.
func obter_commit_de_merge(destino: String, origem: String) -> Dictionary:
	if not branches.has(destino) or not branches.has(origem):
		return {}
	var da_origem := _alcancaveis(obter_head(origem))
	for commit in historico(destino):
		var pais := pais_de(commit)
		if pais.size() > 1 and da_origem.has(pais[1]):
			return commit
	return {}

# Branches cujo head é `commit_id` (para decorar o log e o Atlas: "HEAD -> main, outra").
func branches_em(commit_id: String) -> Array[String]:
	var resultado: Array[String] = []
	for nome in branches.keys():
		if str(branches[nome]["head"]) == commit_id:
			resultado.append(str(nome))
	return resultado

func branch_existe(nome: String) -> bool:
	return branches.has(nome)

func listar_branches() -> Array[String]:
	var nomes: Array[String] = []
	for nome in branches.keys():
		nomes.append(str(nome))
	return nomes

# Letras minúsculas, números, '-' e '_' (até 40 caracteres, sem começar por '-' ou '_').
func nome_branch_valido(nome: String) -> bool:
	if nome.is_empty() or nome.length() > 40:
		return false
	if nome.begins_with("-") or nome.begins_with("_"):
		return false
	for caractere in nome:
		var permitido: bool = (caractere >= "a" and caractere <= "z") \
			or (caractere >= "0" and caractere <= "9") or caractere == "-" or caractere == "_"
		if not permitido:
			return false
	return true

# git branch <nome>: cria a branch apontando para o commit atual. NÃO troca de branch.
func criar_branch(nome: String) -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("branch", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	if not nome_branch_valido(nome):
		return _resultado_falha("branch", FALHA_NOME_INVALIDO,
			"[color=#FF6B6B]fatal: '%s' não é um nome de branch válido (use letras minúsculas, números, '-' e '_').[/color]" % nome.replace("[", "[lb]"))
	if branches.has(nome):
		return _resultado_falha("branch", FALHA_BRANCH_JA_EXISTE,
			"[color=#FF6B6B]fatal: a branch '%s' já existe.[/color]" % nome)
	var head := obter_head()
	if head.is_empty():
		return _resultado_falha("branch", FALHA_SEM_COMMITS,
			"[color=#FF6B6B]fatal: '%s' ainda não tem commits; faça um commit antes de criar uma branch.[/color]" % branch_ativa)
	branches[nome] = {"head": head, "mundo": {}}
	branch_criada.emit(nome, head)
	return _resultado(true, "", "[color=#3DFF9B]Branch '%s' criada a partir de '%s' (%s).[/color]" % [nome, branch_ativa, head])

# git switch <nome>: seleciona uma branch que já existe. Arquivos soltos e na staging
# acompanham o jogador (sem conflitos nesta etapa).
func trocar_branch(nome: String) -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("switch", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	if not branches.has(nome):
		return _resultado_falha("switch", FALHA_BRANCH_INEXISTENTE,
			"[color=#FF6B6B]fatal: a branch '%s' não existe.[/color]" % nome.replace("[", "[lb]"))
	if nome == branch_ativa:
		# Não é erro de Git (o Git só avisa), então não conta como falha para a tutora.
		return _resultado(false, FALHA_JA_NA_BRANCH, "Você já está na branch '%s'." % nome)
	var anterior := branch_ativa
	branch_ativa = nome
	_registrar_reflog("switch", obter_head(anterior), obter_head(nome), "moving from %s to %s" % [anterior, nome], anterior)
	# A pasta de trabalho acompanha o HEAD: arquivos commitados só na outra branch somem
	# da lista de "não rastreados" (antes de avisar quem escuta o sinal).
	sincronizar_inventario_com_git()
	branch_ativa_mudou.emit(anterior, nome)
	return _resultado(true, "", "[color=#3DFF9B]Mudou para a branch '%s'.[/color]" % nome)

# git log: o histórico da branch ativa como texto (BBCode), do mais recente ao mais antigo.
# `resumido` = uma linha por commit (--oneline). Avisa quem escuta (`log_consultado`).
func formatar_log(resumido: bool = false) -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("log", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	var linha_do_tempo := historico()
	if linha_do_tempo.is_empty():
		return _resultado_falha("log", FALHA_SEM_COMMITS,
			"[color=#FFCC00]fatal: a branch '%s' ainda não tem commits.[/color]" % branch_ativa)
	var linhas: Array[String] = []
	for commit in linha_do_tempo:
		var id := str(commit["id"])
		var decoracao := _decoracao(id)
		if resumido:
			linhas.append("[color=#FFE08A]%s[/color]%s %s" % [id, decoracao, str(commit["mensagem"]).replace("[", "[lb]")])
			continue
		linhas.append("[color=#FFE08A]commit %s[/color]%s" % [id, decoracao])
		var pais := pais_de(commit)
		if pais.size() > 1:
			linhas.append("Merge: %s" % " ".join(pais))
		linhas.append("\n    %s\n" % str(commit["mensagem"]).replace("[", "[lb]"))
	log_consultado.emit(branch_ativa)
	return _resultado(true, "", "\n".join(linhas))

# " (HEAD -> main, vida-alternativa)" para o commit apontado por alguma branch.
func _decoracao(commit_id: String) -> String:
	var nomes := branches_em(commit_id)
	if nomes.is_empty():
		return ""
	var partes: Array[String] = []
	if branch_ativa in nomes:
		partes.append("[color=#3DFF9B]HEAD -> %s[/color]" % branch_ativa)
		nomes.erase(branch_ativa)
	for nome in nomes:
		partes.append("[color=#3DA9FF]%s[/color]" % nome)
	return " (%s)" % ", ".join(partes)

# git merge <origem>: integra `origem` na branch ATIVA (o destino).
#  * origem já está no histórico do destino  -> "Already up to date" (nada muda);
#  * destino é ancestral da origem            -> fast-forward (o head do destino anda);
#  * histórico divergiu                       -> NOVO commit de merge com dois pais
#                                               [head do destino, head da origem].
# O head da origem não muda; commits e ancestralidade existentes são preservados.
# Sem conflitos: o modelo só acrescenta arquivos, então a integração é sempre limpa.
func mesclar(origem: String) -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("merge", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	if not branches.has(origem):
		return _resultado_falha("merge", FALHA_BRANCH_INEXISTENTE,
			"[color=#FF6B6B]merge: '%s' não é algo que possamos integrar (a branch não existe).[/color]" % origem.replace("[", "[lb]"))
	if origem == branch_ativa:
		return _resultado_falha("merge", FALHA_MESMA_BRANCH,
			"[color=#FF6B6B]merge: não dá para integrar a branch '%s' nela mesma.[/color]" % origem)
	if not staging_area.is_empty():
		return _resultado_falha("merge", FALHA_STAGING_PENDENTE,
			"[color=#FFCC00]merge: há arquivos na staging area. Faça o commit antes de integrar.[/color]")
	var destino := branch_ativa
	var head_destino := obter_head(destino)
	var head_origem := obter_head(origem)
	if head_destino.is_empty():
		return _resultado_falha("merge", FALHA_SEM_COMMITS,
			"[color=#FF6B6B]merge: '%s' ainda não tem commits.[/color]" % destino)
	if eh_ancestral(head_origem, head_destino):
		return _resultado(true, "", "Already up to date. '%s' já está integrada em '%s'." % [origem, destino])
	if eh_ancestral(head_destino, head_origem):
		branches[destino]["head"] = head_origem
		_registrar_reflog("merge", head_destino, head_origem, "merge %s: Fast-forward" % origem)
		sincronizar_inventario_com_git()
		merge_realizado.emit(origem, destino, head_origem, true)
		return _resultado(true, "", "[color=#3DFF9B]Fast-forward: '%s' avançou até %s.[/color]" % [destino, head_origem])
	var novo_commit := {
		"id": "c" + str(commits.size() + 1) + "a" + str(randi() % 90 + 10),
		"mensagem": "Merge branch '%s' into %s" % [origem, destino],
		"arquivos": [],  # o merge não traz arquivos novos; eles vêm pelo segundo pai
		"pai": head_destino,
		"pais": [head_destino, head_origem],
	}
	commits.append(novo_commit)
	branches[destino]["head"] = novo_commit["id"]
	_registrar_reflog("merge", head_destino, novo_commit["id"], "merge %s" % origem)
	sincronizar_inventario_com_git()
	merge_realizado.emit(origem, destino, novo_commit["id"], false)
	return _resultado(true, "", "[color=#3DFF9B]Merge feito: '%s' integrada em '%s'.[/color]\n[%s] %s\nPais: %s e %s" % [
		origem, destino, novo_commit["id"], novo_commit["mensagem"], head_destino, head_origem])

# ======================================================================================
# Desfazer e recuperar: reflog, reset, revert, cherry-pick e stash (fases futuras)
# Mesmo contrato das operações acima: { ok, erro (FALHA_* ou ""), mensagem (BBCode) }.
# Nada aqui é chamado pelas fases atuais: são só capacidades novas do repositório. Nenhuma
# apaga commits do object store (`commits`): `reset` só move ponteiros, e é por isso que o
# reflog consegue recuperar o que parecia perdido.
# ======================================================================================

func _novo_id_commit() -> String:
	return "c" + str(commits.size() + 1) + "a" + str(randi() % 90 + 10)

# Anota um movimento do HEAD no reflog. `branch` vazio = a branch ativa.
func _registrar_reflog(acao: String, de: String, para: String, detalhe: String = "", branch: String = "") -> void:
	reflog.append({
		"indice": reflog.size(),
		"acao": acao,
		"branch": branch if not branch.is_empty() else branch_ativa,
		"de": de,
		"para": para,
		"detalhe": detalhe,
	})

# Referência -> id de commit: "HEAD", "HEAD~N" ("HEAD^" = HEAD~1), nome de branch ou id.
# Devolve "" se não existir (ou se o histórico não tem N pais).
func resolver_referencia(ref: String) -> String:
	var texto := ref.strip_edges()
	var base := texto
	var passos := 0
	var til := texto.find("~")
	if til >= 0:
		base = texto.substr(0, til)
		var resto := texto.substr(til + 1)
		passos = 1 if resto.is_empty() else (int(resto) if resto.is_valid_int() else -1)
	elif texto.ends_with("^"):
		base = texto.trim_suffix("^")
		passos = 1
	if passos < 0:
		return ""
	var id := ""
	if base == "HEAD" or base.is_empty():
		id = obter_head()
	elif branches.has(base):
		id = obter_head(base)
	elif not obter_commit(base).is_empty():
		id = base
	if id.is_empty():
		return ""
	for _i in range(passos):
		var pais := pais_de(obter_commit(id))
		if pais.is_empty():
			return ""
		id = pais[0]
	return id

# git reflog: movimentos do HEAD, do mais recente ao mais antigo (HEAD@{0} é o último).
func formatar_reflog() -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("reflog", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	if reflog.is_empty():
		return _resultado_falha("reflog", FALHA_SEM_COMMITS, "[color=#FFCC00]O reflog ainda está vazio.[/color]")
	var linhas: Array[String] = []
	for i in range(reflog.size() - 1, -1, -1):
		var e: Dictionary = reflog[i]
		var ordem := reflog.size() - 1 - i
		var id := str(e["para"])
		linhas.append("[color=#FFE08A]%s[/color] HEAD@{%d}: %s: %s" % [id if not id.is_empty() else "-------", ordem, e["acao"], str(e["detalhe"]).replace("[", "[lb]")])
	reflog_consultado.emit()
	return _resultado(true, "", "\n".join(linhas))

# Arquivos versionados em `antes` que deixaram de ser em `depois` (ids de commit; "" = nenhum).
func _arquivos_perdidos(antes: String, depois: String) -> Array[String]:
	var perdidos: Array[String] = []
	var ficam: Array[String] = []
	for commit in _em_ordem_de_criacao(_alcancaveis(depois)):
		for arquivo in commit["arquivos"]:
			ficam.append(str(arquivo))
	var lista := _em_ordem_de_criacao(_alcancaveis(antes))
	lista.reverse()
	for commit in lista:
		for arquivo in commit["arquivos"]:
			var nome := str(arquivo)
			if nome not in ficam and nome not in perdidos:
				perdidos.append(nome)
	return perdidos

# git reset [--soft|--mixed|--hard] <alvo>: move o HEAD da branch ativa para `alvo`.
#  soft  -> só move o ponteiro; os arquivos dos commits descartados ficam na staging area;
#  mixed -> move e esvazia a staging area; os arquivos voltam para a pasta como "não rastreados";
#  hard  -> move e DESTRÓI: staging e os arquivos dos commits descartados saem do inventário.
# Os commits descartados NÃO somem do object store: o reflog continua achando.
func resetar_para(alvo: String, modo: String = "mixed") -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("reset", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	if modo not in ["soft", "mixed", "hard"]:
		return _resultado_falha("reset", FALHA_MODO_INVALIDO,
			"[color=#FF6B6B]reset: modo '%s' inválido. Use --soft, --mixed ou --hard.[/color]" % modo.replace("[", "[lb]"))
	var destino := resolver_referencia(alvo)
	if destino.is_empty():
		return _resultado_falha("reset", FALHA_COMMIT_INEXISTENTE,
			"[color=#FF6B6B]fatal: '%s' não é um commit válido.[/color]" % alvo.replace("[", "[lb]"))
	var origem := obter_head()
	var perdidos := _arquivos_perdidos(origem, destino)
	_registro_branch(branch_ativa)["head"] = destino
	_registrar_reflog("reset", origem, destino, "reset --%s: moving to %s" % [modo, alvo])
	match modo:
		"soft":
			for arquivo in perdidos:
				if arquivo not in staging_area:
					staging_area.append(arquivo)
				if arquivo not in inventario_player:
					inventario_player.append(arquivo)
		"mixed":
			staging_area.clear()
			for arquivo in perdidos:
				if arquivo not in inventario_player:
					inventario_player.append(arquivo)
		"hard":
			staging_area.clear()
			for arquivo in perdidos:
				inventario_player.erase(arquivo)
	sincronizar_inventario_com_git()
	reset_realizado.emit(modo, origem, destino)
	return _resultado(true, "", "[color=#3DFF9B]HEAD agora está em %s (reset --%s).[/color]" % [destino, modo])

# git revert <commit>: cria um commit NOVO que desfaz o efeito de `ref`, sem apagar a história
# (ao contrário do reset). O commit desfeito precisa estar na branch ativa; merge não é suportado.
func reverter(ref: String) -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("revert", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	var id := resolver_referencia(ref)
	if id.is_empty() or not eh_ancestral(id, obter_head()):
		return _resultado_falha("revert", FALHA_COMMIT_INEXISTENTE,
			"[color=#FF6B6B]fatal: '%s' não é um commit da branch '%s'.[/color]" % [ref.replace("[", "[lb]"), branch_ativa])
	var alvo := obter_commit(id)
	if pais_de(alvo).size() > 1:
		return _resultado_falha("revert", FALHA_MERGE_COMMIT,
			"[color=#FFCC00]revert: desfazer um commit de merge ainda não é suportado.[/color]")
	if not staging_area.is_empty():
		return _resultado_falha("revert", FALHA_STAGING_PENDENTE,
			"[color=#FFCC00]revert: há arquivos na staging area. Faça o commit antes.[/color]")
	var head := obter_head()
	var novo := {
		"id": _novo_id_commit(),
		"mensagem": "Revert \"%s\"" % str(alvo["mensagem"]),
		# Desfazer um revert devolve o que ele tinha tirado (`removidos`), e vice-versa.
		"arquivos": alvo.get("removidos", []).duplicate(),
		"removidos": alvo["arquivos"].duplicate(),
		"reverte": id,
		"pai": head,
		"pais": [head],
	}
	commits.append(novo)
	_registro_branch(branch_ativa)["head"] = novo["id"]
	_registrar_reflog("revert", head, novo["id"], "revert %s" % id)
	sincronizar_inventario_com_git()
	revert_realizado.emit(id, novo["id"])
	return _resultado(true, "", "[color=#3DFF9B][%s] %s\nDesfaz %s sem apagar a história.[/color]" % [novo["id"], novo["mensagem"], id])

# git cherry-pick <commit>: copia UM commit (mesma mensagem e arquivos) para a branch ativa.
func escolher_commit(ref: String) -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("cherry-pick", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	var id := resolver_referencia(ref)
	if id.is_empty():
		return _resultado_falha("cherry-pick", FALHA_COMMIT_INEXISTENTE,
			"[color=#FF6B6B]fatal: '%s' não é um commit válido.[/color]" % ref.replace("[", "[lb]"))
	var head := obter_head()
	if head.is_empty():
		return _resultado_falha("cherry-pick", FALHA_SEM_COMMITS,
			"[color=#FF6B6B]fatal: '%s' ainda não tem commits.[/color]" % branch_ativa)
	if eh_ancestral(id, head):
		return _resultado(false, FALHA_JA_NA_BRANCH, "O commit %s já está na branch '%s'." % [id, branch_ativa])
	var original := obter_commit(id)
	if pais_de(original).size() > 1:
		return _resultado_falha("cherry-pick", FALHA_MERGE_COMMIT,
			"[color=#FFCC00]cherry-pick: copiar um commit de merge ainda não é suportado.[/color]")
	if not staging_area.is_empty():
		return _resultado_falha("cherry-pick", FALHA_STAGING_PENDENTE,
			"[color=#FFCC00]cherry-pick: há arquivos na staging area. Faça o commit antes.[/color]")
	var novo := {
		"id": _novo_id_commit(),
		"mensagem": original["mensagem"],
		"arquivos": original["arquivos"].duplicate(),
		"cherry_pick_de": id,
		"pai": head,
		"pais": [head],
	}
	if original.has("conteudos"):
		novo["conteudos"] = original["conteudos"].duplicate()
	commits.append(novo)
	_registro_branch(branch_ativa)["head"] = novo["id"]
	_registrar_reflog("cherry-pick", head, novo["id"], "cherry-pick %s" % id)
	for arquivo in novo["arquivos"]:
		if arquivo not in inventario_player:
			inventario_player.append(arquivo)
	sincronizar_inventario_com_git()
	cherry_pick_realizado.emit(id, novo["id"])
	return _resultado(true, "", "[color=#3DFF9B][%s] %s\nCopiado de %s.[/color]" % [novo["id"], novo["mensagem"], id])

# git stash: guarda o trabalho em andamento (staging area + arquivos soltos) e limpa a pasta.
func guardar_stash(mensagem: String = "") -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("stash", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	sincronizar_inventario_com_git()
	if staging_area.is_empty() and working_directory.is_empty():
		return _resultado_falha("stash", FALHA_NADA_PARA_GUARDAR,
			"[color=#FFCC00]Nada para guardar: não há trabalho em andamento.[/color]")
	var item := {
		"mensagem": mensagem if not mensagem.is_empty() else "WIP on %s" % branch_ativa,
		"branch": branch_ativa,
		"staging": staging_area.duplicate(),
		"soltos": working_directory.duplicate(),
	}
	stash_pilha.append(item)
	var guardados: Array = item["staging"] + item["soltos"]
	for arquivo in guardados:
		inventario_player.erase(arquivo)
	staging_area.clear()
	sincronizar_inventario_com_git()
	stash_guardado.emit(guardados)
	return _resultado(true, "", "[color=#3DFF9B]Trabalho guardado (%s): %s.[/color]" % [item["mensagem"], ", ".join(guardados)])

# git stash pop: devolve o último trabalho guardado (staging area e arquivos soltos).
func aplicar_stash() -> Dictionary:
	if not git_inicializado:
		return _resultado_falha("stash", FALHA_SEM_REPOSITORIO, MSG_NAO_E_REPOSITORIO)
	if stash_pilha.is_empty():
		return _resultado_falha("stash", FALHA_STASH_VAZIO,
			"[color=#FFCC00]Não há nada guardado no stash.[/color]")
	var item: Dictionary = stash_pilha.pop_back()
	var devolvidos: Array = item["staging"] + item["soltos"]
	for arquivo in devolvidos:
		if arquivo not in inventario_player:
			inventario_player.append(arquivo)
	for arquivo in item["staging"]:
		if arquivo not in staging_area:
			staging_area.append(arquivo)
	sincronizar_inventario_com_git()
	stash_aplicado.emit(devolvidos)
	return _resultado(true, "", "[color=#3DFF9B]Trabalho recuperado (%s): %s.[/color]" % [item["mensagem"], ", ".join(devolvidos)])

# Conteúdo de `arquivo` na versão mais recente do histórico de `branch` ("" = ativa), quando os
# commits foram criados com `conteudos`. "" se nenhum commit guardou texto desse arquivo.
func conteudo_em(arquivo: String, branch: String = "") -> String:
	for commit in historico(branch):
		if arquivo in commit.get("removidos", []):
			return ""
		var textos: Dictionary = commit.get("conteudos", {})
		if textos.has(arquivo):
			return str(textos[arquivo])
	return ""

# Estado do "mundo" guardado em uma branch (dicionário opaco; ver `branches`).
# Devolve a referência viva, ou {} (solto) se a branch ainda não existe.
func obter_mundo_branch(nome: String) -> Dictionary:
	if not branches.has(nome):
		return {}
	return branches[nome]["mundo"]

func definir_mundo_branch(nome: String, chave: String, valor: Variant) -> bool:
	if not branches.has(nome):
		return false
	branches[nome]["mundo"][chave] = valor
	return true

func _registro_branch(nome: String) -> Dictionary:
	if not branches.has(nome):
		branches[nome] = {"head": "", "mundo": {}}
	return branches[nome]

func _resultado(ok: bool, erro: String, mensagem: String) -> Dictionary:
	return {"ok": ok, "erro": erro, "mensagem": mensagem}

func _resultado_falha(comando: String, motivo: String, mensagem: String) -> Dictionary:
	return _resultado(false, motivo, registrar_falha(comando, motivo, mensagem))

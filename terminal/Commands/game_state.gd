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
var commits: Array[Dictionary] = []       

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
		working_directory.append(arquivo)

# true se o arquivo já entrou em algum commit
func esta_versionado(arquivo: String) -> bool:
	for commit in commits:
		if arquivo in commit["arquivos"]:
			return true
	return false

func _arquivos_versionados() -> Array[String]:
	var resultado: Array[String] = []
	for commit in commits:
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

func criar_commit(mensagem: String) -> String:
	if not git_inicializado:
		return registrar_falha("commit", FALHA_SEM_REPOSITORIO, "[color=#FF6B6B]Erro: fatal: not a git repository[/color]")
	if staging_area.is_empty():
		return registrar_falha("commit", FALHA_STAGING_VAZIA, "Nada para fazer commit (staging area vazia). Use 'git add'.")

	var primeiro_commit := commits.is_empty()
	var novo_commit = {
		"id": "c" + str(commits.size() + 1) + "a" + str(randi() % 90 + 10),
		"mensagem": mensagem, # mantém o padrão do seu dicionário
		"arquivos": staging_area.duplicate()
	}
	commits.append(novo_commit)

	# Os arquivos continuam no inventário/pasta: commit grava um snapshot, não consome os arquivos.
	staging_area.clear()

	# GATILHO DA VITÓRIA: Avisa o jogo que um commit válido aconteceu
	commit_realizado.emit(novo_commit)

	var cabecalho := "master (root-commit) %s" if primeiro_commit else "master %s"
	return ("[color=#3DFF9B][" + cabecalho + "] %s\n Comitados com sucesso![/color]") % [novo_commit.id, novo_commit.mensagem]

# Limpa todo o estado da fase atual (usado futuramente ao trocar de fase).
# Nao emite sinais e nao e chamado automaticamente.
func reset_fase() -> void:
	git_inicializado = false
	working_directory.clear()
	staging_area.clear()
	commits.clear()
	inventario_player.clear()
	liberacao_progressiva = false
	comandos_liberados.clear()
	progresso_tutoria = PROGRESSO_INICIAL.duplicate(true)

func obter_status() -> String:
	if not git_inicializado:
		return registrar_falha("status", FALHA_SEM_REPOSITORIO, "[color=#FF6B6B]fatal: not a git repository (or any of the parent directories): .git[/color]\nDigite 'git init' para começar.")

	var retorno = "[color=#3DA9FF]## No branch master[/color]\n"

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

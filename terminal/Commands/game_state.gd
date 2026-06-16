extends Node

# Sinal que avisa os scripts de fase quando um commit foi concluído
signal commit_realizado(commit_info: Dictionary)

var git_inicializado: bool = false
var working_directory: Array[String] = [] 
var staging_area: Array[String] = []      
var commits: Array[Dictionary] = []       

# Lista que guarda fisicamente o que o jogador pegou no mapa
var inventario_player: Array[String] = []

func _ready() -> void:
	inventario_player = []
	working_directory = []

# Chamado quando o player coleta um item no chão do mapa
func coletar_arquivo_no_mapa(nome_arquivo: String) -> void:
	if not nome_arquivo in inventario_player:
		inventario_player.append(nome_arquivo)

# Sincroniza o inventário do jogador com o Git ao entrar no computador
func sincronizar_inventario_com_git() -> void:
	working_directory = inventario_player.duplicate()

func inicializar_repositorio() -> String:
	if git_inicializado:
		return "O repositório Git já foi inicializado."
	git_inicializado = true
	return "[color=#3DFF9B]Repositório Git vazio inicializado nesta fase.[/color]"

func adicionar_ao_stage(arquivo: String) -> String:
	if not git_inicializado:
		return "[color=#FF6B6B]Erro: fatal: not a git repository (or any of the parent directories): .git[/color]"
	if not arquivo in working_directory:
		return "[color=#FFCC00]Erro: o arquivo '%s' não existe no Working Directory.[/color]" % arquivo
	if arquivo in staging_area:
		return "O arquivo '%s' já está na Staging Area." % arquivo

	staging_area.append(arquivo)
	return "[color=#3DFF9B]Adicionado '%s' à Staging Area (Pronto para Commit).[/color]" % arquivo

func criar_commit(mensagem: String) -> String:
	if not git_inicializado:
		return "[color=#FF6B6B]Erro: fatal: not a git repository[/color]"
	if staging_area.is_empty():
		return "Nada para fazer commit (staging area vazia). Use 'git add'."

	var novo_commit = {
		"id": "c" + str(commits.size() + 1) + "a" + str(randi() % 90 + 10),
		"mensagem": mensagem, # mantém o padrão do seu dicionário
		"arquivos": staging_area.duplicate()
	}
	commits.append(novo_commit)

	# Atualiza o inventário real tirando o que foi salvo
	for item in staging_area:
		working_directory.erase(item)
		inventario_player.erase(item) # Remove do bolso do jogador também!
	staging_area.clear()

	# GATILHO DA VITÓRIA: Avisa o jogo que um commit válido aconteceu
	commit_realizado.emit(novo_commit)

	return "[color=#3DFF9B][master (root-commit) %s] %s\n Comitados com sucesso![/color]" % [novo_commit.id, novo_commit.mensagem]

func obter_status() -> String:
	if not git_inicializado:
		return "[color=#FF6B6B]fatal: not a git repository (or any of the parent directories): .git[/color]\nDigite 'git init' para começar."

	var retorno = "[color=#3DA9FF]## No branch master[/color]\n"

	if not staging_area.is_empty():
		retorno += "\nMudanças prontas para o commit:\n"
		for item in staging_area:
			retorno += "\t[color=#3DFF9B]modified:   %s[/color]\n" % item

	if not working_directory.is_empty():
		retorno += "\nArquivos não monitorados (coletados ou no chão):\n"
		for item in working_directory:
			retorno += "\t[color=#FF6B6B]untracked:  %s[/color]\n" % item

	if staging_area.is_empty() and working_directory.is_empty():
		retorno += "\nNada para atualizar, working tree limpa."

	return retorno

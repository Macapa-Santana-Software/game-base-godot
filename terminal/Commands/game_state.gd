extends Node

# Estado do Git na Fase 1
var git_inicializado: bool = false
var working_directory: Array[String] = [] # Itens que o player coletou no chão
var staging_area: Array[String] = []      # Itens preparados com 'git add'
var commits: Array[Dictionary] = []       # Histórico de commits salvos

# Reinicia o estado para a Fase 1
func _ready() -> void:
	# Simulação: o player começa a fase sabendo que precisa coletar esses arquivos
	working_directory = ["arquivo1.txt", "arquivo2.txt"] 

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
		return "O arquivo '%s' ya está na Staging Area." % arquivo
		
	staging_area.append(arquivo)
	return "[color=#3DFF9B]Adicionado '%s' à Staging Area (Pronto para Commit).[/color]" % arquivo

func criar_commit(mensagem: String) -> String:
	if not git_inicializado:
		return "[color=#FF6B6B]Erro: fatal: not a git repository[/color]"
		
	if staging_area.is_empty():
		return "Nada para fazer commit (staging area vazia). Use 'git add'."
		
	if mensagem.is_empty():
		return "[color=#FF6B6B]Erro: Você precisa de uma mensagem de commit. Uso: git commit -m \"mensagem\"[/color]"

	# Cria o snapshot
	var novo_commit = {
		"id": "c" + str(commits.size() + 1) + "a" + str(randi() % 90 + 10),
		"mensagem": mensagem,
		"arquivos": staging_area.duplicate()
	}
	commits.append(novo_commit)
	
	# Remove os itens do working directory e limpa o stage (eles foram salvos!)
	for item in staging_area:
		working_directory.erase(item)
	staging_area.clear()
	
	return "[color=#3DFF9B][master (root-commit) %s] %s\n Comitados com sucesso![/color]" % [novo_commit.id, novo_commit.mensagem]

func obter_status() -> String:
	if not git_inicializado:
		return "[color=#FF6B6B]fatal: not a git repository (or any of the parent directories): .git[/color]\nDigite 'git init' para começar."
		
	var retorno = "[color=#3DA9FF]## No branch master[/color]\n"
	
	# Arquivos no Stage
	if not staging_area.is_empty():
		retorno += "\n[color=#3DFF9B]Mudanças prontas para o commit:[/color]\n"
		for item in staging_area:
			retorno += "\t[color=#3DFF9B]modified:   %s[/color]\n" % item
	
	# Arquivos soltos no mapa (Working Directory)
	if not working_directory.is_empty():
		retorno += "\n[color=#FF6B6B]Arquivos não monitorados (coletados ou no chão):[/color]\n"
		for item in working_directory:
			retorno += "\t[color=#FF6B6B]untracked:  %s[/color]\n" % item
			
	if staging_area.is_empty() and working_directory.is_empty():
		retorno += "\nNada para atualizar, working tree limpa. Fase concluída!"
		
	return retorno

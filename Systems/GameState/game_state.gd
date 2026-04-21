extends Node

signal fragment_collected(item_name: String)
signal staging_area_changed(items: Array[String])
signal commit_created(commit_data: Dictionary)
signal checkout_applied(world_state: Dictionary)

var working_directory: Array[String] = []
var staging_area: Array[String] = []
var current_branch: String = "main"

var _commit_counter: int = 1
var _head_by_branch: Dictionary = {}
var _remote_head_by_branch: Dictionary = {}
var _branch_data: Dictionary = {}


func _ready() -> void:
	_initialize_repository()


func _initialize_repository() -> void:
	var initial_state := {
		"state_id": "mundo_inicial",
		"platforms_enabled": ["plataforma_inicio"],
		"enemy_positions": {"inimigo_a": Vector2(320, 160)}
	}

	var root_commit := {
		"hash": "c000000",
		"message": "Estado inicial do laboratório",
		"timestamp": Time.get_datetime_string_from_system(),
		"branch": "main",
		"items": [],
		"parent": "",
		"world_state": initial_state
	}

	_branch_data["main"] = {
		"commits": [root_commit],
		"world_states": {"c000000": initial_state}
	}
	_head_by_branch["main"] = "c000000"
	_remote_head_by_branch["main"] = "c000000"


func collect_fragment(item_name: String) -> String:
	if item_name.is_empty():
		return "Erro: item inválido."
	if working_directory.has(item_name) or staging_area.has(item_name):
		return "Aviso: '%s' já está no diretório de trabalho." % item_name

	working_directory.append(item_name)
	fragment_collected.emit(item_name)
	return "Fragmento '%s' coletado e adicionado ao diretório de trabalho." % item_name


func git_add(item_name: String) -> String:
	if item_name.is_empty():
		return "Uso: git add <item>"

	if not working_directory.has(item_name):
		return "Erro: item '%s' não encontrado no diretório de trabalho." % item_name

	working_directory.erase(item_name)
	if not staging_area.has(item_name):
		staging_area.append(item_name)
	staging_area_changed.emit(staging_area.duplicate())
	return "Item '%s' adicionado à área de stage." % item_name


func git_commit(message: String) -> Dictionary:
	if staging_area.is_empty():
		return {"ok": false, "message": "Nada para commitar. Use git add antes do commit."}
	if message.strip_edges().is_empty():
		return {"ok": false, "message": "Erro: mensagem de commit obrigatória. Use -m \"mensagem\"."}

	var parent_hash: String = _head_by_branch.get(current_branch, "")
	var commit_hash := _generate_commit_hash()
	var snapshot := _build_world_snapshot(staging_area)
	var commit := {
		"hash": commit_hash,
		"message": message.strip_edges(),
		"timestamp": Time.get_datetime_string_from_system(),
		"branch": current_branch,
		"items": staging_area.duplicate(),
		"parent": parent_hash,
		"world_state": snapshot
	}

	_get_branch_commits(current_branch).append(commit)
	_get_branch_world_states(current_branch)[commit_hash] = snapshot
	_head_by_branch[current_branch] = commit_hash
	staging_area.clear()
	staging_area_changed.emit(staging_area.duplicate())
	commit_created.emit(commit)

	return {
		"ok": true,
		"message": "[%s %s] %s" % [current_branch, commit_hash, message.strip_edges()],
		"commit": commit
	}


func git_log() -> Array[Dictionary]:
	var commits: Array = _get_branch_commits(current_branch)
	var history: Array[Dictionary] = []
	for i in range(commits.size() - 1, -1, -1):
		history.append(commits[i])
	return history


func git_checkout(hash_or_branch: String) -> Dictionary:
	if hash_or_branch.is_empty():
		return {"ok": false, "message": "Uso: git checkout <hash|branch>"}

	if _branch_data.has(hash_or_branch):
		current_branch = hash_or_branch
		var branch_head: String = _head_by_branch.get(current_branch, "")
		var state: Dictionary = _get_branch_world_states(current_branch).get(branch_head, {})
		checkout_applied.emit(state)
		return {"ok": true, "message": "Agora você está na branch '%s'." % current_branch}

	var world_states: Dictionary = _get_branch_world_states(current_branch)
	if not world_states.has(hash_or_branch):
		return {"ok": false, "message": "Erro: commit '%s' não encontrado na branch atual." % hash_or_branch}

	var world_state: Dictionary = world_states[hash_or_branch]
	_head_by_branch[current_branch] = hash_or_branch
	checkout_applied.emit(world_state)
	return {"ok": true, "message": "Checkout aplicado para o commit %s." % hash_or_branch}


func git_branch_create(branch_name: String) -> Dictionary:
	if branch_name.is_empty():
		return {"ok": false, "message": "Uso: git branch <nome>"}
	if _branch_data.has(branch_name):
		return {"ok": false, "message": "Erro: branch '%s' já existe." % branch_name}

	var source_commits: Array = _get_branch_commits(current_branch).duplicate(true)
	var source_states: Dictionary = _get_branch_world_states(current_branch).duplicate(true)
	_branch_data[branch_name] = {"commits": source_commits, "world_states": source_states}
	_head_by_branch[branch_name] = _head_by_branch.get(current_branch, "")
	_remote_head_by_branch[branch_name] = _head_by_branch.get(current_branch, "")
	return {"ok": true, "message": "Branch '%s' criada a partir de '%s'." % [branch_name, current_branch]}


func git_merge(source_branch: String) -> Dictionary:
	if source_branch.is_empty():
		return {"ok": false, "message": "Uso: git merge <branch>"}
	if source_branch == current_branch:
		return {"ok": false, "message": "Erro: não é possível fazer merge da mesma branch."}
	if not _branch_data.has(source_branch):
		return {"ok": false, "message": "Erro: branch '%s' não existe." % source_branch}

	var source_head: String = _head_by_branch.get(source_branch, "")
	var target_head: String = _head_by_branch.get(current_branch, "")
	if source_head == target_head:
		return {"ok": true, "message": "Já está tudo sincronizado entre as branches."}

	# Simulação de conflito para fase 4.
	return {
		"ok": false,
		"conflict": true,
		"message": "Conflito detectado entre '%s' e '%s'. Resolva os obstáculos para concluir o merge." % [current_branch, source_branch]
	}


func git_push() -> Dictionary:
	var local_head: String = _head_by_branch.get(current_branch, "")
	var remote_head: String = _remote_head_by_branch.get(current_branch, "")
	if local_head == remote_head:
		return {"ok": true, "message": "Tudo atualizado no repositório remoto simulado."}

	if remote_head != "" and remote_head != _get_parent_of(local_head):
		return {"ok": false, "message": "Push rejeitado: execute git pull e resolva os conflitos."}

	_remote_head_by_branch[current_branch] = local_head
	return {"ok": true, "message": "Push concluído para origin/%s." % current_branch}


func git_pull() -> Dictionary:
	var local_head: String = _head_by_branch.get(current_branch, "")
	var remote_head: String = _remote_head_by_branch.get(current_branch, "")
	if remote_head == local_head:
		return {"ok": true, "message": "Já está atualizado com o remoto."}
	if remote_head == "":
		return {"ok": true, "message": "Nenhuma atualização remota disponível."}

	_head_by_branch[current_branch] = remote_head
	var state: Dictionary = _get_branch_world_states(current_branch).get(remote_head, {})
	checkout_applied.emit(state)
	return {"ok": true, "message": "Pull aplicado. HEAD atualizado para %s." % remote_head}


func get_status_lines() -> Array[String]:
	return [
		"Branch atual: %s" % current_branch,
		"Diretório de trabalho: %s" % str(working_directory),
		"Área de stage: %s" % str(staging_area),
		"HEAD: %s" % _head_by_branch.get(current_branch, "")
	]


func _generate_commit_hash() -> String:
	var hash := "c%06d" % _commit_counter
	_commit_counter += 1
	return hash


func _build_world_snapshot(staged_items: Array[String]) -> Dictionary:
	var item_count := staged_items.size()
	return {
		"state_id": "estado_%s" % _head_by_branch.get(current_branch, "root"),
		"platforms_enabled": ["plataforma_inicio", "plataforma_%d" % max(item_count, 1)],
		"enemy_positions": {"inimigo_a": Vector2(280 + item_count * 24, 160)}
	}


func _get_branch_commits(branch: String) -> Array:
	return _branch_data.get(branch, {}).get("commits", [])


func _get_branch_world_states(branch: String) -> Dictionary:
	return _branch_data.get(branch, {}).get("world_states", {})


func _get_parent_of(commit_hash: String) -> String:
	for commit in _get_branch_commits(current_branch):
		if commit.get("hash", "") == commit_hash:
			return commit.get("parent", "")
	return ""

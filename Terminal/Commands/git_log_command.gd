extends GitCommand
class_name GitLogCommand

func execute(_context: Dictionary) -> String:
	var lines: Array[String] = []
	var commits: Array[Dictionary] = GameState.git_log()
	if commits.is_empty():
		return "Nenhum commit encontrado."

	for commit in commits:
		lines.append("commit %s (%s)" % [commit.get("hash", ""), commit.get("branch", "")])
		lines.append("Data: %s" % commit.get("timestamp", ""))
		lines.append("    %s" % commit.get("message", ""))
		lines.append("")
	return "\n".join(lines).strip_edges()

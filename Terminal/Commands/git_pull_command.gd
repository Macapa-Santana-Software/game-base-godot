extends GitCommand
class_name GitPullCommand

func execute(_context: Dictionary) -> String:
	var result: Dictionary = GameState.git_pull()
	return result.get("message", "Falha ao executar pull.")

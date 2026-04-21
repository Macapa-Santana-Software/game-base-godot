extends GitCommand
class_name GitPushCommand

func execute(_context: Dictionary) -> String:
	var result: Dictionary = GameState.git_push()
	return result.get("message", "Falha ao executar push.")

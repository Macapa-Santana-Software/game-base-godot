extends GitCommand
class_name GitMergeCommand

func execute(context: Dictionary) -> String:
	var args: Array[String] = context.get("args", [])
	if args.is_empty():
		return "Uso: git merge <branch>"
	var result: Dictionary = GameState.git_merge(args[0])
	return result.get("message", "Falha ao executar merge.")

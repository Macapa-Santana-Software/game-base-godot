extends GitCommand
class_name GitCommitCommand

func execute(context: Dictionary) -> String:
	var args: Array[String] = context.get("args", [])
	var commit_message := _extract_message(args)
	var result: Dictionary = GameState.git_commit(commit_message)
	return result.get("message", "Falha ao executar commit.")


func _extract_message(args: Array[String]) -> String:
	for i in range(args.size()):
		if args[i] == "-m" and i + 1 < args.size():
			return " ".join(args.slice(i + 1))
	return ""

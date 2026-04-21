extends GitCommand
class_name GitBranchCommand

func execute(context: Dictionary) -> String:
	var args: Array[String] = context.get("args", [])
	if args.is_empty():
		return "Uso: git branch <nome>"
	var result: Dictionary = GameState.git_branch_create(args[0])
	return result.get("message", "Falha ao criar branch.")

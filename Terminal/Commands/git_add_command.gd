extends GitCommand
class_name GitAddCommand

func execute(context: Dictionary) -> String:
	var args: Array[String] = context.get("args", [])
	if args.is_empty():
		return "Uso: git add <item>"
	return GameState.git_add(args[0])

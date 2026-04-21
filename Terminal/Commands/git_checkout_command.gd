extends GitCommand
class_name GitCheckoutCommand

func execute(context: Dictionary) -> String:
	var args: Array[String] = context.get("args", [])
	if args.is_empty():
		return "Uso: git checkout <hash|branch>"
	var result: Dictionary = GameState.git_checkout(args[0])
	return result.get("message", "Falha ao executar checkout.")

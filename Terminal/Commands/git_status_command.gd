extends GitCommand
class_name GitStatusCommand

func execute(_context: Dictionary) -> String:
	return "\n".join(GameState.get_status_lines())

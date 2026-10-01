class_name ExitArea extends Area2D

## Emitido quando o Player entra na saida ja desbloqueada. Ainda sem ouvinte:
## sera usado nas proximas etapas (tela de vitoria, troca de fase).
signal unlocked_entered

var locked : bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return

	print("[Saída] Player entrou na saída.")

	if locked:
		print("[Saída] Saída bloqueada.")
		return

	unlocked_entered.emit()

## Chamada futuramente quando o commit correto acontecer nesta fase.
func unlock() -> void:
	locked = false
	$Visual.color = Color(0.2, 0.9, 0.3, 0.6)
	print("[Saída] Saída desbloqueada.")

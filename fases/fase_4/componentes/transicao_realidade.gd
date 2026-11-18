class_name TransicaoRealidade extends CanvasLayer
## Fade colorido usado ao trocar de realidade. Congela o jogo durante o fade para o
## teleporte acontecer "no escuro", sem o jogador se mexer.

const DURACAO_ENTRADA := 0.2
const DURACAO_SAIDA := 0.3

@onready var cortina: ColorRect = $Cortina

var ocupada: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cortina.color = Color(0, 0, 0, 0)


## Escurece com `cor`, executa `a_meio` (o teleporte) e clareia. Ignora pedidos
## enquanto outra transição estiver em andamento.
func transitar(cor: Color, a_meio: Callable) -> void:
	if ocupada:
		return
	ocupada = true
	var estava_pausado := get_tree().paused
	get_tree().paused = true

	cortina.color = Color(cor, 0.0)
	var entrada := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrada.tween_property(cortina, "color:a", 1.0, DURACAO_ENTRADA)
	await entrada.finished

	a_meio.call()

	var saida := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	saida.tween_property(cortina, "color:a", 0.0, DURACAO_SAIDA)
	await saida.finished

	get_tree().paused = estava_pausado
	ocupada = false

# res://Texto/Fase1/fase_1_dialogos.gd
extends CanvasLayer

# Agora o nó aparece no Inspetor para você arrastar e soltar!
@export var caixa_dialogo: Control 

var falas_fase_1: Array[String] = [
	"🤖 [color=#51CF66][IA]:[/color] Bip... bop... Conexão estabelecida!",
	"🤖 [color=#51CF66][IA]:[/color] Alguém aí? Ah, oi, Walker! Sou a IA assistente deste fragmento... ou o que sobrou de mi.",
	"🤖 [color=#51CF66][IA]:[/color] O sistema central entrou em colapso total. Tá uma bagunça completa por aqui.",
	"🤖 [color=#51CF66][IA]:[/color] Eu vi alguns pedaços de código importantes jogados pelo chão da sala (`main.gd` e `player.gd`).",
	"🤖 [color=#51CF66][IA]:[/color] Pegue eles no chão do mapa e depois interaja com o Terminal Central para começarmos a arrumar isso!"
]

func _ready() -> void:
	print("[IA FASE 1]: Iniciando contagem regressiva de 3 segundos...")
	
	# Espera os 3 segundos exatos
	await get_tree().create_timer(3.0).timeout
	
	print("[IA FASE 1]: 3 segundos se passaram!")
	
	print("[IA FASE 1]: Caixa de diálogo encontrada! Iniciando texto...")
	caixa_dialogo.iniciar_dialogo(falas_fase_1)

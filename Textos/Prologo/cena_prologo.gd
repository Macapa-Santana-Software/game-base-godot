extends CanvasLayer

# Arraste a sua caixa de diálogo instanciada para cá ou ajuste o caminho
@onready var caixa_dialogo = $CaixaDialogo # Subclasse Control que está na raiz

# O texto do seu prólogo estruturado em Array de Strings
var texto_do_prologo: Array[String] = [
	"Antes da fragmentação, existia apenas uma única realidade.",
	"Os Codex eram uma civilização avançada, responsáveis por preservar a estabilidade da linha do tempo no universo.",
	"Durante eras, isso manteve o mundo estável.",
	"Mas, com o tempo, os Codex passaram a enxergar diferenças e imperfeições como falhas.",
	"Realidades alternativas surgiam constantemente, cada uma seguindo caminhos diferentes a partir das escolhas feitas ao longo da existência.",
	"Convencidos de que poderiam eliminar conflitos e criar uma linha perfeita da realidade, eles iniciaram um processo de unificação.",
	"A tentativa ficou conhecida mais tarde como a Merge Catastrophe.",
	"Algumas realidades simplesmente não podiam coexistir.\nQuando os Codex forçaram a fusão entre linhas incompatíveis, a estrutura do universo entrou em colapso.",
	"A continuidade do universo se dividiu inumeras linhas paralelas, cada uma carregando apenas partes incompletas do mundo original.",
	"Foi nesse cenário que surgiram os Walkers.",
	"Diferente dos demais, eles conseguiam atravessar fragmentos da realidade sem serem afetados pelas inconsistências causadas pela fragmentação.",
	"Para restaurar a estabilidade das linhas corrompidas, os Walkers utilizavam o único sistema capaz de interagir diretamente com a estrutura do universo: o Git.",
	"Por meio dele, era possível registrar estados estáveis, recuperar versões anteriores e corrigir conflitos antes que se espalhassem.",
	"Agora, o que resta da realidade depende disso."
]

func _ready() -> void:
	# Conecta o sinal para saber quando o prólogo terminou
	caixa_dialogo.dialogo_finalizado.connect(_on_prologo_terminou)
	
	# Inicia o diálogo passando o texto do prólogo
	caixa_dialogo.iniciar_dialogo(texto_do_prologo)

func _on_prologo_terminou() -> void:
	print("O prólogo acabou! Aqui você muda para o menu ou para a primeira fase.")
	# Exemplo de transição de cena:
	# get_tree().change_scene_to_file("res://cenas/Fase1.tscn")

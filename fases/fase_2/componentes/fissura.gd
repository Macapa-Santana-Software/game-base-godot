class_name FissuraFase2 extends ZonaInteracao
## Ponto de ANCORAGEM entre as duas realidades.
##
## A fissura NÃO troca de realidade nem executa `git switch`. Ela só marca um lugar
## que existe nas duas realidades, em coordenadas locais equivalentes (mesmo `id_par`).
## Quando uma troca de branch acontece (GameState.branch_ativa_mudou) com o jogador
## sobre uma fissura, o RealidadesFase2 o reposiciona na fissura-par da realidade de
## destino. Longe de uma fissura, a troca leva o jogador à última posição conhecida (ou
## à entrada) da realidade de destino.
##
## Não tem prompt de interação (a tecla T abre o terminal que fica ao lado dela): a dica
## provisória `mensagem` aparece sozinha, uma vez, quando o jogador chega.

const GRUPO_FISSURAS := &"fissura_fase2"

## Identificador compartilhado pelas duas fissuras de um par.
@export var id_par: StringName = &""

## Realidade (branch) da área em que esta fissura está. Descoberta no _ready.
var realidade: String = ""

var _dica_mostrada: bool = false


func _enter_tree() -> void:
	add_to_group(GRUPO_FISSURAS)


func _ready() -> void:
	super()
	var no := get_parent()
	while no:
		if no is AreaFase2:
			realidade = (no as AreaFase2).realidade
			break
		no = no.get_parent()


## Âncora, não interação: nunca mostra prompt nem responde à tecla de interação.
func disponivel() -> bool:
	return false


func _on_body_entered(body: Node2D) -> void:
	super(body)
	if _dica_mostrada or not body is Player or mensagem == "":
		return
	var progresso := ProgressoFase2.de(self)
	if progresso and not progresso.todas_ativas(flags_requeridas):
		return
	_dica_mostrada = true
	MensagemHud.mostrar_em(self, mensagem)

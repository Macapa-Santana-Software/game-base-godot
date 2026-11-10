class_name RegistroFinalFase2 extends ZonaInteracao
## Registro final da fase (Área 5): interação NARRATIVA com o artefato.
##
## Fica disponível só quando DUAS coisas aconteceram de verdade:
##   * o merge real (`convergencia_concluida`, derivada do GameState), e
##   * a reflexão: o jogador inspecionou no Atlas o commit de merge real (`merge_inspecionado`).
## Antes disso o artefato fica esmaecido e, ao se aproximar, o Eidolon orienta a consultar o Atlas
## (sinal `consulta_sem_reflexao`; a fala em si é do EidolonFase2).
##
## Mostra dados REAIS do repositório (nada fictício): identificador e mensagem do commit de merge,
## a branch de destino e a relação com as duas linhas históricas integradas (os dois pais e quantas
## memórias próprias cada linha trouxe). Pode ser relido a qualquer momento (e continua disponível
## depois de um reload). A PRIMEIRA observação emite `observado` e liga `registro_observado`; o
## EidolonFase2 então abre o fechamento depois que o jogador teve tempo de ler os dados.

const GRUPO := &"registro_final_fase2"
const ALFA_DORMENTE := 0.45

## Primeira observação: `texto` é o que o jogador vai ler no HUD (serve para calcular o tempo de leitura).
signal observado(texto: String)
## O jogador se aproximou com o merge feito, mas sem ter inspecionado o commit de merge no Atlas.
signal consulta_sem_reflexao

## Nó (relativo a esta zona) que representa o registro; fica esmaecido enquanto indisponível.
@export var visual: NodePath = NodePath()


func _enter_tree() -> void:
	add_to_group(GRUPO)


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	var progresso := ProgressoFase2.de(self)
	if progresso:
		progresso.flag_alterada.connect(func(_nome: StringName, _valor: bool) -> void: _atualizar_brilho())
	_atualizar_brilho()


func _atualizar_brilho() -> void:
	var brilho := get_node_or_null(visual) as CanvasItem
	if brilho:
		brilho.modulate.a = 1.0 if disponivel() else ALFA_DORMENTE


func _on_body_entered(body: Node2D) -> void:
	super(body)
	if not body is Player or disponivel():
		return
	var progresso := ProgressoFase2.de(self)
	if progresso == null:
		return
	if not progresso.obter(ProgressoFase2.CONVERGENCIA_CONCLUIDA):
		MensagemHud.mostrar_em(self, "O registro está em silêncio. As realidades ainda não convergiram.")
	else:
		consulta_sem_reflexao.emit()


func _aplicar_efeitos() -> void:
	var progresso := ProgressoFase2.de(self)
	if progresso == null:
		return
	var texto := _texto(progresso.dados_convergencia())
	var primeira_vez := not progresso.obter(ProgressoFase2.REGISTRO_OBSERVADO)
	MensagemHud.mostrar_em(self, texto, 3)
	if primeira_vez:
		observado.emit(texto)  # antes de ligar a flag: o Eidolon já sabe quanto tempo de leitura dar
	progresso.definir(ProgressoFase2.REGISTRO_OBSERVADO, true)


func _texto(dados: Dictionary) -> String:
	if dados.is_empty():
		return "O registro está em silêncio. As realidades ainda não convergiram."
	var merge: Dictionary = dados["merge"]
	var pais := GameState.pais_de(merge)
	return "[Registro final] Commit %s: \"%s\", em '%s'. Pais: %s (linha %s, %s) e %s (linha %s, %s)." % [
		merge["id"], merge["mensagem"], ProgressoFase2.BRANCH_MAIN,
		pais[0], ProgressoFase2.BRANCH_MAIN, memorias_proprias(dados["linha_main"].size()),
		pais[1], ProgressoFase2.BRANCH_VIDA, memorias_proprias(dados["linha_vida"].size())]


## "1 memória própria", "2 memórias próprias".
static func memorias_proprias(quantidade: int) -> String:
	return "%d memória própria" % quantidade if quantidade == 1 else "%d memórias próprias" % quantidade

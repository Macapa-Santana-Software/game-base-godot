extends CanvasLayer

## Emitido quando o jogador clica em "PRÓXIMA FASE".
## Ouvido pela fase, que resolve a troca via FaseManager.
signal proxima_fase_pressed

const GRUPO := "victory_screen"
const DURACAO_FADE := 0.25

## Texto por número de fase. Fases sem entrada usam a mensagem genérica (e escondem o resumo).
const RESUMOS := {
	1: {
		"mensagem": "Você registrou o primeiro estado desta realidade.",
		"comandos": "git init   git status\ngit add   git commit",
	},
	2: {
		"mensagem": "A ponte voltou: você consertou numa cópia segura e trouxe de volta.",
		"comandos": "git log   git branch\ngit switch   git merge",
	},
	3: {
		"mensagem": "O mural foi restaurado sem perder o seu trabalho.",
		"comandos": "git diff   git restore\ngit restore --staged",
	},
	4: {
		"mensagem": "Duas realidades convergiram em uma só história.",
		"comandos": "git branch   git switch\ngit merge   git log",
	},
	5: {
		"mensagem": "As linhas se encontraram: você resolveu um conflito.",
		"comandos": "git merge   git diff\ngit add   git merge --abort",
	},
	6: {
		"mensagem": "Você aprendeu três jeitos de voltar atrás.",
		"comandos": "git revert   git stash\ngit reset --soft/--hard",
	},
}
const MENSAGEM_GENERICA := "Objetivo cumprido. A realidade avança."
const TITULO_FIM := "FIM DE JOGO"
const MENSAGEM_FIM := "Você chegou ao fim desta jornada.\nObrigado por jogar!"

@onready var raiz: Control = %Control
@onready var titulo_label: Label = %TituloLabel
@onready var mensagem_label: Label = %MensagemLabel
@onready var separador: HSeparator = %Separador
@onready var comandos_titulo: Label = %ComandosTitulo
@onready var comandos_label: Label = %ComandosLabel
@onready var proxima_fase_button: Button = %ProximaFaseButton

func _ready() -> void:
	add_to_group(GRUPO)
	hide()
	proxima_fase_button.pressed.connect(_on_proxima_fase_pressed)

func mostrar() -> void:
	_preencher_textos()
	show()
	get_tree().paused = true
	raiz.modulate.a = 0.0
	create_tween().tween_property(raiz, "modulate:a", 1.0, DURACAO_FADE)
	if proxima_fase_button.visible:
		proxima_fase_button.grab_focus()

func _preencher_textos() -> void:
	# Fase aberta direto (editor/F6): alinha o índice com a cena antes de ler o número.
	FaseManager.sincronizar_com_cena_atual()
	if not FaseManager.has_next_phase():
		_mostrar_fim_de_jogo()
		return
	var numero: int = FaseManager.get_current_phase_number()
	var resumo: Dictionary = RESUMOS.get(numero, {})
	titulo_label.text = "FASE %d CONCLUÍDA" % numero
	mensagem_label.text = resumo.get("mensagem", MENSAGEM_GENERICA)

	var tem_comandos := resumo.has("comandos")
	separador.visible = tem_comandos
	comandos_titulo.visible = tem_comandos
	comandos_label.visible = tem_comandos
	comandos_label.text = resumo.get("comandos", "")

	# Sem fase seguinte o botão não teria efeito: some, e a mensagem explica.
	if FaseManager.has_next_phase():
		proxima_fase_button.show()
	else:
		proxima_fase_button.hide()
		mensagem_label.text += "\nPor enquanto, é só. Volte em breve!"

## Última fase da sequência: só uma mensagem de fim de jogo (sem resumo de comandos nem botão).
func _mostrar_fim_de_jogo() -> void:
	titulo_label.text = TITULO_FIM
	mensagem_label.text = MENSAGEM_FIM
	separador.hide()
	comandos_titulo.hide()
	comandos_label.hide()
	proxima_fase_button.hide()

func _on_proxima_fase_pressed() -> void:
	proxima_fase_pressed.emit()

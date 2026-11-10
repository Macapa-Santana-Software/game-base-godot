class_name ConfiguracaoTerminal extends Resource
## Tudo o que muda de uma fase para outra no TerminalUI. Cada fase cria um .tres desta
## classe e o atribui ao `config` do terminal; o terminal é o mesmo para todas.
##
## Sem configuração, o TerminalUI usa `padrao_fase_1()`, idêntica ao comportamento original,
## então a cena da Fase 1 não precisa mudar.
##
## As RESPOSTAS dos comandos vêm das classes GitCommand_* (que chamam o GameState); aqui
## ficam só a apresentação do terminal e quais comandos a fase oferece.

@export var titulo: String = "TERMINAL GIT :: DATACENTER/DEV"
@export_multiline var mensagem_boas_vindas: String = ""
@export var prompt: String = "dev@central:~$"
@export var cor_prompt: Color = Color("3DFF9B")
@export var texto_do_campo: String = "Digite um comando Git..."
## Comandos oferecidos pela fase. "help" deve estar na lista para o jogador pedir ajuda.
@export var comandos: PackedStringArray = PackedStringArray()
## Texto quando um comando da fase ainda não foi liberado (`%s` = nome do comando).
@export_multiline var mensagem_comando_bloqueado: String = ""


## Configuração original do terminal, usada pela Fase 1.
static func padrao_fase_1() -> ConfiguracaoTerminal:
	var config := ConfiguracaoTerminal.new()
	config.mensagem_boas_vindas = "SISTEMA CENTRAL DE TERMINAL - FASE 1\n" \
		+ "A IA vai te orientar por aqui. Em dúvida, digite 'git help'."
	config.comandos = PackedStringArray(["init", "add", "commit", "status", "help"])
	return config


func prompt_formatado() -> String:
	return "[color=#%s]%s[/color] " % [cor_prompt.to_html(false), prompt]

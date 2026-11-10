class_name GitCommand_Help extends GitCommand
## `git help`: lista os comandos que o jogador pode usar agora, com um resumo na
## metáfora do jogo (sala = pasta, caixa = staging area, foto = commit).
## Também conta como "dica pedida" para a tutora (sinal ajuda_pedida).

## Ordem de exibição. Os 4 primeiros são os da Fase 1 (a saída dela não muda); os demais
## aparecem depois, na ordem em que a fase os declarou.
const ORDEM: Array[String] = ["init", "status", "add", "commit", "log", "branch", "switch", "merge"]

const USO := {
	"init": "git init",
	"status": "git status",
	"add": "git add <arquivo>",
	"commit": "git commit -m \"mensagem\"",
	"log": "git log [--oneline]",
	"branch": "git branch [<nome>]",
	"switch": "git switch <branch>",
	"merge": "git merge <branch>",
}

const RESUMO := {
	"init": "abre o caderno de registros (cria o repositório)",
	"status": "mostra a sala e a caixa: o que está solto e o que está pronto",
	"add": "põe arquivos na caixa (staging area)",
	"commit": "tira a foto da caixa (cria um save point)",
	"log": "lê a história da realidade em que você está (os commits)",
	"branch": "lista as linhas de realidade; com um nome, cria uma nova (sem entrar nela)",
	"switch": "muda para outra linha de realidade (move o HEAD)",
	"merge": "integra a outra linha de realidade na que você está",
}

## Comandos da fase atual; o interpretador preenche ao configurar a fase.
var comandos_da_fase: Array[String] = []

func execute(_args: Array[String], _raw_input: String) -> String:
	GameState.ajuda_pedida.emit()

	var linhas: Array[String] = ["[color=#3DA9FF]Comandos que você pode usar agora:[/color]"]
	for comando in ORDEM:
		if comando in comandos_da_fase and GameState.comando_liberado(comando):
			linhas.append("  [color=#FFE08A]%s[/color]\n      %s" % [USO[comando], RESUMO[comando]])
	linhas.append("Digite [color=#FFE08A]git help[/color] sempre que quiser rever esta lista.")
	return "\n".join(linhas)

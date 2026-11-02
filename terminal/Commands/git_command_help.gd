class_name GitCommand_Help extends GitCommand
## `git help`: lista os comandos que o jogador pode usar agora, com um resumo na
## metáfora do jogo (sala = pasta, caixa = staging area, foto = commit).
## Também conta como "dica pedida" para a tutora (sinal ajuda_pedida).

const ORDEM: Array[String] = ["init", "status", "add", "commit"]

const USO := {
	"init": "git init",
	"status": "git status",
	"add": "git add <arquivo>",
	"commit": "git commit -m \"mensagem\"",
}

const RESUMO := {
	"init": "abre o caderno de registros (cria o repositório)",
	"status": "mostra a sala e a caixa: o que está solto e o que está pronto",
	"add": "põe arquivos na caixa (staging area)",
	"commit": "tira a foto da caixa (cria um save point)",
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

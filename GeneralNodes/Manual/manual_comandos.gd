class_name ManualComandos extends RefCounted

## Conteúdo do Manual do Sistema: uma entrada por comando Git.
## Só dados (nenhum comando é executado a partir daqui). Textos em BBCode simples;
## os campos "sintaxe" e "exemplo" são listas de linhas de comando.
##
## "jogo" liga o comando à metáfora usada pela IA (sala, caixa, foto), para o jogador
## relacionar a explicação ao que acontece no jogo.

const ENTRADAS := {
	"init": {
		"titulo": "git init",
		"sintaxe": ["git init"],
		"faz": "Cria um repositório Git vazio na pasta atual. A partir daí o Git guarda o histórico do projeto numa pasta oculta chamada .git.",
		"serve": "É o primeiro passo para versionar um projeto. Sem ele, os outros comandos respondem \"not a git repository\".",
		"exemplo": ["git init"],
		"resultado": "O terminal avisa que o repositório foi inicializado. Os arquivos continuam iguais e ainda não existe nenhum commit: nada foi registrado.",
		"jogo": "Abre o caderno de registros da sala. Faz-se uma vez por projeto.",
	},
	"status": {
		"titulo": "git status",
		"sintaxe": ["git status"],
		"faz": "Mostra a situação atual: quais arquivos são novos e ainda não rastreados (untracked), quais estão preparados para o próximo commit e se há algo a registrar. Só lê: não altera nada.",
		"serve": "Olhar antes de agir. É o comando para se orientar e para conferir o efeito de git add e git commit.",
		"exemplo": ["git status"],
		"resultado": "Em vermelho, arquivos não rastreados (untracked). Em verde, arquivos preparados (new file). Sem pendências, aparece \"working tree limpa\".",
		"jogo": "Mostra a sala (arquivos soltos, em vermelho) e a caixa (arquivos preparados, em verde).",
	},
	"add": {
		"titulo": "git add",
		"sintaxe": ["git add <arquivo>", "git add ."],
		"faz": "Move mudanças para a staging area (área de preparação): a lista do que vai entrar no próximo commit. Com o ponto, prepara tudo que é novo ou mudou na pasta atual.",
		"serve": "Escolher exatamente o que será registrado, em vez de levar tudo junto sem querer.",
		"exemplo": ["git add main.gd", "git add ."],
		"resultado": "O arquivo deixa de ser \"não rastreado\" e aparece em verde no git status, pronto para o commit. Ele ainda NÃO foi registrado no histórico.",
		"jogo": "Coloca o arquivo na caixa. A caixa é a staging area.",
	},
	"commit": {
		"titulo": "git commit",
		"sintaxe": ["git commit -m \"mensagem\""],
		"faz": "Registra de forma permanente, no histórico, uma versão do que está na staging area, junto com uma mensagem. Só entra o que foi preparado com git add; o resto fica de fora.",
		"serve": "Criar pontos de salvamento (save points) para consultar, comparar e voltar a versões anteriores. A mensagem explica o que mudou.",
		"exemplo": ["git commit -m \"Adiciona main.gd e setup.gd\""],
		"resultado": "O Git mostra o identificador do commit e a mensagem, e a staging area fica vazia. Arquivos já registrados deixam de aparecer como novos no git status.",
		"jogo": "Tira a foto (save point) do que estava na caixa. Escreva mensagens claras: elas contam o que cada foto guarda.",
	},
}

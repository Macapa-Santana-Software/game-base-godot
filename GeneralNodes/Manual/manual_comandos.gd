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
	"log": {
		"titulo": "git log",
		"sintaxe": ["git log", "git log --oneline"],
		"faz": "Mostra o histórico de commits da branch em que você está, do mais recente para o mais antigo. Cada commit aparece com seu identificador e a mensagem. Só lê: não altera nada.",
		"serve": "Entender o que já aconteceu no projeto antes de mudar algo, e conferir o efeito de commits e merges.",
		"exemplo": ["git log", "git log --oneline"],
		"resultado": "Uma lista de commits. A branch em que você está aparece marcada com HEAD, e as outras branches aparecem ao lado do commit para onde apontam. Com --oneline, uma linha por commit.",
		"jogo": "Lê o passado do mundo: as fotos (commits) que já foram tiradas, da mais nova para a mais antiga.",
	},
	"branch": {
		"titulo": "git branch",
		"sintaxe": ["git branch", "git branch <nome>"],
		"faz": "Sem nome, lista as branches (a atual vem marcada com *). Com um nome, cria uma nova branch a partir do commit atual. Criar a branch NÃO muda você para ela.",
		"serve": "Trabalhar numa cópia paralela do projeto, sem arriscar a linha principal (main).",
		"exemplo": ["git branch ponte"],
		"resultado": "O terminal confirma a criação e informa que você continua na branch em que estava. Nada nos arquivos muda ainda.",
		"jogo": "Cria uma cópia segura do mundo: uma linha paralela onde o conserto pode ser feito sem mexer na main.",
	},
	"switch": {
		"titulo": "git switch",
		"sintaxe": ["git switch <branch>"],
		"faz": "Passa para outra branch que já existe. A pasta de trabalho passa a mostrar o que existe naquela linha do histórico.",
		"serve": "Alternar entre linhas de trabalho, por exemplo entre a main e uma branch de conserto.",
		"exemplo": ["git switch ponte", "git switch main"],
		"resultado": "O terminal avisa que você mudou de branch. O que for commitado a partir daí fica só na branch atual.",
		"jogo": "Troca de realidade: na branch ponte a peça existe; na main, ainda não.",
	},
	"merge": {
		"titulo": "git merge",
		"sintaxe": ["git merge <branch>"],
		"faz": "Traz para a branch ATUAL o que foi feito em outra branch. Se a branch atual não andou desde que a outra nasceu, o Git apenas a adianta (fast-forward). Se as duas andaram, cria um commit de merge juntando as linhas.",
		"serve": "Levar um conserto ou uma novidade feita numa branch de volta para a linha principal.",
		"exemplo": ["git switch main", "git merge ponte"],
		"resultado": "O terminal informa o fast-forward ou o merge. O que estava só na outra branch passa a existir também na atual. Exige a staging area vazia (faça o commit antes).",
		"jogo": "Traz o conserto da ponte de volta para a main: é isso que faz a ponte existir no mundo principal.",
	},
}

class_name ConceitosFase2 extends RefCounted
## Conteúdo do painel de Conceitos da Fase 2: um verbete por conceito de Git usado na fase.
## Só dados. Textos curtos, em BBCode simples; "comando" é uma lista de linhas (pode ser vazia).
##
## "jogo" liga o conceito à metáfora da fase (Atlas, realidades, ecos) para o jogador relacionar
## a explicação ao que vê. Só entram conceitos que a Fase 2 realmente usa.

const ORDEM: Array[String] = ["repositorio", "commit", "branch", "head", "switch", "merge", "log"]

const ENTRADAS := {
	"repositorio": {
		"rotulo": "repo",
		"titulo": "Repositório",
		"faz": "A pasta que o Git acompanha. Guarda todo o histórico do projeto: os commits, as branches e a posição atual (HEAD).",
		"jogo": "O Atlas das Ramificações é o repositório desta fase: cada nó é um commit e cada linha é uma branch.",
		"comando": [],
	},
	"commit": {
		"rotulo": "commit",
		"titulo": "Commit",
		"faz": "Registro permanente de um estado do projeto, com uma mensagem. Cada commit aponta para o anterior (seu pai) e assim forma o histórico.",
		"jogo": "Ao registrar um eco nasce um nó novo no Atlas, ligado ao anterior por um fio.",
		"comando": ["git add <arquivo>", "git commit -m \"mensagem\""],
	},
	"branch": {
		"rotulo": "branch",
		"titulo": "Branch",
		"faz": "Uma linha independente de desenvolvimento. Criar uma branch não copia arquivos nem muda onde você está: só cria um novo ponteiro para o commit atual.",
		"jogo": "A vida-alternativa é uma branch: uma realidade que passa a crescer separada de main.",
		"comando": ["git branch <nome>"],
	},
	"head": {
		"rotulo": "HEAD",
		"titulo": "HEAD",
		"faz": "Aponta para a branch ativa e, por ela, para o commit atual. Os próximos commits entram na branch para onde o HEAD aponta.",
		"jogo": "No Atlas, o marcador HEAD mostra em qual realidade você está agora.",
		"comando": [],
	},
	"switch": {
		"rotulo": "switch",
		"titulo": "Switch",
		"faz": "Troca a branch ativa, movendo o HEAD. A pasta de trabalho passa a refletir aquela linha. Nada é apagado nem unido.",
		"jogo": "Trocar de branch leva você à outra realidade. As fissuras são âncoras: ligam pontos equivalentes das duas.",
		"comando": ["git switch <branch>"],
	},
	"merge": {
		"rotulo": "merge",
		"titulo": "Merge",
		"faz": "Integra na branch ativa o histórico de outra branch. Se as duas divergiram, cria um commit de merge com dois pais. A branch de origem não muda.",
		"jogo": "Estando em main, o merge reúne a vida-alternativa: no Atlas, o nó de merge recebe dois fios.",
		"comando": ["git merge <branch>"],
	},
	"log": {
		"rotulo": "log",
		"titulo": "Log",
		"faz": "Lista os commits da branch ativa, do mais recente ao mais antigo, com id e mensagem. Só lê: não altera nada.",
		"jogo": "É a consulta ao passado do Atlas: mostra o que já foi registrado.",
		"comando": ["git log", "git log --oneline"],
	},
}

class_name RoteiroDicasEidolon extends RefCounted
## Texto das DICAS GRADUAIS do Eidolon (a lógica fica em DicasEidolon).
##
## Três níveis:
##   1 ORIENTAÇÃO   aponta o que observar no cenário ou no Atlas; não explica a solução
##   2 CONCEITO     explica o conceito Git envolvido (com nota técnica "Em Git:" à parte)
##   3 PRÁTICA      diz que comando usar; nunca o executa
##
## Voz: a mesma da Etapa 1. Eidolon ainda está na fase de CERTEZA: formal, preciso, um pouco
## burocrático; ajuda o Walker a ler os registros. Aqui NÃO há dúvida nem mudança de opinião.
## As notas "Em Git:" descrevem só o comportamento real do Git e ficam separadas da fala.
##
## Placeholders: {branch_alvo} {ativa} {nome} {origem} {arquivo} {comando}.
## Trechos entre `crases` aparecem destacados como comandos.

## Etapas na ordem de progressão (usada para saber se o jogador avançou).
const ETAPAS: Array[StringName] = [
	&"consultar_log", &"criar_branch", &"entrar_vida", &"coletar_eco_vida",
	&"registrar_vida_add", &"registrar_vida_commit", &"voltar_main",
	&"coletar_eco_main", &"registrar_main_add", &"registrar_main_commit",
	&"integrar", &"inspecionar_merge", &"observar_registro", &"concluido",
]

## Dica por etapa e nível: { fala, nota? }
const DICAS_ETAPA := {
	&"consultar_log": {
		1: {"fala": "Há uma memória neste Atlas que você ainda não leu. O terminal sabe consultá-la."},
		2: {"fala": "O histórico é a sequência de memórias de uma linha, da mais recente à mais antiga. Lê-lo é o primeiro passo para entender onde estamos.",
			"nota": "Em Git: o histórico de uma branch é a sequência de commits que leva ao seu commit mais recente."},
		3: {"fala": "Para ler as memórias desta linha, digite `git log`."},
	},
	&"criar_branch": {
		1: {"fala": "O Atlas ainda mostra uma única linha. Observe o que está faltando."},
		2: {"fala": "Uma branch é uma referência para uma linha de desenvolvimento. Criá-la não significa mudar para ela.",
			"nota": "Em Git: uma branch é um ponteiro para um commit. Criar uma branch não altera a branch ativa."},
		3: {"fala": "Para abrir uma nova linha, use `git branch` seguido do nome. Meus registros apontam '{branch_alvo}'."},
	},
	&"entrar_vida": {
		1: {"fala": "A nova linha já existe no Atlas, mas o HEAD marca outra. Em qual linha você está agora?"},
		2: {"fala": "O HEAD indica a linha ativa: é nela que o seu trabalho acontece. Para trabalhar em outra linha, é preciso mudar para ela.",
			"nota": "Em Git: o HEAD aponta para a branch em que você está; `git switch` muda para outra branch."},
		3: {"fala": "Para entrar na nova linha, use `git switch {branch_alvo}` em qualquer terminal (o do Arquivo é o mais próximo de quem está em main)."},
	},
	&"coletar_eco_vida": {
		1: {"fala": "O eco desta linha fica além do espinheiro. O que existe do outro lado do Atlas?"},
		2: {"fala": "O que está acessível depende da linha ativa: o espinheiro existe nesta realidade e não existe em main.",
			"nota": "Em Git: cada branch tem o seu próprio conteúdo; ao trocar de branch, a pasta de trabalho muda junto."},
		3: {"fala": "Use `git switch main` junto a uma fissura, caminhe por main até o outro lado do espinheiro e volte com `git switch {branch_alvo}` na fissura de lá."},
	},
	&"registrar_vida_add": {
		1: {"fala": "Um arquivo novo está na pasta, mas o Git ainda não o acompanha. Observe o estado dela."},
		2: {"fala": "Antes de registrar, escolhe-se o que entra no registro. Essa área de espera é a staging area.",
			"nota": "Em Git: `git add` coloca alterações na staging area; o commit registra apenas o que está nela."},
		3: {"fala": "Separe o arquivo com `git add {arquivo}`, ou `git add .` para tudo."},
	},
	&"registrar_vida_commit": {
		1: {"fala": "O arquivo já foi separado. Falta transformá-lo em memória."},
		2: {"fala": "Um commit é uma memória registrada: o instantâneo do que estava na staging area, com uma mensagem.",
			"nota": "Em Git: `git commit` grava o conteúdo da staging area como um novo commit na branch ativa."},
		3: {"fala": "Registre com `git commit -m \"mensagem\"`."},
	},
	&"voltar_main": {
		1: {"fala": "O registro ficou nesta linha. O Atlas mostra que a outra ainda não o possui."},
		2: {"fala": "Cada linha tem o seu próprio histórico: o que foi registrado aqui não existe em main até ser integrado.",
			"nota": "Em Git: um novo commit faz avançar apenas a branch ativa; as outras branches continuam onde estavam."},
		3: {"fala": "Volte à linha principal com `git switch main`."},
	},
	&"coletar_eco_main": {
		1: {"fala": "O eco de main fica no sudoeste desta realidade. Observe por onde se chega até ele."},
		2: {"fala": "Para que as duas linhas tenham histórias diferentes, cada uma precisa receber os seus próprios registros.",
			"nota": "Em Git: duas branches divergem quando cada uma recebe commits que a outra não tem."},
		3: {"fala": "Recolha o eco; depois use `git add` e `git commit` aqui, em main."},
	},
	&"registrar_main_add": {
		1: {"fala": "O eco de main é um arquivo novo nesta linha. Falta separá-lo."},
		2: {"fala": "Como antes: só o que está na staging area entra no próximo commit."},
		3: {"fala": "Use `git add {arquivo}` e depois `git commit -m \"mensagem\"`."},
	},
	&"registrar_main_commit": {
		1: {"fala": "O arquivo está separado. Você já sabe como transformá-lo em memória."},
		2: {"fala": "O commit grava a staging area na linha ativa, que agora é main."},
		3: {"fala": "Registre com `git commit -m \"mensagem\"`."},
	},
	&"integrar": {
		1: {"fala": "Duas linhas, cada uma com registros que a outra não tem. O Atlas as mostra separadas. A integração se faz na linha de destino."},
		2: {"fala": "Integrar é trazer para a linha ativa os registros de outra. A linha ativa é o destino.",
			"nota": "Em Git: `git merge <branch>` traz para a branch ativa os commits de <branch>. Se os históricos divergiram, cria um commit de merge com dois pais."},
		3: {"fala": "Estando em main, use `git merge {branch_alvo}`."},
	},
	&"inspecionar_merge": {
		1: {"fala": "O Atlas guarda o ponto onde as duas linhas se encontram. Procure-o e inspecione-o."},
		2: {"fala": "Um commit de merge é diferente dos outros: aponta para dois commits, um de cada linha.",
			"nota": "Em Git: um commit de merge registra a integração de históricos e referencia os dois commits que foram unidos."},
		3: {"fala": "Abra o Atlas (há artefatos no Arquivo e no Ponto de Convergência), selecione o nó de dois fios e inspecione-o com ENTER ou clique."},
	},
	&"observar_registro": {
		1: {"fala": "As linhas convergiram. O registro final, na última câmara, guarda o resultado."},
		2: {"fala": "O registro final lê o histórico real do repositório. Falta observá-lo."},
		3: {"fala": "Siga até o registro final, na última câmara, e interaja com ele."},
	},
}

## Falha do GameState -> explicação. Chaves: o motivo (ou "motivo:comando" quando específico).
##   categoria         "sintaxe" (forma do comando) | "ordem" (fora de ordem) | "compreensao" (conceito)
##   fala_na_primeira  sintaxe só fala na 1ª vez se isto for true (o terminal já mostra o erro)
##   etapa_fallback    etapa cujas dicas valem quando o nível não está aqui (padrão: a etapa atual)
##   niveis            { nível: {fala, nota?} }; nível ausente = usa a dica da etapa
const CATALOGO := {
	# --- sintaxe ---------------------------------------------------------------------------
	"uso_incorreto:commit": {"categoria": "sintaxe", "niveis": {
		3: {"fala": "A mensagem do commit vai entre aspas: `git commit -m \"texto\"`."}}},
	"uso_incorreto:add": {"categoria": "sintaxe", "niveis": {
		3: {"fala": "Diga o que separar: `git add nome-do-arquivo`, ou `git add .` para tudo."}}},
	"uso_incorreto:branch": {"categoria": "sintaxe", "niveis": {
		3: {"fala": "O comando aceita no máximo um nome: `git branch nome`."}}},
	"uso_incorreto:switch": {"categoria": "sintaxe", "niveis": {
		3: {"fala": "É preciso indicar a linha de destino: `git switch nome`."}}},
	"uso_incorreto:merge": {"categoria": "sintaxe", "niveis": {
		3: {"fala": "Indique a linha a integrar: `git merge nome`."}}},
	"uso_incorreto:log": {"categoria": "sintaxe", "niveis": {
		3: {"fala": "A única opção disponível é `git log --oneline`."}}},
	"uso_incorreto": {"categoria": "sintaxe", "niveis": {
		3: {"fala": "Confira a forma do comando em `git help`."}}},
	"comando_inexistente": {"categoria": "sintaxe", "niveis": {
		3: {"fala": "Os comandos começam por `git`. `git help` lista os que já despertaram."}}},
	"nao_e_git": {"categoria": "sintaxe", "niveis": {
		3: {"fala": "Os comandos começam por `git`. `git help` lista os que já despertaram."}}},
	"nome_invalido": {"categoria": "sintaxe", "fala_na_primeira": true, "niveis": {
		1: {"fala": "Neste Atlas, os nomes de linha usam letras minúsculas, números, '-' e '_'."},
		3: {"fala": "Meus registros apontam o nome '{branch_alvo}'."}}},
	"arquivo_inexistente": {"categoria": "sintaxe", "fala_na_primeira": true, "niveis": {
		1: {"fala": "Esse nome não está na pasta. `git status` mostra os nomes exatos."},
		3: {"fala": "Copie o nome tal como `git status` o mostra, por exemplo `git add {arquivo}`."}}},
	"branch_inexistente_parecida": {"categoria": "sintaxe", "fala_na_primeira": true, "niveis": {
		1: {"fala": "Não encontro a linha '{nome}'. `git branch` lista as que existem."},
		3: {"fala": "Confira a grafia: meus registros apontam '{branch_alvo}'."}}},

	# --- ordem -------------------------------------------------------------------------------
	"comando_bloqueado": {"categoria": "ordem"},
	"comando_indisponivel": {"categoria": "ordem"},
	"merge_bloqueado": {"categoria": "ordem", "etapa_fallback": &"integrar"},
	"staging_vazia": {"categoria": "ordem", "niveis": {
		1: {"fala": "A staging area está vazia: nada foi separado para o registro. O que falta antes do commit?"},
		2: {"fala": "O commit só grava o que está na staging area.",
			"nota": "Em Git: `git commit` registra apenas o que foi adicionado com `git add`."}}},
	"nada_para_adicionar": {"categoria": "ordem", "niveis": {
		1: {"fala": "Não há arquivo novo na pasta. O mundo ainda não lhe deu algo para registrar."},
		2: {"fala": "Só se separa o que existe na pasta e ainda não foi registrado nesta linha."}}},
	"staging_pendente": {"categoria": "ordem", "niveis": {
		1: {"fala": "Há arquivos separados que ainda não viraram memória. Registre-os antes de integrar."},
		3: {"fala": "Use `git commit -m \"mensagem\"` e depois repita a integração."}}},

	# --- compreensão ----------------------------------------------------------------------------
	"branch_ja_existe": {"categoria": "compreensao", "niveis": {
		2: {"fala": "A linha '{nome}' já existe. Criar uma branch não leva você até ela.",
			"nota": "Em Git: `git branch <nome>` só cria o ponteiro; para mudar de branch usa-se `git switch`."},
		3: {"fala": "Para entrar nela, use `git switch {nome}`."}}},
	"branch_inexistente": {"categoria": "compreensao", "niveis": {
		2: {"fala": "Só se muda para uma linha que já existe. Antes é preciso abri-la.",
			"nota": "Em Git: `git switch <branch>` exige uma branch que já exista."},
		3: {"fala": "Abra-a com `git branch {nome}` e depois entre com `git switch {nome}`."}}},
	"branch_inexistente:merge": {"categoria": "compreensao", "niveis": {
		2: {"fala": "Só se integra uma linha que já existe. `git branch` lista as que existem."},
		3: {"fala": "Confira o nome: meus registros apontam '{branch_alvo}'."}}},
	"mesma_branch": {"categoria": "compreensao", "niveis": {
		2: {"fala": "Você está em '{ativa}': integrar uma linha nela mesma não faz sentido. O destino é sempre a linha ativa.",
			"nota": "Em Git: `git merge <branch>` traz os commits de <branch> para a branch ativa, que é o destino."},
		3: {"fala": "Mude para o destino com `git switch main` e então use `git merge {origem}`."}}},
	"ja_na_staging": {"categoria": "compreensao", "niveis": {
		2: {"fala": "Esse arquivo já foi separado: está na staging area, pronto para o commit."}}},
	"ja_versionado": {"categoria": "compreensao", "niveis": {
		2: {"fala": "Esse arquivo já faz parte do histórico desta linha. Um novo registro só é pedido se algo mudar."}}},
}

## Quando o jogador tenta `git merge` antes de poder: diz o que falta (nível 1).
const MERGE_FALTA := {
	"vida": "A integração exige registros próprios nas duas linhas. A '{branch_alvo}' ainda não tem o dela.",
	"main": "Falta o registro de main: ela precisa ter algo que a outra linha não tem.",
	"destino": "Integra-se na linha de destino. Volte para main antes.",
}

const ESGOTADO := "Já lhe indiquei o caminho que conheço. Releia as minhas indicações e observe o Atlas."

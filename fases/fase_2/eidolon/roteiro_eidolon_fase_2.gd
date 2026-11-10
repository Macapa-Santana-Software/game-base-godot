class_name RoteiroEidolonFase2 extends RefCounted
## TODO o texto do Eidolon na Fase 2, num só lugar (a lógica fica em EidolonFase2).
##
## Voz: arquivista formal, preciso, paciente; pensa em "registros", "memórias" e "desvios".
## Nunca erra sobre Git: o que ele erra são JUÍZOS (chamar a divergência de falha). Fragmentos
## de memória faltando aparecem como "[...]".
##
## Cada entrada:
##   canal       "dialogo" (CaixaDialogo, bloqueante) | "terminal" (reação a um comando)
##   prioridade  1 baixa · 2 normal · 3 alta (alta ignora o cooldown do balão)
##   unica       true = só é dita uma vez (persistida em EidolonEstado)
##   etapa       etapa do arco que esta fala inaugura (opcional)
##   linhas      falas do Eidolon (com {chaves} substituídas por EidolonFase2)
##   nota        nota técnica "Em Git:" (opcional) — texto NEUTRO, sem a voz do Eidolon
##   balao       versão curta para quando o terminal está fechado (opcional; sem ela a fala
##               fica em silêncio fora do terminal)
##
## Trechos entre `crases` aparecem destacados como comandos. Revisão técnica das notas:
## só descrevem o comportamento real do Git (ver docs/FASE_2_ESTRUTURA.md).

const PREFIXO_DIALOGO := "Eidolon: "

const FALAS := {
	# ---- Despertar (diálogo bloqueante): ao chegar perto do terminal/Atlas da Área 1 --------
	&"despertar": {
		"canal": "dialogo", "prioridade": 3, "unica": true,
		"etapa": EidolonEstado.ETAPA_CERTEZA,
		"linhas": [
			"...Walker? Sim. Eu me reconheço. Fui um arquivista, ou parte de um.",
			"Este Atlas guarda o que restou do meu ofício: as memórias e as linhas que as ligam.",
			"Meu trabalho era manter cada realidade em ordem. Toda divergência é um erro esperando correção.",
			"Comece pelo terminal: peça o histórico da realidade em que estamos.",
		],
	},

	# ---- git log (primeira vez) ----------------------------------------------------------------
	&"log_primeira": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": [
			"A memória mais antiga deste registro: “{mensagem}”. Dela partem todas as outras.",
			"Meus registros apontam uma possibilidade que nunca foi aberta: '{branch_alvo}'. Se eu a abrir a partir daqui... o mundo muda?",
			"Abra-a aqui mesmo, pelo terminal: `git branch {branch_alvo}`.",
		],
		"nota": "Em Git: `git log` lista os commits do histórico da branch ativa, do mais recente ao mais antigo.",
	},

	# ---- git branch <nome> (a branch esperada) ---------------------------------------------------
	&"branch_criada": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": [
			"Nada mudou. Continuamos em '{ativa}'. E, no entanto, o Atlas ganhou uma linha nova.",
			"Uma possibilidade ainda não catalogada. Vou tratá-la como um desvio a observar.",
			"Criar uma linha não nos leva até ela. Para entrar, use o terminal: `git switch {branch_alvo}`.",
		],
		"balao": "Uma linha nova no Atlas. E continuamos em '{ativa}'. Para entrar nela, use no terminal: git switch {branch_alvo}.",
		"nota": "Em Git: `git branch <nome>` cria um novo ponteiro para o commit atual. O HEAD continua na branch em que você estava.",
	},

	# ---- git branch <outro nome> ---------------------------------------------------------------------
	&"branch_criada_outra": {
		"canal": "terminal", "prioridade": 2, "unica": false, "intervalo_s": 20.0,
		"linhas": [
			"Uma possibilidade nova: '{nome}'. Meus registros esperavam outra: '{branch_alvo}'.",
		],
		"nota": "Em Git: `git branch <nome>` cria um novo ponteiro para o commit atual. O HEAD continua na branch em que você estava.",
	},
}


## ---- Etapa 3: desconforto (Área 2) e dúvida (Área 3) ---------------------------------------------
## Eidolon AINDA acredita que divergência é desvio. Ele só encontra evidências que não consegue
## explicar: não conclui nada, e a integração das realidades não é mencionada como solução.
## Fragmentos (ids frag_*): o texto que o jogador lê está na cena; aqui só a reação de Eidolon.
## `evidencia` (opcional): conta como evidência quando a fala é entregue (ver EidolonEstado).
const NOTA_SWITCH := "Em Git: `git switch` muda a branch ativa (o HEAD) e o conteúdo da pasta de trabalho; o histórico dos commits continua intacto."

const FALAS_REALIDADES := {
	# Área 2: a trilha verde acende (momento-chave: prioridade alta, ignora o cooldown do balão)
	&"a2_desconforto_main": {
		"canal": "terminal", "prioridade": 3, "unica": true, "etapa": EidolonEstado.ETAPA_DESCONFORTO,
		"linhas": ["Uma trilha verde que não consta nos meus registros. Um desvio, sem dúvida. Estamos em '{ativa}', mas ela está... acesa."],
		"balao": "Uma trilha verde que não consta nos meus registros. Um desvio, sem dúvida. Estamos em '{ativa}', mas ela está... acesa.",
	},
	&"a2_desconforto_vida": {
		"canal": "terminal", "prioridade": 3, "unica": true, "etapa": EidolonEstado.ETAPA_DESCONFORTO,
		"linhas": ["A trilha verde nos acompanha: o HEAD está nela. Um desvio, sem dúvida. Mas por que me incomoda tanto?"],
		"balao": "A trilha verde nos acompanha: o HEAD está nela. Um desvio, sem dúvida. Mas por que me incomoda tanto?",
	},

	# git switch
	&"switch_primeira": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": [
			"O cenário mudou. As memórias, não: a primeira continua no Atlas.",
			"Estamos em '{ativa}'. A mesma estrutura, outro desfecho.",
		],
		"balao": "O cenário mudou, mas as memórias continuam no Atlas. Estamos em '{ativa}'.",
		"nota": NOTA_SWITCH,
	},
	&"switch_a3_primeira": {
		"canal": "terminal", "prioridade": 2, "unica": true, "evidencia": "complementares",
		"linhas": [
			"Mesma sala, outro desfecho: o que falta numa realidade existe na outra.",
			"Eu chamaria isto de desvio. Mas desvios não costumam ser tão... complementares.",
		],
		"balao": "Mesma sala, outro desfecho. O que falta numa realidade existe na outra. Complementares... estranho para um desvio.",
		"nota": "Em Git: ao trocar de branch, a pasta de trabalho passa a refletir os arquivos daquela branch.",
	},
	&"switch_main_apos_commit": {
		"canal": "terminal", "prioridade": 2, "unica": true, "evidencia": "arquivo_ausente_em_main",
		"linhas": [
			"{sujeito} {nao_existe} aqui. {registrado} na outra linha.",
			"Cada linha guarda o que a outra não tem. Isso não deveria me surpreender, e no entanto.",
		],
		"balao": "{sujeito} {nao_existe} aqui. {registrado} na outra linha. Cada uma guarda o que a outra não tem.",
		"nota": "Em Git: ao voltar para a branch main, a pasta de trabalho deixa de ter os arquivos que só existem na outra branch; eles continuam no histórico dela.",
	},

	# git add / git commit (dados reais das operações)
	&"add_primeira": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": ["Separado não é registrado. {arquivos} {espera} na staging area, ainda fora da história."],
		"nota": "Em Git: `git add` coloca o arquivo na staging area; ele só entra no histórico depois de `git commit`.",
	},
	&"commit_vida": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": [
			"Uma nova memória nesta linha: “{mensagem}” ({id}), com {arquivos}. Em 'main' ela não existe.",
			"O Atlas mostra de onde ela nasceu, se quiser ver.",
		],
		"balao": "Nova memória em '{ativa}': “{mensagem}”. Em main ela não existe.",
		"nota": "Em Git: um commit avança apenas a branch ativa; as outras branches continuam onde estavam.",
	},

	# Ecos principais (reação curta, depois do texto do eco). Momento-chave da história: prioridade
	# alta, não cai no cooldown do balão por causa de um fragmento opcional lido antes.
	&"eco_vida_reacao": {
		"canal": "terminal", "prioridade": 3, "unica": true,
		"linhas": ["Há uma assinatura de arquivista neste eco: 'preservada de propósito'. Isso não consta na doutrina que eu recordo."],
		"balao": "Há uma assinatura de arquivista neste eco: 'preservada de propósito'. Isso não consta na doutrina que eu recordo.",
	},
	&"eco_main_reacao": {
		"canal": "terminal", "prioridade": 3, "unica": true,
		"linhas": ["Este eco guarda a sala como era antes da poda. Curioso: o que falta aqui, a outra linha conservou."],
		"balao": "Este eco guarda a sala como era antes da poda. Curioso: o que falta aqui, a outra linha conservou.",
	},

	# Fragmentos opcionais: reação curta de Eidolon (nunca obrigatória)
	&"frag_m1": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": ["Poda: o procedimento correto. Então por que a palavra 'encerrada' me incomoda?"],
		"balao": "Poda: o procedimento correto. Então por que a palavra 'encerrada' me incomoda?",
	},
	&"frag_m2": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": ["Desligada. Alguém preferiu cortar a ponte a consertá-la. [...] Isso não é falha de estrutura."],
		"balao": "Desligada. Alguém preferiu cortar a ponte a consertá-la. Isso não é falha de estrutura.",
	},
	&"frag_m3": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": ["'E.' [...] Não me lembro de ter pedido isso. Ou de não ter pedido."],
		"balao": "'E.' [...] Não me lembro de ter pedido isso. Ou de não ter pedido.",
	},
	&"frag_v1": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": ["Catalogada, não esquecida. Por quem? E por quê?"],
		"balao": "Catalogada, não esquecida. Por quem? E por quê?",
	},
	&"frag_v2": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": ["'Catalogar ambos.' Nunca vi essa instrução no manual. Ou vi, e não lembro."],
		"balao": "'Catalogar ambos.' Nunca vi essa instrução no manual. Ou vi, e não lembro.",
	},
	&"frag_v3": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": ["Escala reduzida. Por que reduzida? A pergunta ficou sem resposta no registro."],
		"balao": "Escala reduzida. Por que reduzida? A pergunta ficou sem resposta no registro.",
	},

	# Reflexão pelo Atlas: depois de inspecionar a memória registrada na branch alternativa
	&"atlas_commit_vida": {
		# Prioridade alta: foi o jogador quem foi inspecionar; a resposta não pode cair no cooldown.
		"canal": "terminal", "prioridade": 3, "unica": true,
		"linhas": [
			"Esta memória pertence a '{branch}': “{mensagem}”. O pai dela está em main ({pai}).",
			"Ela nasceu de lá, e main ainda não a conhece.",
		],
		"balao": "Esta memória nasceu de {pai}, em main. E main ainda não a conhece.",
		"nota": "Em Git: cada commit aponta para o commit anterior (o pai); uma branch é apenas o ponteiro para o commit mais recente da sua linha.",
		"nota_no_balao": true,
	},
}


## ---- Etapa 4: conflito (Área 4) e reinterpretação parcial (Área 5) ----------------------------
## Antes do merge Eidolon defende que UMA linha deve prevalecer (a doutrina). Depois, vê que nenhuma
## desapareceu: surpresa e questionamento, não aceitação. A Catástrofe NÃO é explicada: a lacuna de
## memória aparece sempre no mesmo ponto (como a antiga unificação foi feita).
## As crenças dele são sobre as REALIDADES; sobre Git ele nunca erra (notas "Em Git:" corretas).
## Falas com `{chaves}`: dados reais do merge (ver EidolonFase2).
const FALAS_CONVERGENCIA := {
	# Área 4, ao chegar (balão): a doutrina
	&"a4_prevalecer": {
		"canal": "terminal", "prioridade": 3, "unica": true, "etapa": EidolonEstado.ETAPA_CONFLITO,
		"linhas": ["Duas linhas não podem ocupar o mesmo registro. Uma deve prevalecer. Escolha a mais [...] correta."],
		"balao": "Duas linhas não podem ocupar o mesmo registro. Uma deve prevalecer. Escolha a mais [...] correta.",
	},
	# Primeira vez que o terminal da Área 4 é aberto antes do merge
	&"a4_prevalecer_terminal": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": [
			"A doutrina diz que da integração resta uma só realidade. Eu diria qual... mas a minha memória falha justamente aí.",
			"Integre, se for preciso. O Atlas mostrará o que sobra.",
		],
	},

	# Logo depois do merge (terminal aberto): curto; o momento forte vem no diálogo ao fechar
	&"merge_terminal": {
		"canal": "terminal", "prioridade": 2, "unica": true,
		"linhas": ["O merge terminou. Mas 'main' e '{origem}' continuam no Atlas. O commit é {id}."],
		"balao": "O merge terminou. Mas as duas linhas continuam no Atlas.",
		"nota": "Em Git: `git merge` integra os commits da branch de origem na branch de destino; a branch de origem continua existindo, com o mesmo histórico.",
	},
	# Ponto de virada (2º diálogo bloqueante)
	&"merge_virada": {
		"canal": "dialogo", "prioridade": 3, "unica": true,
		"linhas": [
			"...Espere. Eu esperava que uma linha substituísse a outra.",
			"Mas 'main' continua aqui. E a 'vida-alternativa' também. Nenhuma desapareceu.",
			"O que fizemos não foi escolher. Foi juntar sem apagar. Isso [...] não consta nos meus registros.",
			"Preciso entender o que acabei de ver. O Atlas deve mostrar o ponto onde elas se encontram. Procure-o.",
		],
	},

	# Reflexão pelo Atlas: só quando o jogador inspeciona o nó REAL do merge, com os pais certos
	&"atlas_merge_reflexao": {
		"canal": "terminal", "prioridade": 3, "unica": true,
		"linhas": [
			"Dois pais: {pai_main}, de main, e {pai_vida}, da vida-alternativa. Nenhuma história engoliu a outra.",
			"Cada linha continua com o seu próprio caminho até aqui; este ponto as une.",
		],
		"balao": "Dois pais, um de cada linha. Nenhuma história engoliu a outra.",
		"nota": "Em Git: um commit de merge registra a integração de históricos e referencia os dois commits que foram unidos.",
		"nota_no_balao": true,  # a nota técnica vem logo depois da fala, separada dela
	},

	# Área 5: tentou o registro com o merge feito, mas sem inspecionar o commit de merge no Atlas.
	# Orienta sem dizer como (as dicas graduais cuidam do resto). Não é única: pode lembrar de novo.
	&"registro_sem_reflexao": {
		"canal": "terminal", "prioridade": 3, "unica": false, "intervalo_s": 25.0,
		"linhas": ["O registro não responde ainda. Antes, observe no Atlas o ponto onde as duas linhas se encontram."],
		"balao": "O registro não responde ainda. Antes, observe no Atlas o ponto onde as duas linhas se encontram.",
	},

	# Área 5, depois de observar o registro final (3º diálogo bloqueante): reinterpretação parcial
	&"fechamento": {
		"canal": "dialogo", "prioridade": 3, "unica": true, "etapa": EidolonEstado.ETAPA_REINTERPRETACAO,
		"linhas": [
			"Integrar... compreendendo as duas histórias. Isso não é o que a doutrina chamava de unificação.",
			"Havia duas histórias, e o registro guarda as duas. Então o que fizemos antes era outra coisa.",
			"Tento lembrar como a antiga unificação foi feita... e encontro o mesmo vazio. Sempre o mesmo.",
			"Há outros registros além desta câmara, Walker. E uma porta de vidro que ainda não sei abrir.",
		],
	},
}


static func obter(id: StringName) -> Dictionary:
	if FALAS.has(id):
		return FALAS[id]
	if FALAS_CONVERGENCIA.has(id):
		return FALAS_CONVERGENCIA[id]
	return FALAS_REALIDADES.get(id, {})

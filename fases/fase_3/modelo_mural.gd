class_name ModeloMural extends Node
## Fase 3 — "O Mural Corrompido": o mini-repositório das RUNAS.
##
## O GameState ainda não guarda o CONTEÚDO dos arquivos (só quais entraram em cada commit),
## e ele não deve ser alterado por enquanto. Por isso, nesta fase, cada runa é um arquivo
## minúsculo ("cor: X") com as três versões que o Git compara:
##
##   base    o que está no último commit (HEAD)
##   indice  o que está na staging area (o "Palco")
##   atual   o que está na pasta de trabalho (a "Oficina")
##
## git add            indice = atual
## git restore        atual  = indice            (descarta a mudança, SEM volta)
## git restore --staged  indice = base           (tira do Palco, a mudança continua na Oficina)
## git diff           compara indice x atual   (--staged: base x indice)
##
## O estado fica em GameState.progresso_tutoria["mural"], então sobrevive a recarregar a cena
## (derrota) e é zerado junto com o resto da fase em reset_fase().
##
## Os comandos do terminal (diff, restore e, nesta fase, add e status) falam com este nó
## através de ModeloMural.ativo(). Sem ele na cena (Fases 1 e 2) eles seguem o GameState.

signal mudou
signal status_executado
signal diff_executado(nomes: Array)
signal runa_preparada(nome: String)
signal runa_restaurada(nome: String, da_staging: bool)
## Uma mudança BOA (não corrompida) foi descartada por um `git restore`.
signal trabalho_descartado(nome: String)

const GRUPO := &"mural_modelo"
const CHAVE := "mural"
const RUIDO := "ruído"

const FALHA_SEM_MUDANCAS := "sem_mudancas"

const ZONA_1: Array[String] = ["sol.runa", "lua.runa", "estrela.runa"]
const ZONA_2: Array[String] = ["terra.runa", "mar.runa", "fogo.runa", "vento.runa"]
const ZONA_3: Array[String] = ["aurora.runa", "eclipse.runa"]

## Mudanças BOAS feitas pelo próprio jogador (nome -> valor). Descartá-las é perder trabalho.
const BOAS := {
	"mar.runa": "verde",
	"aurora.runa": "dourado",
}

## base / indice / atual de cada runa no começo da fase.
const INICIAL := {
	# Zona 1: o Mural da Entrada (a corrupção passou aqui)
	"sol.runa": {"base": "dourado", "indice": "dourado", "atual": RUIDO},
	"lua.runa": {"base": "prata", "indice": "prata", "atual": RUIDO},
	"estrela.runa": {"base": "azul", "indice": "azul", "atual": "azul"},
	# Zona 2: a Oficina (corrupção + UMA mudança boa que não pode ser perdida)
	"terra.runa": {"base": "verde", "indice": "verde", "atual": RUIDO},
	"mar.runa": {"base": "azul", "indice": "azul", "atual": "verde"},
	"fogo.runa": {"base": "vermelho", "indice": "vermelho", "atual": RUIDO},
	"vento.runa": {"base": "prata", "indice": "prata", "atual": "prata"},
	# Zona 3: o Palco (alguém deu "git add ." às pressas: as duas mudanças já estão no Palco)
	"aurora.runa": {"base": "prata", "indice": "dourado", "atual": "dourado"},
	"eclipse.runa": {"base": "roxo", "indice": RUIDO, "atual": RUIDO},
}

var _estado: Dictionary = {}


## O modelo da cena atual, ou null se a fase não tem mural (Fases 1 e 2).
static func ativo() -> ModeloMural:
	var arvore := Engine.get_main_loop() as SceneTree
	if arvore == null:
		return null
	return arvore.get_first_node_in_group(GRUPO) as ModeloMural


func _enter_tree() -> void:
	add_to_group(GRUPO)
	if not GameState.progresso_tutoria.has(CHAVE):
		GameState.progresso_tutoria[CHAVE] = {"runas": INICIAL.duplicate(true), "flags": {}}
	_estado = GameState.progresso_tutoria[CHAVE]


# ---------------------------------------------------------------------------
# Consultas
# ---------------------------------------------------------------------------

func nomes() -> Array[String]:
	var lista: Array[String] = []
	for nome in _estado["runas"].keys():
		lista.append(str(nome))
	return lista


func existe(nome: String) -> bool:
	return _estado["runas"].has(nome)


## { base, indice, atual } da runa (referência viva). {} se não existe.
func dados(nome: String) -> Dictionary:
	return _estado["runas"].get(nome, {})


func flag(chave: String) -> bool:
	return bool(_estado["flags"].get(chave, false))


func _marcar(chave: String) -> void:
	_estado["flags"][chave] = true


func preparada(nome: String) -> bool:
	var d := dados(nome)
	return not d.is_empty() and d["indice"] != d["base"]


func modificada(nome: String) -> bool:
	var d := dados(nome)
	return not d.is_empty() and d["atual"] != d["indice"]


func limpa(nome: String) -> bool:
	var d := dados(nome)
	return not d.is_empty() and d["atual"] == d["base"] and d["indice"] == d["base"]


## A mudança boa dessa runa foi perdida (nem na Oficina nem no Palco)?
func boa_perdida(nome: String) -> bool:
	if not BOAS.has(nome):
		return false
	var d := dados(nome)
	return d["atual"] != BOAS[nome] and d["indice"] != BOAS[nome]


func alguma_boa_perdida() -> bool:
	for nome in BOAS.keys():
		if boa_perdida(str(nome)):
			return true
	return false


## Zonas 1 e 2 sem corrupção e a mudança boa do mar preservada.
func zona_2_ok() -> bool:
	if not flag("diff_visto"):
		return false
	for nome in ZONA_1 + ZONA_2:
		if dados(nome)["atual"] == RUIDO:
			return false
	return not boa_perdida("mar.runa")


func zona_3_ok() -> bool:
	if not zona_2_ok():
		return false
	var aurora := dados("aurora.runa")
	return limpa("eclipse.runa") \
		and aurora["indice"] == aurora["atual"] and aurora["indice"] != aurora["base"]


# ---------------------------------------------------------------------------
# Comandos
# ---------------------------------------------------------------------------

func texto_status() -> String:
	var preparadas: Array[String] = []
	var modificadas: Array[String] = []
	for nome in nomes():
		if preparada(nome):
			preparadas.append(nome)
		if modificada(nome):
			modificadas.append(nome)

	var linhas: Array[String] = ["[color=#3DA9FF]## No branch %s[/color]" % GameState.branch_ativa]
	if not preparadas.is_empty():
		linhas.append("\nMudanças no Palco (prontas para o commit):")
		for nome in preparadas:
			linhas.append("\t[color=#3DFF9B]modified:   %s[/color]" % nome)
	if not modificadas.is_empty():
		linhas.append("\nMudanças na Oficina (ainda NÃO preparadas):")
		for nome in modificadas:
			linhas.append("\t[color=#FF6B6B]modified:   %s[/color]" % nome)
	if preparadas.is_empty() and modificadas.is_empty():
		linhas.append("\nNada para atualizar, working tree limpa.")
	else:
		linhas.append("\n[color=#8AA0B8]Dica: %s mostra exatamente o que mudou em cada runa.[/color]" % "git diff")

	_marcar("status_visto")
	if zona_2_ok():
		_marcar("status_palco")
	status_executado.emit()
	mudou.emit()
	return "\n".join(linhas)


func texto_diff(args: Array[String]) -> String:
	var no_palco := false
	var alvos: Array[String] = []
	for arg in args:
		if arg == "--staged" or arg == "--cached":
			no_palco = true
		elif arg.begins_with("-"):
			return GameState.registrar_falha("diff", GameState.FALHA_USO_INCORRETO,
				"[color=#FF6B6B]Erro: opção '%s' não reconhecida. Use: git diff [--staged] [<arquivo>][/color]" % arg.replace("[", "[lb]"))
		else:
			var resolvido := _resolver(arg)
			if resolvido.is_empty():
				return _arquivo_inexistente("diff", arg)
			alvos.append(resolvido)
	if alvos.is_empty():
		alvos = nomes()

	var linhas: Array[String] = []
	var com_diferenca: Array[String] = []
	for nome in alvos:
		var d := dados(nome)
		var antes: String = d["base"] if no_palco else d["indice"]
		var depois: String = d["indice"] if no_palco else d["atual"]
		if antes == depois:
			continue
		com_diferenca.append(nome)
		linhas.append("[color=#FFE08A]diff --git a/%s b/%s[/color]" % [nome, nome])
		linhas.append("[color=#8AA0B8]--- a/%s\n+++ b/%s[/color]" % [nome, nome])
		linhas.append("[color=#FF6B6B]-cor: %s[/color]" % antes)
		linhas.append("[color=#3DFF9B]+cor: %s[/color]\n" % depois)

	_marcar("diff_visto")
	diff_executado.emit(com_diferenca)
	mudou.emit()
	if linhas.is_empty():
		var onde := "no Palco" if no_palco else "na Oficina"
		return "[color=#8AA0B8]Nenhuma diferença %s: nada mudou em relação à versão anterior.[/color]" % onde
	return "\n".join(linhas).strip_edges()


func restaurar(args: Array[String]) -> String:
	var do_palco := false
	var alvos: Array[String] = []
	for arg in args:
		if arg == "--staged" or arg == "-S":
			do_palco = true
		elif arg == ".":
			for nome in nomes():
				if nome not in alvos:
					alvos.append(nome)
		elif arg.begins_with("-"):
			return GameState.registrar_falha("restore", GameState.FALHA_USO_INCORRETO,
				"[color=#FF6B6B]Erro: opção '%s' não reconhecida. Use: git restore [--staged] <arquivo>[/color]" % arg.replace("[", "[lb]"))
		else:
			var resolvido := _resolver(arg)
			if resolvido.is_empty():
				return _arquivo_inexistente("restore", arg)
			if resolvido not in alvos:
				alvos.append(resolvido)
	if alvos.is_empty():
		return GameState.registrar_falha("restore", GameState.FALHA_USO_INCORRETO,
			"[color=#FF6B6B]Erro: Uso correto: git restore <arquivo>   ou   git restore --staged <arquivo>[/color]")

	var feitos: Array[String] = []
	var perdidos: Array[String] = []
	for nome in alvos:
		var d := dados(nome)
		if do_palco:
			if d["indice"] == d["base"]:
				continue
			d["indice"] = d["base"]
			feitos.append(nome)
			_marcar("restore_staged_feito")
		else:
			if d["atual"] == d["indice"]:
				continue
			if d["atual"] != RUIDO:
				perdidos.append(nome)
			d["atual"] = d["indice"]
			feitos.append(nome)
			_marcar("restore_feito")

	if feitos.is_empty():
		var motivo := "Nenhuma dessas runas está no Palco." if do_palco else "Nenhuma dessas runas tem mudanças na Oficina para descartar."
		return GameState.registrar_falha("restore", FALHA_SEM_MUDANCAS,
			"[color=#FFCC00]%s Confira com git status.[/color]" % motivo)

	for nome in feitos:
		runa_restaurada.emit(nome, do_palco)
	for nome in perdidos:
		trabalho_descartado.emit(nome)
	mudou.emit()

	if do_palco:
		return "[color=#3DFF9B]Tirada do Palco: %s. A mudança continua na Oficina.[/color]" % ", ".join(feitos)
	return "[color=#3DFF9B]Restaurada: %s. A mudança foi descartada e NÃO volta.[/color]" % ", ".join(feitos)


func adicionar(args: Array[String]) -> String:
	var alvos: Array[String] = []
	for arg in args:
		if arg == "." or arg == "-A" or arg == "--all":
			for nome in nomes():
				if modificada(nome) and nome not in alvos:
					alvos.append(nome)
		else:
			var resolvido := _resolver(arg)
			if resolvido.is_empty():
				return _arquivo_inexistente("add", arg)
			if resolvido not in alvos:
				alvos.append(resolvido)

	var feitos: Array[String] = []
	for nome in alvos:
		if not modificada(nome):
			continue
		var d := dados(nome)
		d["indice"] = d["atual"]
		feitos.append(nome)
	if feitos.is_empty():
		return GameState.registrar_falha("add", GameState.FALHA_NADA_PARA_ADICIONAR,
			"[color=#FFCC00]Nada para adicionar: essas runas não têm mudanças na Oficina.[/color]")

	for nome in feitos:
		runa_preparada.emit(nome)
	mudou.emit()
	return "[color=#3DFF9B]No Palco (pronto para commit): %s.[/color]" % ", ".join(feitos)


## Reescreve as mudanças BOAS que o jogador perdeu (Altar da Reescrita).
func refazer_boas() -> void:
	for nome in BOAS.keys():
		if boa_perdida(str(nome)):
			dados(str(nome))["atual"] = BOAS[nome]
	mudou.emit()


# ---------------------------------------------------------------------------
# Auxiliares
# ---------------------------------------------------------------------------

## "sol.runa" -> "sol.runa"; "sol" -> "sol.runa"; desconhecido -> "".
func _resolver(arg: String) -> String:
	if existe(arg):
		return arg
	if existe(arg + ".runa"):
		return arg + ".runa"
	return ""


func _arquivo_inexistente(comando: String, arg: String) -> String:
	return GameState.registrar_falha(comando, GameState.FALHA_ARQUIVO_INEXISTENTE,
		"[color=#FFCC00]Erro: '%s' não é uma runa do mural. Veja os nomes com git status.[/color]" % arg.replace("[", "[lb]"))

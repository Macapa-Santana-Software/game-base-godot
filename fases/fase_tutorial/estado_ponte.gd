class_name EstadoPonte extends RefCounted
## Fatos da fase tutorial lidos do GameState (fonte única para a tutora, os objetivos,
## a ponte e a fase). Nada aqui guarda estado próprio: tudo é derivado do repositório
## Git real, então sobrevive a recarregar a cena.

const ARQUIVO := "ponte.tile"
const BRANCH := "ponte"

## Chaves guardadas em GameState.progresso_tutoria (zeradas em reset_fase()).
const FLAG_LOG := "log_visto"
const FLAG_ENTROU := "entrou_ponte"


## O arquivo da ponte está no histórico dessa branch?
static func versionada_em(branch: String) -> bool:
	if not GameState.branch_existe(branch):
		return false
	for commit in GameState.historico(branch):
		if ARQUIVO in commit["arquivos"]:
			return true
	return false


## A ponte já chegou ao mundo principal (merge feito)?
static func na_main() -> bool:
	return versionada_em(GameState.BRANCH_PADRAO)


## A ponte já foi consertada (commitada) na cópia segura?
static func na_ponte() -> bool:
	return versionada_em(BRANCH)


static func coletada() -> bool:
	return ARQUIVO in GameState.inventario_player or na_ponte()


static func log_visto() -> bool:
	return bool(GameState.progresso_tutoria.get(FLAG_LOG, false))


static func entrou_na_ponte() -> bool:
	return bool(GameState.progresso_tutoria.get(FLAG_ENTROU, false)) or na_ponte()


static func marcar(flag: String) -> void:
	GameState.progresso_tutoria[flag] = true

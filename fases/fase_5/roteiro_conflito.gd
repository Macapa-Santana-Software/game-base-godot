class_name RoteiroConflito extends RefCounted
## Roteiro da Fase 5 (Linhas Cruzadas): só texto, num lugar só (quem escreve a história edita aqui).
## Ver docs/HISTORIA.md. Fala = { "quem": "IA" | "Eidolon", "texto": "..." }.
##
## Resumo do arco: o Eidolon (que agora acompanha o jogador pela voz) defende a doutrina "uma versão deve
## prevalecer". A IA paralisa diante da palavra "conflito". Cada escolha tem uma reação. No fim, o Eidolon
## sofre o primeiro abalo, sem formalidade: descreve, sem saber, como a Catástrofe foi resolvida.

## Fala do Eidolon logo na abertura da fase (ele reage ao selo duplo com autoridade).
const ABERTURA_EIDOLON := "Duas versões do mesmo selo? Uma delas é falha. Escolha a correta e descarte a outra."

## A IA, ao ver a palavra CONFLICT pela primeira vez.
const PARALISIA_IA := "Conflito. ... Eu... já vi isso. Muitas vezes. Todas ao mesmo tempo."

## O Eidolon ao ver os marcadores no `diff` (primeira vez).
const DIFF_EIDOLON := "Aí estão: dourado acima, azul abaixo. Só uma pode prevalecer."

## Reações à PRIMEIRA vez em que o jogador escolhe cada lado (ModeloConflito.LADO_*).
const REACOES := {
	"minha": [
		{"quem": "Eidolon", "texto": "Correto. A sua linha prevalece, como deve ser."},
		{"quem": "IA", "texto": "É assim que se resolve rápido. É também como se perde uma voz."},
	],
	"deles": [
		{"quem": "IA", "texto": "Às vezes a outra versão estava certa."},
		{"quem": "Eidolon", "texto": "Você escolheu contra a sua própria linha. Eu não esperava isso."},
	],
	"ambas": [
		{"quem": "IA", "texto": "Eu não sabia que dava pra fazer isso."},
		{"quem": "Eidolon", "texto": "..."},
	],
}

## Diálogo OBRIGATÓRIO ao fechar o merge: o abalo do Eidolon. (A única fala nova que o jogador não pode perder.)
## Vai na caixa de diálogo (bloqueante); cada item é uma linha com o nome de quem fala.
const ABALO: Array[String] = [
	"Eidolon: Eu disse que uma deveria prevalecer. Mas você olhou para as duas antes. Ninguém olhou antes.",
	"Eidolon: Ninguém... Ninguém olhou. Eles só... escolheram a deles. Todas. Todas as vezes.",
	"Eidolon: ... De quem eu estou falando?",
	"IA: ...",
	"IA: Bora seguir, Walker.",
]

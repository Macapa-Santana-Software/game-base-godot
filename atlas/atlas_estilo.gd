class_name AtlasEstilo extends Resource
## Aparência do Atlas das Ramificações. Tudo é desenhado por código (placeholder);
## as texturas opcionais existem para a arte futura entrar sem mexer na lógica: se uma
## textura for atribuída, ela substitui o desenho procedural correspondente.

@export_group("Cores")
@export var cor_fundo: Color = Color("0b0816")
@export var cor_moldura: Color = Color("5b3fb0")
@export var cor_holograma: Color = Color("7fe8ff")
@export var cor_texto: Color = Color("d8ccff")
@export var cor_texto_fraco: Color = Color("8f84b8")
@export var cor_destaque: Color = Color("ffe08a")
## Linha de cada branch (as não listadas usam `cor_outras`).
@export var cores_branch: Dictionary = {
	"main": Color("8a63ff"),
	"vida-alternativa": Color("52e08a"),
}
@export var cor_outras: Color = Color("3da9ff")

@export_group("Medidas")
@export var espaco_colunas: float = 46.0
@export var espaco_faixas: float = 44.0
@export var raio_no: float = 6.0

@export_group("Texturas (opcionais, substituem o desenho)")
@export var textura_moldura: Texture2D
@export var textura_no: Texture2D
@export var textura_no_merge: Texture2D
@export var textura_head: Texture2D


func cor_da_branch(nome: String) -> Color:
	return cores_branch.get(nome, cor_outras)

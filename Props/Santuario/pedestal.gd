class_name PedestalArquivo extends Node2D

## Pedestal de um arquivo: aceso enquanto o arquivo está nele, apagado depois de coletado.

@export var nome_arquivo: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var luz: PointLight2D = $Luz


func _ready() -> void:
	GameState.arquivo_coletado.connect(_on_arquivo_coletado)
	_atualizar(nome_arquivo in GameState.inventario_player)


func _on_arquivo_coletado(nome: String) -> void:
	if nome == nome_arquivo:
		_atualizar(true)


func _atualizar(coletado: bool) -> void:
	sprite.frame = 0 if coletado else 1
	luz.energy = 0.0 if coletado else 0.6

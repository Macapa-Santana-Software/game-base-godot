class_name HeartIcon
extends Control
## Um coracao pixelado unico. Fica vermelho quando cheio e cinza quando vazio.

const PIXELS : Array[String] = [
	"0110110",
	"1111111",
	"1111111",
	"0111110",
	"0011100",
	"0001000",
]

@export var pixel_size : float = 3.0
@export var full_color : Color = Color(0.85, 0.16, 0.16)
@export var empty_color : Color = Color(0.32, 0.32, 0.32)

var _filled : bool = true

func _ready() -> void:
	custom_minimum_size = Vector2(PIXELS[0].length(), PIXELS.size()) * pixel_size

func set_filled(value : bool) -> void:
	if _filled == value:
		return
	_filled = value
	queue_redraw()

func _draw() -> void:
	var color : Color = full_color if _filled else empty_color
	for y in PIXELS.size():
		var row : String = PIXELS[y]
		for x in row.length():
			if row[x] == "1":
				draw_rect(Rect2(x * pixel_size, y * pixel_size, pixel_size, pixel_size), color)

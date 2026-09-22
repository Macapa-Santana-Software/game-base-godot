class_name KnockbackComponent
extends Node
## Componente generico de knockback para qualquer CharacterBody2D (Player,
## Enemy, Boss, NPC...). So mexe na velocity do dono, por um tempo curto, e
## deixa o move_and_slide() do proprio dono fazer o resto (respeita colisoes
## e paredes). Nao sabe nada de vida/dano — quem chama apply() decide isso.
##
## Quem precisar que IA/estados nao sobrescrevam a velocity durante o
## empurrao deve escutar knockback_started/knockback_ended e pausar o que for
## necessario (ver Player/Enemy: pausam a propria state machine).

signal knockback_started()
signal knockback_ended()

## Quanto tempo o empurrao dura. Curto e controlado, sem fisica complexa.
@export var duration : float = 0.18

var _body : CharacterBody2D
var _timer : float = 0.0
var _start_velocity : Vector2 = Vector2.ZERO

## Chame uma vez, geralmente no _ready() do dono: knockback_component.setup(self)
func setup(body : CharacterBody2D) -> void:
	_body = body

func is_active() -> bool:
	return _timer > 0.0

## Aplica o empurrao. direction nao precisa estar normalizada; force define a
## velocidade inicial do empurrao (px/s). Ignorado se direction for zero.
func apply(direction : Vector2, force : float) -> void:
	if _body == null or direction == Vector2.ZERO or force <= 0.0:
		return
	_start_velocity = direction.normalized() * force
	_body.velocity = _start_velocity
	_timer = duration
	knockback_started.emit()

## Chame no _physics_process() do dono, antes de move_and_slide(), enquanto
## is_active() for true. Desacelera linearmente ate zero em `duration` segundos.
func physics_tick(delta : float) -> void:
	if _timer <= 0.0:
		return
	_timer = maxf(_timer - delta, 0.0)
	if _timer <= 0.0:
		_body.velocity = Vector2.ZERO
		knockback_ended.emit()
	else:
		_body.velocity = _start_velocity * (_timer / duration)

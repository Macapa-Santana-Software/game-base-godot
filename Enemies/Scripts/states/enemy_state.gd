class_name EnemyState extends Node


## Stores a reference to the enemy that this state belongs to
var enemy : Enemy
var state_machine : EnemyStateMachine

# What happens when we initialize this state?
func init() -> void:
	pass # Replace with function body.


## What happens when the player enters this State?
func enter() -> void:
	pass


## What happens when the player exits this State?
func exit() -> void:
	pass


## What happens during the _process update in this State?
func process(_delta : float ) -> EnemyState:
	return null


## What happens during the _physics_process update in this State?
func physics(_delta : float) -> EnemyState:
	return null

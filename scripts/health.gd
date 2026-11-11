class_name Health
extends Node

signal changed(current: float, maximum: float)
signal died

@export var max_health := 100.0

var current: float


func _ready() -> void:
	current = max_health


func take_damage(amount: float) -> void:
	if current <= 0.0:
		return  # already dead
	current = maxf(current - amount, 0.0)
	changed.emit(current, max_health)
	if current <= 0.0:
		died.emit()

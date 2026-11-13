class_name Experience
extends Node

signal exp_changed(current: float, needed: float)
signal leveled_up(new_level: int)

# EXP needed to go from level 0 to level 1.
@export var base_exp_needed := 100.0
# Each level needs this many times more EXP than the one before (+15%).
@export var growth := 1.15
# Temporary cap (the real goal is no limit).
@export var max_level := 4444

var level := 0
var current_exp := 0.0
var exp_to_next := 100.0


func _ready() -> void:
	exp_to_next = base_exp_needed


func add_exp(amount: float) -> void:
	if level >= max_level:
		return  # capped
	current_exp += amount
	# "while" because one big orb could cross more than one level.
	while current_exp >= exp_to_next and level < max_level:
		current_exp -= exp_to_next
		level += 1
		exp_to_next = roundf(exp_to_next * growth)
		leveled_up.emit(level)
	if level >= max_level:
		current_exp = exp_to_next  # bar stays full
	exp_changed.emit(current_exp, exp_to_next)

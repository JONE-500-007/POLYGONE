class_name CardLevel
extends Resource

# What the player gets when the item reaches this level. Bonuses are fractions: 0.05 = +5%.
@export_multiline var description := ""
@export var damage_bonus : float = 0.0
@export var size_bonus : float = 0.0
@export var fire_rate_bonus : float = 0.0
@export var projectile_bonus : int = 0

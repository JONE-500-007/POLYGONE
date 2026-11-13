extends Weapon

# Bullets per volley before any level bonus.
@export var base_projectiles := 3
# Angle between two neighbouring bullets of the fan (degrees).
@export var fan_angle_degrees := 12.0


# All bullets leave at once, spread around the direction of the target.
func _start_firing(target: Node3D, player: Player) -> void:
	var count := base_projectiles + _extra_projectiles
	for i in count:
		# Center the fan on the target: 3 bullets -> -12, 0, +12 degrees.
		var offset := (i - (count - 1) / 2.0) * fan_angle_degrees
		_fire_at(target, player, offset)

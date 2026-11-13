extends Weapon

# Seconds between the bullets of one volley.
@export var shot_interval := 0.1

var _shots_left := 0  # bullets still waiting to be fired in the current volley
var _shot_timer := 0.0


func _is_firing() -> bool:
	return _shots_left > 0


# First bullet goes out immediately, the extra ones follow.
func _start_firing(target: Node3D, player: Player) -> void:
	_fire_at(target, player)
	_shots_left = _extra_projectiles
	_shot_timer = shot_interval


func _continue_firing(delta: float, player: Player) -> void:
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return
	var next_target := _find_nearest_enemy()
	if next_target == null:
		_shots_left = 0  # nothing left to shoot at
		return
	_fire_at(next_target, player)
	_shots_left -= 1
	_shot_timer = shot_interval

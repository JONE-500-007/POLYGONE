extends Camera3D

@export var target: Node3D
@export var follow_speed := 8.0

var _offset := Vector3.ZERO


func _ready() -> void:
	# Remember how far the camera is from the target on the ground plane.
	_offset = global_position - target.global_position
	_offset.y = 0.0


func _physics_process(delta: float) -> void:
	var desired := Vector3(
		target.global_position.x + _offset.x,
		global_position.y,
		target.global_position.z + _offset.z
	)
	# Smooth follow: higher follow_speed = camera sticks closer to the target.
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))

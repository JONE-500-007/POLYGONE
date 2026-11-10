extends CharacterBody3D

@export var move_speed := 5.0
@export var jump_velocity := 6.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var model_pivot: Node3D = $ModelPivot


func _ready() -> void:
	var data := GameState.selected_character
	if data == null:
		# Fallback so the game scene also works when run directly.
		data = load("res://data/characters/cube.tres") as CharacterData
	model_pivot.add_child(data.model_scene.instantiate())


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Move relative to where the camera is looking
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam := get_viewport().get_camera_3d()
	var forward := -cam.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam.global_basis.x
	right.y = 0.0
	right = right.normalized()

	var direction := right * input.x - forward * input.y
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	move_and_slide()

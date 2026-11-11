extends CharacterBody3D
class_name Player

@export var move_speed := 5.0
@export var jump_velocity := 6.0

# Pushes from enemies. Reset every physics frame.
var external_velocity := Vector3.ZERO

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var model_pivot: Node3D = $ModelPivot
@onready var health: Health = $Health

var is_dead := false


func _ready() -> void:
	add_to_group("player")
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	var data := GameState.selected_character
	if data == null:
		# Fallback so the game scene also works when run directly.
		data = load("res://data/characters/cube.tres") as CharacterData
	model_pivot.add_child(data.model_scene.instantiate())
	
func _on_health_changed(current: float, maximum: float) -> void:
	print("Player HP: %d / %d" % [current, maximum])


func _on_died() -> void:
	is_dead = true
	print("Player died")


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if not is_dead and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Move relative to where the camera is looking
	var input := Vector2.ZERO if is_dead else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam := get_viewport().get_camera_3d()
	var forward := -cam.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam.global_basis.x
	right.y = 0.0
	right = right.normalized()

	var direction := right * input.x - forward * input.y
	velocity.x = direction.x * move_speed + external_velocity.x
	velocity.z = direction.z * move_speed + external_velocity.z
	external_velocity = Vector3.ZERO

	move_and_slide()

extends CharacterBody3D
class_name Player
signal item_changed(card: CardData, level: int)

@export var move_speed := 5.0
@export var jump_velocity := 6.0

# Pushes from enemies. Reset every physics frame.
var external_velocity := Vector3.ZERO

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var model_pivot: Node3D = $ModelPivot
@onready var health: Health = $Health

var is_dead := false
# Everything the player owns: card -> current level.
var items: Dictionary = {}
# Spawned weapon nodes, so a level-up can update the weapon that already exists.
var _weapon_nodes: Dictionary = {}


func _ready() -> void:
	add_to_group("player")
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	#var data := GameState.selected_character
	var data: CharacterData = GameState.selected_character
	if data == null:
		# Fallback so the game scene also works when run directly.
		data = load("res://data/characters/cube.tres") as CharacterData
	model_pivot.add_child(data.model_scene.instantiate())
	gain_card(data.starting_weapon)
	
func get_item_level(card: CardData) -> int:
	return items.get(card, 0)
	
# Total damage bonus from all passives (0.05 = +5%). Weapons read this when they fire.
func get_damage_bonus() -> float:
	var total := 0.0
	for card in items:
		if card.kind != CardData.Kind.PASSIVE:
			continue
		if card.base_bonus:
			total += card.base_bonus.damage_bonus
		for i in items[card] - 1:
			total += card.levels[i].damage_bonus
	return total


# Gain a card: Lv.1 if new, otherwise one level higher (until its max level).
func gain_card(card: CardData) -> void:
	if card == null:
		return
	var level := get_item_level(card) + 1
	if level > card.max_level:
		return
	items[card] = level

	if card.kind == CardData.Kind.WEAPON:
		# weapon.gd looks at get_parent() as Player, so it must be a direct child.
		if level == 1 and card.weapon_scene:
			var new_weapon := card.weapon_scene.instantiate()
			add_child(new_weapon)
			_weapon_nodes[card] = new_weapon
		var weapon = _weapon_nodes.get(card)
		if weapon:
			weapon.apply_level(card, level)
	item_changed.emit(card, level)
	
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

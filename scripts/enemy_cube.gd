extends CharacterBody3D

@export var move_speed := 2.5
# Distance at which enemy and player count as touching (enemy radius + player radius).
@export var contact_distance := 1.0
# Speed given to this enemy when a splayer overlaps it (strong).
@export var shove_from_player := 12.0
# Speed given to the player when this enemy overlaps it (very weak).
@export var shove_on_player := 1.0
# How often (seconds) the enemy asks for a new path to the player.
@export var repath_interval := 0.25
# Damage dealt to a player on touch, and seconds between hits from this enemy.
@export var damage := 10.0
@export var attack_interval := 1.0
# Random body height range (meters).
@export var min_height := 1.5
@export var max_height := 3.5
@export var orb_scene: PackedScene

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var nav_agent: NavigationAgent3D = $Feet/NavigationAgent3D
@onready var feet: Node3D = $Feet
@onready var body: MeshInstance3D = $Body
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var health: Health = $Health
@onready var health_bar: Node3D = $HealthBar3D


var _repath_timer := 0.0
var _nav_ready := false
var _attack_cooldown := 0.0


func _ready() -> void:
	add_to_group("enemy")
	#health.died.connect(queue_free)
	health.died.connect(_on_died)
	# Spread path requests out so a big wave does not ask for paths on the same frame.
	_repath_timer = randf() * repath_interval
	_randomize_height()
	# The navigation map needs one physics frame before it can answer path queries.
	await get_tree().physics_frame
	_nav_ready = true
	
func _on_died() -> void:
	if orb_scene:
		var orb := orb_scene.instantiate() as Node3D
		# Drop at the enemy's feet (floor level), a little above the ground.
		orb.position = Vector3(global_position.x, feet.global_position.y + 0.6, global_position.z)
		# "deferred": the enemy dies in the middle of a physics step (a projectile hit it),
		# and Godot does not allow adding a collision area at that moment.
		get_parent().add_child.call_deferred(orb)
	queue_free()


func _randomize_height() -> void:
	var height := randf_range(min_height, max_height)
	body.scale.y = height

	# Give this enemy its own copy of the shape. Otherwise every enemy shares
	# one shape resource and they would all end up with the same height.
	var capsule := (collision_shape.shape as CapsuleShape3D).duplicate() as CapsuleShape3D
	capsule.height = height
	collision_shape.shape = capsule

	# The capsule and the body are both centered on the enemy, so they line up.
	body.position.y = 0.0
	collision_shape.position.y = 0.0
	# Navigation measures from the enemy's feet, not its center.
	feet.position.y = -height / 2.0
	# Put the health bar just above the top of the body.
	health_bar.position.y = height / 2.0 + 0.6


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= gravity * delta

	var shove := Vector3.ZERO
	var nearest: Player = null
	var best_distance := INF

	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player.is_dead:
			continue
		var offset := player.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()

		if distance < best_distance:
			best_distance = distance
			nearest = player

		# Soft contact: the deeper the overlap, the harder the push.
		if distance < contact_distance and distance > 0.001:
			if _attack_cooldown <= 0.0:
				player.health.take_damage(damage)
				_attack_cooldown = attack_interval
			var away := -offset / distance  # direction from player to enemy
			var overlap := (contact_distance - distance) / contact_distance
			shove += away * shove_from_player * overlap
			player.external_velocity += -away * shove_on_player * overlap

	var chase := Vector3.ZERO
	if nearest and _nav_ready and best_distance > 0.1:
		# Ask for a new path every so often instead of every frame (cheaper).
		_repath_timer -= delta
		if _repath_timer <= 0.0:
			_repath_timer = repath_interval
			nav_agent.target_position = nearest.global_position

		# Walk toward the next point on the path (it goes around obstacles).
		var to_next := nav_agent.get_next_path_position() - global_position
		to_next.y = 0.0
		if to_next.length() > 0.05:
			chase = to_next.normalized() * move_speed

	velocity.x = chase.x + shove.x
	velocity.z = chase.z + shove.z

	move_and_slide()

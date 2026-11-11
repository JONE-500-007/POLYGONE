extends Node3D

@export var projectile_scene: PackedScene
@export var damage := 15.0
@export var projectile_speed := 14.0
# Seconds between shots.
@export var fire_interval := 1.0
# Only shoot at enemies closer than this (meters).
@export var max_range := 18.0

var _cooldown := 0.0


func _physics_process(delta: float) -> void:
	var player := get_parent() as Player
	if player == null or player.is_dead:
		return

	_cooldown -= delta
	if _cooldown > 0.0:
		return

	var target := _find_nearest_enemy()
	if target == null:
		return

	_fire_at(target, player)
	_cooldown = fire_interval


func _find_nearest_enemy() -> Node3D:
	var nearest: Node3D = null
	var best := max_range * max_range
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Node3D
		var offset := enemy.global_position - global_position
		offset.y = 0.0
		var distance_squared := offset.length_squared()
		if distance_squared < best:
			best = distance_squared
			nearest = enemy
	return nearest


func _fire_at(target: Node3D, player: Player) -> void:
	var direction := target.global_position - global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		return

	var projectile := projectile_scene.instantiate() as Projectile
	projectile.damage = damage
	projectile.speed = projectile_speed
	projectile.direction = direction.normalized()
	# Add it next to the player (inside the same 3D world), not at the scene root.
	player.get_parent().add_child(projectile)
	projectile.global_position = global_position

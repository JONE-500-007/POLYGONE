class_name Weapon
extends Node3D

@export var projectile_scene: PackedScene
@export var damage := 15.0
@export var projectile_speed := 14.0
# Seconds between volleys.
@export var fire_interval := 1.0
# Only shoot at enemies closer than this (meters).
@export var max_range := 18.0

var card: CardData
var level := 1

var _damage_mult := 1.0
var _size_mult := 1.0
var _rate_mult := 1.0
var _extra_projectiles := 0  # bonus bullets per volley, from level-ups
var _cooldown := 0.0


# Called by the player when the weapon is gained or levelled up.
func apply_level(card_data: CardData, new_level: int) -> void:
	card = card_data
	level = new_level
	_damage_mult = 1.0
	_size_mult = 1.0
	_rate_mult = 1.0
	_extra_projectiles = 0
	# Level 2 uses levels[0], level 3 uses levels[1], and so on (bonuses add up).
	for i in new_level - 1:
		var bonus: CardLevel = card.levels[i]
		_damage_mult += bonus.damage_bonus
		_size_mult += bonus.size_bonus
		_rate_mult += bonus.fire_rate_bonus
		_extra_projectiles += bonus.projectile_bonus


func _physics_process(delta: float) -> void:
	var player := get_parent() as Player
	if player == null or player.is_dead:
		return

	_cooldown -= delta

	# A volley is still in progress: let the weapon continue it.
	if _is_firing():
		_continue_firing(delta, player)
		return

	if _cooldown > 0.0:
		return

	var target := _find_nearest_enemy()
	if target == null:
		return

	_start_firing(target, player)
	_cooldown = fire_interval / _rate_mult


# ---- Each weapon overrides these to decide HOW it shoots ----

# True while a volley is still being fired (only weapons that fire over time need this).
func _is_firing() -> bool:
	return false


func _continue_firing(_delta: float, _player: Player) -> void:
	pass


# Called when the cooldown is ready and an enemy is in range.
func _start_firing(target: Node3D, player: Player) -> void:
	_fire_at(target, player)


# ---- Shared helpers ----

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


# Fire one bullet at the target; angle_offset turns it left/right (degrees).
func _fire_at(target: Node3D, player: Player, angle_offset := 0.0) -> void:
	var direction := target.global_position - global_position
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	direction = direction.normalized().rotated(Vector3.UP, deg_to_rad(angle_offset))

	var projectile := projectile_scene.instantiate() as Projectile
	projectile.damage = damage * (_damage_mult + player.get_damage_bonus())
	projectile.speed = projectile_speed
	projectile.direction = direction
	projectile.scale = Vector3.ONE * _size_mult
	# Add it next to the player (inside the same 3D world), not at the scene root.
	player.get_parent().add_child(projectile)
	projectile.global_position = global_position

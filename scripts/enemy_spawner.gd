extends Node3D

@export var enemy_scene: PackedScene
# Seconds between waves.
@export var wave_interval := 8.0
@export var base_enemies := 5
@export var extra_per_wave := 2
# Do not spawn more when this many enemies are alive.
@export var max_alive := 60
# Spawn ring around the player, in meters (outside the screen).
@export var spawn_distance_min := 18.0
@export var spawn_distance_max := 22.0
# A wave is spread over this angle on each side of its center direction.
@export var wave_spread_degrees := 50.0
# +10% enemies for every player beyond the first.
@export var bonus_per_extra_player := 0.10

var _wave := 0
var _time_to_next_wave := 2.0  # first wave comes shortly after start


func _physics_process(delta: float) -> void:
	_time_to_next_wave -= delta
	if _time_to_next_wave <= 0.0:
		_time_to_next_wave = wave_interval
		_spawn_wave()


func _spawn_wave() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty() or enemy_scene == null:
		return

	_wave += 1
	var count := base_enemies + (_wave - 1) * extra_per_wave
	var multiplier := 1.0 + bonus_per_extra_player * (players.size() - 1)
	count = roundi(count * multiplier)

	var alive := get_tree().get_nodes_in_group("enemy").size()
	count = mini(count, max_alive - alive)

	var target := players.pick_random() as Node3D
	var center_angle := randf() * TAU
	var spread := deg_to_rad(wave_spread_degrees)
	var nav_map := get_world_3d().navigation_map

	for i in count:
		var angle := center_angle + randf_range(-spread, spread)
		var distance := randf_range(spawn_distance_min, spawn_distance_max)
		var point := target.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
		# Snap to the nearest walkable point so enemies never spawn inside walls.
		point = NavigationServer3D.map_get_closest_point(nav_map, point)

		var enemy := enemy_scene.instantiate() as Node3D
		add_child(enemy)
		enemy.global_position = point + Vector3.UP * 3.0

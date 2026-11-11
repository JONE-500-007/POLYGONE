extends Node3D

# Hide the bar while health is full (good for enemies).
@export var hide_when_full := false

@onready var fill: MeshInstance3D = $Fill
# The bar looks for a sibling node called "Health" next to it.
@onready var health: Health = get_parent().get_node("Health") as Health

var _bar_width := 1.0


func _ready() -> void:
	_bar_width = (fill.mesh as QuadMesh).size.x
	health.changed.connect(_on_health_changed)
	_on_health_changed(health.max_health, health.max_health)


func _process(_delta: float) -> void:
	# Face the screen: copy the camera's orientation so the bar is always flat to the view.
	var cam := get_viewport().get_camera_3d()
	if cam:
		global_basis = cam.global_basis


func _on_health_changed(current: float, maximum: float) -> void:
	var ratio := clampf(current / maximum, 0.0, 1.0)
	# Shrink the fill, then slide it so its left edge stays in place.
	fill.scale.x = maxf(ratio, 0.001)
	fill.position.x = -(1.0 - ratio) * _bar_width / 2.0
	visible = not (hide_when_full and ratio >= 1.0)

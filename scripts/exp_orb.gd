extends Area3D

@export var exp_value := 10.0
@export var bob_height := 0.15
@export var bob_speed := 3.0

@onready var body: MeshInstance3D = $Body

var _time := randf() * TAU   # random start so orbs do not bob in sync
var _collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta * bob_speed
	# Move only the visible mesh, not the Area3D itself (the pickup zone stays put).
	body.position.y = sin(_time) * bob_height


func _on_body_entered(other: Node3D) -> void:
	if _collected:
		return
	var xp := other.get_node_or_null("Experience") as Experience
	if xp == null:
		return
	_collected = true
	xp.add_exp(exp_value)
	queue_free()

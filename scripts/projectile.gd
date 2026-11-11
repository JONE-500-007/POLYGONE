class_name Projectile
extends Area3D

@export var speed := 14.0
@export var damage := 15.0
# Seconds before the projectile disappears if it hits nothing.
@export var lifetime := 3.0

# Set by the weapon right after the projectile is created.
var direction := Vector3.FORWARD


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		var health := body.get_node_or_null("Health") as Health
		if health:
			health.take_damage(damage)
	# Hit an enemy or a wall: the projectile is used up.
	queue_free()

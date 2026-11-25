extends Area2D

## White Lightning Teleport Projectile
## Travels forward carrying White Lightning, damaging enemies and granting damage invulnerability.

@export var speed: float = 650.0
@export var max_distance: float = 160.0
@export var damage: int = 15

var player: CharacterBody2D = null
var facing_dir: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var hit_bodies: Array = []

@onready var raycast: RayCast2D = $RayCast2D
@onready var sprite: Sprite2D = $Sprite2D

func setup(p: CharacterBody2D, dir: Vector2) -> void:
	player = p
	facing_dir = dir.normalized()
	if facing_dir == Vector2.ZERO:
		facing_dir = Vector2.DOWN
	global_position = player.global_position
	rotation = facing_dir.angle()
	
	# Raycast to detect solid walls (collision mask 1 and 2)
	raycast.target_position = Vector2(24, 0)
	raycast.collision_mask = 3 # layer 1 (world) and layer 2 (walls)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	
	var step = speed * delta
	
	# Check if a wall is ahead. Enemies are ignored so the lightning pierces through them.
	raycast.force_raycast_update()
	while raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider is Node and (collider.is_in_group("inimigo") or collider == player):
			raycast.add_exception(collider)
			raycast.force_raycast_update()
		else:
			_finish_teleport()
			return
		
	# Move projectile
	var move_vec = facing_dir * step
	global_position += move_vec
	distance_traveled += step
	
	# Keep player with the teleport projectile
	player.global_position = global_position
	
	if distance_traveled >= max_distance:
		_finish_teleport()

func _on_body_entered(body: Node2D) -> void:
	if body == player or body in hit_bodies:
		return
	hit_bodies.append(body)
	
	if body.is_in_group("inimigo"):
		if "vida" in body:
			body.vida -= damage
	elif body.is_in_group("Quebravel"):
		if body.has_method("quebra"):
			body.quebra()

func _finish_teleport() -> void:
	if is_instance_valid(player):
		player.global_position = global_position
		if player.has_method("finish_teleport"):
			player.finish_teleport()
	queue_free()

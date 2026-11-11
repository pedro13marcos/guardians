extends Area2D

## Monkey Whirlwind Tail Spin
## Rapidly spins the mechanical tail around Monkey dealing damage to all surrounding enemies within 160px radius.

@export var damage: int = 20
@export var spin_duration: float = 0.45
@export var spin_rotations: float = 2.5 # rotations during spin

var player: CharacterBody2D = null
var elapsed: float = 0.0
var hit_bodies: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func setup(p: CharacterBody2D) -> void:
	player = p
	global_position = player.global_position

func _ready() -> void:
	# Damage all already overlapping bodies immediately
	for body in get_overlapping_bodies():
		_apply_damage(body)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	
	global_position = player.global_position
	elapsed += delta
	var progress = clamp(elapsed / spin_duration, 0.0, 1.0)
	
	# Rotate tail whirlwind
	sprite.rotation = progress * TAU * spin_rotations
	
	# Scale punch and fade
	var scale_factor = 0.3125 * (0.8 + 0.2 * sin(progress * PI))
	sprite.scale = Vector2(scale_factor, scale_factor)
	
	# Re-check overlapping bodies continuously during spin
	for body in get_overlapping_bodies():
		_apply_damage(body)
		
	if progress >= 1.0:
		if is_instance_valid(player) and player.has_method("finish_tail_spin"):
			player.finish_tail_spin()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	_apply_damage(body)

func _apply_damage(body: Node2D) -> void:
	if body == player or body in hit_bodies:
		return
	
	if body.is_in_group("inimigo") or body.has_method("take_damage") or "vida" in body:
		hit_bodies[body] = true
		if body.has_method("take_damage"):
			body.take_damage(damage)
		elif "vida" in body:
			body.vida -= damage
	elif body.is_in_group("Quebravel"):
		hit_bodies[body] = true
		if body.has_method("quebra"):
			body.quebra()

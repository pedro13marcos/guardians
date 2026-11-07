extends Area2D

## Guardian Staff Slam & Divine Restoration Effect
## Heals Guardian for half of his life (+50 HP) and unleashes an expanding radiant light burst that repels nearby enemies.

@export var heal_amount: int = 50
@export var damage: int = 10
@export var duration: float = 0.45

var player: CharacterBody2D = null
var elapsed: float = 0.0
var hit_bodies: Dictionary = {}

@onready var shockwave: Line2D = $ShockwaveRing
@onready var light: PointLight2D = $PointLight2D

func setup(p: CharacterBody2D) -> void:
	player = p
	global_position = player.global_position
	
	# Restore half of player's life
	if "vida" in player:
		player.vida = min(player.vida + heal_amount, 100)
		if player.has_method("atualizaUI"):
			player.atualizaUI()

func _ready() -> void:
	_generate_ring()
	for body in get_overlapping_bodies():
		_apply_effect(body)

func _generate_ring() -> void:
	shockwave.clear_points()
	var points_count = 32
	var r = 10.0
	for i in range(points_count + 1):
		var angle = (float(i) / points_count) * TAU
		shockwave.add_point(Vector2(cos(angle) * r, sin(angle) * r))

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
		
	elapsed += delta
	var progress = clamp(elapsed / duration, 0.0, 1.0)
	
	# Expanding ring shockwave
	var radius = lerp(10.0, 60.0, progress)
	shockwave.clear_points()
	var points_count = 32
	for i in range(points_count + 1):
		var angle = (float(i) / points_count) * TAU
		shockwave.add_point(Vector2(cos(angle) * radius, sin(angle) * radius))
	
	shockwave.default_color = Color(1.0, 0.9, 0.4, 1.0 - progress)
	light.energy = (1.0 - progress) * 3.0
	
	for body in get_overlapping_bodies():
		_apply_effect(body)
		
	if progress >= 1.0:
		if is_instance_valid(player) and player.has_method("finish_guardian_slam"):
			player.finish_guardian_slam()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	_apply_effect(body)

func _apply_effect(body: Node2D) -> void:
	if body == player or body in hit_bodies:
		return
	hit_bodies[body] = true
	
	if body.is_in_group("inimigo"):
		if "vida" in body:
			body.vida -= damage
	elif body.is_in_group("Quebravel"):
		if body.has_method("quebra"):
			body.quebra()

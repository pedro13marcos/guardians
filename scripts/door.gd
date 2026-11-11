extends Area2D

@export var isOpen: bool = false
@export var level: String = ""
@export var slide_direction: String = "auto" # "auto", "up", "down", "left", "right"

@onready var anim_sprite = $AnimatedSprite2D
@onready var solid_collider = get_node_or_null("StaticBody2D/CollisionShape2D")

var _has_preloaded: bool = false

func _ready():
	_update_door_state()

func _process(_delta):
	_update_door_state()

func _update_door_state():
	if isOpen:
		if anim_sprite:
			anim_sprite.play("open")
		# When open, physical blocking collision is disabled so players can walk through
		if solid_collider:
			solid_collider.set_deferred("disabled", true)
		
		# Pre-load next level as soon as door opens
		if not _has_preloaded and level and not level.is_empty():
			_has_preloaded = true
			Global.preload_level(level)
	else:
		if anim_sprite:
			anim_sprite.play("close")
		# When closed:
		# If it's an exit door with a level assigned, keep physical collider disabled so stepping into it triggers next level when opened.
		# If it's a security/barrier door (empty level), enable physical collision so it solid-blocks until opened.
		if solid_collider:
			if level == null or level.is_empty():
				solid_collider.set_deferred("disabled", false)
			else:
				solid_collider.set_deferred("disabled", true)

func _on_body_entered(body):
	if isOpen and body.name == "Player":
		if level and not level.is_empty():
			var dir_vector: Vector2 = _determine_slide_direction(body)
			nextLevel(level, dir_vector)

func _determine_slide_direction(body: Node2D) -> Vector2:
	if slide_direction != "auto":
		match slide_direction.to_lower():
			"up":
				return Vector2.UP
			"down":
				return Vector2.DOWN
			"left":
				return Vector2.LEFT
			"right":
				return Vector2.RIGHT
	
	# Auto-detect from player velocity
	var vel: Vector2 = Vector2.ZERO
	if "velocity" in body:
		vel = body.velocity
	if vel.length() > 5.0:
		if abs(vel.x) > abs(vel.y):
			return Vector2.LEFT if vel.x < 0 else Vector2.RIGHT
		else:
			return Vector2.UP if vel.y < 0 else Vector2.DOWN
	
	# Fallback to door relative position
	var diff: Vector2 = global_position - body.global_position
	if abs(diff.x) > abs(diff.y):
		return Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if diff.y > 0 else Vector2.UP

func nextLevel(Level: String, dir_vector: Vector2 = Vector2.UP):
	Global.transition_to_level(Level, dir_vector)

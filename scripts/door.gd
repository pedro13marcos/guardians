extends Area2D

@export var isOpen: bool = false
@export var level: String = ""
@export var door_side: String = "auto" # "left", "right", "top", "bottom", "auto"
@export var slide_direction: String = "auto" # backward compatibility alias

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
			var motion_vec: Vector2 = _determine_motion_vector(body)
			nextLevel(level, motion_vec)

## Determines the screen slide motion vector based on door position:
## Door on LEFT -> slide from left to right (Vector2.RIGHT)
## Door on RIGHT -> slide from right to left (Vector2.LEFT)
## Door on TOP -> slide from top to bottom (Vector2.DOWN)
## Door on BOTTOM -> slide from bottom to top (Vector2.UP)
func _determine_motion_vector(body: Node2D) -> Vector2:
	var side_str: String = door_side if door_side != "auto" else slide_direction
	match side_str.to_lower():
		"left":
			return Vector2.RIGHT
		"right":
			return Vector2.LEFT
		"top", "up":
			return Vector2.DOWN
		"bottom", "down":
			return Vector2.UP
	
	# Auto-detect from player velocity when stepping into door
	var vel: Vector2 = Vector2.ZERO
	if "velocity" in body:
		vel = body.velocity
	if vel.length() > 5.0:
		if abs(vel.x) > abs(vel.y):
			# Moving leftwards means door is on the left -> slide from left to right
			return Vector2.RIGHT if vel.x < 0 else Vector2.LEFT
		else:
			# Moving upwards means door is on top -> slide from top to bottom
			return Vector2.DOWN if vel.y < 0 else Vector2.UP
	
	# Fallback to door relative position relative to player
	var diff: Vector2 = global_position - body.global_position
	if abs(diff.x) > abs(diff.y):
		return Vector2.RIGHT if diff.x < 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if diff.y < 0 else Vector2.UP

func nextLevel(Level: String, motion_vec: Vector2 = Vector2.DOWN):
	Global.transition_to_level(Level, motion_vec)

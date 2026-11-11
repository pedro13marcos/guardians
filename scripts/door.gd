extends Area2D

@export var isOpen: bool = false
@export var level: String = ""

@onready var anim_sprite = $AnimatedSprite2D
@onready var solid_collider = get_node_or_null("StaticBody2D/CollisionShape2D")

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
			nextLevel(level)

func nextLevel(Level):
	Global.save_level(Level)
	get_tree().change_scene_to_file(Level)

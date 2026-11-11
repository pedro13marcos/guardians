extends Area2D

## Unified Astral Rift Wall for Guardian ("F").
## Starts as an impassable wall tile marked with an astral dimensional rift.
## When Guardian interacts, it dissolves into a walkable purple astral floor tile!

@export var is_open: bool = false

var is_player_inside: bool = false
var player_ref: Node2D = null

@onready var anim_sprite = $AnimatedSprite2D
@onready var wall_collider = $StaticBody2D/CollisionShape2D
@onready var prompt_label = $PromptLabel

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if is_open:
		open_wall(true)
	else:
		close_wall(true)

func _process(_delta: float) -> void:
	if is_player_inside and player_ref:
		if is_open:
			if prompt_label:
				prompt_label.visible = false
			return
		
		# Only Guardian ("F") has planar magic to breach dimensions
		if player_ref.personagem == "F":
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "[E / Action] Phase Astral Wall"
			
			if Input.is_action_just_pressed("Action"):
				open_wall()
		else:
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "Guardian only"
	else:
		if prompt_label:
			prompt_label.visible = false

func open_wall(immediate: bool = false) -> void:
	is_open = true
	if wall_collider:
		wall_collider.set_deferred("disabled", true)
	
	if anim_sprite:
		anim_sprite.play("open")
		if not immediate:
			var tween = create_tween()
			anim_sprite.modulate = Color(1.8, 1.3, 2.0, 1.0)
			tween.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)

func close_wall(immediate: bool = false) -> void:
	is_open = false
	if wall_collider:
		wall_collider.set_deferred("disabled", false)
	
	if anim_sprite:
		anim_sprite.play("closed")
		if not immediate:
			var tween = create_tween()
			anim_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
			tween.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = false
		player_ref = null

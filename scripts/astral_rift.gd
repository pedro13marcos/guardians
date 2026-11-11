extends Area2D

## Reusable Astral Rift interactable item for Guardian ("F").
## When Guardian channels magical dimensional energy, the targeted AstralWall opens into a walkable path.

@export var target_astral_wall: NodePath = ""
@export var is_rift_activated: bool = false

var is_player_inside: bool = false
var player_ref: Node2D = null

@onready var sprite = $Sprite2D
@onready var prompt_label = $PromptLabel

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if is_rift_activated:
		_apply_active_visuals()

func _process(_delta: float) -> void:
	if is_player_inside and player_ref:
		if is_rift_activated:
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "Astral Path Open"
			return
			
		# Only Guardian ("F") has magical planar powers
		if player_ref.personagem == "F":
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "[E / Action] Open Astral Path"
			
			if Input.is_action_just_pressed("Action"):
				_activate_rift()
		else:
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "Guardian only"
	else:
		if prompt_label:
			prompt_label.visible = false

func _activate_rift() -> void:
	is_rift_activated = true
	_apply_active_visuals()
	
	if target_astral_wall and not target_astral_wall.is_empty():
		var wall = get_node_or_null(target_astral_wall)
		if wall and wall.has_method("open_wall"):
			wall.open_wall()
			print("AstralRift: Astral wall demarked path opened by Guardian!")
	else:
		print("AstralRift: No target_astral_wall linked!")

func _apply_active_visuals() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.3, 0.9, 1.8, 1.0), 0.3)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.14, 0.14), 0.3)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = false
		player_ref = null

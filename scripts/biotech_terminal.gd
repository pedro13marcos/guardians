extends Area2D

## Reusable Biotech Terminal that only Monkey ("A") can interact with.
## Unlocks the linked target_door when accessed.

@export var target_door: NodePath = ""
@export var is_accessed: bool = false

var is_player_inside: bool = false
var player_ref: Node2D = null

@onready var sprite = $Sprite2D
@onready var prompt_label = $PromptLabel

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if is_accessed:
		_apply_accessed_visuals()

func _process(_delta: float) -> void:
	if is_player_inside and player_ref:
		if is_accessed:
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "Access Granted (Door Unlocked)"
			return
			
		# Only Monkey ("A") knows how to operate this laboratory security terminal
		if player_ref.personagem == "A":
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "[E / Action] Access Terminal"
			
			if Input.is_action_just_pressed("Action"):
				_access_terminal()
		else:
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "Unauthorized: Monkey scientist required"
	else:
		if prompt_label:
			prompt_label.visible = false

func _access_terminal() -> void:
	is_accessed = true
	_apply_accessed_visuals()
	
	if target_door and not target_door.is_empty():
		var door = get_node_or_null(target_door)
		if door:
			if "isOpen" in door:
				door.isOpen = true
			elif door.has_method("open"):
				door.open()
			print("BiotechTerminal: Monkey authorized! Security door opened.")
	else:
		print("BiotechTerminal: No target_door linked!")

func _apply_accessed_visuals() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.3, 1.2, 0.4, 1.0), 0.3)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = false
		player_ref = null

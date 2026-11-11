extends Area2D

## Reusable Biotech Terminal that only Monkey ("A") can interact with.
## Can open multiple doors, barriers, or walls!
## Assign single target_door, or multiple target_doors / target_nodes in the inspector.

@export var target_door: NodePath = ""
@export var target_nodes: Array[NodePath] = []
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
				prompt_label.text = tr("prompt_terminal_unlocked")
			return
			
		# Only Monkey ("A") knows how to operate this laboratory security terminal
		if player_ref.personagem == "A":
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = tr("prompt_access_terminal")
			
			if Input.is_action_just_pressed("Action"):
				_access_terminal()
		else:
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = tr("prompt_monkey_only")
	else:
		if prompt_label:
			prompt_label.visible = false

func _access_terminal() -> void:
	is_accessed = true
	_apply_accessed_visuals()
	
	var all_targets: Array[NodePath] = []
	if target_door and not target_door.is_empty():
		all_targets.append(target_door)
	for path in target_nodes:
		if path and not path.is_empty() and not all_targets.has(path):
			all_targets.append(path)
	
	for path in all_targets:
		var node = get_node_or_null(path)
		if node:
			_unlock_or_open(node)
	
	print("BiotechTerminal: Monkey authorized! Opened %d targets." % all_targets.size())

func _unlock_or_open(target: Node) -> void:
	if "isOpen" in target:
		target.isOpen = true
	elif "is_open" in target:
		target.is_open = true
	
	if target.has_method("open_wall"):
		target.open_wall()
	elif target.has_method("open"):
		target.open()

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

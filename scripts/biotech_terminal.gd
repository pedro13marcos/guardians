extends Area2D

## Reusable Biotech Terminal that only Monkey ("A") can interact with.
## Can open multiple doors, barriers, or walls!
## Displays animated cyber terminal art and switches to offline when accessed.

@export var target_door: NodePath = ""
@export var target_nodes: Array[NodePath] = []
@export var is_accessed: bool = false
@export var light_energy_frames: Array[float] = [0.45, 0.32, 0.4]

var is_player_inside: bool = false
var player_ref: Node2D = null

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var sprite = anim
@onready var light: PointLight2D = $PointLight2D if has_node("PointLight2D") else null
@onready var prompt_label = $PromptLabel

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if is_accessed:
		_apply_accessed_visuals()
	else:
		if anim and anim.sprite_frames and anim.sprite_frames.has_animation("Up"):
			anim.play("Up")
			_syncToGlobalClock()
			if not anim.frame_changed.is_connected(_updateLight):
				anim.frame_changed.connect(_updateLight)
		_updateLight()

func _syncToGlobalClock() -> void:
	if not anim or not anim.sprite_frames or not anim.sprite_frames.has_animation("Up"):
		return
	var frames = anim.sprite_frames
	var count = frames.get_frame_count("Up")
	if count <= 0:
		return
	var fps = frames.get_animation_speed("Up")
	var t = Time.get_ticks_msec() / 1000.0 * fps
	anim.frame = int(t) % count
	anim.frame_progress = t - floor(t)

func _updateLight() -> void:
	if not light:
		return
	if is_accessed:
		light.enabled = false
		return
	light.enabled = true
	var list = light_energy_frames if not light_energy_frames.is_empty() else [0.45, 0.32, 0.4]
	var idx = (anim.frame if anim else 0) % list.size()
	light.energy = list[idx]

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
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("Down"):
		anim.play("Down")
	_updateLight()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = false
		player_ref = null

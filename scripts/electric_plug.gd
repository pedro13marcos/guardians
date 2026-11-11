extends Area2D

## Reusable Electric Conduit Plug for White Lightning (V).
## Connect two plugs together by assigning the paired_plug NodePath in inspector.

@export var paired_plug: NodePath = ""
@export var transfer_cooldown: float = 0.8

var is_player_inside: bool = false
var player_ref: Node2D = null
static var last_transfer_time: float = -999.0

@onready var sprite = $Sprite2D
@onready var prompt_label = $PromptLabel

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false

func _process(_delta: float) -> void:
	if is_player_inside and player_ref:
		# Only White Lightning ("V") can enter electric lines
		if player_ref.personagem == "V":
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "[Space / A] Enter Conduit"
			
			if Input.is_action_just_pressed("Action"):
				_try_teleport()
		else:
			if prompt_label:
				prompt_label.visible = true
				prompt_label.text = "White Lightning only"
	else:
		if prompt_label:
			prompt_label.visible = false

func _try_teleport() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_transfer_time < transfer_cooldown:
		return
	
	if not paired_plug or paired_plug.is_empty():
		print("ElectricPlug: No paired_plug set!")
		return
		
	var target = get_node_or_null(paired_plug)
	if target and target is Node2D:
		last_transfer_time = now
		_do_electric_fx(global_position)
		_do_electric_fx(target.global_position)
		
		# Teleport player smoothly
		player_ref.global_position = target.global_position
		print("ElectricPlug: White Lightning traveled through conduit!")

func _do_electric_fx(pos: Vector2) -> void:
	# Subtle visual pulse / flash
	var pulse = Sprite2D.new()
	pulse.texture = sprite.texture
	pulse.global_position = pos
	pulse.scale = sprite.scale * 1.5
	pulse.modulate = Color(0.2, 0.8, 1.0, 0.8)
	pulse.z_index = 50
	get_parent().add_child(pulse)
	
	var tween = create_tween()
	tween.tween_property(pulse, "scale", sprite.scale * 2.2, 0.25)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.25)
	tween.tween_callback(pulse.queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = true
		player_ref = body

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_player_inside = false
		player_ref = null

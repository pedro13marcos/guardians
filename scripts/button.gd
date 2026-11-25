extends Area2D

## Interactive Access Terminal (Button / Switch)
## Displays an animated cyber terminal (frames 1, 2, 3) with screen glow,
## and switches to "terminal off" when accessed / pressed.

var colPlayer: bool = false
var isButtonPressed: bool = false

signal buttonPressed

const LIGHT_ENERGY = [0.45, 0.32, 0.4]

@export var light_energy_frames: Array[float] = [0.45, 0.32, 0.4]

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var light: PointLight2D = $PointLight2D if has_node("PointLight2D") else null

func _ready() -> void:
	isButtonPressed = false
	colPlayer = false
	anim.play("Up")
	_syncToGlobalClock()
	if anim.sprite_frames and anim.sprite_frames.has_animation("Up"):
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
	if isButtonPressed:
		light.enabled = false
		return
	light.enabled = true
	var energy_list = light_energy_frames if not light_energy_frames.is_empty() else LIGHT_ENERGY
	var idx = anim.frame % energy_list.size()
	light.energy = energy_list[idx]

func _process(_delta: float) -> void:
	if colPlayer and Input.is_action_just_released("Action") and not isButtonPressed:
		press()

func press() -> void:
	if isButtonPressed:
		return
	isButtonPressed = true
	anim.play("Down")
	_updateLight()
	emit_signal("buttonPressed")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		colPlayer = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		colPlayer = false

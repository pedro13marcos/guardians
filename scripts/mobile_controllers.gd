extends CanvasLayer

## Auto-hiding on-screen touch controller HUD.
## Hidden by default; appears when the screen is touched or clicked on any device,
## stays visible while touching, and smoothly fades out after inactivity.

@export var fade_delay: float = 2.0
@export var fade_duration: float = 0.4
@export var start_visible: bool = false

@onready var control: Control = $Control

var active_touches: Dictionary = {}
var timer: float = 0.0

func _ready() -> void:
	if start_visible:
		control.modulate.a = 1.0
	else:
		control.modulate.a = 0.0
	timer = 0.0

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = true
			_wake_up()
		else:
			active_touches.erase(event.index)
			if active_touches.is_empty():
				timer = fade_delay
	elif event is InputEventScreenDrag:
		active_touches[event.index] = true
		_wake_up()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				active_touches[-1] = true
				_wake_up()
			else:
				active_touches.erase(-1)
				if active_touches.is_empty():
					timer = fade_delay
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			active_touches[-1] = true
			_wake_up()

func _wake_up() -> void:
	timer = fade_delay
	control.modulate.a = 1.0

func _process(delta: float) -> void:
	if active_touches.size() > 0:
		timer = fade_delay
		control.modulate.a = 1.0
	else:
		if timer > 0.0:
			timer -= delta
		elif control.modulate.a > 0.0:
			control.modulate.a = move_toward(control.modulate.a, 0.0, delta / fade_duration)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		active_touches.clear()

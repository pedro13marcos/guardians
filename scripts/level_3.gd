extends Node2D

const LEVEL_DURATION: float = 60.0

var nextLevel: String = "res://scenes/level_4.tscn"
var time_elapsed: float = 0.0
var is_completed: bool = false
var timer_label: Label = null

func _ready() -> void:
	if has_node("door"):
		$door.level = nextLevel
		$door.isOpen = false
	
	if has_node("HUD2"):
		$HUD2.setObjetivo("tempo", int(LEVEL_DURATION), 0)
	
	_setup_timer_ui()
	setCameraLimits()

func _setup_timer_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "TimerCanvas"
	canvas.layer = 10
	add_child(canvas)
	
	timer_label = Label.new()
	timer_label.name = "CountdownLabel"
	timer_label.text = "SURVIVE: 01:00"
	
	# Center near top of screen
	timer_label.anchor_left = 0.5
	timer_label.anchor_right = 0.5
	timer_label.anchor_top = 0.0
	timer_label.anchor_bottom = 0.0
	timer_label.offset_left = -180
	timer_label.offset_right = 180
	timer_label.offset_top = 18
	timer_label.offset_bottom = 60
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var settings = LabelSettings.new()
	settings.font_size = 28
	settings.font_color = Color(1.0, 0.9, 0.3, 1.0) # Gold yellow
	settings.outline_size = 4
	settings.outline_color = Color(0.1, 0.1, 0.1, 0.9)
	timer_label.label_settings = settings
	
	canvas.add_child(timer_label)

func _process(delta: float) -> void:
	if not is_completed:
		time_elapsed += delta
		var remaining = max(0.0, LEVEL_DURATION - time_elapsed)
		
		# Update HUD2 progress bar
		if has_node("HUD2"):
			$HUD2.atualizaObjetivo(int(time_elapsed))
		
		# Update countdown text
		if timer_label:
			var mins = int(remaining) / 60
			var secs = int(remaining) % 60
			timer_label.text = "SURVIVE: %02d:%02d" % [mins, secs]
			if remaining <= 10.0:
				timer_label.label_settings.font_color = Color(1.0, 0.3, 0.3, 1.0)
		
		# Timer complete
		if time_elapsed >= LEVEL_DURATION:
			_complete_level_timer()

func _complete_level_timer() -> void:
	is_completed = true
	if has_node("door"):
		$door.isOpen = true
	
	if has_node("HUD2"):
		$HUD2.atualizaObjetivo(int(LEVEL_DURATION))
	
	if timer_label:
		timer_label.text = "DOOR OPENED! REACH THE EXIT!"
		timer_label.label_settings.font_color = Color(0.3, 1.0, 0.4, 1.0)
	
	# Stop spawners
	for child in get_children():
		if child.has_method("stop_spawning"):
			child.stop_spawning()

func setCameraLimits() -> void:
	# Camera bounds are handled by Camera2D.gd (follows the player without showing the void).
	pass

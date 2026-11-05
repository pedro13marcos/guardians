extends Node2D

var nextLevel: String = "res://scenes/ending_page.tscn"

func _ready() -> void:
	if has_node("door"):
		$door.level = nextLevel
		$door.isOpen = false
	setCameraLimits()

func setCameraLimits() -> void:
	if not has_node("Camera2D"):
		return
	# Clamp precisely to Level 3 wall bounds so no void outside walls is visible
	$Camera2D.limit_left = -640
	$Camera2D.limit_top = -384
	$Camera2D.limit_right = 480
	$Camera2D.limit_bottom = 448
	$Camera2D.limit_smoothed = true

extends Node2D

var nextLevel: String = "res://scenes/ending_page.tscn"

func _ready() -> void:
	if has_node("door"):
		$door.level = nextLevel
		$door.isOpen = false
	
	if has_node("HUD2"):
		$HUD2.setObjetivo("activate", 1, 0)
	
	setCameraLimits()

func _process(_delta: float) -> void:
	pass

func open_exit_door() -> void:
	if has_node("door"):
		$door.isOpen = true
	if has_node("HUD2"):
		$HUD2.atualizaObjetivo(1)

func setCameraLimits() -> void:
	pass

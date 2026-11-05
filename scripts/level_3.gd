extends Node2D

var nextLevel: String = "res://scenes/ending_page.tscn"

func _ready() -> void:
	if has_node("door"):
		$door.level = nextLevel
		$door.isOpen = false
	setCameraLimits()

func setCameraLimits() -> void:
	if not has_node("Background") or not has_node("Camera2D"):
		return
	var mapSize = $Background.get_used_rect()
	var celSize = $Background.tile_set.tile_size
	$Camera2D.limit_left = int(mapSize.position.x * celSize.x * $Background.scale.x)
	$Camera2D.limit_top = int(mapSize.position.y * celSize.y * $Background.scale.y)
	$Camera2D.limit_right = int(mapSize.end.x * celSize.x * $Background.scale.x)
	$Camera2D.limit_bottom = int(mapSize.end.y * celSize.y * $Background.scale.y)
	$Camera2D.limit_smoothed = true

extends Control

func _draw() -> void:
	var parent = get_parent()
	if parent and parent.has_method("draw_minimap"):
		parent.draw_minimap(self)

extends Node

## Global singleton for Guardians game.
## Manages global game state and persistent overlays such as the version watermark.

const GAME_VERSION: String = "0.7"

func _ready() -> void:
	_create_watermark()

func _create_watermark() -> void:
	# Persistent canvas layer on top of all scenes
	var canvas = CanvasLayer.new()
	canvas.name = "WatermarkLayer"
	canvas.layer = 120 # Top-most layer above menus and HUD
	add_child(canvas)
	
	var label = Label.new()
	label.name = "WatermarkLabel"
	label.text = "pre-alpha version " + GAME_VERSION
	
	# Add child to the CanvasLayer first so anchors calculate against viewport
	canvas.add_child(label)
	
	# Bottom wide alignment
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -36.0
	label.offset_bottom = -8.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	
	# Clean, semi-transparent watermark styling
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.65))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

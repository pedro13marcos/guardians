extends StaticBody2D

## Reusable Astral Wall that dissolves when an Astral Rift is activated by Guardian ("F").

@export var is_open: bool = false

@onready var collision = $CollisionShape2D
@onready var sprite = $Sprite2D

func _ready() -> void:
	if is_open:
		open_wall(true)
	else:
		close_wall(true)

func open_wall(immediate: bool = false) -> void:
	is_open = true
	collision.set_deferred("disabled", true)
	
	if immediate:
		sprite.modulate.a = 0.15
	else:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.15, 0.4)

func close_wall(immediate: bool = false) -> void:
	is_open = false
	collision.set_deferred("disabled", false)
	
	if immediate:
		sprite.modulate.a = 1.0
	else:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.4)

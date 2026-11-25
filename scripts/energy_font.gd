extends Area2D

@export var energiaMax: int = 20
## Target hero code ("V" = White Lightning, "F" = Guardian, "A" = Monkey).
## Leave empty to pick a hero randomly when spawned.
@export var target_character: String = ""

const HERO_CODES: Array[String] = ["V", "F", "A"]

func _ready() -> void:
	if not HERO_CODES.has(target_character):
		target_character = HERO_CODES[randi() % HERO_CODES.size()]
	$AnimatedSprite.play(target_character)
	$AnimatedSprite.scale = Vector2(0.007, 0.007)
	$AnimatedSprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and "personagem" in body and body.personagem == target_character:
		if body.energia < 100:
			body.energia += energiaMax
			if body.energia > 100:
				body.energia = 100
			body.atualizaUI()
			queue_free()

extends Area2D

@onready var player = get_node("../Player");

@export var energiaMax = 20;

func _ready():
	$AnimatedSprite.play(player.personagem)
	$AnimatedSprite.scale = Vector2(0.125, 0.125)
	$AnimatedSprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _on_body_entered(body):
	if body.name == "Player":
		if body.energia < 100:
			body.energia += energiaMax;
			if body.energia > 100: body.energia = 100;
			body.atualizaUI();
			queue_free();
		

extends Area2D

@onready var player = get_node("../Player");

func _ready():
	$AnimatedSprite.play(player.personagem);

func _on_body_entered(body):
	if body.name == "Player":
		if body.energia < 100:
			body.energia += 10;
			if body.energia > 100: body.energia = 100;
			body.atualizaUI();
			queue_free();
		


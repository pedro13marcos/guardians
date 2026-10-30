extends Area2D

@onready var player = get_node("../../Player");

var speed = 8;
var facingDir = Vector2();
var animName;

func _ready():
	facingDir = player.getFacingDir();
	global_position.x = player.getX()+(facingDir.x*8);
	global_position.y = player.getY();
	animName = player.playerAnim();
	$AnimatedSprite2D.play(animName);

func _on_body_entered(body):
	
	if body.name != "Player":
		if body.is_in_group("inimigo"):
			body.vida -= 5;
		
		elif body.is_in_group("Quebravel"):
			body.quebra();
		queue_free();
		
func _physics_process(delta):
	position.x += (facingDir.x*speed);
	position.y += (facingDir.y*speed);


func _on_mata_tiro_timeout():
	queue_free();

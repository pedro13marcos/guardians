extends Area2D

var colPlayer: bool;
var isButtonPressed: bool;

signal buttonPressed;

func _ready():
	isButtonPressed = false;
	colPlayer = false;
	$AnimatedSprite2D.play("Up");


func _process(delta):
	if colPlayer && Input.is_action_just_released("Action") && !isButtonPressed:
		$AnimatedSprite2D.play("Down");
		emit_signal("buttonPressed");
		isButtonPressed = true;
		


func _on_body_entered(body):
	if body.name == "Player":
		colPlayer = true;


func _on_body_exited(body):
	if body.name == "Player":
		colPlayer = true;

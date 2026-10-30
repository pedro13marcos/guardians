extends Area2D

@export var isOpen: bool;
@export var level: String;

func _ready():
	isOpen = false;
	$AnimatedSprite2D.play("close");

func _process(delta):
	if isOpen:
		$AnimatedSprite2D.play("open");
	else:
		$AnimatedSprite2D.play("close");
		

func _on_body_entered(body):
	if isOpen:
		if body.name == "Player":
			nextLevel(level);

func nextLevel(Level):
	get_tree().change_scene_to_file(Level);

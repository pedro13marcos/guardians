extends StaticBody2D

@onready var anim = $AnimatedSprite2D;

func _ready():
	anim.play("default");

func quebra():
	anim.play("broke");

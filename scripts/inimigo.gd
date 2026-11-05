extends CharacterBody2D

var distPers = 10;
var speed = 60;
var life = 5;
var vida = 5;
@export var disPers: float = 250.0;
@export var always_pursue: bool = false;

@export var player: Node2D
@onready var nav_agent := $NavigationAgent2D as NavigationAgent2D
@onready var novoEnergia = preload("res://scenes/energy_font.tscn");
@onready var novoItemVida = preload("res://scenes/life_font.tscn");
@onready var pai = get_node("..");

signal inimigoMorto;

func _ready():
	randomize();
	vida = life;
	if player == null and is_inside_tree() and get_tree() != null:
		player = get_tree().get_first_node_in_group("player");
	makePath();
	
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	if nav_agent == null:
		if has_node("NavigationAgent2D"):
			nav_agent = $NavigationAgent2D
		else:
			return
	var next_pos = nav_agent.get_next_path_position()
	var dir = to_local(next_pos).normalized()
	if dir == Vector2.ZERO and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	var is_moving = always_pursue or (disPers > global_position.distance_to(player.global_position));
	if is_moving:
		velocity = dir*speed;
		move_and_slide();
	atualizaVida();
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i);
		if collision.get_collider().name == "Player":
			collision.get_collider().danoPlayer();
			
	#changing animation of enemy
	if is_moving:
		if abs(dir.x) > 0.05:
			$AnimatedSprite2D.flip_h = dir.x > 0;
		if abs(dir.x) > abs(dir.y):
			if dir.x > 0:
				$AnimatedSprite2D.play("direita");
			else:
				$AnimatedSprite2D.play("esquerda");
		elif abs(dir.y) > abs(dir.x):
			if dir.y > 0:
				$AnimatedSprite2D.play("baixo");
			else:
				$AnimatedSprite2D.play("cima");
	else:
		$AnimatedSprite2D.stop();
	
func makePath() -> void:
	nav_agent.target_position = player.global_position;

func _on_att_nav_timeout():
	makePath();
	$attNav.start();
	
func atualizaVida():
	if vida != null and vida <= 0:
		if randi_range(0,10) < 6:
			randomize();
			if randi_range(0,4) <= 3:
				var Energia = novoEnergia.instantiate();
				Energia.position = position;
				pai.add_child(Energia);
			else:
				var itemVida = novoItemVida.instantiate();
				itemVida.position = position;
				pai.add_child(itemVida);
				pass
		emit_signal("inimigoMorto");
		queue_free();
		

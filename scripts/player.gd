extends CharacterBody2D

var speed = 80;
var facingDir = Vector2();
var vel = Vector2();
var personagem = "V";
var hurtCoolDown = false;

var vida = 100;
var energia = 100;
var isFacingLeft: bool = false;
var activeTail: Node2D = null;


@onready var novoPoder = preload("res://scenes/atack_power.tscn");
@onready var monkeyTailScene = preload("res://scenes/monkey_tail.tscn");
@onready var anim = $AnimatedSprite2D
@onready var UI = get_node("../HUD2");
@onready var pai = get_node("..");

#@export var UI: CanvasLayer;

func _ready():
	atualizaUI();
	anim.play("Vdown");
	anim.stop();
	personagem = "V";
	facingDir = Vector2(0,1);
	isFacingLeft = false;
	update_sprite_flip();
	
func _physics_process(_delta):
	vel = Vector2();
	
	var move_left = Input.is_action_pressed("ui_left");
	var move_right = Input.is_action_pressed("ui_right");
	var move_up = Input.is_action_pressed("ui_up");
	var move_down = Input.is_action_pressed("ui_down");
	
	if move_left and not move_right:
		vel.x = -1;
		isFacingLeft = true;
		update_sprite_flip();
	elif move_right and not move_left:
		vel.x = 1;
		isFacingLeft = false;
		update_sprite_flip();
	# When vel.x == 0 (straight up, straight down, or stopped), anim.flip_h is preserved
	
	if move_up and not move_down:
		vel.y = -1;
	elif move_down and not move_up:
		vel.y = 1;
	
	if vel != Vector2.ZERO:
		facingDir = vel;
		if vel.x != 0:
			if vel.x < 0:
				anim.play(personagem + "left");
			else:
				anim.play(personagem + "right");
		elif vel.y < 0:
			anim.play(personagem + "up");
		elif vel.y > 0:
			anim.play(personagem + "down");
	else:
		anim.stop();

	velocity = vel*speed;
	move_and_slide();
	
	if Input.is_action_just_pressed("Ataque"):
		if energia >= 10:
			if personagem == "A":
				if not is_instance_valid(activeTail):
					energia -= 10;
					atualizaUI();
					activeTail = monkeyTailScene.instantiate();
					pai.add_child(activeTail);
			else:
				energia -= 10;
				atualizaUI();
				var poder = novoPoder.instantiate();
				pai.add_child(poder);
	
	if Input.is_action_just_pressed("changeCharacter"):
		personagem = trocaPersonagem(personagem);
		anim.play(personagem+"down");
		anim.stop();
		update_sprite_flip();
	

func update_sprite_flip():
	# White Lightning ("V") has its base sprite facing right.
	# Guardian ("F") and Monkey ("A") have their base sprites facing left.
	if personagem == "V":
		anim.flip_h = isFacingLeft;
	else:
		anim.flip_h = not isFacingLeft;
	

func trocaPersonagem(personagem):
	if personagem == "V":
		personagem = "F";
	elif personagem == "F":
		personagem = "A";
	elif personagem == "A":
		personagem = "V";
	UI.atualizaPersonagem(personagem);
	return personagem;
	
func getX():
	return global_position.x;
	
func getY():
	return global_position.y;
	
func getFacingDir():
	return facingDir;

func playerAnim():
	return anim.animation;
	
func atualizaUI():
	UI.atualizaVida(vida);
	UI.atualizaEnergia(energia);


func _on_hurting_cool_down_timeout():
	hurtCoolDown = false;
	modulate = Color (1,1,1)


func _on_energy_growing_timeout():
	if energia<100:
		energia+=1;
		atualizaUI();
	
func morrePlayer():
	get_tree().reload_current_scene();
	
func danoPlayer():
	if !hurtCoolDown:
		vida-=10
		if vida <=0:
			morrePlayer();
		hurtCoolDown = true;
		modulate = Color(1,0.5,0.5);
		$hurtingCoolDown.start(1);
		atualizaUI();

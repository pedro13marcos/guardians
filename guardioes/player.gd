extends CharacterBody2D

var speed = 80;
var facingDir = Vector2();
var vel = Vector2();
var personagem = "V";
var hurtCoolDown = false;

var vida = 100;
var energia = 100;


@onready var novoPoder = preload("res://atack_power.tscn");
@onready var anim = $AnimatedSprite2D
@onready var UI = get_node("../HUD");
@onready var pai = get_node("..");

#@export var UI: CanvasLayer;

func _ready():
	atualizaUI();
	anim.play("Vdown");
	anim.stop();
	personagem = "V";
	facingDir = Vector2(0,1);
	
func _physics_process(delta):
	vel = Vector2();
	
	if Input.is_action_pressed("ui_up"):
		vel.y = -1;
		facingDir = Vector2(0,-1);
		anim.play(personagem+"up")
	elif Input.is_action_pressed("ui_down"):
		vel.y = 1;
		facingDir = Vector2(0,1);
		anim.play(personagem+"down")
	elif Input.is_action_pressed("ui_left"):
		vel.x = -1;
		facingDir = Vector2(-1,0);
		anim.play(personagem+"left")
	elif Input.is_action_pressed("ui_right"):
		vel.x = 1;
		facingDir = Vector2(1,0);
		anim.play(personagem+"right");
	
	if vel.x == 0 && vel.y ==0:
		anim.stop();

	velocity = vel*speed;
	move_and_slide();
	
	if Input.is_action_just_pressed("atack"):

		if energia >= 10:
			energia -= 10;
			atualizaUI();
			var poder = novoPoder.instantiate();
			add_child(poder);
	
	if Input.is_action_just_pressed("changeCharacter"):
		personagem = trocaPersonagem(personagem);
		anim.play(personagem+"down");
		anim.stop();
	

func trocaPersonagem(personagem):
	if personagem == "V":
		personagem = "F";
	elif personagem == "F":
		personagem = "A";
	elif personagem == "A":
		personagem = "V";
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

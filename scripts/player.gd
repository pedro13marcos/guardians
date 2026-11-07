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

## Side ability energy spending (takes ~1/3 of the 100 energy bar).
## Exposed as integer export so it can be easily balanced or adjusted for upgrades.
@export var side_ability_energy_cost: int = 33;

var is_performing_side_ability: bool = false;
var is_teleporting: bool = false;

@onready var novoPoder = preload("res://scenes/atack_power.tscn");
@onready var monkeyTailScene = preload("res://scenes/monkey_tail.tscn");
@onready var wlTeleportScene = preload("res://scenes/wl_teleport.tscn");
@onready var monkeyTailSpinScene = preload("res://scenes/monkey_tail_spin.tscn");
@onready var guardianHealScene = preload("res://scenes/guardian_heal.tscn");

@onready var anim = $AnimatedSprite2D;
@onready var UI = get_node("../HUD2");
@onready var pai = get_node("..");

func _ready():
	atualizaUI();
	anim.play("Vdown");
	anim.stop();
	personagem = "V";
	facingDir = Vector2(0,1);
	isFacingLeft = false;
	update_sprite_flip();
	
func _physics_process(_delta):
	# If White Lightning is currently teleporting, his position is driven by the lightning projectile
	if is_teleporting:
		return;
		
	vel = Vector2();
	
	# Normal movement controls (only when not locking in a ground ability)
	if not is_performing_side_ability:
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
	
	# --- Primary Attack ---
	if Input.is_action_just_pressed("Ataque") and not is_performing_side_ability:
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
	
	# --- Side Ability (Key F / Square / X / Y) ---
	if Input.is_action_just_pressed("side_ability") and not is_performing_side_ability:
		if energia >= side_ability_energy_cost:
			executa_side_ability();
	
	# --- Character Switch (Key R / Triangle) ---
	if Input.is_action_just_pressed("changeCharacter") and not is_performing_side_ability:
		personagem = trocaPersonagem(personagem);
		anim.play(personagem+"down");
		anim.stop();
		update_sprite_flip();

func executa_side_ability() -> void:
	energia -= side_ability_energy_cost;
	atualizaUI();
	is_performing_side_ability = true;
	
	if personagem == "V":
		# White Lightning: Lightning Bolt Dash & Teleport without damage
		is_teleporting = true;
		anim.play("Vside");
		update_sprite_flip();
		var tp = wlTeleportScene.instantiate();
		pai.add_child(tp);
		tp.setup(self, facingDir);
	elif personagem == "A":
		# Monkey: Whirlwind Tail Spin (quarter screen radius)
		anim.play("Aside");
		update_sprite_flip();
		var spin = monkeyTailSpinScene.instantiate();
		pai.add_child(spin);
		spin.setup(self);
	elif personagem == "F":
		# Guardian: Staff slam on the floor, heals half of his life (+50 HP)
		anim.play("Fside");
		update_sprite_flip();
		var heal = guardianHealScene.instantiate();
		pai.add_child(heal);
		heal.setup(self);

func finish_teleport() -> void:
	is_teleporting = false;
	is_performing_side_ability = false;
	anim.play(personagem + "down");
	anim.stop();
	update_sprite_flip();

func finish_tail_spin() -> void:
	is_performing_side_ability = false;
	anim.play(personagem + "down");
	anim.stop();
	update_sprite_flip();

func finish_guardian_slam() -> void:
	is_performing_side_ability = false;
	anim.play(personagem + "down");
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
	# White Lightning is completely invulnerable during his lightning teleport
	if is_teleporting:
		return;
		
	if !hurtCoolDown:
		vida-=10
		if vida <=0:
			morrePlayer();
		hurtCoolDown = true;
		modulate = Color(1,0.5,0.5);
		$hurtingCoolDown.start(1);
		atualizaUI();

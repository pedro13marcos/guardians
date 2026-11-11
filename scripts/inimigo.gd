extends CharacterBody2D

var speed: float = 60.0
var life: int = 5
var is_dead: bool = false

var vida: int = 5:
	set(val):
		vida = val
		if is_inside_tree():
			if vida <= 0 and not is_dead:
				is_dead = true
				call_deferred("_die")
			elif vida > 0:
				_play_hit_feedback()

@export var disPers: float = 250.0
@export var always_pursue: bool = false
@export var player: Node2D = null

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var att_timer: Timer = $attNav

@onready var novoEnergia = preload("res://scenes/energy_font.tscn")
@onready var novoItemVida = preload("res://scenes/life_font.tscn")
@onready var pai = get_node_or_null("..")

signal inimigoMorto

var _is_nav_ready: bool = false
var _stuck_timer: float = 0.0
var _last_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	randomize()
	add_to_group("inimigo")
	vida = life
	_last_position = global_position
	
	_resolve_player()
	
	if nav_agent != null:
		nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	if att_timer != null:
		att_timer.wait_time = randf_range(0.18, 0.28)
	
	# In Godot 4, wait for the first physics tick before querying NavigationServer
	call_deferred("_setup_navigation")

func _setup_navigation() -> void:
	await get_tree().physics_frame
	_is_nav_ready = true
	makePath()

func _resolve_player() -> void:
	if is_instance_valid(player):
		return
	var found = get_tree().get_first_node_in_group("player")
	if is_instance_valid(found):
		player = found as Node2D
		return
	if has_node("../Player"):
		player = get_node("../Player") as Node2D

func _physics_process(delta: float) -> void:
	_resolve_player()
	if not is_instance_valid(player):
		_update_animations(Vector2.ZERO, false)
		return
	
	if not _is_nav_ready:
		return
	
	var dist_to_player: float = global_position.distance_to(player.global_position)
	var is_in_range: bool = always_pursue or (dist_to_player <= disPers)
	
	if not is_in_range:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animations(Vector2.ZERO, false)
		return
	
	# Check if we already reached desired target distance
	if nav_agent.is_navigation_finished():
		var direct_to_player = player.global_position - global_position
		if direct_to_player.length() <= 20.0:
			# Close attack range
			_apply_movement(direct_to_player.normalized() * (speed * 0.4))
		else:
			_apply_movement(Vector2.ZERO)
		_check_player_collisions()
		return
	
	# Calculate path direction towards next path point in world space
	var next_path_pos: Vector2 = nav_agent.get_next_path_position()
	var move_dir: Vector2 = (next_path_pos - global_position).normalized()
	
	# If next_path_pos is too close or empty, direct towards target
	if move_dir == Vector2.ZERO:
		move_dir = (player.global_position - global_position).normalized()
	
	# Unstuck watchdog: detect if moving into a corner vertex
	if global_position.distance_to(_last_position) < 1.0 and is_in_range:
		_stuck_timer += delta
		if _stuck_timer > 0.35:
			# Nudge slightly perpendicular to glide around corner
			var perp = Vector2(-move_dir.y, move_dir.x)
			move_dir = (move_dir + perp * 0.7).normalized()
			if _stuck_timer > 0.8:
				makePath()
				_stuck_timer = 0.0
	else:
		_stuck_timer = 0.0
	
	_last_position = global_position
	var intended_velocity: Vector2 = move_dir * speed
	
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(intended_velocity)
	else:
		_apply_movement(intended_velocity)
	
	_check_player_collisions()
	atualizaVida()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	_apply_movement(safe_velocity)

func _apply_movement(vel: Vector2) -> void:
	velocity = vel
	move_and_slide()
	_update_animations(velocity, velocity.length() > 2.0)

func _check_player_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.name == "Player":
			if collider.has_method("danoPlayer"):
				collider.danoPlayer()

func _update_animations(dir: Vector2, is_moving: bool) -> void:
	if not is_instance_valid(anim_sprite):
		return
	
	if is_moving and dir.length() > 2.0:
		if abs(dir.x) > 0.05:
			anim_sprite.flip_h = dir.x > 0
		if abs(dir.x) > abs(dir.y):
			if dir.x > 0:
				anim_sprite.play("direita")
			else:
				anim_sprite.play("esquerda")
		else:
			if dir.y > 0:
				anim_sprite.play("baixo")
			else:
				anim_sprite.play("cima")
	else:
		anim_sprite.stop()

func makePath() -> void:
	if not is_instance_valid(player) or not is_instance_valid(nav_agent):
		return
	
	# Snap target to nearest valid point on navigation mesh to prevent unreachable target stalls
	var map_rid: RID = nav_agent.get_navigation_map()
	var target_pt: Vector2 = player.global_position
	if map_rid.is_valid():
		target_pt = NavigationServer2D.map_get_closest_point(map_rid, player.global_position)
	
	nav_agent.target_position = target_pt

func _on_att_nav_timeout() -> void:
	makePath()
	if att_timer != null:
		att_timer.start(randf_range(0.18, 0.28))

func take_damage(amount: int = 5) -> void:
	self.vida -= amount

func dano(amount: int = 5) -> void:
	take_damage(amount)

func danoInimigo(amount: int = 5) -> void:
	take_damage(amount)

func _play_hit_feedback() -> void:
	if not is_instance_valid(anim_sprite):
		return
	var tween = create_tween()
	anim_sprite.modulate = Color(3.0, 0.3, 0.3, 1.0) # Bright red flash
	tween.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)

func _die() -> void:
	atualizaVida()

func atualizaVida() -> void:
	if vida != null and vida <= 0:
		if is_dead:
			pass
		is_dead = true
		if randi_range(0, 10) < 6:
			if randi_range(0, 4) <= 3:
				var energia = novoEnergia.instantiate()
				energia.position = position
				if pai:
					pai.add_child(energia)
			else:
				var item_vida = novoItemVida.instantiate()
				item_vida.position = position
				if pai:
					pai.add_child(item_vida)
		emit_signal("inimigoMorto")
		queue_free()

extends Node2D

signal enemy_spawned(enemy: Node2D)

@export var enemy_scene: PackedScene = preload("res://scenes/inimigo.tscn")
@export var auto_spawn: bool = true
@export var spawn_interval: float = 5.0
@export var initial_delay: float = 2.0
@export var max_active_enemies: int = 5
@export var spawn_offset: Vector2 = Vector2(0, 24)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $SpawnTimer

var active_enemies: Array[Node2D] = []
var is_active: bool = false

func _ready() -> void:
	if sprite:
		sprite.play("close")
	if timer:
		timer.timeout.connect(_on_spawn_timer_timeout)
	if auto_spawn:
		start_spawning(initial_delay)

func start_spawning(delay: float = -1.0) -> void:
	is_active = true
	var first_delay = delay if delay > 0 else spawn_interval
	if timer:
		timer.start(first_delay)

func stop_spawning() -> void:
	is_active = false
	if timer:
		timer.stop()

func _on_spawn_timer_timeout() -> void:
	if not is_active:
		return
	spawn_enemy()
	if timer and is_active:
		timer.start(spawn_interval)

func spawn_enemy() -> Node2D:
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e))
	if max_active_enemies > 0 and active_enemies.size() >= max_active_enemies:
		return null

	if enemy_scene == null:
		return null

	# Animate door opening
	if sprite:
		sprite.play("open")

	var enemy = enemy_scene.instantiate() as Node2D
	if enemy == null:
		return null

	# Assign player reference if enemy expects it
	var player_node: Node2D = null
	if has_node("../Player"):
		player_node = get_node("../Player") as Node2D
	elif is_inside_tree() and get_tree() != null:
		player_node = get_tree().get_first_node_in_group("player") as Node2D

	if "player" in enemy:
		enemy.player = player_node

	# Position the enemy relative to the spawner door
	enemy.global_position = global_position + spawn_offset

	# Add to the level scene
	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(enemy)
	elif is_inside_tree() and get_tree() != null and get_tree().current_scene:
		get_tree().current_scene.add_child(enemy)

	active_enemies.append(enemy)
	enemy_spawned.emit(enemy)

	# Close the door after a short animation duration
	if is_inside_tree() and get_tree() != null:
		get_tree().create_timer(0.5).timeout.connect(func():
			if is_instance_valid(sprite):
				sprite.play("close")
		)
	elif is_instance_valid(sprite):
		sprite.play("close")

	return enemy

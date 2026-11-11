extends Area2D

@onready var player = get_node_or_null("../Player")

var speed: float = 8.0
var facingDir: Vector2 = Vector2.DOWN
var animName: String = ""

func _ready() -> void:
	if not is_instance_valid(player):
		var found = get_tree().get_first_node_in_group("player")
		if is_instance_valid(found):
			player = found
	
	if is_instance_valid(player):
		if player.has_method("getFacingDir"):
			facingDir = player.getFacingDir().normalized()
		if player.has_method("getX") and player.has_method("getY"):
			global_position = Vector2(player.getX() + (facingDir.x * 8.0), player.getY() + (facingDir.y * 8.0))
		else:
			global_position = player.global_position + (facingDir * 8.0)
		
		if player.has_method("playerAnim"):
			animName = player.playerAnim()
	
	if facingDir == Vector2.ZERO:
		facingDir = Vector2.DOWN
		
	_setup_sprite_animation()

func _setup_sprite_animation() -> void:
	if not has_node("AnimatedSprite2D"):
		return
	var sprite: AnimatedSprite2D = $AnimatedSprite2D
	if sprite.sprite_frames == null:
		return
		
	if not animName.is_empty() and sprite.sprite_frames.has_animation(animName):
		sprite.play(animName)
	else:
		var p_char: String = "V"
		if is_instance_valid(player) and "personagem" in player:
			p_char = player.personagem
		
		var dir_str: String = "down"
		if abs(facingDir.x) > abs(facingDir.y):
			dir_str = "right" if facingDir.x > 0 else "left"
		else:
			dir_str = "down" if facingDir.y > 0 else "up"
			
		var candidate = p_char + dir_str
		if sprite.sprite_frames.has_animation(candidate):
			sprite.play(candidate)
		elif sprite.sprite_frames.has_animation("Vdown"):
			sprite.play("Vdown")

func _on_body_entered(body: Node2D) -> void:
	if body == player or body.name == "Player":
		return
	
	# Damage enemy
	if body.is_in_group("inimigo") or body.has_method("take_damage") or "vida" in body:
		if body.has_method("take_damage"):
			body.take_damage(5)
		elif "vida" in body:
			body.vida -= 5
		queue_free()
		return
	elif body.is_in_group("Quebravel"):
		if body.has_method("quebra"):
			body.quebra()
		queue_free()
		return
		
	if body is TileMap or body is StaticBody2D:
		queue_free()

func _physics_process(_delta: float) -> void:
	position += facingDir * speed

func _on_mata_tiro_timeout() -> void:
	queue_free()

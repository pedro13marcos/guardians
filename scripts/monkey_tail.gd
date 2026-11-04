extends Node2D

@onready var tail_line: Line2D = $TailLine
@onready var claw: Sprite2D = $Claw
@onready var hit_box: Area2D = $HitBox

@onready var player: CharacterBody2D = get_node_or_null("../Player")

const EXTEND_SPEED: float = 900.0
const RETRACT_SPEED: float = 1100.0
const IMPACT_HOLD_TIME: float = 0.04

enum State { EXTENDING, IMPACT, RETRACTING, DONE }
var state: State = State.EXTENDING

var max_reach: float = 200.0
var facing_dir: Vector2 = Vector2.DOWN
var current_length: float = 0.0
var target_distance: float = 200.0
var hit_collider: Object = null
var hit_applied: bool = false
var impact_timer: float = 0.0

func _ready() -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	
	# Compute half-screen distance based on camera zoom (defaults to 200px)
	var camera = get_viewport().get_camera_2d()
	if camera and camera.zoom.x > 0:
		max_reach = get_viewport_rect().size.x / (camera.zoom.x * 2.0)
	else:
		max_reach = 200.0
	
	facing_dir = player.getFacingDir().normalized()
	if facing_dir == Vector2.ZERO:
		facing_dir = Vector2.DOWN
	
	global_position = player.global_position
	claw.rotation = facing_dir.angle()
	
	# Raycast forward to detect obstacles and find contact point
	_detect_obstacle()
	_update_geometry()

func _detect_obstacle() -> void:
	var space_state = get_world_2d().direct_space_state
	var start_pos = player.global_position
	var closest_hit = max_reach
	hit_collider = null
	
	# Parallel rays matching the sleek, proportional tail thickness
	var perp = Vector2(-facing_dir.y, facing_dir.x) * 2.5
	var test_origins = [start_pos, start_pos + perp, start_pos - perp]
	
	for orig in test_origins:
		var query = PhysicsRayQueryParameters2D.create(orig, orig + facing_dir * max_reach, 7, [player.get_rid()])
		query.collide_with_areas = true
		query.collide_with_bodies = true
		var res = space_state.intersect_ray(query)
		if not res.is_empty():
			var dist = start_pos.distance_to(res.position)
			if dist < closest_hit:
				closest_hit = dist
				hit_collider = res.collider
	
	# If an obstacle was hit, stop at contact point; otherwise full half-screen
	target_distance = clamp(closest_hit, 8.0, max_reach)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	
	# Keep tail base anchored to Monkey even while moving
	global_position = player.global_position
	
	match state:
		State.EXTENDING:
			current_length += EXTEND_SPEED * delta
			if current_length >= target_distance:
				current_length = target_distance
				_trigger_impact(hit_collider)
				state = State.IMPACT
				impact_timer = IMPACT_HOLD_TIME
		State.IMPACT:
			impact_timer -= delta
			if impact_timer <= 0.0:
				state = State.RETRACTING
		State.RETRACTING:
			current_length -= RETRACT_SPEED * delta
			if current_length <= 0.0:
				current_length = 0.0
				state = State.DONE
				queue_free()
				return
		State.DONE:
			return
	
	_update_geometry()

func _update_geometry() -> void:
	var tip_pos = facing_dir * current_length
	claw.position = tip_pos
	hit_box.position = tip_pos
	
	if current_length > 4.0:
		tail_line.visible = true
		# Claw base collar is ~5px behind claw center at 0.42 scale
		var line_end = facing_dir * max(0.0, current_length - 5.0)
		tail_line.points = PackedVector2Array([Vector2.ZERO, line_end])
	else:
		tail_line.visible = false

func _on_hit_box_body_entered(body: Node2D) -> void:
	if state == State.EXTENDING and body != player:
		target_distance = current_length
		_trigger_impact(body)
		state = State.IMPACT
		impact_timer = IMPACT_HOLD_TIME

func _trigger_impact(primary_target: Object) -> void:
	if hit_applied:
		return
	hit_applied = true
	
	# Apply damage / break to primary target
	if primary_target and primary_target != player:
		_apply_damage_to(primary_target)
	
	# Also damage any overlapping targets at claw tip
	if is_instance_valid(hit_box):
		for body in hit_box.get_overlapping_bodies():
			if body != player and body != primary_target:
				_apply_damage_to(body)

func _apply_damage_to(target: Object) -> void:
	if not is_instance_valid(target):
		return
	if target.is_in_group("inimigo"):
		if "vida" in target:
			target.vida -= 5
	elif target.is_in_group("Quebravel"):
		if target.has_method("quebra"):
			target.quebra()

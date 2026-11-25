extends Camera2D

## Camera that always follows the player smoothly while clamping to the map boundaries.
## Prevents showing the empty void outside the level's tilemap.

@export var player: CharacterBody2D
@export var smooth_speed: float = 10.0

var _tilemap: TileMap
var _map_rect: Rect2 = Rect2()
var _has_bounds: bool = false

func _ready() -> void:
	if player == null and has_node("../Player"):
		player = get_node("../Player") as CharacterBody2D
	if has_node("../Background"):
		_tilemap = get_node("../Background") as TileMap
		_compute_map_bounds()
	
	# Clear static editor limits so dynamic boundary clamp takes full control
	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000
	limit_smoothed = false
	position_smoothing_enabled = false
	
	# Immediately snap to the valid player position on spawn so there's no initial jump
	if is_instance_valid(player):
		global_position = _compute_target(player.global_position)

func _compute_map_bounds() -> void:
	if _tilemap == null or _tilemap.tile_set == null:
		_has_bounds = false
		return
	var used: Rect2i = _tilemap.get_used_rect()
	if used.size == Vector2i.ZERO:
		_has_bounds = false
		return
	var cell: Vector2 = Vector2(_tilemap.tile_set.tile_size) * _tilemap.scale.abs()
	var top_left_local: Vector2 = _tilemap.map_to_local(used.position) - cell * 0.5
	var bottom_right_local: Vector2 = _tilemap.map_to_local(used.end - Vector2i.ONE) + cell * 0.5
	var p1: Vector2 = _tilemap.to_global(top_left_local)
	var p2: Vector2 = _tilemap.to_global(bottom_right_local)
	var min_pt: Vector2 = Vector2(minf(p1.x, p2.x), minf(p1.y, p2.y))
	var max_pt: Vector2 = Vector2(maxf(p1.x, p2.x), maxf(p1.y, p2.y))
	_map_rect = Rect2(min_pt, max_pt - min_pt)
	_has_bounds = true

func _compute_target(target: Vector2) -> Vector2:
	if not _has_bounds:
		return target
	var half: Vector2 = get_viewport_rect().size / zoom * 0.5
	var res := target
	
	# Horizontal clamping / centering
	if _map_rect.size.x <= half.x * 2.0:
		res.x = _map_rect.position.x + _map_rect.size.x * 0.5
	else:
		res.x = clampf(target.x, _map_rect.position.x + half.x, _map_rect.end.x - half.x)
		
	# Vertical clamping / centering
	if _map_rect.size.y <= half.y * 2.0:
		res.y = _map_rect.position.y + _map_rect.size.y * 0.5
	else:
		res.y = clampf(target.y, _map_rect.position.y + half.y, _map_rect.end.y - half.y)
		
	return res

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var target := _compute_target(player.global_position)
	if delta > 0.0:
		# Framerate-independent smooth exponential decay
		var weight: float = 1.0 - exp(-smooth_speed * delta)
		global_position = global_position.lerp(target, weight)
	else:
		global_position = target

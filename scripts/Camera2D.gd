extends Camera2D

## Camera that always follows the player but never shows the void (empty tilemap cells).
## When the player cannot be centered on one axis without exposing the void, the camera
## keeps following on the other axis, using the closest valid position to the player.

@export var player: CharacterBody2D;

var _tilemap: TileMap
var _cell: Vector2 = Vector2(32, 32)
var _origin: Vector2i = Vector2i.ZERO
var _grid_size: Vector2i = Vector2i.ZERO
var _prefix: PackedInt32Array = PackedInt32Array()

func _ready() -> void:
	if player == null and has_node("../Player"):
		player = get_node("../Player") as CharacterBody2D
	if has_node("../Background"):
		_tilemap = get_node("../Background") as TileMap
		_build_grid()
	# Level scripts must not clamp the camera by region anymore.
	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000
	limit_smoothed = false
	position_smoothing_enabled = false

func _build_grid() -> void:
	var used: Rect2i = _tilemap.get_used_rect()
	_origin = used.position
	_grid_size = used.size
	_cell = Vector2(_tilemap.tile_set.tile_size) * _tilemap.scale
	var w: int = _grid_size.x
	var h: int = _grid_size.y
	# Summed-area table of filled cells for O(1) rectangle queries.
	_prefix.resize((w + 1) * (h + 1))
	_prefix.fill(0)
	for y in range(h):
		var row_sum: int = 0
		for x in range(w):
			if _tilemap.get_cell_source_id(0, Vector2i(x, y) + _origin) != -1:
				row_sum += 1
			_prefix[(y + 1) * (w + 1) + (x + 1)] = _prefix[y * (w + 1) + (x + 1)] + row_sum

func _is_view_valid(center: Vector2, half: Vector2) -> bool:
	var eps: float = 0.01
	var x0: int = int(floor((center.x - half.x + eps) / _cell.x)) - _origin.x
	var x1: int = int(ceil((center.x + half.x - eps) / _cell.x)) - _origin.x
	var y0: int = int(floor((center.y - half.y + eps) / _cell.y)) - _origin.y
	var y1: int = int(ceil((center.y + half.y - eps) / _cell.y)) - _origin.y
	if x0 < 0 or y0 < 0 or x1 > _grid_size.x or y1 > _grid_size.y:
		return false
	var stride: int = _grid_size.x + 1
	var filled: int = _prefix[y1 * stride + x1] - _prefix[y0 * stride + x1] - _prefix[y1 * stride + x0] + _prefix[y0 * stride + x0]
	return filled == (x1 - x0) * (y1 - y0)

func _candidates(p: float, half: float, cell: float, origin: int, count: int) -> Array[float]:
	var result: Array[float] = [p]
	var first: int = int(floor((p - 2.0 * half) / cell))
	var last: int = int(ceil((p + 2.0 * half) / cell))
	for b in range(maxi(first, origin), mini(last, origin + count) + 1):
		var edge: float = b * cell
		result.append(edge + half)
		result.append(edge - half)
	return result

func _compute_position(target: Vector2) -> Vector2:
	if _tilemap == null or _grid_size == Vector2i.ZERO:
		return target
	var half: Vector2 = get_viewport_rect().size / zoom * 0.5
	if _is_view_valid(target, half):
		return target
	var xs: Array[float] = _candidates(target.x, half.x, _cell.x, _origin.x, _grid_size.x)
	var ys: Array[float] = _candidates(target.y, half.y, _cell.y, _origin.y, _grid_size.y)
	var best: Vector2 = target
	var best_d: float = INF
	for cx in xs:
		var dx: float = (cx - target.x) * (cx - target.x)
		if dx >= best_d:
			continue
		for cy in ys:
			var d: float = dx + (cy - target.y) * (cy - target.y)
			if d >= best_d:
				continue
			if _is_view_valid(Vector2(cx, cy), half):
				best = Vector2(cx, cy)
				best_d = d
	if best_d == INF:
		# Map smaller than the view: center on the used area.
		return (Vector2(_origin) + Vector2(_grid_size) * 0.5) * _cell
	return best

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		position = _compute_position(player.global_position)

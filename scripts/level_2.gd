extends Node2D

var inimigosMortos
var buttonPressed;

var nextLevel = "res://scenes/level_3.tscn";

var maxSwitches = 3;

var _cam_left: float = -384.0
var _cam_top: float = -192.0
var _cam_right: float = 192.0
var _cam_bottom: float = 224.0

func _ready():
	buttonPressed = 0;
	inimigosMortos = 0;
	$HUD2.setObjetivo("switch", maxSwitches, buttonPressed);
	$door.level = nextLevel;
	if has_node("Camera2D"):
		$Camera2D.limit_smoothed = true
	_init_camera_limits()
	
func _process(delta):
	if buttonPressed >= 3:
		$door.isOpen = true;
	_update_camera_limits(delta)

func _init_camera_limits() -> void:
	if not has_node("Player") or not has_node("Camera2D"):
		return
	var targets = _get_target_limits($Player.global_position)
	_cam_left = targets[0]
	_cam_top = targets[1]
	_cam_right = targets[2]
	_cam_bottom = targets[3]
	$Camera2D.limit_left = int(_cam_left)
	$Camera2D.limit_top = int(_cam_top)
	$Camera2D.limit_right = int(_cam_right)
	$Camera2D.limit_bottom = int(_cam_bottom)

func _get_target_limits(p: Vector2) -> Array[float]:
	# Default center limits
	var target_l: float = -384.0
	var target_r: float = 192.0
	var target_t: float = -192.0
	var target_b: float = 224.0

	# Vertical position is checked first for the north/south corridors, because those
	# corridors extend left of x = -200 and would otherwise be mistaken for the west branch.
	var in_hall: bool = p.y >= -168.0 and p.y <= 200.0
	if p.x > 160.0:
		# East branch (leads to Button 2) - ceiling is at -160, floor at 416, right wall at 1024
		target_l = -384.0
		target_r = 1024.0
		target_t = -160.0
		target_b = 416.0
	elif p.y < -168.0:
		# North branch (leads to Button 3) - ceiling at -736, walls at -352 and 128
		target_l = -352.0
		target_r = 128.0
		target_t = -736.0
		target_b = 224.0
	elif p.y > 200.0:
		# South branch (leads to Button 1) - floor at 832, walls at -384 and 128
		target_l = -384.0
		target_r = 128.0
		target_t = -192.0
		target_b = 832.0
	elif in_hall and p.x < -200.0:
		# West branch (leads to Door) - ceiling at -192, floor at 192, left wall at -1056
		target_l = -1056.0
		target_r = 192.0
		target_t = -192.0
		target_b = 192.0

	return [target_l, target_t, target_r, target_b]

func _update_camera_limits(delta: float) -> void:
	if not has_node("Player") or not has_node("Camera2D"):
		return
	var targets = _get_target_limits($Player.global_position)
	var lerp_weight: float = clamp(8.0 * delta, 0.0, 1.0)
	_cam_left = lerp(_cam_left, targets[0], lerp_weight)
	_cam_top = lerp(_cam_top, targets[1], lerp_weight)
	_cam_right = lerp(_cam_right, targets[2], lerp_weight)
	_cam_bottom = lerp(_cam_bottom, targets[3], lerp_weight)

	$Camera2D.limit_left = int(round(_cam_left))
	$Camera2D.limit_top = int(round(_cam_top))
	$Camera2D.limit_right = int(round(_cam_right))
	$Camera2D.limit_bottom = int(round(_cam_bottom))
	


func _on_inimigo_inimigo_morto():
	inimigosMortos += 1;
	

func _on_button_button_pressed():
	buttonPressed += 1
	$HUD2.atualizaObjetivo(buttonPressed);

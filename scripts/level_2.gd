extends Node2D

var inimigosMortos
var buttonPressed;

var nextLevel = "res://scenes/level_3.tscn";

var maxSwitches = 3;

func _ready():
	buttonPressed = 0;
	inimigosMortos = 0;
	$HUD2.setObjetivo("switch",maxSwitches,buttonPressed);
	$door.level = nextLevel;
	if has_node("Camera2D"):
		$Camera2D.limit_smoothed = true
	updateCameraLimits();
	
func _process(delta):
	if buttonPressed >= 3:
		$door.isOpen = true;
	updateCameraLimits();

func setCameraLimits():
	updateCameraLimits()

func updateCameraLimits():
	if not has_node("Player") or not has_node("Camera2D"):
		return
	var p = $Player.global_position
	var l = -384
	var r = 128
	var t = -192
	var b = 192

	if p.y < -100:
		# North corridor (leads to Button 3 at (-176, -696))
		l = -352
		r = 128
		t = -736
		b = 192
	elif p.y > 100 and p.x < 200:
		# South corridor (leads to Button 1 at (-192, 776))
		l = -384
		r = 64
		t = -160
		b = 832
	elif p.x < -200:
		# West hallway (leads to Door at (-984, 8))
		l = -1056
		r = 128
		t = -192
		b = 192
	elif p.x > 40:
		# East hallway (leads to Button 2 at (960, 152)) and SE alcove
		r = 1024
		t = -160
		if p.x >= 350 and p.y >= 80:
			l = 448
			b = 416
		else:
			l = -352
			b = 192
	else:
		# Center intersection
		l = -384
		r = 128
		t = -192
		b = 192

	$Camera2D.limit_left = l
	$Camera2D.limit_right = r
	$Camera2D.limit_top = t
	$Camera2D.limit_bottom = b
	


func _on_inimigo_inimigo_morto():
	inimigosMortos += 1;
	

func _on_button_button_pressed():
	buttonPressed += 1
	$HUD2.atualizaObjetivo(buttonPressed);

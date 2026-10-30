extends Node2D

var inimigosMortos
var buttonPressed;

var nextLevel = "res://ending_page.tscn";

var maxSwitches = 3;

func _ready():
	buttonPressed = 0;
	inimigosMortos = 0;
	$HUD2.setObjetivo("switch",maxSwitches,buttonPressed);
	$door.level = nextLevel;
	setCameraLimits();
	
func _process(delta):
	if buttonPressed >= 3:
		$door.isOpen = true;

func setCameraLimits():
	var mapSize = $Background.get_used_rect();
	var celSize = $Background.cell_quadrant_size;
	$Camera2D.limit_left = mapSize.position.x * celSize*$Background.scale.x;
	$Camera2D.limit_top = mapSize.position.y * celSize*$Background.scale.y;
	$Camera2D.limit_right = mapSize.end.x * celSize*$Background.scale.x;
	$Camera2D.limit_bottom = mapSize.end.y * celSize*$Background.scale.y;
	


func _on_inimigo_inimigo_morto():
	inimigosMortos += 1;
	

func _on_button_button_pressed():
	buttonPressed += 1
	$HUD2.atualizaObjetivo(buttonPressed);

extends Node2D

var inimigosMortos
var buttonPressed;

var nextLevel = "res://scenes/ending_page.tscn";

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
	var celSize = $Background.tile_set.tile_size;
	$Camera2D.limit_left = int(mapSize.position.x * celSize.x * $Background.scale.x);
	$Camera2D.limit_top = int(mapSize.position.y * celSize.y * $Background.scale.y);
	$Camera2D.limit_right = int(mapSize.end.x * celSize.x * $Background.scale.x);
	$Camera2D.limit_bottom = int(mapSize.end.y * celSize.y * $Background.scale.y);
	


func _on_inimigo_inimigo_morto():
	inimigosMortos += 1;
	

func _on_button_button_pressed():
	buttonPressed += 1
	$HUD2.atualizaObjetivo(buttonPressed);

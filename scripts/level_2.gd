extends Node2D

var inimigosMortos
var buttonPressed;

var nextLevel = "res://scenes/level_3.tscn";

var maxSwitches = 3;

func _ready():
	buttonPressed = 0;
	inimigosMortos = 0;
	$HUD2.setObjetivo("switch", maxSwitches, buttonPressed);
	$door.level = nextLevel;
	# Camera bounds are handled by Camera2D.gd (follows the player without showing the void).

func _process(_delta):
	if buttonPressed >= 3:
		$door.isOpen = true;

func _on_inimigo_inimigo_morto():
	inimigosMortos += 1;
	

func _on_button_button_pressed():
	buttonPressed += 1
	$HUD2.atualizaObjetivo(buttonPressed);

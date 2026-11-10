extends Node2D

var inimigosMortos;
var maxInimigo = 9;

var nextLevel = "res://scenes/level_2.tscn";

@onready var novoEnergia = preload("res://scenes/energy_font.tscn");

func _ready():
	inimigosMortos = 0;
	$HUD2.setObjetivo("Inimigo",maxInimigo,inimigosMortos);
	$door.level = nextLevel;
	setCameraLimits();
	
func _process(delta):
	if inimigosMortos >= 9:
		$door.isOpen = true;

func setCameraLimits():
	# Camera bounds are handled by Camera2D.gd (follows the player without showing the void).
	pass
	


func _on_inimigo_inimigo_morto():
	inimigosMortos += 1; 
	$HUD2.atualizaObjetivo(inimigosMortos);

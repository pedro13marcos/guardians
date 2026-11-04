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
	var mapSize = $Background.get_used_rect();
	var celSize = $Background.tile_set.tile_size;
	$Camera2D.limit_left = int(mapSize.position.x * celSize.x * $Background.scale.x);
	$Camera2D.limit_top = int(mapSize.position.y * celSize.y * $Background.scale.y);
	$Camera2D.limit_right = int(mapSize.end.x * celSize.x * $Background.scale.x);
	$Camera2D.limit_bottom = int(mapSize.end.y * celSize.y * $Background.scale.y);
	


func _on_inimigo_inimigo_morto():
	inimigosMortos += 1; 
	$HUD2.atualizaObjetivo(inimigosMortos);

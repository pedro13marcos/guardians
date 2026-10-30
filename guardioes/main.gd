extends Node2D

var inimigosMortos;

var nextLevel = "res://level_2.tscn";

@onready var novoEnergia = preload("res://energy_font.tscn");

func _ready():
	inimigosMortos = 0;
	$HUD.atualizaMorteInimigo(str(inimigosMortos)+"/9");
	$door.level = nextLevel;
	setCameraLimits();
	
func _process(delta):
	if inimigosMortos >= 9:
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
	$HUD.atualizaMorteInimigo(str(inimigosMortos)+"/9");


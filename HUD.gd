extends CanvasLayer

func _ready():
	$BoxContainer/HBoxContainer/HealthBar.global_position.x = 20
	$BoxContainer/HBoxContainer/HealthBar.global_position.y = 20;
	$BoxContainer/HBoxContainer3/EnergyBar.global_position.x = DisplayServer.window_get_size().x - 220;
	$BoxContainer/HBoxContainer3/EnergyBar.global_position.y = 20;
	$BoxContainer/HBoxContainer/HealthBar.set_tint_progress(Color(0,1,0,1));
	pass
	
func atualizaVida(vida):
	$Canvas/BoxContainer/HBoxContainer/HealthBar.value = vida;

	if vida >= 50 && vida < 100:
		var red = ((100.0 - ((vida-50.0)*2.0))/100.0);
		$Canvas/BoxContainer/HBoxContainer/HealthBar.set_tint_progress(Color(red,1,0,1));
	elif vida > 0 && vida < 50:
		var green = vida/50.0
		$Canvas/BoxContainer/HBoxContainer/HealthBar.set_tint_progress(Color(1,green,0,1))
	

func atualizaMorteInimigo(inimigosMortos):
	$Canvas/BoxContainer/HBoxContainer2/Label.text = inimigosMortos;

func atualizaEnergia(energia):
	$Canvas/BoxContainer/HBoxContainer3/EnergyBar.value = energia;

extends CanvasLayer

@export var healthBar: TextureProgressBar;
@export var goals: TextureProgressBar;
@export var energyBar: TextureProgressBar;

var topObjetivo;

func _ready():
	$HUD2.show()
	$HUD2/uiWL.show();
	$HUD2/uiG.hide();
	$HUD2/uiM.hide();
	healthBar.set_tint_progress(Color(0,1,0,1));
	pass
	
func atualizaVida(vida):
	
	healthBar.value = vida;

	if vida >= 50 && vida < 100:
		var red = ((100.0 - ((vida-50.0)*2.0))/100.0);
		healthBar.set_tint_progress(Color(red,1,0,1));
	elif vida > 0 && vida < 50:
		var green = vida/50.0
		healthBar.set_tint_progress(Color(1,green,0,1))

func setObjetivo(tipo,top,atual):
	topObjetivo = top;
	
	if (tipo == "Inimigo"):
		$HUD2/goalEn.show();
		$HUD2/goalSw.hide();
		$HUD2/goalTime.hide();
		pass;
	elif(tipo == "switch"):
		$HUD2/goalEn.hide();
		$HUD2/goalSw.show();
		$HUD2/goalTime.hide();
		pass;
	elif(tipo == "tempo"):
		$HUD2/goalEn.hide();
		$HUD2/goalSw.hide();
		$HUD2/goalTime.show();
		pass;
	atualizaObjetivo(atual);

func atualizaPersonagem(per):
	if per == "V":
		$HUD2/uiWL.show();
		$HUD2/uiG.hide();
		$HUD2/uiM.hide();
	elif per == "F":
		$HUD2/uiWL.hide();
		$HUD2/uiG.show();
		$HUD2/uiM.hide();
	elif per == "A":
		$HUD2/uiWL.hide();
		$HUD2/uiG.hide();
		$HUD2/uiM.show();
	pass;
	
func atualizaObjetivo(quantidade):
	var value: float
	value = (float(quantidade)/float(topObjetivo))*100.0;
	if value>=100:
		$HUD2/goalDone.show();
	else:
		$HUD2/goalDone.hide();
	
	$HUD2/Goals.value = int(value);
	pass;

func atualizaEnergia(energia):
	energyBar.value = energia;

extends CanvasLayer

@export var healthBar: TextureProgressBar;
@export var goals: TextureProgressBar;
@export var energyBar: TextureProgressBar;

var topObjetivo;

@onready var bubble_wl = preload("res://assets/Bars/bubble_face_wl.png")
@onready var bubble_guardian = preload("res://assets/Bars/bubble_face_guardian.png")
@onready var bubble_monkey = preload("res://assets/Bars/bubble_face_monkey.png")

func _ready():
	$HUD2.show()
	$HUD2/uiWL.show();
	$HUD2/uiG.hide();
	$HUD2/uiM.hide();
	atualizaPersonagem("V")
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
		if has_node("HUD2/NextHeroBubble1"):
			$HUD2/NextHeroBubble1.texture = bubble_guardian
		if has_node("HUD2/NextHeroBubble2"):
			$HUD2/NextHeroBubble2.texture = bubble_monkey
	elif per == "F":
		$HUD2/uiWL.hide();
		$HUD2/uiG.show();
		$HUD2/uiM.hide();
		if has_node("HUD2/NextHeroBubble1"):
			$HUD2/NextHeroBubble1.texture = bubble_monkey
		if has_node("HUD2/NextHeroBubble2"):
			$HUD2/NextHeroBubble2.texture = bubble_wl
	elif per == "A":
		$HUD2/uiWL.hide();
		$HUD2/uiG.hide();
		$HUD2/uiM.show();
		if has_node("HUD2/NextHeroBubble1"):
			$HUD2/NextHeroBubble1.texture = bubble_wl
		if has_node("HUD2/NextHeroBubble2"):
			$HUD2/NextHeroBubble2.texture = bubble_guardian
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

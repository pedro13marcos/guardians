extends Control

var isPaused = false;

func _ready():
	hide();

func _process(delta):
	
	if Input.is_action_just_released("Pause"):
		isPaused = !isPaused;
		
		if isPaused:
			get_tree().paused = true;
			show();
			$MarginContainer/VBoxContainer/Continue.grab_focus();
		else:
			get_tree().paused = false;
			hide();
	

func _on_continue_button_up():
	isPaused = false;
	get_tree().paused = false;
	hide();

func _on_quit_button_up():
	get_tree().quit();

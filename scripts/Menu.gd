extends Control

func _ready():
	$MarginContainer/VBoxContainer/play.grab_focus();
	pass;

func _process(delta):
	#if Input.is_action_just_pressed("ui_accept"):
	#	$MarginContainer/VBoxContainer/quit.grab_focus();
		
		pass

func _on_play_button_up():
	get_tree().change_scene_to_file("res://scenes/main.tscn");

func _on_quit_button_up():
	get_tree().quit();

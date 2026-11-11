extends Control

func _ready():
	$MenuSlate/MarginContainer/VBoxContainer/play.grab_focus();

func _on_play_button_up():
	get_tree().change_scene_to_file("res://scenes/main.tscn");

func _on_options_button_up():
	# Placeholder for options panel / sound settings
	pass

func _on_quit_button_up():
	get_tree().quit();

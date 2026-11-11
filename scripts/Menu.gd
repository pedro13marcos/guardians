extends Control

@onready var menu_slate: PanelContainer = $MenuSlate
@onready var options_slate: PanelContainer = $OptionsSlate
@onready var continue_btn: Button = $MenuSlate/MarginContainer/VBoxContainer/continue
@onready var play_btn: Button = $MenuSlate/MarginContainer/VBoxContainer/play
@onready var options_btn: Button = $MenuSlate/MarginContainer/VBoxContainer/options
@onready var quit_btn: Button = $MenuSlate/MarginContainer/VBoxContainer/quit
@onready var language_select: OptionButton = $OptionsSlate/MarginContainer/VBoxContainer/LanguageRow/LanguageSelect
@onready var fullscreen_check: CheckBox = $OptionsSlate/MarginContainer/VBoxContainer/FullscreenCheck
@onready var back_btn: Button = $OptionsSlate/MarginContainer/VBoxContainer/Back
@onready var options_title: Label = $OptionsSlate/MarginContainer/VBoxContainer/Title
@onready var language_label: Label = $OptionsSlate/MarginContainer/VBoxContainer/LanguageRow/LanguageLabel

func _ready() -> void:
	menu_slate.visible = true
	options_slate.visible = false
	
	if Global.check_save():
		continue_btn.show()
		continue_btn.grab_focus()
	else:
		continue_btn.hide()
		play_btn.grab_focus()

	_sync_options_state()
	_refresh_ui_text()

func _sync_options_state() -> void:
	if fullscreen_check != null:
		var current_mode = DisplayServer.window_get_mode()
		fullscreen_check.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	_populate_language_options()

func _populate_language_options() -> void:
	if language_select == null:
		return
	language_select.clear()
	var selected_idx: int = 0
	for i in range(Global.SUPPORTED_LANGUAGES.size()):
		var lang_info: Dictionary = Global.SUPPORTED_LANGUAGES[i]
		var display_text: String = ""
		if not lang_info["label_key"].is_empty():
			display_text = tr(lang_info["label_key"])
		else:
			display_text = lang_info["native_name"]
		language_select.add_item(display_text, i)
		if lang_info["id"] == Global.current_language_mode:
			selected_idx = i
	language_select.select(selected_idx)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and options_slate.visible:
		_on_back_button_up()
		get_viewport().set_input_as_handled()

func _on_continue_button_up() -> void:
	Global.load_game()

func _on_play_button_up() -> void:
	Global.save_level("res://scenes/main.tscn")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_options_button_up() -> void:
	_sync_options_state()
	menu_slate.visible = false
	options_slate.visible = true
	if language_select:
		language_select.grab_focus()

func _on_back_button_up() -> void:
	options_slate.visible = false
	menu_slate.visible = true
	if continue_btn and continue_btn.visible:
		continue_btn.grab_focus()
	else:
		play_btn.grab_focus()

func _on_quit_button_up() -> void:
	get_tree().quit()

func _on_language_select_item_selected(index: int) -> void:
	if index < 0 or index >= Global.SUPPORTED_LANGUAGES.size():
		return
	var lang_id: String = Global.SUPPORTED_LANGUAGES[index]["id"]
	Global.set_language_mode(lang_id)
	_refresh_ui_text()

func _on_fullscreen_check_toggled(button_pressed: bool) -> void:
	Global.set_fullscreen(button_pressed)

func _refresh_ui_text() -> void:
	_populate_language_options()
	if continue_btn:
		continue_btn.text = tr("menu_continue")
	if play_btn:
		play_btn.text = tr("menu_play")
	if options_btn:
		options_btn.text = tr("menu_options")
	if quit_btn:
		quit_btn.text = tr("menu_quit")
	if options_title:
		options_title.text = tr("options_title")
	if language_label:
		language_label.text = tr("menu_language")
	if fullscreen_check:
		fullscreen_check.text = tr("options_fullscreen")
	if back_btn:
		back_btn.text = tr("menu_back")

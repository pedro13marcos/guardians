extends Control

@onready var menu_slate: PanelContainer = $MenuSlate
@onready var options_slate: PanelContainer = $OptionsSlate
@onready var demo_slate: PanelContainer = $DemoSlate
@onready var saves_slate: PanelContainer = $SavesSlate

# Main Menu Buttons
@onready var play_btn: Button = $MenuSlate/MarginContainer/VBoxContainer/play
@onready var demo_btn: Button = $MenuSlate/MarginContainer/VBoxContainer/demo
@onready var saves_btn: Button = $MenuSlate/MarginContainer/VBoxContainer/saves
@onready var options_btn: Button = $MenuSlate/MarginContainer/VBoxContainer/options
@onready var quit_btn: Button = $MenuSlate/MarginContainer/VBoxContainer/quit

# Options Slate Controls
@onready var language_select: OptionButton = $OptionsSlate/MarginContainer/VBoxContainer/LanguageRow/LanguageSelect
@onready var fullscreen_check: CheckBox = $OptionsSlate/MarginContainer/VBoxContainer/FullscreenCheck
@onready var back_btn: Button = $OptionsSlate/MarginContainer/VBoxContainer/Back
@onready var options_title: Label = $OptionsSlate/MarginContainer/VBoxContainer/Title
@onready var language_label: Label = $OptionsSlate/MarginContainer/VBoxContainer/LanguageRow/LanguageLabel

# Demo Slate Controls
@onready var demo_title: Label = $DemoSlate/MarginContainer/VBoxContainer/Title
@onready var demo_subtitle: Label = $DemoSlate/MarginContainer/VBoxContainer/Subtitle
@onready var demo_lvl1_btn: Button = $DemoSlate/MarginContainer/VBoxContainer/Level1
@onready var demo_lvl2_btn: Button = $DemoSlate/MarginContainer/VBoxContainer/Level2
@onready var demo_lvl3_btn: Button = $DemoSlate/MarginContainer/VBoxContainer/Level3
@onready var demo_lvl4_btn: Button = $DemoSlate/MarginContainer/VBoxContainer/Level4
@onready var demo_saves_btn: Button = $DemoSlate/MarginContainer/VBoxContainer/HBoxContainer/OpenSaves
@onready var demo_back_btn: Button = $DemoSlate/MarginContainer/VBoxContainer/HBoxContainer/Back

# Saves Slate Controls
@onready var saves_title: Label = $SavesSlate/MarginContainer/VBoxContainer/Title
@onready var saves_back_btn: Button = $SavesSlate/MarginContainer/VBoxContainer/Back

var slot_rows: Array = []

func _ready() -> void:
	slot_rows = [
		$SavesSlate/MarginContainer/VBoxContainer/SlotContainer/Slot1,
		$SavesSlate/MarginContainer/VBoxContainer/SlotContainer/Slot2,
		$SavesSlate/MarginContainer/VBoxContainer/SlotContainer/Slot3,
		$SavesSlate/MarginContainer/VBoxContainer/SlotContainer/Slot4
	]
	
	_connect_slot_signals()
	_show_slate(menu_slate)
	
	# Play option is left unavailable as requested
	if play_btn != null:
		play_btn.disabled = true
		play_btn.focus_mode = Control.FOCUS_NONE
	
	demo_btn.grab_focus()
	
	_sync_options_state()
	_refresh_ui_text()

func _connect_slot_signals() -> void:
	for i in range(1, 5):
		var row: Node = slot_rows[i - 1]
		if row == null:
			continue
		var resume_btn: Button = row.get_node_or_null("MarginContainer/HBox/Actions/ResumeBtn")
		var new_btn: Button = row.get_node_or_null("MarginContainer/HBox/Actions/NewBtn")
		var delete_btn: Button = row.get_node_or_null("MarginContainer/HBox/Actions/DeleteBtn")
		
		if resume_btn and not resume_btn.button_up.is_connected(_on_slot_resume.bind(i)):
			resume_btn.button_up.connect(_on_slot_resume.bind(i))
		if new_btn and not new_btn.button_up.is_connected(_on_slot_new.bind(i)):
			new_btn.button_up.connect(_on_slot_new.bind(i))
		if delete_btn and not delete_btn.button_up.is_connected(_on_slot_delete.bind(i)):
			delete_btn.button_up.connect(_on_slot_delete.bind(i))

func _show_slate(target: PanelContainer) -> void:
	menu_slate.visible = (target == menu_slate)
	options_slate.visible = (target == options_slate)
	demo_slate.visible = (target == demo_slate)
	saves_slate.visible = (target == saves_slate)

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
	if event.is_action_pressed("ui_cancel"):
		if options_slate.visible or demo_slate.visible or saves_slate.visible:
			_on_back_button_up()
			get_viewport().set_input_as_handled()

func _on_demo_button_up() -> void:
	_show_slate(demo_slate)
	if demo_lvl1_btn:
		demo_lvl1_btn.grab_focus()

func _on_saves_button_up() -> void:
	_show_slate(saves_slate)
	_refresh_saves_ui()
	var first_btn: Button = _find_first_focusable_slot_btn()
	if first_btn:
		first_btn.grab_focus()
	elif saves_back_btn:
		saves_back_btn.grab_focus()

func _find_first_focusable_slot_btn() -> Button:
	for row in slot_rows:
		var resume: Button = row.get_node_or_null("MarginContainer/HBox/Actions/ResumeBtn")
		if resume and resume.visible:
			return resume
		var new_btn: Button = row.get_node_or_null("MarginContainer/HBox/Actions/NewBtn")
		if new_btn and new_btn.visible:
			return new_btn
	return null

func _on_options_button_up() -> void:
	_sync_options_state()
	_show_slate(options_slate)
	if language_select:
		language_select.grab_focus()

func _on_back_button_up() -> void:
	_show_slate(menu_slate)
	demo_btn.grab_focus()

func _on_quit_button_up() -> void:
	get_tree().quit()

# Demo Level Direct Select
func _on_demo_level_selected(level_path: String) -> void:
	Global.save_level(level_path)
	get_tree().change_scene_to_file(level_path)

func _on_level1_button_up() -> void:
	_on_demo_level_selected("res://scenes/main.tscn")

func _on_level2_button_up() -> void:
	_on_demo_level_selected("res://scenes/level_2.tscn")

func _on_level3_button_up() -> void:
	_on_demo_level_selected("res://scenes/level_3.tscn")

func _on_level4_button_up() -> void:
	_on_demo_level_selected("res://scenes/level_4.tscn")

# Save Slots Actions
func _on_slot_resume(slot_idx: int) -> void:
	Global.load_from_slot(slot_idx)

func _on_slot_new(slot_idx: int) -> void:
	Global.start_new_game_in_slot(slot_idx, "res://scenes/main.tscn")

func _on_slot_delete(slot_idx: int) -> void:
	Global.delete_slot(slot_idx)
	_refresh_saves_ui()

func _refresh_saves_ui() -> void:
	for i in range(1, 5):
		var row: Node = slot_rows[i - 1]
		if row == null:
			continue
		var data: Dictionary = Global.get_slot_data(i)
		var is_active: bool = (i == Global.current_save_slot)
		
		var title_lbl: Label = row.get_node_or_null("MarginContainer/HBox/InfoBox/HeaderRow/SlotTitle")
		var active_lbl: Label = row.get_node_or_null("MarginContainer/HBox/InfoBox/HeaderRow/ActiveBadge")
		var details_lbl: Label = row.get_node_or_null("MarginContainer/HBox/InfoBox/Details")
		var resume_btn: Button = row.get_node_or_null("MarginContainer/HBox/Actions/ResumeBtn")
		var new_btn: Button = row.get_node_or_null("MarginContainer/HBox/Actions/NewBtn")
		var delete_btn: Button = row.get_node_or_null("MarginContainer/HBox/Actions/DeleteBtn")
		
		if title_lbl:
			var title_fmt = tr("slot_title")
			title_lbl.text = title_fmt % i if title_fmt.contains("%d") else "Slot %d" % i
		if active_lbl:
			active_lbl.visible = is_active
			active_lbl.text = "[" + tr("slot_active") + "]"
		
		if data.get("exists", false):
			if details_lbl:
				var ts = str(data.get("timestamp", ""))
				var lvl_name = str(data.get("level_name", ""))
				var ver = str(data.get("version", Global.GAME_VERSION))
				if not ts.is_empty():
					details_lbl.text = "%s  |  %s  |  v%s" % [lvl_name, ts, ver]
				else:
					details_lbl.text = "%s  |  v%s" % [lvl_name, ver]
			if resume_btn:
				resume_btn.visible = true
				resume_btn.text = tr("slot_load")
			if new_btn:
				new_btn.text = tr("slot_new")
			if delete_btn:
				delete_btn.visible = true
				delete_btn.text = tr("slot_delete")
		else:
			if details_lbl:
				details_lbl.text = tr("slot_empty")
			if resume_btn:
				resume_btn.visible = false
			if new_btn:
				new_btn.text = tr("slot_new")
			if delete_btn:
				delete_btn.visible = false

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
	if play_btn:
		play_btn.text = tr("menu_play_unavailable")
	if demo_btn:
		demo_btn.text = tr("menu_demo")
	if saves_btn:
		saves_btn.text = tr("menu_saves")
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
	if demo_title:
		demo_title.text = tr("demo_title")
	if demo_subtitle:
		demo_subtitle.text = tr("demo_subtitle")
	if demo_lvl1_btn:
		demo_lvl1_btn.text = tr("demo_level_1")
	if demo_lvl2_btn:
		demo_lvl2_btn.text = tr("demo_level_2")
	if demo_lvl3_btn:
		demo_lvl3_btn.text = tr("demo_level_3")
	if demo_lvl4_btn:
		demo_lvl4_btn.text = tr("demo_level_4")
	if demo_saves_btn:
		demo_saves_btn.text = tr("demo_open_saves")
	if demo_back_btn:
		demo_back_btn.text = tr("menu_back")
	if saves_title:
		saves_title.text = tr("saves_title")
	if saves_back_btn:
		saves_back_btn.text = tr("menu_back")
	_refresh_saves_ui()

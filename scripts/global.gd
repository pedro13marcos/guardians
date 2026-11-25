extends Node

## Global singleton for Guardians game.
## Manages global game state, configuration/save persistence, translation,
## level background pre-loading, directional slide transitions, and persistent overlays.

const GAME_VERSION: String = "0.56"
const CONF_PATH: String = "user://confGame.json"
const SAVE_PATH: String = "user://saveGame.json"
const TOTAL_SAVE_SLOTS: int = 4
const SLOT_PATH_PREFIX: String = "user://save_slot_"

var current_language_mode: String = "auto"
var fullscreen: bool = false
var current_resolution_id: String = "auto"
var current_scaling_mode: String = "expand"
var current_level: String = "res://scenes/main.tscn"
var current_save_slot: int = 1
var watermark_label: Label = null

var is_transitioning: bool = false
var max_reached_sector: int = 1
var _preloaded_resources: Dictionary = {}

const SUPPORTED_LANGUAGES: Array[Dictionary] = [
	{"id": "auto",  "label_key": "lang_auto", "native_name": "Automatic"},
	{"id": "en",    "label_key": "lang_en",   "native_name": "English"},
	{"id": "es",    "label_key": "lang_es",   "native_name": "Español"},
	{"id": "pt_BR", "label_key": "lang_pt",   "native_name": "Português (BR)"}
]

const RESOLUTION_PRESETS: Array[Dictionary] = [
	{"id": "auto",        "label_key": "res_native",       "size": Vector2i.ZERO},
	{"id": "3840x2160",   "label": "3840 x 2160 (4K UHD)", "size": Vector2i(3840, 2160)},
	{"id": "2560x1440",   "label": "2560 x 1440 (1440p)",   "size": Vector2i(2560, 1440)},
	{"id": "1920x1080",   "label": "1920 x 1080 (1080p FHD)", "size": Vector2i(1920, 1080)},
	{"id": "1600x900",    "label": "1600 x 900 (900p HD+)",   "size": Vector2i(1600, 900)},
	{"id": "1366x768",    "label": "1366 x 768 (Laptop)",   "size": Vector2i(1366, 768)},
	{"id": "1280x720",    "label": "1280 x 720 (720p HD)",  "size": Vector2i(1280, 720)},
	{"id": "1920x1200",   "label": "1920 x 1200 (16:10)",   "size": Vector2i(1920, 1200)},
	{"id": "1680x1050",   "label": "1680 x 1050 (16:10)",   "size": Vector2i(1680, 1050)},
	{"id": "1280x800",    "label": "1280 x 800 (Deck)",     "size": Vector2i(1280, 800)},
	{"id": "1600x1200",   "label": "1600 x 1200 (4:3)",     "size": Vector2i(1600, 1200)},
	{"id": "1024x768",    "label": "1024 x 768 (4:3)",      "size": Vector2i(1024, 768)},
	{"id": "2560x1080",   "label": "2560 x 1080 (21:9)",    "size": Vector2i(2560, 1080)},
	{"id": "3440x1440",   "label": "3440 x 1440 (21:9)",    "size": Vector2i(3440, 1440)}
]

const SCALING_MODES: Array[Dictionary] = [
	{"id": "expand", "label_key": "scaling_expand"},
	{"id": "keep",   "label_key": "scaling_keep"}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_csv_translations("res://translation/translation.csv")
	load_config()
	_migrate_legacy_save()
	_create_watermark()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.alt_pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)):
			set_fullscreen(not fullscreen)

## Loads CSV translations at runtime and registers them with TranslationServer
func _load_csv_translations(csv_path: String) -> void:
	if not FileAccess.file_exists(csv_path):
		return
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		return

	var headers: PackedStringArray = file.get_csv_line()
	if headers.size() < 2:
		return

	var translations_by_locale: Dictionary = {}
	for i in range(1, headers.size()):
		var loc = headers[i].strip_edges()
		if not loc.is_empty():
			var tr_res = Translation.new()
			tr_res.locale = loc
			translations_by_locale[i] = tr_res

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 2:
			continue
		var key = row[0].strip_edges()
		if key.is_empty():
			continue
		for i in range(1, min(row.size(), headers.size())):
			if translations_by_locale.has(i):
				translations_by_locale[i].add_message(key, row[i])

	for idx in translations_by_locale.keys():
		var tr_res: Translation = translations_by_locale[idx]
		TranslationServer.add_translation(tr_res)
		if tr_res.locale == "pt_BR":
			var pt_alias = Translation.new()
			pt_alias.locale = "pt"
			for msg_key in tr_res.get_message_list():
				pt_alias.add_message(msg_key, tr_res.get_message(msg_key))
			TranslationServer.add_translation(pt_alias)

## Sets the language mode ("auto", "en", "es", "pt_BR") and applies it to TranslationServer
func set_language_mode(mode: String) -> void:
	current_language_mode = mode
	if mode == "auto":
		var os_loc = OS.get_locale()
		var resolved = _resolve_supported_locale(os_loc)
		TranslationServer.set_locale(resolved)
	else:
		TranslationServer.set_locale(mode)
	save_config()

func _resolve_supported_locale(raw_locale: String) -> String:
	var lower = raw_locale.to_lower()
	if lower.begins_with("es"):
		return "es"
	elif lower.begins_with("pt"):
		return "pt_BR"
	return "en"

func set_fullscreen(is_fullscreen: bool) -> void:
	fullscreen = is_fullscreen
	apply_display_settings()
	save_config()

func set_resolution_by_id(res_id: String) -> void:
	current_resolution_id = res_id
	apply_display_settings()
	save_config()

func set_scaling_mode(mode: String) -> void:
	current_scaling_mode = mode
	apply_display_settings()
	save_config()

func get_current_resolution_size() -> Vector2i:
	for preset in RESOLUTION_PRESETS:
		if preset["id"] == current_resolution_id:
			return preset["size"]
	return Vector2i.ZERO

func apply_display_settings() -> void:
	# Configure viewport scaling mode to expand so the game can fill any monitor
	var root_win: Window = get_tree().root
	if root_win:
		root_win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		if current_scaling_mode == "keep":
			root_win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		else:
			root_win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	var screen_id: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_id)
	
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var target_size = get_current_resolution_size()
		if target_size == Vector2i.ZERO:
			# Auto: 85% of screen size, maintaining 16:9 or 4:3 proportion
			var w = int(screen_size.x * 0.85)
			var h = int(screen_size.y * 0.85)
			target_size = Vector2i(w, h)
		
		# Ensure window size never overflows the active monitor boundaries
		target_size.x = mini(target_size.x, screen_size.x)
		target_size.y = mini(target_size.y, screen_size.y)
		DisplayServer.window_set_size(target_size)
		
		var screen_pos: Vector2i = DisplayServer.screen_get_position(screen_id)
		var win_pos = screen_pos + (screen_size - target_size) / 2
		DisplayServer.window_set_position(win_pos)

# -------------------------------------------------------------
# Configuration File Persistence (user://confGame.json)
# -------------------------------------------------------------

func save_config() -> void:
	var data = {
		"lang": current_language_mode,
		"fullscreen": fullscreen,
		"resolution": current_resolution_id,
		"scaling": current_scaling_mode,
		"version": GAME_VERSION
	}
	var file = FileAccess.open(CONF_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		print("Config saved successfully!")

func load_config() -> void:
	if not FileAccess.file_exists(CONF_PATH):
		set_language_mode("auto")
		apply_display_settings()
		return
	var file = FileAccess.open(CONF_PATH, FileAccess.READ)
	if file == null:
		set_language_mode("auto")
		apply_display_settings()
		return
	var json_str = file.get_as_text()
	var data = JSON.parse_string(json_str)
	if typeof(data) == TYPE_DICTIONARY:
		var saved_lang = data.get("lang", "auto")
		fullscreen = bool(data.get("fullscreen", false))
		current_resolution_id = str(data.get("resolution", "auto"))
		current_scaling_mode = str(data.get("scaling", "expand"))
		set_language_mode(saved_lang)
		apply_display_settings()
		print("Config loaded successfully!")
	else:
		set_language_mode("auto")
		apply_display_settings()

# -------------------------------------------------------------
# 4-Slot Game Save Persistence (user://save_slot_1..4.json)
# -------------------------------------------------------------

func get_slot_path(slot_idx: int) -> String:
	var clamped_slot = clampi(slot_idx, 1, TOTAL_SAVE_SLOTS)
	return "%s%d.json" % [SLOT_PATH_PREFIX, clamped_slot]

## Migrates old single saveGame.json or saveGame.txt to Slot 1 if Slot 1 does not exist yet
func _migrate_legacy_save() -> void:
	var slot1_path = get_slot_path(1)
	if not FileAccess.file_exists(slot1_path):
		var old_path = ""
		if FileAccess.file_exists(SAVE_PATH):
			old_path = SAVE_PATH
		elif FileAccess.file_exists("user://saveGame.txt"):
			old_path = "user://saveGame.txt"
		if not old_path.is_empty():
			var src = FileAccess.open(old_path, FileAccess.READ)
			if src:
				var content = src.get_as_text()
				var dst = FileAccess.open(slot1_path, FileAccess.WRITE)
				if dst:
					dst.store_string(content)
					print("Global: Migrated legacy save to Slot 1.")

func check_slot_save(slot_idx: int) -> bool:
	var path = get_slot_path(slot_idx)
	return FileAccess.file_exists(path)

func has_any_save() -> bool:
	for i in range(1, TOTAL_SAVE_SLOTS + 1):
		if check_slot_save(i):
			return true
	return false

func check_save() -> bool:
	return has_any_save()

func checkSave() -> bool:
	return has_any_save()

func get_level_display_name(level_path: String) -> String:
	if level_path.contains("main.tscn"):
		var t = tr("demo_level_1")
		return t if not t.is_empty() and t != "demo_level_1" else "SEC-01 Infiltration"
	elif level_path.contains("level_2.tscn"):
		var t = tr("demo_level_2")
		return t if not t.is_empty() and t != "demo_level_2" else "SEC-02 Generators"
	elif level_path.contains("level_3.tscn"):
		var t = tr("demo_level_3")
		return t if not t.is_empty() and t != "demo_level_3" else "SEC-03 Defense Matrix"
	elif level_path.contains("level_4.tscn"):
		var t = tr("demo_level_4")
		return t if not t.is_empty() and t != "demo_level_4" else "SEC-04 Core Lab"
	elif level_path.is_empty():
		var t = tr("slot_empty")
		return t if not t.is_empty() and t != "slot_empty" else "Empty Slot"
	return level_path.get_file().get_basename()

func get_slot_data(slot_idx: int) -> Dictionary:
	var path = get_slot_path(slot_idx)
	var empty_dict = {
		"exists": false,
		"slot": slot_idx,
		"last_level": "",
		"level_name": tr("slot_empty") if tr("slot_empty") != "slot_empty" else "Empty Slot",
		"timestamp": "",
		"version": ""
	}
	if not FileAccess.file_exists(path):
		return empty_dict
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return empty_dict
	var text = file.get_as_text()
	var json = JSON.parse_string(text)
	if typeof(json) != TYPE_DICTIONARY:
		return empty_dict
	
	var lvl_path: String = str(json.get("last_level", "res://scenes/main.tscn"))
	var lvl_name: String = get_level_display_name(lvl_path)
	return {
		"exists": true,
		"slot": slot_idx,
		"last_level": lvl_path,
		"level_name": lvl_name,
		"timestamp": str(json.get("timestamp", "")),
		"version": str(json.get("version", GAME_VERSION))
	}

func save_to_slot(slot_idx: int, level_path: String = "") -> void:
	current_save_slot = clampi(slot_idx, 1, TOTAL_SAVE_SLOTS)
	if not level_path.is_empty():
		if not level_path.contains("menu.tscn") and not level_path.contains("ending_page.tscn"):
			current_level = level_path
	
	var data = {
		"slot": current_save_slot,
		"last_level": current_level,
		"version": GAME_VERSION,
		"timestamp": Time.get_datetime_string_from_system()
	}
	var path = get_slot_path(current_save_slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		print("Global: Game saved to Slot %d! Level: %s" % [current_save_slot, current_level])

func load_from_slot(slot_idx: int) -> void:
	current_save_slot = clampi(slot_idx, 1, TOTAL_SAVE_SLOTS)
	var slot_info = get_slot_data(current_save_slot)
	if slot_info["exists"] and not slot_info["last_level"].is_empty():
		current_level = slot_info["last_level"]
	else:
		current_level = "res://scenes/main.tscn"
		save_to_slot(current_save_slot, current_level)
	
	print("Global: Game loaded from Slot %d! Resuming from: %s" % [current_save_slot, current_level])
	get_tree().change_scene_to_file(current_level)

func delete_slot(slot_idx: int) -> void:
	var path = get_slot_path(slot_idx)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("Global: Deleted Slot %d at %s" % [slot_idx, path])

func start_new_game_in_slot(slot_idx: int, level_path: String = "res://scenes/main.tscn") -> void:
	current_save_slot = clampi(slot_idx, 1, TOTAL_SAVE_SLOTS)
	current_level = level_path
	save_to_slot(current_save_slot, current_level)
	get_tree().change_scene_to_file(current_level)

func save_game(level_path: String = "") -> void:
	save_to_slot(current_save_slot, level_path)

func save_level(level_path: String) -> void:
	save_game(level_path)

func load_game() -> void:
	# If current slot has a save, load it; otherwise find first slot with a save, or slot 1
	if check_slot_save(current_save_slot):
		load_from_slot(current_save_slot)
		return
	for i in range(1, TOTAL_SAVE_SLOTS + 1):
		if check_slot_save(i):
			load_from_slot(i)
			return
	load_from_slot(1)

func reset_save() -> void:
	delete_slot(current_save_slot)

# -------------------------------------------------------------
# Level Pre-loading and Directional Slide Transition
# -------------------------------------------------------------

## Asynchronously requests background loading for the next level as soon as a door opens
func preload_level(scene_path: String) -> void:
	if scene_path == null or scene_path.is_empty():
		return
	if _preloaded_resources.has(scene_path):
		return
	if not ResourceLoader.exists(scene_path):
		return
	
	var err = ResourceLoader.load_threaded_request(scene_path)
	if err == OK:
		_preloaded_resources[scene_path] = true
		print("Global: Preloading next level in background -> ", scene_path)
	else:
		var res = load(scene_path)
		if res is PackedScene:
			_preloaded_resources[scene_path] = res

## Returns the cached / preloaded PackedScene ready for instant instantiation
func get_preloaded_scene(scene_path: String) -> PackedScene:
	if _preloaded_resources.has(scene_path):
		var stored = _preloaded_resources[scene_path]
		if stored is PackedScene:
			return stored
		var status = ResourceLoader.load_threaded_get_status(scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var res = ResourceLoader.load_threaded_get(scene_path)
			if res is PackedScene:
				return res
	if ResourceLoader.exists(scene_path):
		return load(scene_path) as PackedScene
	return null

## Transitions smoothly between scenes with a synchronized push slide.
## Both screens slide in lockstep: the old level slides out while the incoming level slides in,
## physically pushing the old level away seamlessly.
func transition_to_level(target_scene: String, motion_vec: Vector2 = Vector2.DOWN) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	save_level(target_scene)

	var vp: Viewport = get_tree().root.get_viewport()
	var vp_size: Vector2 = vp.get_visible_rect().size
	if vp_size.x <= 0 or vp_size.y <= 0:
		vp_size = Vector2(1600, 1200)

	# 1. Capture outgoing screen
	var old_tex: ImageTexture = null
	var old_img: Image = vp.get_texture().get_image()
	if old_img != null and not old_img.is_empty():
		old_tex = ImageTexture.create_from_image(old_img)

	# 2. Overlay CanvasLayer (layer 115, just below watermark at 120)
	var canvas := CanvasLayer.new()
	canvas.name = "SceneTransitionLayer"
	canvas.layer = 115
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(root_ctrl)

	var old_rect := TextureRect.new()
	if old_tex != null:
		old_rect.texture = old_tex
	old_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	old_rect.stretch_mode = TextureRect.STRETCH_SCALE
	old_rect.size = vp_size
	old_rect.position = Vector2.ZERO
	root_ctrl.add_child(old_rect)

	# 3. Create off-screen SubViewport to render the incoming scene
	var sv := SubViewport.new()
	sv.size = Vector2i(int(vp_size.x), int(vp_size.y))
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas.add_child(sv)

	var next_scene_res = get_preloaded_scene(target_scene)
	var next_level: Node = null
	if next_scene_res != null:
		next_level = next_scene_res.instantiate()

	if next_level == null:
		# Fallback if instantiation failed
		sv.queue_free()
		get_tree().change_scene_to_file(target_scene)
		canvas.queue_free()
		is_transitioning = false
		return

	sv.add_child(next_level)

	# 4. Incoming scene TextureRect (uses live SubViewport texture, enters sliding from opposite edge)
	var new_rect := TextureRect.new()
	new_rect.texture = sv.get_texture()
	new_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	new_rect.stretch_mode = TextureRect.STRETCH_SCALE
	new_rect.size = vp_size
	new_rect.position = -motion_vec * vp_size
	root_ctrl.add_child(new_rect)

	# 5. Add stylish seam divider along the joint between the two screens
	var divider := ColorRect.new()
	divider.color = Color(0.04, 0.06, 0.1, 0.95)
	var accent := ColorRect.new()
	accent.color = Color(0.2, 0.75, 1.0, 0.8)

	if abs(motion_vec.x) > abs(motion_vec.y):
		divider.size = Vector2(8.0, vp_size.y)
		accent.size = Vector2(2.0, vp_size.y)
		if motion_vec.x > 0:
			# Pushing right: new_rect is on the left, seam is on right edge of new_rect
			divider.position = Vector2(vp_size.x - 4.0, 0)
			accent.position = Vector2(4.0, 0)
		else:
			# Pushing left: new_rect is on the right, seam is on left edge of new_rect
			divider.position = Vector2(-4.0, 0)
			accent.position = Vector2(2.0, 0)
	else:
		divider.size = Vector2(vp_size.x, 8.0)
		accent.size = Vector2(vp_size.x, 2.0)
		if motion_vec.y > 0:
			# Pushing down: new_rect is above old_rect, seam is on bottom edge of new_rect
			divider.position = Vector2(0, vp_size.y - 4.0)
			accent.position = Vector2(0, 4.0)
		else:
			# Pushing up: new_rect is below old_rect, seam is on top edge of new_rect
			divider.position = Vector2(0, -4.0)
			accent.position = Vector2(0, 2.0)

	divider.add_child(accent)
	new_rect.add_child(divider)

	# 6. Wait 1 frame so SubViewport renders its initial layout/camera
	await get_tree().process_frame

	# 7. Synchronized push tween:
	#    old_rect slides OUT to motion_vec * vp_size
	#    new_rect slides IN from -motion_vec * vp_size to Vector2.ZERO
	#    Cubic in-out provides buttery acceleration and cushioning
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	var duration: float = 0.55

	var old_end_pos := motion_vec * vp_size
	tween.tween_property(old_rect, "position", old_end_pos, duration)
	tween.tween_property(new_rect, "position", Vector2.ZERO, duration)

	await tween.finished

	# 8. Reparent live incoming level from SubViewport to scene root and hand over control
	var old_scene = get_tree().current_scene
	if is_instance_valid(next_level):
		next_level.reparent(get_tree().root)
		get_tree().current_scene = next_level

	if is_instance_valid(old_scene):
		old_scene.queue_free()

	canvas.queue_free()
	is_transitioning = false
	print("Global: Level push transition completed smoothly.")

func _create_watermark() -> void:
	# Persistent canvas layer on top of all scenes
	var canvas = CanvasLayer.new()
	canvas.name = "WatermarkLayer"
	canvas.layer = 120 # Top-most layer above menus and HUD
	add_child(canvas)
	
	watermark_label = Label.new()
	watermark_label.name = "WatermarkLabel"
	watermark_label.text = "pre-alpha version " + GAME_VERSION
	
	# Add child to the CanvasLayer first so anchors calculate against viewport
	canvas.add_child(watermark_label)
	
	# Bottom wide alignment
	watermark_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	watermark_label.offset_top = -36.0
	watermark_label.offset_bottom = -8.0
	watermark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	watermark_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	
	# Clean, semi-transparent watermark styling
	watermark_label.add_theme_font_size_override("font_size", 14)
	watermark_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.65))
	watermark_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	watermark_label.add_theme_constant_override("shadow_offset_x", 1)
	watermark_label.add_theme_constant_override("shadow_offset_y", 1)
	
	watermark_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

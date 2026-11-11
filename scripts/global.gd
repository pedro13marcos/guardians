extends Node

## Global singleton for Guardians game.
## Manages global game state, translation/language options, and persistent overlays.

const GAME_VERSION: String = "0.38"
const CONF_PATH: String = "user://confGame.json"

var current_language_mode: String = "auto"
var watermark_label: Label = null

const SUPPORTED_LANGUAGES: Array[Dictionary] = [
	{"id": "auto",  "label_key": "lang_auto", "native_name": "Automatic"},
	{"id": "en",    "label_key": "lang_en",   "native_name": "English"},
	{"id": "es",    "label_key": "lang_es",   "native_name": "Español"},
	{"id": "pt_BR", "label_key": "lang_pt",   "native_name": "Português (BR)"}
]

func _ready() -> void:
	_load_csv_translations("res://translation/translation.csv")
	load_config()
	_create_watermark()

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
		# Alias for pt_BR -> pt so base language code resolves
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

func save_config() -> void:
	var data = {
		"lang": current_language_mode,
		"version": GAME_VERSION
	}
	var file = FileAccess.open(CONF_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

func load_config() -> void:
	if not FileAccess.file_exists(CONF_PATH):
		set_language_mode("auto")
		return
	var file = FileAccess.open(CONF_PATH, FileAccess.READ)
	if file == null:
		set_language_mode("auto")
		return
	var json_str = file.get_as_text()
	var data = JSON.parse_string(json_str)
	if typeof(data) == TYPE_DICTIONARY:
		var saved_lang = data.get("lang", "auto")
		set_language_mode(saved_lang)
	else:
		set_language_mode("auto")

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

extends CanvasLayer

## Facility Minimap & Tactical Radar
## Interlinks the exit of each level with the entrance of the next,
## displaying a cohesive multi-sector facility floorplan, real-time player tracking,
## active transit corridors, and door lock states.

@onready var map_panel: Control = $MapPanel

var is_expanded: bool = false
var pulse_time: float = 0.0

var current_sector: int = 1
var player_ref: Node2D = null
var door_ref: Node2D = null
var is_door_open: bool = false

# Preloaded comic font
var ui_font: Font = null

# Sector metadata mapping
var sectors = {
	1: {
		"id": 1,
		"scene": "main.tscn",
		"name_key": "minimap_sec1",
		"code": "SEC-01",
		"desc": "Infiltration Wing",
		"world_rect": Rect2(0.0, 0.0, 576.0, 544.0),
		"compact_rect": Rect2(160.0, 135.0, 85.0, 60.0),
		"expanded_rect": Rect2(300.0, 260.0, 170.0, 120.0),
		"door_pos": Vector2(304.0, 32.0), # Top exit
		"door_side": "top"
	},
	2: {
		"id": 2,
		"scene": "level_2.tscn",
		"name_key": "minimap_sec2",
		"code": "SEC-02",
		"desc": "Generator Complex",
		"world_rect": Rect2(-1050.0, -750.0, 2070.0, 1580.0),
		"compact_rect": Rect2(145.0, 28.0, 115.0, 78.0),
		"expanded_rect": Rect2(270.0, 55.0, 230.0, 155.0),
		"door_pos": Vector2(-984.0, 8.0), # West exit
		"door_side": "left"
	},
	3: {
		"id": 3,
		"scene": "level_3.tscn",
		"name_key": "minimap_sec3",
		"code": "SEC-03",
		"desc": "Defense Hub",
		"world_rect": Rect2(-650.0, -390.0, 1140.0, 850.0),
		"compact_rect": Rect2(35.0, 32.0, 75.0, 70.0),
		"expanded_rect": Rect2(50.0, 62.0, 150.0, 140.0),
		"door_pos": Vector2(-144.0, 431.0), # South exit
		"door_side": "bottom"
	},
	4: {
		"id": 4,
		"scene": "level_4.tscn",
		"name_key": "minimap_sec4",
		"code": "SEC-04",
		"desc": "Core Laboratory & Vault",
		"world_rect": Rect2(-650.0, -390.0, 1140.0, 880.0),
		"compact_rect": Rect2(30.0, 135.0, 85.0, 65.0),
		"expanded_rect": Rect2(40.0, 255.0, 170.0, 130.0),
		"door_pos": Vector2(-48.0, 456.0), # Deep South exit
		"door_side": "bottom"
	}
}

func _ready() -> void:
	layer = 8 # Above standard HUD (layer 1), below Pause (layer 25)
	
	if ResourceLoader.exists("res://assets/Fonts/comic_adventure.ttf"):
		ui_font = load("res://assets/Fonts/comic_adventure.ttf")
	
	_detect_current_sector()
	_update_panel_dimensions()
	
	if map_panel:
		map_panel.gui_input.connect(_on_map_gui_input)

func _detect_current_sector() -> void:
	var root_scene = get_tree().current_scene
	if not root_scene:
		return
		
	var path: String = root_scene.scene_file_path
	if path.ends_with("main.tscn"):
		current_sector = 1
	elif path.ends_with("level_2.tscn"):
		current_sector = 2
	elif path.ends_with("level_3.tscn"):
		current_sector = 3
	elif path.ends_with("level_4.tscn"):
		current_sector = 4
	else:
		current_sector = 1
		
	if "max_reached_sector" in Global:
		Global.max_reached_sector = maxi(Global.max_reached_sector, current_sector)
		
	# Find player
	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref and root_scene.has_node("Player"):
		player_ref = root_scene.get_node("Player") as Node2D
		
	# Find door
	door_ref = root_scene.get_node_or_null("door")

func _process(delta: float) -> void:
	pulse_time += delta
	
	# Verify player and door state
	if not is_instance_valid(player_ref) or not is_instance_valid(door_ref):
		_detect_current_sector()
		
	if is_instance_valid(door_ref) and "isOpen" in door_ref:
		is_door_open = door_ref.isOpen
	else:
		is_door_open = false
		
	if map_panel:
		map_panel.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		toggle_expanded()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		toggle_expanded()
		get_viewport().set_input_as_handled()

func toggle_expanded() -> void:
	is_expanded = !is_expanded
	_update_panel_dimensions()

func _on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_expanded()

func _update_panel_dimensions() -> void:
	if not map_panel:
		return
		
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_expanded:
		# Centered larger tactical blueprint view
		tween.tween_property(map_panel, "anchor_left", 0.5, 0.25)
		tween.parallel().tween_property(map_panel, "anchor_right", 0.5, 0.25)
		tween.parallel().tween_property(map_panel, "anchor_top", 0.5, 0.25)
		tween.parallel().tween_property(map_panel, "anchor_bottom", 0.5, 0.25)
		tween.parallel().tween_property(map_panel, "offset_left", -270.0, 0.25)
		tween.parallel().tween_property(map_panel, "offset_top", -210.0, 0.25)
		tween.parallel().tween_property(map_panel, "offset_right", 270.0, 0.25)
		tween.parallel().tween_property(map_panel, "offset_bottom", 210.0, 0.25)
	else:
		# Compact top-right HUD radar view
		tween.tween_property(map_panel, "anchor_left", 1.0, 0.25)
		tween.parallel().tween_property(map_panel, "anchor_right", 1.0, 0.25)
		tween.parallel().tween_property(map_panel, "anchor_top", 0.0, 0.25)
		tween.parallel().tween_property(map_panel, "anchor_bottom", 0.0, 0.25)
		tween.parallel().tween_property(map_panel, "offset_left", -285.0, 0.25)
		tween.parallel().tween_property(map_panel, "offset_top", 16.0, 0.25)
		tween.parallel().tween_property(map_panel, "offset_right", -15.0, 0.25)
		tween.parallel().tween_property(map_panel, "offset_bottom", 232.0, 0.25)

## Main canvas drawing for the interconnected minimap
func draw_minimap(canvas: Control) -> void:
	var size: Vector2 = canvas.size
	
	# 1. Backing panel & Sci-fi Frame
	var bg_color = Color(0.04, 0.07, 0.12, 0.92) if not is_expanded else Color(0.03, 0.05, 0.09, 0.96)
	canvas.draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)
	
	# Tech border & corner brackets
	var border_color = Color(0.18, 0.75, 0.95, 0.85)
	canvas.draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 2.0)
	
	var corner_len: float = 12.0
	# Draw bright cyan sci-fi corner highlights
	canvas.draw_line(Vector2(0, 0), Vector2(corner_len, 0), Color.WHITE, 2.0)
	canvas.draw_line(Vector2(0, 0), Vector2(0, corner_len), Color.WHITE, 2.0)
	canvas.draw_line(Vector2(size.x, 0), Vector2(size.x - corner_len, 0), Color.WHITE, 2.0)
	canvas.draw_line(Vector2(size.x, 0), Vector2(size.x, corner_len), Color.WHITE, 2.0)
	canvas.draw_line(Vector2(0, size.y), Vector2(corner_len, size.y), Color.WHITE, 2.0)
	canvas.draw_line(Vector2(0, size.y), Vector2(0, size.y - corner_len), Color.WHITE, 2.0)
	canvas.draw_line(Vector2(size.x, size.y), Vector2(size.x - corner_len, size.y), Color.WHITE, 2.0)
	canvas.draw_line(Vector2(size.x, size.y), Vector2(size.x, size.y - corner_len), Color.WHITE, 2.0)
	
	# Header Bar
	var header_title: String = tr("minimap_title")
	var sec_info = sectors.get(current_sector, sectors[1])
	var cur_name: String = tr(sec_info["name_key"])
	
	if ui_font:
		# Title text
		canvas.draw_string(ui_font, Vector2(10.0, 18.0), header_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, border_color)
		
		# Toggle hint
		var hint_str: String = tr("minimap_collapse_hint") if is_expanded else tr("minimap_expand_hint")
		var hint_x: float = size.x - 110.0 if not is_expanded else size.x - 120.0
		canvas.draw_string(ui_font, Vector2(hint_x, 18.0), hint_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, Color(0.7, 0.85, 1.0, 0.75))
		
		# Active Sector indicator banner
		var banner_text: String = cur_name.to_upper()
		canvas.draw_string(ui_font, Vector2(10.0, size.y - 8.0), banner_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.9, 0.3, 0.95))
		
		# Transit status banner
		if is_door_open:
			var open_msg: String = tr("minimap_transit_open")
			var blink: float = (sin(pulse_time * 8.0) + 1.0) * 0.5
			var open_col = Color(0.2, 1.0, 0.4).lerp(Color(0.8, 1.0, 0.9), blink)
			canvas.draw_string(ui_font, Vector2(size.x - 100.0, size.y - 8.0), open_msg, HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, open_col)
	
	# 2. Draw Interlinking Corridors (Transit Tubes)
	_draw_all_transit_corridors(canvas)
	
	# 3. Draw All 4 Sectors
	for s_id in [1, 2, 3, 4]:
		_draw_sector_room(canvas, s_id)
		
	# 4. Legend (Shown in Expanded View)
	if is_expanded:
		_draw_tactical_legend(canvas, size)

## Draws the physical rooms for each sector
func _draw_sector_room(canvas: Control, s_id: int) -> void:
	var info = sectors[s_id]
	var rect: Rect2 = info["expanded_rect"] if is_expanded else info["compact_rect"]
	var max_sec = Global.max_reached_sector if ("max_reached_sector" in Global) else current_sector
	var is_current: bool = (s_id == current_sector)
	var is_cleared: bool = (s_id < current_sector or (s_id < max_sec and not is_current))
	var is_future: bool = (s_id > current_sector and s_id >= max_sec)
	
	# Fill styling
	var fill_col: Color
	var border_col: Color
	var line_width: float = 1.5
	
	if is_current:
		fill_col = Color(0.06, 0.22, 0.36, 0.85)
		border_col = Color(0.2, 0.9, 1.0, 1.0)
		line_width = 2.0
	elif is_cleared:
		fill_col = Color(0.04, 0.18, 0.12, 0.70)
		border_col = Color(0.2, 0.8, 0.45, 0.85)
	else:
		fill_col = Color(0.03, 0.05, 0.08, 0.50)
		border_col = Color(0.25, 0.35, 0.45, 0.45)
		
	canvas.draw_rect(rect, fill_col, true)
	canvas.draw_rect(rect, border_col, false, line_width)
	
	# Subtle inner grid
	if is_current or is_expanded:
		var grid_col = Color(border_col.r, border_col.g, border_col.b, 0.15)
		var step_x = rect.size.x / 4.0
		var step_y = rect.size.y / 3.0
		for i in range(1, 4):
			canvas.draw_line(Vector2(rect.position.x + i * step_x, rect.position.y), Vector2(rect.position.x + i * step_x, rect.position.y + rect.size.y), grid_col, 1.0)
		for j in range(1, 3):
			canvas.draw_line(Vector2(rect.position.x, rect.position.y + j * step_y), Vector2(rect.position.x + rect.size.x, rect.position.y + j * step_y), grid_col, 1.0)
	
	# Sector Code & Status
	if ui_font:
		var code_str: String = info["code"]
		var text_col = Color(1, 1, 1, 0.9) if is_current else (Color(0.5, 0.9, 0.6, 0.85) if is_cleared else Color(0.45, 0.55, 0.65, 0.6))
		var f_size: int = 12 if is_expanded else 9
		canvas.draw_string(ui_font, Vector2(rect.position.x + 4.0, rect.position.y + f_size + 2.0), code_str, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, text_col)
		
		if is_cleared:
			# Checkmark ✓ for cleared
			canvas.draw_string(ui_font, Vector2(rect.position.x + rect.size.x - 14.0, rect.position.y + f_size + 2.0), "OK", HORIZONTAL_ALIGNMENT_RIGHT, -1, f_size - 1, Color(0.3, 1.0, 0.5, 0.9))
		elif is_future:
			# Locked symbol
			canvas.draw_string(ui_font, Vector2(rect.position.x + rect.size.x - 14.0, rect.position.y + f_size + 2.0), "-", HORIZONTAL_ALIGNMENT_RIGHT, -1, f_size, Color(0.4, 0.5, 0.6, 0.6))
		elif is_expanded:
			# Description in expanded view
			canvas.draw_string(ui_font, Vector2(rect.position.x + 4.0, rect.position.y + rect.size.y - 6.0), info["desc"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 0.9, 1.0, 0.75))
			
	# Draw Exit Door on active or cleared sector
	_draw_sector_door(canvas, s_id, rect)
	
	# If this is the active current sector, draw player tracker blip
	if is_current:
		_draw_player_blip(canvas, info, rect)

## Draws the exit door indicator on a sector
func _draw_sector_door(canvas: Control, s_id: int, rect: Rect2) -> void:
	var info = sectors[s_id]
	var door_pt: Vector2
	var side = info["door_side"]
	
	match side:
		"top":
			door_pt = Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y)
		"bottom":
			door_pt = Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y)
		"left":
			door_pt = Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5)
		"right":
			door_pt = Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y * 0.5)
			
	var is_current: bool = (s_id == current_sector)
	var is_open: bool = is_door_open if is_current else (s_id < current_sector)
	
	var d_col = Color(0.2, 1.0, 0.4, 1.0) if is_open else (Color(1.0, 0.3, 0.3, 0.9) if is_current else Color(0.4, 0.5, 0.6, 0.6))
	
	# Door notch / block
	var door_size: float = 6.0 if not is_expanded else 10.0
	var d_rect: Rect2
	if side in ["top", "bottom"]:
		d_rect = Rect2(door_pt.x - door_size * 0.5, door_pt.y - 2.0, door_size, 4.0)
	else:
		d_rect = Rect2(door_pt.x - 2.0, door_pt.y - door_size * 0.5, 4.0, door_size)
		
	canvas.draw_rect(d_rect, d_col, true)
	
	# If active and open, draw expanding pulsing aura
	if is_current and is_open:
		var aura_r: float = (fmod(pulse_time * 3.0, 1.0)) * 10.0 + 2.0
		var aura_alpha: float = 1.0 - (aura_r / 12.0)
		canvas.draw_circle(door_pt, aura_r, Color(0.2, 1.0, 0.4, aura_alpha * 0.5))

## Draws the animated, interlinking corridors that physically connect exits to entrances
func _draw_all_transit_corridors(canvas: Control) -> void:
	# Corridor 1 -> 2: Sector 1 TOP exit -> Sector 2 SOUTH entrance
	var r1 = sectors[1]["expanded_rect"] if is_expanded else sectors[1]["compact_rect"]
	var r2 = sectors[2]["expanded_rect"] if is_expanded else sectors[2]["compact_rect"]
	var p1_exit = Vector2(r1.position.x + r1.size.x * 0.5, r1.position.y)
	var p2_entry = Vector2(r1.position.x + r1.size.x * 0.5, r2.position.y + r2.size.y)
	_draw_transit_tube(canvas, p1_exit, p2_entry, 1, 2)
	
	# Corridor 2 -> 3: Sector 2 WEST exit -> Sector 3 EAST entrance
	var r3 = sectors[3]["expanded_rect"] if is_expanded else sectors[3]["compact_rect"]
	var p2_exit = Vector2(r2.position.x, r2.position.y + r2.size.y * 0.5)
	var p3_entry = Vector2(r3.position.x + r3.size.x, r2.position.y + r2.size.y * 0.5)
	_draw_transit_tube(canvas, p2_exit, p3_entry, 2, 3)
	
	# Corridor 3 -> 4: Sector 3 SOUTH exit -> Sector 4 NORTH entrance
	var r4 = sectors[4]["expanded_rect"] if is_expanded else sectors[4]["compact_rect"]
	var p3_exit = Vector2(r3.position.x + r3.size.x * 0.5, r3.position.y + r3.size.y)
	var p4_entry = Vector2(r3.position.x + r3.size.x * 0.5, r4.position.y)
	_draw_transit_tube(canvas, p3_exit, p4_entry, 3, 4)
	
	# Final Extraction Corridor: Sector 4 SOUTH exit -> Surface extraction
	var p4_exit = Vector2(r4.position.x + r4.size.x * 0.5, r4.position.y + r4.size.y)
	var p4_ext = Vector2(r4.position.x + r4.size.x * 0.5, r4.position.y + r4.size.y + (18.0 if not is_expanded else 28.0))
	_draw_transit_tube(canvas, p4_exit, p4_ext, 4, 5)

## Draws a single interlinking transit conduit between two sector connection points
func _draw_transit_tube(canvas: Control, start_pt: Vector2, end_pt: Vector2, from_sec: int, to_sec: int) -> void:
	var is_traversed: bool = (current_sector > from_sec)
	var is_active_conduit: bool = (current_sector == from_sec and is_door_open)
	
	var tube_col: Color
	var line_w: float = 3.0 if not is_expanded else 4.0
	
	if is_active_conduit:
		# Glowing vibrant green when transit door is open!
		tube_col = Color(0.2, 1.0, 0.5, 0.95)
	elif is_traversed:
		# Subdued cyan/green for already traversed corridors
		tube_col = Color(0.25, 0.75, 0.6, 0.7)
	else:
		# Dim dashed gray for locked upcoming sectors
		tube_col = Color(0.3, 0.4, 0.5, 0.35)
		
	# Draw dual-rail conduit lines
	var dir = (end_pt - start_pt).normalized()
	var normal = Vector2(-dir.y, dir.x) * (2.5 if not is_expanded else 4.0)
	
	canvas.draw_line(start_pt + normal, end_pt + normal, tube_col, 1.2)
	canvas.draw_line(start_pt - normal, end_pt - normal, tube_col, 1.2)
	
	# Active energy flow animation when exit door is open!
	if is_active_conduit:
		var dist = start_pt.distance_to(end_pt)
		var num_pulses = 3
		for i in range(num_pulses):
			var t = fmod((pulse_time * 1.5) + (float(i) / float(num_pulses)), 1.0)
			var energy_pos = start_pt.lerp(end_pt, t)
			canvas.draw_circle(energy_pos, 2.5, Color(1.0, 1.0, 1.0, 0.95))
			canvas.draw_circle(energy_pos, 4.5, Color(0.2, 1.0, 0.4, 0.45))
			
		# Conduit arrow indicating transit direction
		var mid = start_pt.lerp(end_pt, 0.5)
		var arrow_pt1 = mid - dir * 4.0 + normal * 0.8
		var arrow_pt2 = mid - dir * 4.0 - normal * 0.8
		canvas.draw_line(arrow_pt1, mid, Color.WHITE, 1.5)
		canvas.draw_line(arrow_pt2, mid, Color.WHITE, 1.5)

## Draws the real-time player radar blip inside the active sector
func _draw_player_blip(canvas: Control, info: Dictionary, rect: Rect2) -> void:
	if not is_instance_valid(player_ref):
		return
		
	var w_rect: Rect2 = info["world_rect"]
	var p_pos = player_ref.global_position
	
	# Clamp and normalize player position inside the world bounds of the level
	var u = clamp((p_pos.x - w_rect.position.x) / w_rect.size.x, 0.05, 0.95)
	var v = clamp((p_pos.y - w_rect.position.y) / w_rect.size.y, 0.05, 0.95)
	
	var blip_x = rect.position.x + u * rect.size.x
	var blip_y = rect.position.y + v * rect.size.y
	var blip_pt = Vector2(blip_x, blip_y)
	
	# Expanding radar sonar ping
	var ping_phase = fmod(pulse_time * 2.5, 1.0)
	var ping_radius = 3.0 + ping_phase * 9.0
	var ping_alpha = (1.0 - ping_phase) * 0.75
	canvas.draw_circle(blip_pt, ping_radius, Color(0.2, 0.9, 1.0, ping_alpha))
	
	# Solid center dot
	canvas.draw_circle(blip_pt, 3.2, Color(1.0, 1.0, 1.0, 1.0))
	canvas.draw_circle(blip_pt, 2.0, Color(0.2, 0.95, 1.0, 1.0))
	
	# Direction pointer if player has velocity or facing dir
	var facing = Vector2.DOWN
	if player_ref.has_method("getFacingDir"):
		facing = player_ref.getFacingDir()
	elif "velocity" in player_ref and player_ref.velocity.length() > 5.0:
		facing = player_ref.velocity.normalized()
		
	if facing != Vector2.ZERO:
		var arrow_head = blip_pt + facing.normalized() * 6.5
		canvas.draw_line(blip_pt, arrow_head, Color(1.0, 1.0, 0.3, 0.9), 1.8)

## Draws tactical blueprint legend in expanded mode
func _draw_tactical_legend(canvas: Control, size: Vector2) -> void:
	if not ui_font:
		return
		
	var legend_y = size.y - 30.0
	var font_sz = 10
	
	# Legend items
	var items = [
		{"symbol": "●", "col": Color(0.2, 0.9, 1.0), "text": tr("minimap_legend_you")},
		{"symbol": "■", "col": Color(1.0, 0.3, 0.3), "text": tr("minimap_legend_exit") + " (LOCKED)"},
		{"symbol": "■", "col": Color(0.2, 1.0, 0.4), "text": tr("minimap_legend_exit") + " (OPEN)"},
		{"symbol": "OK", "col": Color(0.3, 1.0, 0.5), "text": tr("minimap_cleared")}
	]
	
	var cur_x = 15.0
	for item in items:
		canvas.draw_string(ui_font, Vector2(cur_x, legend_y), item["symbol"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, item["col"])
		cur_x += 16.0
		canvas.draw_string(ui_font, Vector2(cur_x, legend_y), item["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, Color(0.8, 0.85, 0.9, 0.8))
		cur_x += 105.0

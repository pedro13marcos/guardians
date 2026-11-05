extends Camera2D

@export var player: CharacterBody2D;

func _ready() -> void:
	if player == null and has_node("../Player"):
		player = get_node("../Player") as CharacterBody2D

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		position = player.global_position

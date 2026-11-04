extends StaticBody2D

@onready var anim = $AnimatedSprite2D;
@onready var light = $PointLight2D;

# Light strength for each frame of the "default" animation, so the glow
# follows what the screen shows.
const LIGHT_ENERGY = [2.44, 1.8, 2.1];

var isBroken = false;

func _ready():
	anim.play("default");
	_syncToGlobalClock();
	anim.frame_changed.connect(_updateLight);
	_updateLight();

# Start every computer on the same frame, based on a shared clock, so all
# screens and lights in the level flicker together instead of at random.
func _syncToGlobalClock():
	var frames = anim.sprite_frames;
	var count = frames.get_frame_count("default");
	var fps = frames.get_animation_speed("default");
	var t = Time.get_ticks_msec() / 1000.0 * fps;
	anim.frame = int(t) % count;
	anim.frame_progress = t - floor(t);

func _updateLight():
	if isBroken:
		light.enabled = false;
		return;
	light.energy = LIGHT_ENERGY[anim.frame % LIGHT_ENERGY.size()];

func quebra():
	isBroken = true;
	anim.play("broke");
	_updateLight();

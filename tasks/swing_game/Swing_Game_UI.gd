extends Control
signal solved

@onready var bar: ColorRect = $MarginContainer/VBoxContainer/Bar
@onready var green_zone: ColorRect = $MarginContainer/VBoxContainer/Bar/GreenZone
@onready var marker: ColorRect = $MarginContainer/VBoxContainer/Bar/Marker
@onready var indicator: Label = $MarginContainer/VBoxContainer/Indicator

# ukuran untuk bar 280 px (layar 384x288)
var levels = [
	{"speed": 140, "zone_width": 70},
	{"speed": 187, "zone_width": 52},
	{"speed": 243, "zone_width": 38},
	{"speed": 243, "zone_width": 38},
	{"speed": 243, "zone_width": 38}
]
var current_level = 0

# animasi Lara berayun (frame sudah disejajarkan di titik gantungan ayunan)
const SWING_FRAMES: Array = [
	preload("res://assets/tasks/swing/swing_anim_0.png"),
	preload("res://assets/tasks/swing/swing_anim_1.png"),
	preload("res://assets/tasks/swing/swing_anim_2.png"),
	preload("res://assets/tasks/swing/swing_anim_3.png"),
]
const SWING_EMPTY = preload("res://assets/tasks/swing/swing_side.png")
var swing_sprite: AnimatedSprite2D
const SFX_HIT = preload("res://assets/audios/PressedRightyButton.mp3")   
var sfx: AudioStreamPlayer

var speed: float = 0.0
var direction: int = 1
var running: bool = false


func _ready() -> void:
	indicator.text = str(current_level) + '/'+ str(len(levels))
	set_process(false)
	_make_swing_sprite()
	sfx = AudioStreamPlayer.new()
	sfx.stream = SFX_HIT
	add_child(sfx)
	start()

func _make_swing_sprite() -> void:
	var frames = SpriteFrames.new()
	frames.set_animation_speed("default", 4.0)
	# gambar Lara berayun hanya ada versi kecil; fase lain hanya rangka ayunan
	if GameManager.current_phase == "Kid":
		for tex in SWING_FRAMES:
			frames.add_frame("default", tex)
	else:
		frames.add_frame("default", SWING_EMPTY)
	swing_sprite = AnimatedSprite2D.new()
	swing_sprite.sprite_frames = frames
	swing_sprite.position = Vector2(192, 128)
	swing_sprite.scale = Vector2(1.5, 1.5)
	add_child(swing_sprite)


func start() -> void:
	current_level = 1
	indicator.text = "0/" + str(len(levels))
	start_level()
	running = true
	set_process(true)


func stop() -> void:
	running = false
	set_process(false)
	if swing_sprite:
		swing_sprite.stop()


func start_level() -> void:
	if swing_sprite:
		swing_sprite.speed_scale = 0.6 + 0.35 * current_level   # makin tinggi level, makin kencang
		swing_sprite.play("default")
	var data = levels[current_level-1]
	speed = data["speed"]
	green_zone.size.x = data["zone_width"]
	green_zone.position.x = randf_range(0.0, bar.size.x - green_zone.size.x)
	marker.position.x = 0.0
	direction = 1


func _process(delta: float) -> void:
	marker.position.x += speed * direction * delta
	var max_x = bar.size.x - marker.size.x
	if marker.position.x >= max_x:
		marker.position.x = max_x
		direction = -1
	elif marker.position.x <= 0.0:
		marker.position.x = 0.0
		direction = 1


func _input(event: InputEvent) -> void:
	if not running: return
	if event.is_action_pressed("ui_accept"):
		check_hit()


func check_hit() -> void:
	var marker_center = marker.position.x + marker.size.x / 2.0
	var zone_left = green_zone.position.x
	var zone_right = green_zone.position.x + green_zone.size.x

	if marker_center >= zone_left and marker_center <= zone_right:
		_play_hit()
		current_level += 1
		if current_level > levels.size():

			sfx.reparent(get_tree().current_scene)
			sfx.finished.connect(sfx.queue_free, CONNECT_ONE_SHOT)
			stop()
			solved.emit()
			return
	else:
		current_level = 1  
	indicator.text = str(current_level - 1) + '/' + str(len(levels))
	start_level()


func _play_hit() -> void:
	if not is_instance_valid(sfx) or sfx.get_parent() != self:
		sfx = AudioStreamPlayer.new()
		sfx.stream = SFX_HIT
		add_child(sfx)
	sfx.play()

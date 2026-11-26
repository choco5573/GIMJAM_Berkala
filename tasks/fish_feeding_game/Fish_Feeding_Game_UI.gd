extends Control
signal solved

@export var shakes_needed: int = 5        # berapa kali goyang
@export var min_move: float = 16.0        # gerakan mouse minimal agar dihitung goyang
@export var fish_margin: float = 25.0     # jarak ikan dari tepi akuarium
@export var fish1_speed: float = 35.0
@export var fish2_speed: float = 50.0

@onready var aquarium: TextureRect = $Aquarium
@onready var fish1: AnimatedSprite2D = $Aquarium/Fishes/Fish1
@onready var fish2: AnimatedSprite2D = $Aquarium/Fishes/Fish2
@onready var food_drop: CPUParticles2D = $Aquarium/FoodDrop
@onready var food_can: TextureRect = $FoodCan

var fishes: Array = []
var speeds: Array = []
var dirs: Array = [1, -1]

var food_falling: bool = false
var running: bool = false
var shake_count: int = 0
var last_dir: int = 0
var anchor_x: float = 0.0


func _ready() -> void:
	food_drop.finished.connect(_on_food_finished)
	fishes = [fish1, fish2]
	speeds = [fish1_speed, fish2_speed]
	food_can.visible = false
	_setup_food_particles()
	set_process(false)


func start() -> void:
	food_falling = false
	shake_count = 0
	last_dir = 0
	anchor_x = get_global_mouse_position().x

	for fish in fishes:
		fish.position.x = randf_range(fish_margin, aquarium.size.x - fish_margin)
		fish.play()

	food_can.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	running = true
	set_process(true)


func stop() -> void:
	running = false
	set_process(false)
	food_can.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if not running: return

	var mouse_pos = get_global_mouse_position()
	food_can.global_position = mouse_pos - food_can.size / 2.0

	_move_fish(delta)
	_check_shake(mouse_pos)

func _move_fish(delta: float) -> void:
	var min_x = fish_margin
	var max_x = aquarium.size.x - fish_margin

	for i in fishes.size():
		var fish = fishes[i]
		fish.position.x += speeds[i] * dirs[i] * delta

		if fish.position.x >= max_x:
			dirs[i] = -1
		elif fish.position.x <= min_x:
			dirs[i] = 1

		fish.flip_h = dirs[i] > 0   # gambar ikan aslinya menghadap kiri


func _check_shake(mouse_pos: Vector2) -> void:
	if food_falling:
		anchor_x = mouse_pos.x
		last_dir = 0
		return

	var diff = mouse_pos.x - anchor_x
	if abs(diff) < min_move: return

	var new_dir = 1 if diff > 0 else -1

	if last_dir != 0 and new_dir != last_dir:
		shake_count += 1
		_drop_food()

	last_dir = new_dir
	anchor_x = mouse_pos.x


func _drop_food() -> void:
	food_drop.global_position = food_can.global_position + Vector2(food_can.size.x / 2.0, food_can.size.y)
	food_drop.restart()
	food_falling = true


func _setup_food_particles() -> void:
	food_drop.emitting = false
	food_drop.one_shot = true
	food_drop.amount = 15
	food_drop.lifetime = 1.0
	food_drop.explosiveness = 0.8        
	food_drop.local_coords = false      

	# keluar dari garis, bukan satu titik
	food_drop.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	food_drop.emission_rect_extents = Vector2(10, 1)

	# arah ke bawah, tapi menyebar
	food_drop.direction = Vector2(0, 1)
	food_drop.spread = 30.0
	food_drop.initial_velocity_min = 10.0
	food_drop.initial_velocity_max = 30.0
	food_drop.gravity = Vector2(0, 120)

	# ukuran bervariasi
	# butiran pakan kira-kira 3-6 px, berapa pun ukuran texture-nya
	var tex_w: float = 8.0
	if food_drop.texture:
		tex_w = max(float(food_drop.texture.get_width()), 1.0)
	food_drop.scale_amount_min = 3.0 / tex_w
	food_drop.scale_amount_max = 6.0 / tex_w


func _on_food_finished() -> void:
	food_falling = false

	if shake_count >= shakes_needed:
		stop()
		solved.emit()

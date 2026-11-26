extends Control
signal solved
signal failed   # tidak dipakai, ada supaya skrip Node2D yang menyambung 'failed' tidak error

@export var duration: float = 30.0            # detik sampai penuh kalau tidak pernah tabrak
@export var scroll_speed: float = 160.0       # kecepatan jalan turun
@export var player_speed: float = 180.0       # kecepatan geser mobil pemain
@export var spawn_min: float = 0.8            # jeda terpendek antar mobil lain
@export var spawn_max: float = 1.6            # jeda terpanjang antar mobil lain
@export var hit_penalty: float = 0.05         # progres yang hilang saat tabrakan (0.05 = 5%)
@export var knockback_distance: float = 30.0  # mobil terdorong mundur sejauh ini
@export var recover_speed: float = 40.0       # kecepatan mobil maju lagi
@export var invulnerable_time: float = 1.0    # kebal sebentar setelah tabrakan
@export var bottom_margin: float = 100.0      # jarak mobil pemain dari bawah
@export var hitbox_shrink: float = 4.0        # kotak tabrakan dikecilkan supaya adil
@export var obstacle_size: Vector2 = Vector2(20, 28)
@export var obstacle_textures: Array[Texture2D] = []   # kosong = kotak warna untuk tes

@onready var road_area: Control = $ColorRect/RoadArea
@onready var road1: TextureRect = $ColorRect/RoadArea/Road1
@onready var road2: TextureRect = $ColorRect/RoadArea/Road2
@onready var obstacles: Control = $ColorRect/RoadArea/Obstacles
@onready var player_car: TextureRect = $ColorRect/RoadArea/PlayerCar
@onready var progress_bar: ProgressBar = $ColorRect/RoadArea/ProgressBar
const SFX_CRASH = preload("res://assets/audios/WalkingAtWall_OffTheMap.mp3")  
var sfx: AudioStreamPlayer

var running: bool = false
var progress: float = 0.0
var spawn_left: float = 0.0
var invuln_left: float = 0.0
var knockback: float = 0.0
var start_position: Vector2


func _ready() -> void:
	start_position = player_car.position
	set_process(false)
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.step = 0.001
	progress_bar.show_percentage = false
	progress_bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	sfx = AudioStreamPlayer.new()
	sfx.stream = SFX_CRASH
	add_child(sfx)

func start() -> void:
	for obs in obstacles.get_children():
		obstacles.remove_child(obs)
		obs.queue_free()

	var area_size = road_area.size
	for road in [road1, road2]:
		road.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		road.stretch_mode = TextureRect.STRETCH_SCALE
		road.size = area_size
	road1.position = Vector2(0, 0)
	road2.position = Vector2(0, -area_size.y)

	player_car.position = start_position
	player_car.modulate.a = 1.0

	progress = 0.0
	knockback = 0.0
	invuln_left = 0.0
	spawn_left = 1.0
	progress_bar.value = 0.0

	running = true
	set_process(true)


func stop() -> void:
	running = false
	set_process(false)


func _process(delta: float) -> void:
	if not running: return

	_scroll_road(delta)
	_move_player(delta)
	_update_obstacles(delta)
	_spawn_obstacle(delta)
	_check_hit()
	_update_progress(delta)


func _scroll_road(delta: float) -> void:
	var h = road_area.size.y
	for road in [road1, road2]:
		road.position.y += scroll_speed * delta
		
		if road.position.y >= h:
			road.position.y -= h * 2.0


func _move_player(delta: float) -> void:
	var axis = Input.get_axis("ui_left", "ui_right")
	var x = player_car.position.x + axis * player_speed * delta
	player_car.position.x = clampf(x, 0.0, road_area.size.x - player_car.size.x)

	knockback = move_toward(knockback, 0.0, recover_speed * delta)
	player_car.position.y = start_position.y + knockback
	
	if invuln_left > 0.0:
		invuln_left -= delta
		var blink = int(invuln_left * 10.0) % 2 == 0
		player_car.modulate.a = 0.4 if blink else 1.0
	else:
		player_car.modulate.a = 1.0


func _spawn_obstacle(delta: float) -> void:
	spawn_left -= delta
	if spawn_left > 0.0: return
	spawn_left = randf_range(spawn_min, spawn_max)

	var obs: Control
	if obstacle_textures.is_empty():
		var box = ColorRect.new()
		box.color = Color.from_hsv(randf(), 0.6, 0.9)
		obs = box
	else:
		var pic = TextureRect.new()
		pic.texture = obstacle_textures.pick_random()
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		obs = pic

	obs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obs.size = obstacle_size
	obs.position = Vector2(randf_range(0.0, road_area.size.x - obstacle_size.x), -obstacle_size.y)
	obs.set_meta("speed", scroll_speed * randf_range(1.0, 1.4))
	obstacles.add_child(obs)


func _update_obstacles(delta: float) -> void:
	for obs in obstacles.get_children():
		obs.position.y += obs.get_meta("speed") * delta
		if obs.position.y > road_area.size.y:
			obs.queue_free()


func _check_hit() -> void:
	if invuln_left > 0.0: return

	var car_rect = player_car.get_global_rect().grow(-hitbox_shrink)
	for obs in obstacles.get_children():
		var obs_rect = obs.get_global_rect().grow(-hitbox_shrink)
		if car_rect.intersects(obs_rect):
			sfx.play()
			progress = maxf(progress - hit_penalty, 0.0)
			knockback = knockback_distance
			invuln_left = invulnerable_time
			return


func _update_progress(delta: float) -> void:
	progress += delta / duration
	progress_bar.value = progress

	if progress >= 1.0:
		stop()
		solved.emit()

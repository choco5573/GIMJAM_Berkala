extends Control
signal solved

@export var clean_radius: float = 26.0
@export var clean_speed: float = 1.5

@onready var dirts: Control = $Floor/Dirts
@onready var broom_head: TextureButton = $BroomHead
@onready var click_hint: AnimatedSprite2D = $ClickHint
const SFX_CLICK = preload("res://assets/audios/Nyapu.mp3")   

var sfx: AudioStreamPlayer
var dirt_health: Dictionary = {}
var remaining: int = 0
var running: bool = false


func _ready() -> void:
	set_process(false)
	broom_head.visible = false
	click_hint.visible = false
	_make_title()
	
	sfx = AudioStreamPlayer.new()
	sfx.stream = SFX_CLICK
	add_child(sfx)


# judul kecil di atas: "Sapu" atau "Pel"
var title_label: Label
var mode: String = "nyapu"

func _make_title() -> void:
	title_label = Label.new()
	title_label.text = "Sapu lantainya! (tahan klik kiri)"
	title_label.position = Vector2(8, 4)
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_constant_override("outline_size", 4)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_label)


# dipanggil task wrapper: "nyapu" atau "ngepel"
func set_mode(task_name: String) -> void:
	mode = task_name
	if task_name == "ngepel":
		title_label.text = "Pel lantainya! (tahan klik kiri)"
		broom_head.modulate = Color(0.7, 0.85, 1.0)
	else:
		title_label.text = "Sapu lantainya! (tahan klik kiri)"
		broom_head.modulate = Color.WHITE


func start() -> void:
	dirt_health.clear()
	for dirt in dirts.get_children():
		dirt_health[dirt] = 1.0
		dirt.visible = true
		dirt.modulate.a = 1.0
	remaining = dirt_health.size()

	broom_head.visible = true
	_move_broom()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

	running = true
	set_process(true)


func stop() -> void:
	running = false
	set_process(false)
	broom_head.visible = false
	click_hint.visible = false
	click_hint.stop()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _move_broom() -> void:
	broom_head.global_position = get_global_mouse_position() - broom_head.size / 2.0


func _process(delta: float) -> void:
	if not running: return

	var mouse_pos = get_global_mouse_position()
	_move_broom()
	_update_hint(mouse_pos)

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return

	for dirt in dirt_health.keys():
		if dirt_health[dirt] <= 0.0: continue

		var dirt_center = dirt.global_position + dirt.size / 2.0
		if mouse_pos.distance_to(dirt_center) > clean_radius: continue

		dirt_health[dirt] -= clean_speed * delta
		dirt.modulate.a = max(dirt_health[dirt], 0.0)

		if dirt_health[dirt] <= 0.0:
			dirt.visible = false
			remaining -= 1
			if remaining <= 0:
				stop()
				solved.emit()
				return

func _input(event: InputEvent) -> void:
	if not running: return
	var mb := event as InputEventMouseButton
	if mb == null: return
	if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		sfx.play()

func _is_over_dirt(mouse_pos: Vector2) -> bool:
	for dirt in dirt_health.keys():
		if dirt_health[dirt] <= 0.0: continue
		var dirt_center = dirt.global_position + dirt.size / 2.0
		if mouse_pos.distance_to(dirt_center) <= clean_radius:
			return true
	return false


func _update_hint(mouse_pos: Vector2) -> void:
	var hovering = _is_over_dirt(mouse_pos)
	if hovering and not click_hint.visible:
		click_hint.visible = true
		click_hint.play()
	elif not hovering and click_hint.visible:
		click_hint.visible = false
		click_hint.stop()

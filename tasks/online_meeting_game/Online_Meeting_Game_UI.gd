extends Control
signal solved
signal failed

# Rapat online (QTE):
#   Huruf muncul satu per satu. Tekan huruf itu sebelum lingkarannya habis.
#   Berhasil minimal `needed_success` dari `keys_per_meeting` = rapat selesai.
#   Kurang dari itu = gagal, popup tertutup, coba lagi dengan E.

const QTE = preload("res://tasks/online_meeting_game/qte.tscn")
const BG_MEETING = preload("res://assets/tasks/assignment/utbk.png")   # layar video call
const SFX_SUCCESS = preload("res://assets/audios/Kantor dan Meeting Key yang benar.mp3")  
const SFX_FAIL = preload("res://assets/audios/PressedTheWrongKey.mp3")         

@export var keys_per_meeting: int = 8
@export var needed_success: int = 6
@export var key_duration: float = 1.4
@export var gap_time: float = 0.5

var keyList = [
	{"keyString": "Q", "keyCode": KEY_Q},
	{"keyString": "L", "keyCode": KEY_L},
	{"keyString": "C", "keyCode": KEY_C},
	{"keyString": "H", "keyCode": KEY_H},
	{"keyString": "T", "keyCode": KEY_T},
	{"keyString": "M", "keyCode": KEY_M},
	{"keyString": "I", "keyCode": KEY_I},
	{"keyString": "P", "keyCode": KEY_P},
]

@onready var scene_rect: ColorRect = $QTEScene
@onready var timer: Timer = $QTEScene/Timer

var running: bool = false
var count: int = 0
var success: int = 0
var gap_left: float = 0.0
var current_qte: Node = null
var title_label: Label
var score_label: Label
var sfx: AudioStreamPlayer


func _ready() -> void:
	set_process(false)
	timer.autostart = false
	timer.stop()

	# QTE contoh di scene tidak dipakai; QTE dibuat lewat kode
	for child in scene_rect.get_children():
		if not (child is Timer):
			child.queue_free()

	scene_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene_rect.position = Vector2.ZERO
	scene_rect.size = Vector2(384, 288)
	scene_rect.color = Color(0, 0, 0, 0)

	var bg = TextureRect.new()
	bg.texture = BG_MEETING
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	title_label = _make_label(Vector2(8, 6), 16)
	title_label.text = "Rapat online - tekan huruf yang muncul!"
	score_label = _make_label(Vector2(8, 264), 14)
	sfx = AudioStreamPlayer.new()
	add_child(sfx)

func _make_label(pos: Vector2, font_size: int) -> Label:
	var label = Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func start() -> void:
	count = 0
	success = 0
	gap_left = 0.8
	running = true
	_update_score()
	set_process(true)


func stop() -> void:
	running = false
	set_process(false)
	if is_instance_valid(current_qte):
		current_qte.queue_free()
	current_qte = null


func _process(delta: float) -> void:
	if not running: return
	if is_instance_valid(current_qte): return

	gap_left -= delta
	if gap_left > 0.0: return

	if count >= keys_per_meeting:
		_finish()
	else:
		_spawn_key()


func _spawn_key() -> void:
	var key = keyList.pick_random()
	var node = QTE.instantiate()
	node.keyString = key["keyString"]
	node.keyCode = key["keyCode"]
	node.eventDuration = key_duration
	node.position = Vector2(randf_range(160, 305), randf_range(70, 205))   # di panel kanan layar
	node.finished.connect(_on_key_finished)
	add_child(node)
	current_qte = node


func _on_key_finished(is_success: bool) -> void:
	if not running: return
	count += 1
	if is_success:
		success += 1
		sfx.stream = SFX_SUCCESS
	else:
		sfx.stream = SFX_FAIL
	sfx.play()
	current_qte = null
	gap_left = gap_time
	_update_score()


func _update_score() -> void:
	score_label.text = "Berhasil: %d / %d   (perlu %d)" % [success, keys_per_meeting, needed_success]


func _finish() -> void:
	if success >= needed_success:
		sfx.reparent(get_tree().current_scene)
		sfx.finished.connect(sfx.queue_free, CONNECT_ONE_SHOT)
		stop()
		solved.emit()
	else:
		stop()
		failed.emit()


func _on_timer_timeout() -> void:
	pass

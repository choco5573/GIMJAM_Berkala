extends Node
# StoryDirector (autoload)
# Mengatur urutan cerita tiap hari: cutscene -> task -> cutscene -> ...
#
# Cara kerja:
#   1. Setiap stage memanggil StoryDirector.enter_room(self, current_room) di _ready().
#   2. Director mencari langkah (step) pertama hari ini yang belum selesai.
#   3. Kalau langkah itu ada di ruangan ini: putar cutscene / munculkan task.
#      Kalau di ruangan lain: tampilkan petunjuk "Pergi ke ..." di HUD.
#   4. Kalau semua langkah selesai: pemain menulis diary di kamar untuk ganti hari.
#
# Mau ubah urutan cerita? Cukup edit STEPS di bawah.
# Mau pindah posisi task? Geser Marker2D di node "Tasks" pada stage (lihat MARK_DEFAULTS).

signal hint_changed(text: String)

const SpawnLocation = preload("res://scripts/Spawn_Location.gd")

# ---------------------------------------------------------------
# task -> scene minigame
# path saja (bukan preload) supaya satu minigame yang error tidak mematikan seluruh cerita
const TASK_SCENES: Dictionary = {
	"karpet_puzzle": "res://tasks/carpet_car_game/Carpet_Car_Game_Task.tscn",
	"sembunyi": "res://tasks/hide_and_seek/Hide_And_Seek_Game_Task.tscn",
	"main_ayunan": "res://tasks/swing_game/Swing_Game_Task.tscn",
	"kasih_makan_ikan": "res://tasks/fish_feeding_game/Fish_Feeding_Game_Task.tscn",
	"floor_is_lava": "res://tasks/floor_is_lava_game/Floor_is_Lava_Game_Task.tscn",
	"tugas": "res://tasks/assignment_game/Assignment_Game_Task.tscn",
	"belajar_tutor_online": "res://tasks/assignment_game/Assignment_Game_Task.tscn",
	"utbk": "res://tasks/assignment_game/Assignment_Game_Task.tscn",
	"nyapu": "res://tasks/cleaning_game/Cleaning_Game_Task.tscn",
	"ngepel": "res://tasks/cleaning_game/Cleaning_Game_Task.tscn",
	"jemur_baju": "res://tasks/jemur_game/Jemur_Game_Task.tscn",
	"rapat_online": "res://tasks/online_meeting_game/Online_Meeting_Game_Task.tscn",
	"tugas_kantor": "res://tasks/office_work_game/Office_Work_Game_Task.tscn",
	"lembur": "res://tasks/office_work_game/Office_Work_Game_Task.tscn",
}

# petunjuk di HUD saat task sedang aktif
const TASK_HINTS: Dictionary = {
	"karpet_puzzle": "Main mobil-mobilan di karpet",
	"sembunyi": "Cari Mama di halaman! Periksa tanda ? (E)",
	"main_ayunan": "Main ayunan",
	"kasih_makan_ikan": "Kasih makan ikan",
	"floor_is_lava": "Lantainya lava!",
	"tugas": "Kerjakan PR di meja",
	"belajar_tutor_online": "Drill soal tutor online",
	"utbk": "Kerjakan UTBK",
	"nyapu": "Menyapu",
	"ngepel": "Membersihkan lantai",
	"jemur_baju": "Menjemur baju",
	"rapat_online": "Ikut rapat online",
	"tugas_kantor": "Kerjakan tugas kantor",
	"lembur": "Lembur",
}

const ROOM_NAMES: Dictionary = {
	"Bedroom": "Kamar",
	"Livingroom": "Ruang Tamu",
	"Park": "Halaman",
}

const PHASE_TITLES: Dictionary = {
	"Kid": "Masa Kecil",
	"Teen": "Masa Remaja",
	"Adult": "Masa Dewasa",
}

# Posisi cadangan task kalau Marker2D dengan nama itu tidak ada di node "Tasks".
# Lebih enak: tambahkan Marker2D dengan nama yang sama di stage, lalu geser di editor.
const MARK_DEFAULTS: Dictionary = {
	"Bedroom": {
		"CarpetCarMark": Vector2(147, 151),
		"DeskMark": Vector2(215, 172),
	},
	"Livingroom": {
		"LavaMark": Vector2(235, 172),
		"FloorMark": Vector2(160, 215),
	},
	"Park": {
		"HideAndSeekMark": Vector2(362, 73),
		"SwingMark": Vector2(257, 118),
		"PondMark": Vector2(96, 165),
		"ClothesMark": Vector2(345, 165),
		"SweepMark": Vector2(200, 185),
	},
}

# ---------------------------------------------------------------
# URUTAN CERITA
#   {"cutscene": id, "room": ...}               -> putar cutscene saat pemain ada di room itu
#        opsi: "goto": room       -> setelah cutscene pindah ke room lain
#              "end_day": true    -> setelah cutscene langsung ganti hari / fase
#              "end_game": true   -> setelah cutscene tampilkan ending
#   {"task": nama, "room": ..., "mark": nama Marker2D}
const STEPS: Dictionary = {
	"Kid": {
		1: [
			{"cutscene": "Kid_Day1_1", "room": "Bedroom"},
			{"cutscene": "Kid_Day1_2", "room": "Livingroom", "goto": "Bedroom"},
			{"task": "karpet_puzzle", "room": "Bedroom", "mark": "CarpetCarMark"},
			{"cutscene": "Kid_Day1_3", "room": "Bedroom"},
			# petak umpet (Kid_Day1_4, sembunyi, Kid_Day1_5) dihapus: setelah make up langsung tulis diary
		],
		2: [
			{"cutscene": "Kid_Day2_1", "room": "Park"},
			{"task": "main_ayunan", "room": "Park", "mark": "SwingMark"},
			{"cutscene": "Kid_Day2_2", "room": "Park"},
			{"task": "kasih_makan_ikan", "room": "Park", "mark": "PondMark"},
			{"cutscene": "Kid_Day2_3", "room": "Park"},
		],
		3: [
			{"cutscene": "Kid_Day3_1", "room": "Livingroom"},
			{"task": "floor_is_lava", "room": "Livingroom", "mark": "LavaMark"},
			{"cutscene": "Kid_Day3_2", "room": "Livingroom"},
		],
		4: [
			{"cutscene": "Kid_Day4", "room": "Park", "end_day": true},
		],
	},
	"Teen": {
		1: [
			{"cutscene": "Teen_Day1_1", "room": "Bedroom"},
			{"task": "tugas", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Teen_Day1_2", "room": "Bedroom"},
			{"task": "nyapu", "room": "Park", "mark": "SweepMark"},
			{"cutscene": "Teen_Day1_3", "room": "Park"},
		],
		2: [
			{"cutscene": "Teen_Day2_1", "room": "Bedroom"},
			{"task": "jemur_baju", "room": "Park", "mark": "ClothesMark"},
			{"cutscene": "Teen_Day2_2", "room": "Park"},
			{"task": "tugas", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Teen_Day2_3", "room": "Bedroom"},
		],
		3: [
			{"cutscene": "Teen_Day3_1", "room": "Bedroom"},
			{"task": "tugas", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Teen_Day3_2", "room": "Bedroom"},
			{"task": "main_ayunan", "room": "Park", "mark": "SwingMark"},
			{"cutscene": "Teen_Day3_3", "room": "Park"},
		],
		4: [
			{"cutscene": "Teen_Day4_1", "room": "Bedroom"},
			{"task": "tugas", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Teen_Day4_2", "room": "Bedroom"},
			{"task": "belajar_tutor_online", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Teen_Day4_3", "room": "Bedroom"},
		],
		5: [
			{"cutscene": "Teen_Day5_1", "room": "Bedroom"},
			{"task": "utbk", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Teen_Day5_2", "room": "Bedroom", "end_day": true},
		],
	},
	"Adult": {
		1: [
			{"cutscene": "Adult_Day1_1", "room": "Bedroom"},
			{"task": "rapat_online", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Adult_Day1_2", "room": "Bedroom"},
			{"cutscene": "Adult_Day1_3", "room": "Livingroom"},
			{"task": "ngepel", "room": "Livingroom", "mark": "FloorMark"},
			{"cutscene": "Adult_Day1_4", "room": "Livingroom"},
		],
		2: [
			{"cutscene": "Adult_Day2_1", "room": "Bedroom"},
			{"task": "tugas_kantor", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Adult_Day2_2", "room": "Bedroom"},
			{"task": "lembur", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Adult_Day2_3", "room": "Bedroom"},
		],
		3: [
			{"cutscene": "Adult_Day3_1", "room": "Bedroom"},
			{"task": "rapat_online", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Adult_Day3_2", "room": "Bedroom"},
			{"cutscene": "Adult_Day3_3", "room": "Livingroom"},
			{"task": "jemur_baju", "room": "Park", "mark": "ClothesMark"},
			{"cutscene": "Adult_Day3_4", "room": "Park"},
		],
		4: [
			{"cutscene": "Adult_Day4_1", "room": "Livingroom"},
			{"task": "tugas_kantor", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Adult_Day4_2", "room": "Bedroom"},
			{"task": "nyapu", "room": "Livingroom", "mark": "FloorMark"},
			{"cutscene": "Adult_Day4_3", "room": "Livingroom"},
			{"cutscene": "Adult_Day4_4", "room": "Bedroom"},
		],
		5: [
			{"cutscene": "Adult_Day5_1", "room": "Bedroom"},
			{"task": "rapat_online", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Adult_Day5_2", "room": "Bedroom"},
			{"task": "nyapu", "room": "Livingroom", "mark": "FloorMark"},
			{"cutscene": "Adult_Day5_3", "room": "Livingroom"},
			{"task": "jemur_baju", "room": "Park", "mark": "ClothesMark"},
			{"cutscene": "Adult_Day5_4", "room": "Park"},
		],
		6: [
			{"cutscene": "Adult_Day6_1", "room": "Bedroom"},
			{"task": "tugas_kantor", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Adult_Day6_2", "room": "Bedroom"},
			{"task": "lembur", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Adult_Day6_3", "room": "Livingroom"},
			{"task": "nyapu", "room": "Livingroom", "mark": "FloorMark"},
			{"task": "kasih_makan_ikan", "room": "Park", "mark": "PondMark"},
			{"cutscene": "Adult_Day6_4", "room": "Park"},
			{"cutscene": "Adult_Day6_5", "room": "Bedroom"},
		],
		7: [
			{"cutscene": "Adult_Day7_1", "room": "Bedroom"},
			{"task": "rapat_online", "room": "Bedroom", "mark": "DeskMark"},
			{"cutscene": "Adult_Day7_2", "room": "Bedroom"},
			{"task": "jemur_baju", "room": "Park", "mark": "ClothesMark"},
			{"cutscene": "Adult_Day7_3", "room": "Livingroom"},
			{"task": "ngepel", "room": "Livingroom", "mark": "FloorMark"},
			{"cutscene": "Adult_Day7_4", "room": "Livingroom"},
			{"cutscene": "Adult_Day7_5", "room": "Bedroom"},
			{"task": "tugas_kantor", "room": "Bedroom", "mark": "DeskMark"},
		],
		8: [
			{"cutscene": "Adult_Day8_1", "room": "Bedroom"},
			{"cutscene": "Adult_Day8_2", "room": "Livingroom"},
			{"cutscene": "Adult_Day8_3", "room": "Park", "end_game": true},
		],
	},
}

# ---------------------------------------------------------------
# MODE TES: isi dengan nama task / id cutscene (misal "sembunyi") untuk langsung loncat
# ke langkah itu pada hari yang sedang aktif. Kosongkan ("") untuk main normal.
const DEBUG_START_AT: String = ""
var _debug_done: bool = false

var stage: Node = null
var room: String = ""
var spawned_task: Node = null
var spawned_task_name: String = ""
var busy: bool = false          # sedang transisi hari / fase
var current_hint: String = ""

var overlay_layer: CanvasLayer
var overlay_rect: ColorRect
var overlay_label: Label
var overlay_tween: Tween
const SFX_NEW_DAY = preload("res://assets/audios/Transisi Diari ke Next day.mp3")
var day_sfx: AudioStreamPlayer

# suara task berhasil / gagal. GANTI path sesuai nama file audiomu.
# Dimuat dengan load() (bukan preload): kalau path salah, game tetap jalan, hanya tanpa suara.
const SFX_TASK_SUCCESS_PATH = "res://assets/audios/TaskSuccess.mp3"
const SFX_TASK_FAIL_PATH = "res://assets/audios/TaskFail.mp3"
var sfx_task_success: AudioStream
var sfx_task_fail: AudioStream
var task_sfx: AudioStreamPlayer

func _ready() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 128
	add_child(overlay_layer)

	overlay_rect = ColorRect.new()
	overlay_rect.color = Color(0, 0, 0, 0)
	overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(overlay_rect)

	overlay_label = Label.new()
	overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_label.add_theme_font_size_override("font_size", 26)
	overlay_label.modulate.a = 0.0
	overlay_layer.add_child(overlay_label)
	day_sfx = AudioStreamPlayer.new()
	day_sfx.stream = SFX_NEW_DAY
	day_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(day_sfx)

	task_sfx = AudioStreamPlayer.new()
	add_child(task_sfx)
	sfx_task_success = _load_sound(SFX_TASK_SUCCESS_PATH)
	sfx_task_fail = _load_sound(SFX_TASK_FAIL_PATH)


func _load_sound(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("File suara tidak ditemukan: " + path)
	return null


# ===================== DIPANGGIL STAGE =====================

func enter_room(stage_node: Node, room_name: String) -> void:
	stage = stage_node
	room = room_name
	spawned_task = null
	spawned_task_name = ""
	refresh.call_deferred()


func refresh() -> void:
	if busy: return
	if not is_instance_valid(stage): return
	if CutsceneManager.playing:
		print("[Story] menunggu cutscene selesai: ", CutsceneManager.current_id)
		return

	_debug_skip()
	var step = current_step()
	print("[Story] %s hari %s | ruangan: %s | langkah: %s" % [GameManager.current_phase, GameManager.current_day, room, str(step)])
	if step.is_empty():
		_set_hint("Tulis diary di kamar untuk tidur")
		return

	if step["room"] != room:
		_set_hint("Pergi ke " + ROOM_NAMES.get(step["room"], step["room"]))
		return

	if step.has("cutscene"):
		_set_hint("")
		_play_cutscene(step)
	else:
		_set_hint(TASK_HINTS.get(step["task"], step["task"]))
		_spawn_task(step)


func _debug_skip() -> void:
	if _debug_done or DEBUG_START_AT == "": return
	_debug_done = true
	for step in get_steps():
		var id = step.get("cutscene", step.get("task", ""))
		if id == DEBUG_START_AT: return
		if step.has("cutscene"):
			CutsceneManager.played[step["cutscene"]] = true
		else:
			ToDoList.complete_task(GameManager.current_phase, int(GameManager.current_day), step["task"])


# ===================== DATA LANGKAH =====================

func get_steps() -> Array:
	var phase_steps: Dictionary = STEPS.get(GameManager.current_phase, {})
	return phase_steps.get(int(GameManager.current_day), [])


func is_step_done(step: Dictionary) -> bool:
	if step.has("cutscene"):
		return CutsceneManager.has_played(step["cutscene"])
	return ToDoList.is_task_done(GameManager.current_phase, int(GameManager.current_day), step["task"])


func current_step() -> Dictionary:
	for step in get_steps():
		if not is_step_done(step):
			return step
	return {}


func is_day_complete() -> bool:
	return current_step().is_empty()


# ===================== CUTSCENE =====================

func _cutscene_list() -> Node:
	match GameManager.current_phase:
		"Kid": return CutscenesListKid
		"Teen": return CutscenesListTeen
		"Adult": return CutscenesListAdult
	return CutscenesListKid


func _play_cutscene(step: Dictionary) -> void:
	var id: String = step["cutscene"]
	var ok: bool = _cutscene_list().play(id)
	if not ok:
		# dialog tidak ada / gagal diputar: lewati supaya game tidak macet
		push_warning("Cutscene gagal diputar, dilewati: " + id)
		CutsceneManager.played[id] = true
		_after_cutscene.call_deferred(step)
		return
	CutsceneManager.cutscene_finished.connect(_after_cutscene.bind(step), CONNECT_ONE_SHOT)


func _after_cutscene(step: Dictionary) -> void:
	if step.get("end_game", false):
		show_ending()
	elif step.get("end_day", false):
		advance_day()
	elif step.has("goto"):
		go_to_room(step["goto"])
	else:
		refresh()


# ===================== TASK =====================

func _spawn_task(step: Dictionary) -> void:
	var task_name: String = step["task"]
	if is_instance_valid(spawned_task) and spawned_task_name == task_name:
		return

	var scene_path: String = TASK_SCENES.get(task_name, "")
	var scene: PackedScene = load(scene_path) if scene_path != "" else null
	if scene == null:
		push_error("Scene task gagal dimuat: " + task_name + " (" + scene_path + ")")
		return

	var parent: Node = stage.get_node_or_null("Tasks")
	if parent == null:
		parent = stage

	var task = scene.instantiate()
	parent.add_child(task)
	task.position = _mark_position(parent, step.get("mark", ""))
	task.accessible = true
	if task.has_method("configure"):
		task.configure(task_name)
	task.task_solved.connect(_on_task_solved.bind(task_name, task), CONNECT_ONE_SHOT)
	# suara gagal untuk minigame yang bisa gagal (PR/UTBK, rapat online, tugas kantor)
	var ui = task.get("game_ui")
	if ui and ui.has_signal("failed"):
		ui.failed.connect(_play_task_sfx.bind(sfx_task_fail))

	spawned_task = task
	spawned_task_name = task_name


func _mark_position(parent: Node, mark_name: String) -> Vector2:
	if mark_name != "":
		var marker = parent.get_node_or_null(mark_name)
		if marker is Node2D:
			return marker.position
		var room_marks: Dictionary = MARK_DEFAULTS.get(room, {})
		if room_marks.has(mark_name):
			return room_marks[mark_name]
	return Vector2(192, 160)


func _on_task_solved(task_name: String, task: Node) -> void:
	_play_task_sfx(sfx_task_success)
	ToDoList.complete_task(GameManager.current_phase, int(GameManager.current_day), task_name)
	if is_instance_valid(task):
		task.queue_free()
	spawned_task = null
	spawned_task_name = ""
	refresh.call_deferred()


func _play_task_sfx(stream: AudioStream) -> void:
	if stream == null: return
	task_sfx.stream = stream
	task_sfx.play()


# ===================== PINDAH RUANGAN / HARI =====================

func _spawn_for(room_name: String) -> Vector2:
	var n = GameManager.get_stage_number(GameManager.current_phase)
	var key = "Stage_%d(first_spawn)" % n
	match room_name:
		"Livingroom": key = "Stage_%d(bedroom-livingroom)" % n
		"Park": key = "Stage_%d(livingroom-park)" % n
	return SpawnLocation.locations.get(key, Vector2(192, 200))


func go_to_room(room_name: String) -> void:
	GameManager.load_room(room_name, _spawn_for(room_name))


# dipanggil Diary (lewat stage.change_time) atau cutscene dengan end_day
func advance_day() -> void:
	if busy: return
	var day = int(GameManager.current_day)
	var title := ""

	if day < ToDoList.get_day_count(GameManager.current_phase):
		GameManager.current_day = str(day + 1)
		title = "Hari ke-%d" % (day + 1)
	else:
		var next_phase = ToDoList.get_next_phase(GameManager.current_phase)
		if next_phase == "":
			show_ending()
			return
		GameManager.current_phase = next_phase
		GameManager.current_day = "1"
		title = PHASE_TITLES.get(next_phase, next_phase) + "\nHari ke-1"

	_transition(title, _load_day_start)


# main menu -> game baru
func start_new_game() -> void:
	if busy: return
	GameManager.reset_progress()
	_transition(PHASE_TITLES["Kid"] + "\nHari ke-1", _load_day_start)


func _load_day_start() -> void:
	go_to_room("Bedroom")


func show_ending() -> void:
	if busy: return
	busy = true
	GameManager.on_task = true
	_set_hint("")
	if overlay_tween:
		overlay_tween.kill()
	overlay_label.text = "Tamat\n\nTerima kasih sudah bermain."
	overlay_tween = create_tween()
	overlay_tween.tween_property(overlay_rect, "color:a", 1.0, 1.5)
	overlay_tween.tween_property(overlay_label, "modulate:a", 1.0, 1.0)
	overlay_tween.tween_interval(4.0)
	overlay_tween.tween_property(overlay_label, "modulate:a", 0.0, 1.0)
	overlay_tween.tween_callback(_back_to_menu)
	overlay_tween.tween_property(overlay_rect, "color:a", 0.0, 0.8)
	overlay_tween.tween_callback(_transition_done)


func _back_to_menu() -> void:
	GameManager.reset_progress()
	stage = null
	GameManager.load_main_menu()


# layar hitam + tulisan, lalu jalankan on_black (ganti scene), lalu terang lagi
func _transition(text: String, on_black: Callable) -> void:
	busy = true
	GameManager.on_task = true
	_set_hint("")
	if overlay_tween:
		overlay_tween.kill()
	overlay_label.text = text
	overlay_tween = create_tween()
	overlay_tween.tween_property(overlay_rect, "color:a", 1.0, 0.8)
	overlay_tween.tween_callback(day_sfx.play)
	overlay_tween.tween_property(overlay_label, "modulate:a", 1.0, 0.5)
	overlay_tween.tween_interval(1.2)
	overlay_tween.tween_callback(on_black)
	overlay_tween.tween_property(overlay_label, "modulate:a", 0.0, 0.5)
	overlay_tween.tween_property(overlay_rect, "color:a", 0.0, 0.8)
	overlay_tween.tween_callback(_transition_done)

func _transition_done() -> void:
	busy = false
	GameManager.on_task = false
	refresh()


# ===================== HINT HUD =====================

func _set_hint(text: String) -> void:
	current_hint = text
	hint_changed.emit(text)


# pesan sementara (misal dari diary)
func flash_hint(text: String) -> void:
	hint_changed.emit(text)

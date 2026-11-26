extends Node

signal cutscene_finished

const BALLOON = preload("res://naratives/balloon/balloon.tscn")
const MAMA_SCENE_PATH = "res://scenes/npc/Mama_NPC.tscn"
const SFX_TEXT = preload("res://assets/audios/MenuCycle&Select.mp3")   
var text_sfx: AudioStreamPlayer

var playing: bool = false
var player_camera: Camera2D
var cutscene_camera: Camera2D
var move_tween: Tween

var travel_cam: Camera2D
var cam_tween: Tween
var return_duration: float = 1.0
var current_cutscene_root: Node = null

# layar hitam untuk transisi di dalam cutscene (di bawah balon dialog, balon layer = 100)
var fade_layer: CanvasLayer
var fade_rect: ColorRect
var fade_tween: Tween

var current_id: String = ""

# id cutscene -> sudah diputar atau belum.
# id yang belum terdaftar di sini otomatis dianggap belum diputar.
var played: Dictionary = {}


func _ready() -> void:
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	travel_cam = Camera2D.new()
	travel_cam.enabled = false
	add_child(travel_cam)

	fade_layer = CanvasLayer.new()
	fade_layer.layer = 90
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)
	text_sfx = AudioStreamPlayer.new()
	text_sfx.stream = SFX_TEXT
	add_child(text_sfx)

# mulai game baru
func reset() -> void:
	played.clear()
	current_id = ""
	playing = false
	fade_rect.color.a = 0.0


func start(dialogue: DialogueResource, title: String = "start", cam_name: String = "") -> void:
	if playing: return
	playing = true
	GameManager.on_task = true
	GameManager.interact = false

	player_camera = get_viewport().get_camera_2d()
	_set_player_anim("idle")

	if cam_name != "":
		set_camera(cam_name)

	DialogueManager.show_dialogue_balloon_scene(BALLOON, dialogue, title)


func play_once(
	id: String,
	dialogue: DialogueResource,
	title: String = "start",
	cam_name: String = "",
	node_name: String = ""
) -> bool:
	if playing: return false
	if played.get(id, false): return false

	current_id = id

	# folder cutscene (Node2D berisi kamera & marker) di dalam stage.
	# kalau tidak ada, pakai scene yang sedang aktif (cutscene tanpa kamera khusus).
	var root_name = node_name if node_name != "" else id
	current_cutscene_root = get_tree().current_scene.find_child(root_name, true, false)
	if current_cutscene_root == null:
		current_cutscene_root = get_tree().current_scene

	start(dialogue, title, cam_name)
	return true


func has_played(id: String) -> bool:
	return played.get(id, false)


# ===================== KAMERA =====================

func set_camera(cam_name: String, duration: float = 0.0) -> void:
	var target = _find(cam_name) as Camera2D
	if target == null:
		push_warning("Kamera tidak ketemu: " + cam_name)
		return

	if cam_tween:
		cam_tween.kill()

	var current = get_viewport().get_camera_2d()
	if current != null and current != travel_cam:
		travel_cam.global_position = current.get_screen_center_position()
		travel_cam.zoom = current.zoom
	travel_cam.enabled = true
	travel_cam.make_current()

	if duration <= 0.0:
		travel_cam.global_position = target.global_position
		travel_cam.zoom = target.zoom
		return

	cam_tween = create_tween().set_parallel(true)
	cam_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	cam_tween.tween_property(travel_cam, "global_position", target.global_position, duration)
	cam_tween.tween_property(travel_cam, "zoom", target.zoom, duration)


# ===================== LAYAR HITAM =====================

# layar perlahan jadi hitam (dipakai untuk "waktu berlalu")
func fade_out(duration: float = 0.6) -> void:
	_fade_to(1.0, duration)


# layar kembali terang
func fade_in(duration: float = 0.6) -> void:
	_fade_to(0.0, duration)


func _fade_to(alpha: float, duration: float) -> void:
	if fade_tween:
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color:a", alpha, max(duration, 0.01))


# ===================== GERAK PLAYER =====================

# jalan ke Marker2D
func move_player(marker_name: String, duration: float = 1.0) -> void:
	var marker = _find(marker_name)
	if marker == null:
		push_warning("Marker tidak ketemu: " + marker_name)
		return
	_queue_move(marker.global_position, duration)


# jalan ke koordinat (tanpa Marker2D)
func move_player_to(x: float, y: float, duration: float = 1.0) -> void:
	_queue_move(Vector2(x, y), duration)


# jalan sekian piksel dari posisi sekarang
func move_player_by(dx: float, dy: float, duration: float = 1.0) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return
	var start_pos = _planned_position if _has_queue() else player.global_position
	_queue_move(start_pos + Vector2(dx, dy), duration)


# diam sebentar di antara gerakan
func cutscene_wait(duration: float) -> void:
	if not _has_queue():
		move_tween = create_tween()
	move_tween.tween_interval(duration)


# hadap kiri / kanan / atas / bawah tanpa bergerak
func player_face(direction: String) -> void:
	var sprite = _player_sprite()
	if sprite == null: return
	match direction:
		"left":
			sprite.flip_h = true
			_set_player_anim("idle")
		"right":
			sprite.flip_h = false
			_set_player_anim("idle")
		"up":
			_set_player_anim("walk_up")
			sprite.stop()
		"down":
			_set_player_anim("walk_down")
			sprite.stop()


var npc_move_tween: Tween

# ===================== MAMA (NPC) =====================
# Dipakai dari file .dialogue, contoh:
#   do CutsceneManager.show_mama(250, 150, "left")
#   do CutsceneManager.mama_walk_to(90, 210, 1.5)
#   do CutsceneManager.hide_mama()
# Mama otomatis hilang saat cutscene selesai.
var mama: Node2D = null
var mama_tween: Tween


func show_mama(x: float, y: float, facing: String = "front") -> void:
	if not is_instance_valid(mama):
		var scene: PackedScene = load(MAMA_SCENE_PATH)
		if scene == null:
			push_error("Scene Mama gagal dimuat")
			return
		mama = scene.instantiate()
		get_tree().current_scene.add_child(mama)
	mama.global_position = Vector2(x, y)
	mama.visible = true
	mama.face(facing)


func hide_mama() -> void:
	if mama_tween:
		mama_tween.kill()
	if is_instance_valid(mama):
		mama.queue_free()
	mama = null


func mama_face(facing: String) -> void:
	if is_instance_valid(mama):
		mama.face(facing)


func mama_walk_to(x: float, y: float, duration: float = 1.0) -> void:
	if not is_instance_valid(mama): return
	var target = Vector2(x, y)
	var d = target - mama.global_position
	var dir = "front"
	if abs(d.x) >= abs(d.y):
		dir = "right" if d.x > 0 else "left"
	elif d.y < 0:
		dir = "back"
	if mama_tween:
		mama_tween.kill()
	mama.walk(dir)
	mama_tween = create_tween()
	mama_tween.tween_property(mama, "global_position", target, max(duration, 0.01))
	mama_tween.tween_callback(Callable(mama, "face").bind(dir))


# NPC (node di group "npc") jalan ke marker. Kalau tidak ada NPC, perintah dilewati.
func move_npc(marker_name: String = "", duration: float = 1.0) -> void:
	if marker_name == "": return
	var marker = _find(marker_name)
	var npc = get_tree().get_first_node_in_group("npc")
	if marker == null or npc == null:
		push_warning("NPC atau marker tidak ditemukan: " + marker_name)
		return

	if npc_move_tween:
		npc_move_tween.kill()

	if duration <= 0.0:
		npc.global_position = marker.global_position
		return

	npc_move_tween = create_tween()
	npc_move_tween.tween_property(npc, "global_position", marker.global_position, duration)


var _planned_position: Vector2 = Vector2.ZERO

func _has_queue() -> bool:
	return move_tween != null and move_tween.is_valid()


func _queue_move(target: Vector2, duration: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("Player tidak ketemu (group: player)")
		return

	var from = _planned_position if _has_queue() else player.global_position

	if duration <= 0.0 and not _has_queue():
		player.global_position = target
		_planned_position = target
		return

	if not _has_queue():
		move_tween = create_tween()

	move_tween.tween_callback(_walk_anim.bind(target - from))
	move_tween.tween_property(player, "global_position", target, max(duration, 0.01))
	move_tween.tween_callback(_set_player_anim.bind("idle"))
	_planned_position = target


# ===================== ANIMASI PLAYER =====================

func _player_sprite() -> AnimatedSprite2D:
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return null
	return player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D


# nama animasi player: "walk_up Kid", "idle Teen", dst.
func _set_player_anim(kind: String) -> void:
	var sprite = _player_sprite()
	if sprite == null or sprite.sprite_frames == null: return
	var anim = kind + " " + GameManager.current_phase
	if sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)


func _walk_anim(dir: Vector2) -> void:
	var sprite = _player_sprite()
	if sprite == null: return
	if abs(dir.x) >= abs(dir.y):
		if abs(dir.x) > 0.5:
			sprite.flip_h = dir.x < 0.0
		_set_player_anim("walk_horizontal")
	elif dir.y < 0.0:
		_set_player_anim("walk_up")
	else:
		_set_player_anim("walk_down")


# ===================== SELESAI =====================

func _find(node_name: String) -> Node:
	if not is_instance_valid(current_cutscene_root):
		return null
	return current_cutscene_root.find_child(node_name, true, false)


func _on_dialogue_ended(_resource) -> void:
	if not playing: return
	playing = false

	if current_id != "":
		played[current_id] = true
		current_id = ""

	if move_tween:
		move_tween.kill()
	_set_player_anim("idle")
	hide_mama()

	# kalau cutscene berakhir dalam keadaan layar hitam, terangkan lagi
	if fade_rect.color.a > 0.0:
		fade_in(0.4)

	_return_camera()


func _return_camera() -> void:
	if cam_tween:
		cam_tween.kill()

	if travel_cam.enabled and is_instance_valid(player_camera):
		cam_tween = create_tween().set_parallel(true)
		cam_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		cam_tween.tween_property(travel_cam, "global_position", player_camera.global_position, return_duration)
		cam_tween.tween_property(travel_cam, "zoom", player_camera.zoom, return_duration)
		cam_tween.finished.connect(_finish_cutscene)
	else:
		_finish_cutscene()


func _finish_cutscene() -> void:
	if is_instance_valid(player_camera):
		player_camera.make_current()
	travel_cam.enabled = false
	GameManager.on_task = false
	cutscene_finished.emit()


func play_text_sfx() -> void:
	text_sfx.play()
	
	
func play_sfx(path: String, volume: float = 0.0) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Suara tidak ketemu: " + path)
		return
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load(path)
	sfx.volume_db = volume
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

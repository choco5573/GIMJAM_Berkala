extends Node2D
signal on_hide_and_seek_game_solved
signal task_solved   # sinyal umum, dipakai StoryDirector

# Petak umpet di halaman:
#   Mama bersembunyi di salah satu tempat bertanda "?".
#   Datangi tanda itu lalu tekan E untuk memeriksa.
#   Salah tempat -> tanda jadi "x". Ketemu -> task selesai.
#
# Posisi tempat sembunyi (koordinat halaman, 384x288). Geser angkanya kalau kurang pas.
const HIDING_SPOTS: Array = [
	{"name": "balik semak-semak", "pos": Vector2(72, 172)},
	{"name": "samping kolam", "pos": Vector2(142, 128)},
	{"name": "ayunan", "pos": Vector2(257, 124)},
	{"name": "kotak pasir", "pos": Vector2(335, 140)},
	{"name": "pojok taman", "pos": Vector2(362, 82)},
	{"name": "pagar bawah", "pos": Vector2(300, 248)},
	{"name": "dinding rumah", "pos": Vector2(52, 245)},
]
const SPOT_RADIUS: float = 18.0

@onready var area: Area2D = $Area2D

var player_on_collision : bool = false   # tidak dipakai lagi, disimpan untuk kompatibilitas
var accessible : bool = false
var puzzle_solved : bool = false

var available_phases : Array = ["Kid"]

var spots: Array = []        # [{ "area": Area2D, "label": Label, "checked": bool }]
var mama_index: int = -1
var current_spot: int = -1


func _ready() -> void:
	for phase in available_phases:
		if phase == GameManager.current_phase:
			accessible = true

	# ikon & tembok bawaan scene tidak dipakai di versi ini
	area.visible = false
	area.set_deferred("monitoring", false)
	var block = get_node_or_null("Area2D/Sprite2D/StaticBody2D/CollisionShape2D")
	if block:
		block.set_deferred("disabled", true)

	_build_spots()
	mama_index = randi() % spots.size()


func _build_spots() -> void:
	for i in HIDING_SPOTS.size():
		var spot = Area2D.new()
		spot.top_level = true   # tidak ikut skala node task
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = SPOT_RADIUS
		shape.shape = circle
		spot.add_child(shape)

		var label = Label.new()
		label.text = "?"
		label.position = Vector2(-4, -30)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_constant_override("outline_size", 4)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		spot.add_child(label)

		add_child(spot)
		spot.global_position = HIDING_SPOTS[i]["pos"]
		spot.body_entered.connect(_on_spot_entered.bind(i))
		spot.body_exited.connect(_on_spot_exited.bind(i))

		# tanda "?" naik turun sedikit
		var bob = label.create_tween().set_loops()
		bob.tween_property(label, "position:y", -34.0, 0.5)
		bob.tween_property(label, "position:y", -30.0, 0.5)

		spots.append({"area": spot, "label": label, "checked": false})


func _input(event: InputEvent) -> void:
	if !accessible: return
	if puzzle_solved: return
	if current_spot < 0: return
	if GameManager.on_task: return

	if event.is_action_pressed("e_accept"):
		_check_spot(current_spot)


func _check_spot(i: int) -> void:
	var spot = spots[i]
	var place: String = HIDING_SPOTS[i]["name"]

	if i == mama_index:
		puzzle_solved = true
		spot["label"].text = "!"
		spot["label"].modulate = Color(1, 0.9, 0.3)
		GameManager.interact = false
		StoryDirector.flash_hint("Ketemu! Mama sembunyi di " + place + "!")
		var wait = create_tween()
		wait.tween_interval(1.0)
		wait.tween_callback(solved)
	else:
		spot["checked"] = true
		spot["label"].text = "x"
		spot["label"].modulate = Color(0.6, 0.6, 0.6)
		StoryDirector.flash_hint("Mama tidak ada di " + place + "...")


func _on_spot_entered(body: Node2D, i: int) -> void:
	if puzzle_solved: return
	if body.is_in_group("player"):
		current_spot = i
		GameManager.interact = true


func _on_spot_exited(body: Node2D, i: int) -> void:
	if puzzle_solved: return
	if body.is_in_group("player") and current_spot == i:
		current_spot = -1
		GameManager.interact = false


# sambungan lama dari scene (Area2D ikon). Tidak dipakai lagi.
func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass


func _on_area_2d_body_exited(_body: Node2D) -> void:
	pass


func solved() -> void:
	GameManager.on_task = false
	GameManager.interact = false
	on_hide_and_seek_game_solved.emit()
	task_solved.emit()

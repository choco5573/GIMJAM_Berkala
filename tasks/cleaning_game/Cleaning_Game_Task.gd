extends Node2D
signal on_cleaning_game_solved
signal task_solved   # sinyal umum, dipakai StoryDirector

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var game_ui: Control = $CanvasLayer/CleaningGameUi
@onready var area: Area2D = $Area2D

var player_on_collision : bool = false
var accessible : bool = false
var puzzle_solved : bool = false

var available_phases : Array = ["Teen", "Adult"]

func _ready() -> void:
	game_ui.solved.connect(solved)
	if game_ui.has_signal("failed"):
		game_ui.failed.connect(failed)
	# sambungkan sinyal Area2D lewat kode (aman walau belum disambung di editor)
	if not area.body_entered.is_connected(_on_area_2d_body_entered):
		area.body_entered.connect(_on_area_2d_body_entered)
	if not area.body_exited.is_connected(_on_area_2d_body_exited):
		area.body_exited.connect(_on_area_2d_body_exited)
	for phase in available_phases:
		if phase == GameManager.current_phase:
			accessible = true


# dipanggil StoryDirector: nyapu / ngepel memakai minigame yang sama
func configure(task_name: String) -> void:
	if game_ui.has_method("set_mode"):
		game_ui.set_mode(task_name)


func _input(event: InputEvent) -> void:
	if !accessible: return
	if puzzle_solved: return

	if event.is_action_pressed("e_accept") and player_on_collision:
		if canvas_layer.visible: return
		if GameManager.on_task: return
		GameManager.on_task = true
		GameManager.interact = false
		canvas_layer.visible = true
		game_ui.start()
	elif event.is_action_pressed("ui_cancel") and canvas_layer.visible:
		get_viewport().set_input_as_handled()   # ESC ini jangan sampai membuka pause menu
		close_ui()


func close_ui() -> void:
	GameManager.on_task = false
	GameManager.interact = player_on_collision
	canvas_layer.visible = false
	game_ui.stop()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if puzzle_solved: return
	if body.is_in_group("player"):
		GameManager.interact = true
		player_on_collision = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if puzzle_solved: return
	if body.is_in_group("player"):
		GameManager.interact = false
		player_on_collision = false


func solved() -> void:
	if puzzle_solved: return
	accessible = false
	puzzle_solved = true
	game_ui.stop()
	GameManager.on_task = false
	GameManager.interact = false
	canvas_layer.visible = false
	on_cleaning_game_solved.emit()
	task_solved.emit()


# gagal: popup ditutup, bisa dicoba lagi dengan menekan E
func failed() -> void:
	close_ui()

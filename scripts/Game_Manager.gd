extends Node
signal task_completed

# Game_Manager = script yang selalu di run di semua scene. (Kalau mau diubah, kasih tau semua yang lain)
# Game_Managernya udah ku add sebagai AutoLoad. Jadi bisa dipanggil discene mana aja (ex : GameManager.load_main_menu())

var game_paused : bool =  false
var on_task : bool = false
var current_phase : String = "Kid"
var current_room : String = "bedroom"
var current_day : String = "1"
var interact : bool = false
var spawn_position : Vector2 = Vector2.ZERO

#jemur
var is_dragging = false

# UI LOAD
const main_menu_scene : PackedScene = preload("res://UI/Main_Menu.tscn")
func load_main_menu():
	get_tree().change_scene_to_packed(main_menu_scene)


# STAGE 1 LOAD
const stage_1_bedroom_scene : PackedScene = preload("res://scenes/stages/stage_1/Stage_1_Bedroom.tscn")
func load_stage_1_Bedroom(spawn : Vector2):
	spawn_position = spawn
	get_tree().change_scene_to_packed(stage_1_bedroom_scene)

const stage_1_Livingroom_scene : PackedScene = preload("res://scenes/stages/stage_1/Stage_1_Livingroom.tscn")
func load_stage_1_Livingroom(spawn : Vector2):
	spawn_position = spawn
	get_tree().change_scene_to_packed(stage_1_Livingroom_scene)

const stage_1_Park_scene : PackedScene = preload("res://scenes/stages/stage_1/Stage_1_Park.tscn")
func load_stage_1_Park(spawn : Vector2):
	spawn_position = spawn
	get_tree().change_scene_to_packed(stage_1_Park_scene)


# STAGE 2 LOAD
const stage_2_bedroom_scene : PackedScene = preload("res://scenes/stages/stage_2/Stage_2_Bedroom.tscn")
func load_stage_2_Bedroom(spawn : Vector2):
	spawn_position = spawn
	get_tree().change_scene_to_packed(stage_2_bedroom_scene)

const stage_2_livingroom_scene : PackedScene = preload("res://scenes/stages/stage_2/Stage_2_Livingroom.tscn")
func load_stage_2_Livingroom(spawn : Vector2):
	spawn_position = spawn
	get_tree().change_scene_to_packed(stage_2_livingroom_scene)

const stage_2_park_scene : PackedScene = preload("res://scenes/stages/stage_2/Stage_2_Park.tscn")
func load_stage_2_Park(spawn : Vector2):
	spawn_position = spawn
	get_tree().change_scene_to_packed(stage_2_park_scene)


# STAGE 3 LOAD
const stage_3_bedroom_scene : PackedScene = preload("res://scenes/stages/stage_3/Stage_3_Bedroom.tscn")
func load_stage_3_Bedroom(spawn : Vector2):
	spawn_position = spawn
	get_tree().change_scene_to_packed(stage_3_bedroom_scene)

const stage_3_livingroom_scene : PackedScene = preload("res://scenes/stages/stage_3/Stage_3_Livingroom.tscn")
func load_stage_3_Livingroom(spawn : Vector2):
	spawn_position = spawn
	get_tree().change_scene_to_packed(stage_3_livingroom_scene)

const stage_3_park_scene : PackedScene = preload("res://scenes/stages/stage_3/Stage_3_Park.tscn")
func load_stage_3_Park(spawn : Vector2):
	spawn_position = spawn
	get_tree().change_scene_to_packed(stage_3_park_scene)


# LOAD ROOM GENERIK (dipakai StoryDirector)
# room = "Bedroom" / "Livingroom" / "Park"
func get_stage_number(phase: String) -> int:
	match phase:
		"Kid": return 1
		"Teen": return 2
		"Adult": return 3
	return 1

func load_room(room: String, spawn: Vector2) -> void:
	var method = "load_stage_%d_%s" % [get_stage_number(current_phase), room]
	if has_method(method):
		call(method, spawn)
	else:
		push_warning("Room tidak dikenal: " + method)


# mulai game baru (dipanggil dari main menu)
'''func reset_progress() -> void:
	game_paused = false
	on_task = false
	interact = false
	is_dragging = false
	current_phase = "Kid"
	current_day = "1"
	current_room = ""
	ToDoList.reset()
	CutsceneManager.reset()'''


# GAME QUIT
func quit_game():
	get_tree().quit()

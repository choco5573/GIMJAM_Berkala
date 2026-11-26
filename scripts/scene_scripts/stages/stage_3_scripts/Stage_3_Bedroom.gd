extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var door: Area2D = $Door
@onready var hud: CanvasLayer = $Hud
@onready var diary: Area2D = $Diary
@onready var tasks: Node2D = $Tasks

const SpawnLocation = preload("res://scripts/Spawn_Location.gd")
var current_room : String = "Bedroom"
const MUSIC_Adult = preload("res://assets/audios/Adult.mp3")  


func _ready() -> void:
	GameManager.current_room = current_room
	MusicManager.play(MUSIC_Adult)
	diary.diary_solved.connect(change_time)
	print("Hello Stage 3 Bedroom")
	hud.room_label.text = current_room
	door.on_door_pressed.connect(door_pressed)
	# kalau scene dijalankan langsung (F6), spawn masih (0,0): pakai posisi Player di editor
	if GameManager.spawn_position != Vector2.ZERO:
		player.position = GameManager.spawn_position
	load_cutscenes()
	load_puzzles()


func door_pressed():
	GameManager.load_stage_3_Livingroom(SpawnLocation.locations["Stage_3(bedroom-livingroom)"])


# diary ditulis -> ganti hari / fase (diatur StoryDirector)
func change_time() -> void:
	StoryDirector.advance_day()


# cutscene dan task hari ini diatur StoryDirector (naratives/Story_Director.gd)
func load_cutscenes():
	StoryDirector.enter_room(self, current_room)


# task dimunculkan StoryDirector di Marker2D dalam node "Tasks"
func load_puzzles() -> void:
	pass

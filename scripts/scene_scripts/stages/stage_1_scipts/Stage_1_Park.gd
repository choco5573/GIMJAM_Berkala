extends Node2D

@onready var door: Area2D = $Door
@onready var hud: CanvasLayer = $Hud
@onready var player: CharacterBody2D = $Player
@onready var tasks: Node2D = $Tasks

const SpawnLocation = preload("res://scripts/Spawn_Location.gd")
var current_room : String = "Park"
const MUSIC_KID = preload("res://assets/audios/Kid.mp3")  


func _ready() -> void:
	GameManager.current_room = current_room
	MusicManager.play(MUSIC_KID)
	print("Hello Stage 1 Park")
	hud.room_label.text = current_room
	door.on_door_pressed.connect(door_pressed)
	# kalau scene dijalankan langsung (F6), spawn masih (0,0): pakai posisi Player di editor
	if GameManager.spawn_position != Vector2.ZERO:
		player.position = GameManager.spawn_position
	load_cutscenes()
	load_puzzles()


func door_pressed():
	GameManager.load_stage_1_Livingroom(SpawnLocation.locations["Stage_1(park-livingroom)"])


# cutscene dan task hari ini diatur StoryDirector (naratives/Story_Director.gd)
func load_cutscenes():
	StoryDirector.enter_room(self, current_room)


func load_puzzles() -> void:
	pass

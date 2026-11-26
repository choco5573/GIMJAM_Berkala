extends Node2D

@onready var door_1: Area2D = $Door_1
@onready var door_2: Area2D = $Door_2
@onready var hud: CanvasLayer = $Hud
@onready var player: CharacterBody2D = $Player
@onready var tasks: Node2D = $Tasks

const SpawnLocation = preload("res://scripts/Spawn_Location.gd")
var current_room : String = "Livingroom"
const MUSIC_Teen = preload("res://assets/audios/Teenager.mp3")  


func _ready() -> void:
	GameManager.current_room = current_room
	MusicManager.play(MUSIC_Teen)
	print("Hello Stage 2 Livingroom")
	hud.room_label.text = current_room
	door_1.on_door_pressed.connect(door_1_pressed)
	door_2.on_door_pressed.connect(door_2_pressed)
	# kalau scene dijalankan langsung (F6), spawn masih (0,0): pakai posisi Player di editor
	if GameManager.spawn_position != Vector2.ZERO:
		player.position = GameManager.spawn_position
	load_cutscenes()
	load_puzzles()


func door_1_pressed():
	GameManager.load_stage_2_Bedroom(SpawnLocation.locations["Stage_2(livingroom-bedroom)"])

func door_2_pressed():
	GameManager.load_stage_2_Park(SpawnLocation.locations["Stage_2(livingroom-park)"])


# cutscene dan task hari ini diatur StoryDirector (naratives/Story_Director.gd)
func load_cutscenes():
	StoryDirector.enter_room(self, current_room)


func load_puzzles() -> void:
	pass

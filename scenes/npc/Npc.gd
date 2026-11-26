extends Node2D
# NPC sederhana untuk cutscene (dipakai Mama).
# Animasi dibuat otomatis dari file: <folder><prefix>front 1.png ... left 3.png
# Ganti sprite_folder / prefix kalau nanti ada sprite Mama sendiri.

@export var sprite_folder: String = "res://assets/sprites/characters_sprites/Lara Adult/casual/"
@export var prefix: String = "lara_ah_"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const DIRECTIONS: Array = ["front", "back", "left", "right"]


func _ready() -> void:
	var frames = SpriteFrames.new()
	for dir in DIRECTIONS:
		var walk = "walk_" + dir
		var idle = "idle_" + dir
		frames.add_animation(walk)
		frames.add_animation(idle)
		frames.set_animation_speed(walk, 6.0)
		for i in [1, 2, 3]:
			var path = sprite_folder + prefix + dir + " " + str(i) + ".png"
			if ResourceLoader.exists(path):
				var tex = load(path)
				frames.add_frame(walk, tex)
				if i == 1:
					frames.add_frame(idle, tex)
	sprite.sprite_frames = frames
	face("front")


# arah: "front" / "back" / "left" / "right" (juga menerima "down" / "up")
func face(dir: String) -> void:
	sprite.play("idle_" + _norm(dir))


func walk(dir: String) -> void:
	sprite.play("walk_" + _norm(dir))


func _norm(dir: String) -> String:
	match dir:
		"down": return "front"
		"up": return "back"
	return dir if DIRECTIONS.has(dir) else "front"

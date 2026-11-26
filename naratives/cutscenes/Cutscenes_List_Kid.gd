extends Node
# Daftar cutscene Masa Kecil.
# id -> file dialog. Judul (~ ...) di dalam file dialog harus sama dengan id.
# Kamera opsional: isi CAMERAS kalau cutscene punya folder Node2D (berisi Camera2D) di stage.

const DIALOGUES: Dictionary = {
	"Kid_Day1_1": preload("res://naratives/cutscenes/kid_day1/Kid_Day1_1.dialogue"),
	"Kid_Day1_2": preload("res://naratives/cutscenes/kid_day1/Kid_Day1_2.dialogue"),
	"Kid_Day1_3": preload("res://naratives/cutscenes/kid_day1/Kid_Day1_3.dialogue"),
	"Kid_Day1_4": preload("res://naratives/cutscenes/kid_day1/Kid_Day1_4.dialogue"),
	"Kid_Day1_5": preload("res://naratives/cutscenes/kid_day1/Kid_Day1_5.dialogue"),
	"Kid_Day2_1": preload("res://naratives/cutscenes/kid_day2/Kid_Day2_1.dialogue"),
	"Kid_Day2_2": preload("res://naratives/cutscenes/kid_day2/Kid_Day2_2.dialogue"),
	"Kid_Day2_3": preload("res://naratives/cutscenes/kid_day2/Kid_Day2_3.dialogue"),
	"Kid_Day3_1": preload("res://naratives/cutscenes/kid_day3/Kid_Day3_1.dialogue"),
	"Kid_Day3_2": preload("res://naratives/cutscenes/kid_day3/Kid_Day3_2.dialogue"),
	"Kid_Day4": preload("res://naratives/cutscenes/kid_day4/Kid_Day4.dialogue"),
}

const CAMERAS: Dictionary = {
	"Kid_Day1_1": "CamIntro",
	"Kid_Day1_2": "Cam1",
	"Kid_Day1_3": "Day1_3_Cam1",
	"Kid_Day1_4": "Day1_4_Cam1",
	"Kid_Day1_5": "Day1_5_Cam1",
}


# putar cutscene berdasarkan id. return false kalau tidak bisa diputar.
func play(id: String) -> bool:
	if not DIALOGUES.has(id):
		push_warning("Dialog cutscene tidak terdaftar: " + id)
		return false
	return CutsceneManager.play_once(id, DIALOGUES[id], id, CAMERAS.get(id, ""), id)


# fungsi lama (masih bisa dipakai)
func play_KID_DAY1_1() -> void:
	play("Kid_Day1_1")

func play_KID_DAY1_2() -> void:
	play("Kid_Day1_2")

func play_KID_DAY1_3() -> void:
	play("Kid_Day1_3")

func play_KID_DAY1_4() -> void:
	play("Kid_Day1_4")

func play_KID_DAY1_5() -> void:
	play("Kid_Day1_5")

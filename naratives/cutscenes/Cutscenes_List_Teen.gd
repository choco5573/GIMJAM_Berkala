extends Node
# Daftar cutscene Masa Remaja.
# id -> file dialog. Judul (~ ...) di dalam file dialog harus sama dengan id.
# Kamera opsional: isi CAMERAS kalau cutscene punya folder Node2D (berisi Camera2D) di stage.

const DIALOGUES: Dictionary = {
	"Teen_Day1_1": preload("res://naratives/cutscenes/teen_day1/Teen_Day1_1.dialogue"),
	"Teen_Day1_2": preload("res://naratives/cutscenes/teen_day1/Teen_Day1_2.dialogue"),
	"Teen_Day1_3": preload("res://naratives/cutscenes/teen_day1/Teen_Day1_3.dialogue"),
	"Teen_Day2_1": preload("res://naratives/cutscenes/teen_day2/Teen_Day2_1.dialogue"),
	"Teen_Day2_2": preload("res://naratives/cutscenes/teen_day2/Teen_Day2_2.dialogue"),
	"Teen_Day2_3": preload("res://naratives/cutscenes/teen_day2/Teen_Day2_3.dialogue"),
	"Teen_Day3_1": preload("res://naratives/cutscenes/teen_day3/Teen_Day3_1.dialogue"),
	"Teen_Day3_2": preload("res://naratives/cutscenes/teen_day3/Teen_Day3_2.dialogue"),
	"Teen_Day3_3": preload("res://naratives/cutscenes/teen_day3/Teen_Day3_3.dialogue"),
	"Teen_Day4_1": preload("res://naratives/cutscenes/teen_day4/Teen_Day4_1.dialogue"),
	"Teen_Day4_2": preload("res://naratives/cutscenes/teen_day4/Teen_Day4_2.dialogue"),
	"Teen_Day4_3": preload("res://naratives/cutscenes/teen_day4/Teen_Day4_3.dialogue"),
	"Teen_Day5_1": preload("res://naratives/cutscenes/teen_day5/Teen_Day5_1.dialogue"),
	"Teen_Day5_2": preload("res://naratives/cutscenes/teen_day5/Teen_Day5_2.dialogue"),
}

const CAMERAS: Dictionary = {
}


# putar cutscene berdasarkan id. return false kalau tidak bisa diputar.
func play(id: String) -> bool:
	if not DIALOGUES.has(id):
		push_warning("Dialog cutscene tidak terdaftar: " + id)
		return false
	return CutsceneManager.play_once(id, DIALOGUES[id], id, CAMERAS.get(id, ""), id)

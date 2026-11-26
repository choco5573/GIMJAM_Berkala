extends Node
# Daftar cutscene Masa Dewasa.
# id -> file dialog. Judul (~ ...) di dalam file dialog harus sama dengan id.
# Kamera opsional: isi CAMERAS kalau cutscene punya folder Node2D (berisi Camera2D) di stage.

const DIALOGUES: Dictionary = {
	"Adult_Day1_1": preload("res://naratives/cutscenes/adult_day1/Adult_Day1_1.dialogue"),
	"Adult_Day1_2": preload("res://naratives/cutscenes/adult_day1/Adult_Day1_2.dialogue"),
	"Adult_Day1_3": preload("res://naratives/cutscenes/adult_day1/Adult_Day1_3.dialogue"),
	"Adult_Day1_4": preload("res://naratives/cutscenes/adult_day1/Adult_Day1_4.dialogue"),
	"Adult_Day2_1": preload("res://naratives/cutscenes/adult_day2/Adult_Day2_1.dialogue"),
	"Adult_Day2_2": preload("res://naratives/cutscenes/adult_day2/Adult_Day2_2.dialogue"),
	"Adult_Day2_3": preload("res://naratives/cutscenes/adult_day2/Adult_Day2_3.dialogue"),
	"Adult_Day3_1": preload("res://naratives/cutscenes/adult_day3/Adult_Day3_1.dialogue"),
	"Adult_Day3_2": preload("res://naratives/cutscenes/adult_day3/Adult_Day3_2.dialogue"),
	"Adult_Day3_3": preload("res://naratives/cutscenes/adult_day3/Adult_Day3_3.dialogue"),
	"Adult_Day3_4": preload("res://naratives/cutscenes/adult_day3/Adult_Day3_4.dialogue"),
	"Adult_Day4_1": preload("res://naratives/cutscenes/adult_day4/Adult_Day4_1.dialogue"),
	"Adult_Day4_2": preload("res://naratives/cutscenes/adult_day4/Adult_Day4_2.dialogue"),
	"Adult_Day4_3": preload("res://naratives/cutscenes/adult_day4/Adult_Day4_3.dialogue"),
	"Adult_Day4_4": preload("res://naratives/cutscenes/adult_day4/Adult_Day4_4.dialogue"),
	"Adult_Day5_1": preload("res://naratives/cutscenes/adult_day5/Adult_Day5_1.dialogue"),
	"Adult_Day5_2": preload("res://naratives/cutscenes/adult_day5/Adult_Day5_2.dialogue"),
	"Adult_Day5_3": preload("res://naratives/cutscenes/adult_day5/Adult_Day5_3.dialogue"),
	"Adult_Day5_4": preload("res://naratives/cutscenes/adult_day5/Adult_Day5_4.dialogue"),
	"Adult_Day6_1": preload("res://naratives/cutscenes/adult_day6/Adult_Day6_1.dialogue"),
	"Adult_Day6_2": preload("res://naratives/cutscenes/adult_day6/Adult_Day6_2.dialogue"),
	"Adult_Day6_3": preload("res://naratives/cutscenes/adult_day6/Adult_Day6_3.dialogue"),
	"Adult_Day6_4": preload("res://naratives/cutscenes/adult_day6/Adult_Day6_4.dialogue"),
	"Adult_Day6_5": preload("res://naratives/cutscenes/adult_day6/Adult_Day6_5.dialogue"),
	"Adult_Day7_1": preload("res://naratives/cutscenes/adult_day7/Adult_Day7_1.dialogue"),
	"Adult_Day7_2": preload("res://naratives/cutscenes/adult_day7/Adult_Day7_2.dialogue"),
	"Adult_Day7_3": preload("res://naratives/cutscenes/adult_day7/Adult_Day7_3.dialogue"),
	"Adult_Day7_4": preload("res://naratives/cutscenes/adult_day7/Adult_Day7_4.dialogue"),
	"Adult_Day7_5": preload("res://naratives/cutscenes/adult_day7/Adult_Day7_5.dialogue"),
	"Adult_Day8_1": preload("res://naratives/cutscenes/adult_day8/Adult_Day8_1.dialogue"),
	"Adult_Day8_2": preload("res://naratives/cutscenes/adult_day8/Adult_Day8_2.dialogue"),
	"Adult_Day8_3": preload("res://naratives/cutscenes/adult_day8/Adult_Day8_3.dialogue"),
}

const CAMERAS: Dictionary = {
}


# putar cutscene berdasarkan id. return false kalau tidak bisa diputar.
func play(id: String) -> bool:
	if not DIALOGUES.has(id):
		push_warning("Dialog cutscene tidak terdaftar: " + id)
		return false
	return CutsceneManager.play_once(id, DIALOGUES[id], id, CAMERAS.get(id, ""), id)

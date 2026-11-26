extends Node
# Daftar tugas per fase dan hari.
# Urutan main (cutscene -> task -> cutscene) ada di naratives/Story_Director.gd.
# Nama task di sini harus sama persis dengan yang dipakai Story_Director.

const DEFAULT_TODO: Array = [
	{
		"phase": "Kid",
		"days": [
			{"day": 1, "tasks": {
				"karpet_puzzle": false,
			}},
			{"day": 2, "tasks": {
				"main_ayunan": false,
				"kasih_makan_ikan": false,
			}},
			{"day": 3, "tasks": {
				"floor_is_lava": false,
			}},
			# canon event: hanya cutscene makan pasir
			{"day": 4, "event": true, "tasks": {}},
		],
	},
	{
		"phase": "Teen",
		"days": [
			{"day": 1, "tasks": {
				"tugas": false,
				"nyapu": false,
			}},
			{"day": 2, "tasks": {
				"jemur_baju": false,
				"tugas": false,
			}},
			{"day": 3, "tasks": {
				"tugas": false,
				"main_ayunan": false,
			}},
			{"day": 4, "tasks": {
				"tugas": false,
				"belajar_tutor_online": false,
			}},
			# canon event: UTBK
			{"day": 5, "event": true, "tasks": {
				"utbk": false,
			}},
		],
	},
	{
		"phase": "Adult",
		"days": [
			{"day": 1, "tasks": {
				"rapat_online": false,
				"ngepel": false,
			}},
			{"day": 2, "tasks": {
				"tugas_kantor": false,
				"lembur": false,
			}},
			{"day": 3, "tasks": {
				"rapat_online": false,
				"jemur_baju": false,
			}},
			{"day": 4, "tasks": {
				"tugas_kantor": false,
				"nyapu": false,
			}},
			{"day": 5, "tasks": {
				"rapat_online": false,
				"nyapu": false,
				"jemur_baju": false,
			}},
			{"day": 6, "tasks": {
				"tugas_kantor": false,
				"lembur": false,
				"nyapu": false,
				"kasih_makan_ikan": false,
			}},
			{"day": 7, "tasks": {
				"rapat_online": false,
				"jemur_baju": false,
				"ngepel": false,
				"tugas_kantor": false,
			}},
			# hari terakhir: hanya cutscene ending
			{"day": 8, "event": true, "tasks": {}},
		],
	},
]

static var todo_list: Array = DEFAULT_TODO.duplicate(true)


# dipanggil saat mulai game baru dari main menu
func reset() -> void:
	todo_list = DEFAULT_TODO.duplicate(true)


func get_tasks(phase: String, day: int) -> Dictionary:
	for phase_data in todo_list:
		if phase_data["phase"] != phase: continue
		for day_data in phase_data["days"]:
			if day_data["day"] == day:
				return day_data.get("tasks", {})
	return {}


func is_task_done(phase: String, day: int, task_name: String) -> bool:
	return get_tasks(phase, day).get(task_name, false)


func complete_task(phase: String, day: int, task_name: String) -> void:
	var tasks = get_tasks(phase, day)
	if tasks.has(task_name):
		tasks[task_name] = true
		GameManager.task_completed.emit()


func get_day_count(phase: String) -> int:
	for phase_data in todo_list:
		if phase_data["phase"] == phase:
			return phase_data["days"].size()
	return 0


func get_next_phase(phase: String) -> String:
	for i in todo_list.size():
		if todo_list[i]["phase"] == phase:
			if i + 1 < todo_list.size():
				return todo_list[i + 1]["phase"]
	return ""   # kosong = sudah fase terakhir

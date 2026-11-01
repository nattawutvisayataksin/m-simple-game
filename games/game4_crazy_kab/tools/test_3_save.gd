extends SceneTree
# test_3_save: record_run + corrupt-file safety (backup/restore real save file)

const SAVE_PATH := "user://taxi_best.json"

var _sim_t := 0.0
var _backup_txt := ""
var _backup_exists := false
var _phase := 0

func _initialize() -> void:
	_backup_exists = FileAccess.file_exists(SAVE_PATH)
	if _backup_exists:
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		_backup_txt = f.get_as_text()
		f.close()

func _finish(code: int, why: String) -> void:
	_delete_save()
	if _backup_exists:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		f.store_string(_backup_txt)
		f.close()
	if code == 0:
		print("TEST_SAVE ALL PASS")
	else:
		print("TEST_SAVE FAIL %s" % why)
	quit(code)

func _delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SAVE_PATH + ".tmp")

func _process(dt: float) -> bool:
	_sim_t += dt
	match _phase:
		0:
			_delete_save()
			var Save := load("res://scripts/save.gd")
			var b: Dictionary = Save.record_run(700, 9)
			# 700 > 500 means liz unlocked, 1200 not reached
			if int(b["best_cash"]) != 700 or int(b["best_rides"]) != 9:
				_finish(1, "basic record")
				return true
			var unl: Array = b["unlocked"]
			if not ("liz" in unl) or "golem" in unl:
				_finish(1, "unlock wrong: %s" % str(unl))
				return true
			_phase = 1
		1:
			# corrupt file: load must return defaults, then still record
			var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
			f.store_string("}{ broken json")
			f.close()
			var Save := load("res://scripts/save.gd")
			var b2: Dictionary = Save.load_best()
			if int(b2["best_cash"]) != 0 or not ("kubi" in (b2["unlocked"] as Array)):
				_finish(1, "corrupt not safe")
				return true
			var b3: Dictionary = Save.record_run(1500, 12)
			# fresh save: unlock liz + golem, best = 1500
			var unl2: Array = b3["unlocked"]
			if int(b3["best_cash"]) != 1500 or not ("golem" in unl2):
				_finish(1, "post-corrupt record wrong: %s" % str(b3))
				return true
			print("TEST_SAVE record/unlock/corrupt-safe PASS unlocked=%s" % str(unl2))
			_finish(0, "")
			return true
	if _sim_t > 10.0:
		_finish(1, "timeout phase=%d" % _phase)
		return true
	return false

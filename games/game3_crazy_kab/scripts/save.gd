extends Object
# save.gd — เก็บสถิติแท็กซี่ แบบ atomic (pattern เดียวกับ user://td_best.json ของเกม 2)
# ต้อง close() ทุกครั้ง (Windows ล็อกไฟล์เงียบ ๆ — กฎ repo)

const SAVE_PATH := "user://taxi_best.json"
const VERSION := 1

# คืน {best_cash, best_rides, unlocked:[...]} — อ่านพังแล้วคืนค่าเริ่ม ไม่พังเกม
static func load_best() -> Dictionary:
	var out := {"best_cash": 0, "best_rides": 0, "unlocked": ["kubi"], "version": VERSION}
	if not FileAccess.file_exists(SAVE_PATH):
		return out
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return out
	var txt := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY:
		return out
	if data.get("version", 0) != VERSION:
		return out   # เวอร์ชันเก่า — ล้างเริ่มใหม่ (กัน save เสีย)
	out["best_cash"] = int(data.get("best_cash", 0))
	out["best_rides"] = int(data.get("best_rides", 0))
	var unl: Variant = data.get("unlocked", ["kubi"])
	if typeof(unl) == TYPE_ARRAY:
		var arr := []
		for s: Variant in unl:
			if typeof(s) == TYPE_STRING and (s == "kubi" or s == "liz" or s == "golem"):
				arr.append(s)
		if not ("kubi" in arr):
			arr.append("kubi")
		out["unlocked"] = arr
	return out

# เขียน atomic: เขียน .tmp แล้ว rename ทับ
static func save_best(data: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)

const car_scene := preload("res://scripts/car.gd")

# รวมผลรอบเข้า save และคืนสถานะ best ใหม่ {best_cash, best_rides, unlocked, new_best_cash, new_unlock:[]}
static func record_run(cash: int, rides: int) -> Dictionary:
	var best := load_best()
	var new_best := cash > int(best["best_cash"])
	best["best_cash"] = maxi(cash, int(best["best_cash"]))
	best["best_rides"] = maxi(rides, int(best["best_rides"]))
	var unl: Array = best["unlocked"]
	var new_unlocked := []
	# เปิดรถใหม่อัตโนมัติเมื่อกำไรรวมถึงเกณฑ์ (DEFS ของ car.gd)
	for d: Dictionary in car_scene.DEFS:
		if cash >= int(d["unlock_cash"]) and not (d["id"] in unl):
			unl.append(d["id"])
			new_unlocked.append(d["name"])
	best["unlocked"] = unl
	save_best(best)
	best["new_best_cash"] = new_best
	best["new_unlocked"] = new_unlocked
	return best

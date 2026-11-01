extends Object
# save.gd — เก็บสถิติแท็กซี่ แบบ atomic (pattern เดียวกับ user://td_best.json ของเกม 2)
# ต้อง close() ทุกครั้ง (Windows ล็อกไฟล์เงียบ ๆ — กฎ repo)

const SAVE_PATH := "user://taxi_best.json"
const VERSION := 2
# ราคาอัปเกรดรถต่อเลเวล (0→1, 1→2, 2→3) — สูงสุด Lv3
const UP_COSTS := [400, 900, 1800]

# คืน {best_cash, best_rides, total_cash, unlocked:[...], upgrades:{...}, car_pick} — อ่านพังแล้วคืนค่าเริ่ม ไม่พังเกม
static func load_best() -> Dictionary:
	var out := {
		"best_cash": 0, "best_rides": 0, "total_cash": 0,
		"unlocked": ["kubi"], "upgrades": {"kubi": 0, "liz": 0, "golem": 0},
		"car_pick": "kubi", "version": VERSION,
	}
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
	if int(data.get("version", 0)) < 1:
		return out   # ไฟล์โบราณเกินหรือเสีย — ล้างเริ่มใหม่
	out["best_cash"] = int(data.get("best_cash", 0))
	out["best_rides"] = int(data.get("best_rides", 0))
	out["total_cash"] = int(data.get("total_cash", 0))
	var pick: Variant = data.get("car_pick", "kubi")
	if typeof(pick) == TYPE_STRING and (pick == "kubi" or pick == "liz" or pick == "golem"):
		out["car_pick"] = pick
	var unl: Variant = data.get("unlocked", ["kubi"])
	if typeof(unl) == TYPE_ARRAY:
		var arr := []
		for s: Variant in unl:
			if typeof(s) == TYPE_STRING and (s == "kubi" or s == "liz" or s == "golem"):
				arr.append(s)
		if not ("kubi" in arr):
			arr.append("kubi")
		out["unlocked"] = arr
	var ups: Variant = data.get("upgrades", {})
	if typeof(ups) == TYPE_DICTIONARY:
		var d := {"kubi": 0, "liz": 0, "golem": 0}
		for k: String in ["kubi", "liz", "golem"]:
			if ups.has(k):
				d[k] = clampi(int(ups[k]), 0, 3)
		out["upgrades"] = d
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
	best["total_cash"] = int(best["total_cash"]) + cash   # เงินสะสมรวมทุกกะ (ทุนซื้ออัปเกรด)
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

# ซื้ออัปเกรดรถ 1 เลเวลด้วยเงินสะสม (คืน best ล่าสุด + buy_ok/bought)
static func buy_upgrade(id: String) -> Dictionary:
	var best := load_best()
	var ok := false
	if id == "kubi" or id == "liz" or id == "golem":
		var lv: Dictionary = best["upgrades"]
		var cur := int(lv.get(id, 0))
		var cost: int = UP_COSTS[cur]
		if cur < 3 and int(best["total_cash"]) >= cost:
			lv[id] = cur + 1
			best["upgrades"] = lv
			best["total_cash"] = int(best["total_cash"]) - cost
			save_best(best)
			ok = true
	best["buy_ok"] = ok
	best["bought"] = id
	return best

# เลือกรถคันที่จะใช้กะถัดไป (เฉพาะคันที่ปลดล็อกแล้ว)
static func pick_car(id: String) -> void:
	var best := load_best()
	if id in (best["unlocked"] as Array):
		best["car_pick"] = id
		save_best(best)

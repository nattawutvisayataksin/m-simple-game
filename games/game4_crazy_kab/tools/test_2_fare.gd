extends SceneTree
# test_2_fare: trip lifecycle + money math
# A: fares: รับ → ส่ง -- fare = 50 + dist/10, mult ตาม % เวลาที่เหลือ
# B: หมดเวลา → ลูกหนี, rides_fail+1
# C: ป้าย 3 วง — จอดวงที่ 2 ต้องได้วงนั้น
# D: กะกลางคืน — ค่าโดยสาร x1.5
# E: ภารกิจ — _finish ให้โบนัส (เซฟถูกแตะ: backup → restore)
# ผ่านทุกรอบ = exit 0

const SAVE_PATH := "user://taxi_best.json"

var play: Node2D
var _sim_t := 0.0
var _phase := 0
var _bak_exists := false
var _bak_txt := ""
func _initialize() -> void:
	_bak_exists = FileAccess.file_exists(SAVE_PATH)
	if _bak_exists:
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		_bak_txt = f.get_as_text()
		f.close()
	play = Node2D.new()
	play.set_script(load("res://scripts/play.gd"))
	root.add_child(play)

func _restore() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SAVE_PATH + ".tmp")
	if _bak_exists:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		f.store_string(_bak_txt)
		f.close()

func _process(dt: float) -> bool:
	_sim_t += dt
	match _phase:
		0:
			# skip auto first passenger: clear & build manual trip
			play.trip = {}
			play.trip_active = false
			play.car.position = Vector2(170, 110)
			play.car.velocity = Vector2.ZERO
			play._new_trip()
			var dist: float = play.car.position.distance_to(play.trip["p"])
			# put car right at pickup
			play.car.position = play.trip["p"]
			play._update_trip(0.01)
			if not play.trip_active:
				print("TEST_FARE FAIL pickup not active d=%.1f" % dist)
				quit(1); return true
			_phase = 1
		1:
			# deliver: force left = 60% -> mult 2.0
			var fare: int = play.trip["fare"]
			play.trip["left"] = play.trip["limit"] * 0.6
			play.car.position = play.trip["drop"]
			play.car.velocity = Vector2.ZERO
			play._update_trip(0.01)
			if play.trip.is_empty() and play.cash > 0:
				# fare=50+d/10 mult2 => total=int(round(fare*2)) ~ >=100
				var ok_total: bool = play.cash >= 100
				print("TEST_FARE deliver cash=%d fare=%d rides=%d" % [play.cash, fare, play.rides_ok])
				if not ok_total or play.rides_ok != 1:
					print("TEST_FARE FAIL money math cash=%d rides=%d" % [play.cash, play.rides_ok])
					quit(1); return true
				_phase = 2
			elif _sim_t > 5.0:
				print("TEST_FARE FAIL deliver timeout trip=%s" % str(play.trip))
				quit(1); return true
		2:
			# timeout path: board then let timer expire
			play._new_trip()
			play.trip_active = true
			play.trip["left"] = 0.05
			play._update_trip(0.1)
			if play.trip.is_empty() and play.rides_fail == 1:
				print("TEST_FARE timeout-pass PASS fail=%d" % play.rides_fail)
				_phase = 3
			elif _sim_t > 8.0:
				print("TEST_FARE FAIL timeout path trip=%s fail=%d" % [str(play.trip), play.rides_fail])
				quit(1); return true
		3:
			# 3 ป้าย: สร้าง 3 วง จอดที่วงที่ 2 แล้วต้องได้ทริปวงนั้น + เหลือ 2 วง
			play.offers = []
			play.trip = {}
			play.trip_active = false
			play._new_trip()
			if play.offers.size() != 3:
				print("TEST_FARE FAIL offers=%d (ต้อง 3)" % play.offers.size())
				quit(1); return true
			var tgt: Dictionary = play.offers[1]
			play.car.position = tgt["p"]
			play.car.velocity = Vector2.ZERO
			play._update_trip(0.01)
			if not play.trip_active or play.trip["p"] != tgt["p"]:
				print("TEST_FARE FAIL pick-3 trip=%s tgt=%s" % [str(play.trip), str(tgt)])
				quit(1); return true
			if play.offers.size() != 2:
				print("TEST_FARE FAIL offers-after=%d (ต้อง 2)" % play.offers.size())
				quit(1); return true
			print("TEST_FARE offers-3 PASS")
			_phase = 4
		4:
			# กะกลางคืน: หยุด เอนจินเกมเดินเอง (เทสคุมจ่ายตัวเองแบบเฟรมเดียว) — เงินรีเซ็ต 0 จ่ายชัด ๆ
			play.set_process(false)
			play.cash = 0
			play.rides_ok = 0
			play.combo = 0
			play.night = true
			var fare4: int = int(play.offers[0]["fare"])
			play.trip = play.offers[0]
			play.trip["vip"] = false   # ล็อคลูกค้าธรรมดา (สูตรคาดหวังให้ถูกทุกรอบ — VIP x3 ยิงเทสตอนรับขึ้นตนเอง)
			play.trip_active = true
			play.car.position = play.trip["drop"]
			play.car.velocity = Vector2.ZERO
			play._update_trip(0.01)
			var exp2 := int(round(float(fare4) * 2.0 * 1.5))   # frac=1.0 → mult 2.0 × night 1.5
			if play.trip.is_empty() and play.cash == exp2:
				print("TEST_FARE night x1.5 PASS total=%d" % exp2)
				# ต่อทันที: stack VIP×3 × กลางคืน×1.5 ต้องจ่าย ×6 ของ fare (same offer, เวลาเต็ม → mult 2)
				var fare_v: int = int(play.offers[0]["fare"])
				play.trip = play.offers[0]
				play.trip["vip"] = true
				play.trip_active = true
				play.car.position = play.trip["drop"]
				play.car.velocity = Vector2.ZERO
				var exp9 := int(round(float(fare_v) * 2.0 * 1.5 * 3.0))
				play._update_trip(0.01)
				if play.cash - exp2 != exp9 or play.trip_active:
					print("TEST_FARE FAIL night-vip-stack cash=%d base=%d expect9=%d fare=%d" % [play.cash, exp2, exp9, fare_v])
					quit(1); return true
				print("TEST_FARE night-vip-stack x9 PASS +%d" % exp9)
				_phase = 5
			else:
				print("TEST_FARE FAIL night cash=%d expect=%d fare=%d rides=%d nearmiss=%d drift=%.1f" % [play.cash, exp2, fare4, play.rides_ok, play.nearmiss_n, play.drift_secs])
				quit(1); return true
		5:
			# ภารกิจ: _finish ต้องให้โบนัส (แตะเซฟจริง — restore ท้ายขั้น)
			play.missions = [{"id": "rides", "goal": 1, "reward": 151, "done": false}]
			play._finish()
			var mm: Array = play.over_info["missions"]
			if play.over_info["mission_bonus"].size() == 1 and bool(mm[0]["done"]):
				print("TEST_FARE mission-bonus PASS %s" % str(play.over_info["mission_bonus"]))
				_restore()
				print("TEST_FARE ALL PASS")
				quit(0); return true
			elif _sim_t > 14.0:
				_restore()
				print("TEST_FARE FAIL mission bonus=%s missions=%s" % [str(play.over_info.get("mission_bonus", [])), str(mm)])
				quit(1); return true
	if _sim_t > 10.0:
		print("TEST_FARE FAIL global timeout phase=%d" % _phase)
		quit(1); return true
	return false

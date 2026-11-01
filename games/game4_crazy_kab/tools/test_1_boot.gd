extends SceneTree
# test_1_boot: load main scene, click into play, verify car + HUD alive (exit 0 = pass)

var _main: Node2D
var _sim_t := 0.0
var _sid := 0

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)

func _process(dt: float) -> bool:
	_sim_t += dt
	match _sid:
		0:
			if _main.screen != 0:   # title
				print("TEST_BOOT FAIL title screen=%s" % String(_main.screen))
				quit(1); return true
			_sid = 1
		1:
			if _sim_t > 0.2:
				_main._click(4)   # SCR.PLAY
				_sid = 2
		2:
			if _main.play_node != null and _main.play_node.car != null:
				if _main.play_node.time_left > 100.0 and _main.play_node.traffic.size() > 0:
					print("TEST_BOOT PASS play=%s car_at=%s time=%.1f" % [_main.play_node, _main.play_node.car.position, _main.play_node.time_left])
					_main._click(7)   # กะฝึกขับ: เช็คเทรนเนอร์ 3 ขั้นต่อ
					_sid = 3
		3:
			if _main.play_node != null and _main.play_node.car != null and _main.play_node.tutor:
				var tu: Node2D = _main.play_node
				# หยุดเอนจินค่อยมานับเอง: _update_trip ตรงสุดวงจร (จอดช้าชนิดแน่ ๆ)
				tu.set_process(false)
				tu._new_trip()
				tu.trip_active = false
				# ขั้น 1: จอดช้าในวงป้าย = ขึ้นรถ → step 1
				tu.car.position = (tu.offers[0] as Dictionary)["p"]
				tu.car.velocity = Vector2.ZERO
				tu._update_trip(0.01)
				tu._update_tutor(0.01)
				if not tu.trip_active or tu.tut_step != 1:
					print("TEST_BOOT FAIL tut-step1 step=%s active=%s" % [str(tu.tut_step), str(tu.trip_active)])
					quit(1); return true
				# ขั้น 2: ส่งถึงหมุดฟ้า → step 2
				tu.car.position = tu.trip["drop"]
				tu.car.velocity = Vector2.ZERO
				tu._update_trip(0.01)
				tu._update_tutor(0.01)
				if tu.tut_step != 2 or tu.rides_ok != 1:
					print("TEST_BOOT FAIL tut-step2 step=%s rides=%d cash=%d" % [str(tu.tut_step), tu.rides_ok, tu.cash])
					quit(1); return true
				# ขั้น 3: ดริฟท์ 1.5 วิ → step 3 · เวลาต้องคง 2:00 (กะฝึกไม่มีวินาทีถอย)
				tu.car.drifting = true
				tu._update_tutor(1.5)
				if tu.tut_step != 3 or absf(tu.time_left - 120.0) > 0.01:
					print("TEST_BOOT FAIL tut-step3 step=%s time=%.2f" % [str(tu.tut_step), tu.time_left])
					quit(1); return true
				print("TEST_BOOT PASS tutor 3-steps rides=%d cash=%d time=%.1f" % [tu.rides_ok, tu.cash, tu.time_left])
				if tu.cash <= 0:
					print("TEST_BOOT FAIL tutor no-money")
					quit(1); return true
				print("TEST_BOOT ALL PASS")
				quit(0); return true
	if _sim_t > 10.0:
		print("TEST_BOOT FAIL timeout sid=%d play=%s screens=%s" % [_sid, _main.play_node, _main.screen])
		quit(1); return true
	return false

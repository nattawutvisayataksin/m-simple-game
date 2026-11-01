extends SceneTree
# test_2_fare: trip lifecycle + money math
# A: fares: รับ → ส่ง -- fare = 50 + dist/10, mult ตาม % เวลาที่เหลือ
# B: หมดเวลา → ลูกหนี, rides_fail+1
# ผ่านทุกรอบ = exit 0

var play: Node2D
var _sim_t := 0.0
var _phase := 0

func _initialize() -> void:
	play = Node2D.new()
	play.set_script(load("res://scripts/play.gd"))
	root.add_child(play)

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
				print("TEST_FARE ALL PASS")
				quit(0); return true
			elif _sim_t > 8.0:
				print("TEST_FARE FAIL timeout path trip=%s fail=%d" % [str(play.trip), play.rides_fail])
				quit(1); return true
	if _sim_t > 10.0:
		print("TEST_FARE FAIL global timeout phase=%d" % _phase)
		quit(1); return true
	return false

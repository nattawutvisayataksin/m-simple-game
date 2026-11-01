extends SceneTree
# test_4_audio: เพลงราตรี + จิ้งหรีดยามดึก (G16)
# A: เริ่มกะกลางคืน = start_music(true) สลับ stream MUSIC_NIGHT + set_ambience(true) จิ้งหรีดเล่น
# B: กลับเมนู (กลางวัน) = stream MUSIC_DAY + จิ้งหรีดหยุด
# C: กลางคืนอีกรอบแล้ว game_over() = ตัดเพลง + ตัดจิ้งหรีด (เหมือนจบกะ)
# ผ่านทั้งหมด = exit 0

var sfx: Node
var _sid := 0
var _sim_t := 0.0

func _initialize() -> void:
	sfx = Node.new()
	sfx.set_script(load("res://scripts/sfx.gd"))
	root.add_child(sfx)

func _process(dt: float) -> bool:
	_sim_t += dt
	match _sid:
		0:
			# เริ่มกะกลางคืน
			sfx.start_music(true)
			sfx.set_ambience(true)
			_sid = 1
		1:
			if _sim_t < 0.15:
				return false
			if sfx._music.stream != sfx.MUSIC_NIGHT or not sfx._amb.playing:
				print("TEST_AUDIO FAIL night stream=%s amb_play=%s" % [str(sfx._music.stream), str(sfx._amb.playing)])
				quit(1); return true
			print("TEST_AUDIO night-music+cricket PASS")
			# กลับเมนู: เป็นกลางวัน + เงียบ
			sfx.start_music(false)
			sfx.set_ambience(false)
			_sid = 2
		2:
			if _sim_t < 0.3:
				return false
			if sfx._music.stream != sfx.MUSIC_DAY or sfx._amb.playing:
				print("TEST_AUDIO FAIL day stream=%s amb_play=%s" % [str(sfx._music.stream), str(sfx._amb.playing)])
				quit(1); return true
			print("TEST_AUDIO day-music+silence PASS")
			# กลางคืนอีกรอบ แล้วจบกะ
			sfx.start_music(true)
			sfx.set_ambience(true)
			_sid = 3
		3:
			if _sim_t < 0.45:
				return false
			sfx.game_over(true)
			_sid = 4
		4:
			if _sim_t < 0.6:
				return false
			if sfx._amb.playing or sfx._music.playing:
				print("TEST_AUDIO FAIL over amb=%s music=%s" % [str(sfx._amb.playing), str(sfx._music.playing)])
				quit(1); return true
			print("TEST_AUDIO game-over cuts-sound PASS")
			print("TEST_AUDIO ALL PASS")
			quit(0); return true
	if _sim_t > 8.0:
		print("TEST_AUDIO FAIL timeout sid=%d" % _sid)
		quit(1); return true
	return false

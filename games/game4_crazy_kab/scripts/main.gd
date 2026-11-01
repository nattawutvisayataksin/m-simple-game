extends Node2D
# main.gd - title/menu: story, how-to, stats guide (per Game Director requirement)
# Thai strings kept on screen; kept short to avoid generation corruption

const PlayScript := preload("res://scripts/play.gd")
const SaveScript := preload("res://scripts/save.gd")
const SfxScript := preload("res://scripts/sfx.gd")

const CAR_TEXES := {
	"kubi": preload("res://assets/sprites/car_kubi.png"),
	"liz": preload("res://assets/sprites/car_liz.png"),
	"golem": preload("res://assets/sprites/car_golem.png"),
}
const CAR_IDS := ["kubi", "liz", "golem"]
const CAR_NAMES := {"kubi": "Kubi Cab", "liz": "กิ้งก่าซิ่ง", "golem": "โกเลมแท็กซี่"}
const CAR_UNLOCK := {"kubi": 0, "liz": 500, "golem": 1200}
# สถิติระดับฐาน (ตรง car.gd DEFS) — อัปเกรด Lv บวกบนนี้แบบเดียวกับ car.gd set_lv
const CAR_BASE := {"kubi": [380.0, 520.0, 620.0, 2.6], "liz": [440.0, 480.0, 520.0, 3.1], "golem": [310.0, 620.0, 900.0, 2.0]}
const CAR_ANG := PI * 0.75   # ภาพรถหันลงซ้าย 135° (ชุดเดียวกับ car.gd)

const W := 1152.0
const H := 648.0

enum SCR { TITLE, STORY, HOWTO, GUIDE, PLAY, OVER }

var screen: int = SCR.TITLE
var play_node: Node2D = null
var best := {}
var buttons := []            # [{rect, label, target}]
var mouse := Vector2.ZERO
var sfx: Node = null

func _ready() -> void:
	sfx = Node.new()
	sfx.name = "Sfx"
	sfx.set_script(SfxScript)
	add_child(sfx)
	best = SaveScript.load_best()
	_to_title()

func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		mouse = ev.position
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for b: Dictionary in buttons:
			if (b["rect"] as Rect2).has_point(mouse):
				_click(int(b["target"]))
				return
	elif ev is InputEventKey and ev.pressed:
		if screen != SCR.PLAY:
			if ev.keycode == KEY_ESCAPE and screen != SCR.TITLE:
				_to_title()

func _to_title() -> void:
	screen = SCR.TITLE
	best = SaveScript.load_best()   # รอบใหม่: โหลดเงินสะสม/อัปเกรด/รถที่เลือกล่าสุด
	if sfx != null:
		sfx.resume_music()
	if play_node != null:
		play_node.queue_free()
		play_node = null
	buttons = [
		{"rect": Rect2(W * 0.5 - 220, 250, 440, 48), "label": "เริ่มเล่น", "target": SCR.PLAY},
		{"rect": Rect2(W * 0.5 - 220, 306, 440, 42), "label": "เรื่องของเกม", "target": SCR.STORY},
		{"rect": Rect2(W * 0.5 - 220, 354, 440, 42), "label": "วิธีเล่น", "target": SCR.HOWTO},
		{"rect": Rect2(W * 0.5 - 220, 402, 440, 42), "label": "คู่มือค่าต่างๆ ของเกม", "target": SCR.GUIDE},
		{"rect": Rect2(W * 0.5 - 220, 450, 440, 42), "label": "รถและสถิติ", "target": SCR.OVER},
	]

func _click(t: int) -> void:
	if sfx != null:
		sfx.play("click")
	if t == SCR.PLAY:
		_start_play()
		return
	if t == SCR.OVER:
		screen = SCR.OVER
		_build_stat_buttons()
		return
	if t >= 20:   # เลือกรถประจำกะ (target 20+i ต่อคัน)
		SaveScript.pick_car(CAR_IDS[t - 20])
		best = SaveScript.load_best()
		_build_stat_buttons()
		return
	if t >= 10:   # ซื้ออัปเกรดรถ (target 10+i ต่อคัน)
		var res: Dictionary = SaveScript.buy_upgrade(CAR_IDS[t - 10])
		best = res
		if bool(res.get("buy_ok", false)):
			sfx.play("drop")
		_build_stat_buttons()
		return
	if t == SCR.TITLE:
		_to_title()
		return
	screen = t
	buttons = [{"rect": Rect2(W * 0.5 - 160, 580, 320, 44), "label": "กลับเมนูหลัก", "target": SCR.TITLE}]

func _build_stat_buttons() -> void:
	var bts := [{"rect": Rect2(W * 0.5 - 160, 560, 320, 44), "label": "กลับเมนูหลัก", "target": SCR.TITLE}]
	var unl: Array = best.get("unlocked", ["kubi"]) as Array
	for i in CAR_IDS.size():
		var id: String = CAR_IDS[i]
		if not (id in unl):
			continue
		var lv: int = int((best.get("upgrades", {}) as Dictionary).get(id, 0))
		var y := 208.0 + 122.0 * float(i)
		if str(best.get("car_pick", "kubi")) != id:
			bts.append({"rect": Rect2(620, y, 168, 38), "label": "ใช้คันนี้", "target": 20 + i})
		if lv < 3:
			var cost: int = SaveScript.UP_COSTS[lv]
			var afford: bool = int(best.get("total_cash", 0)) >= cost
			bts.append({"rect": Rect2(804, y, 250, 38), "label": ("อัปเกรด Lv%d (%d บาท)" % [lv + 1, cost]) if afford else ("ต้องการ %d บาท" % cost), "target": 10 + i})
	buttons = bts

func _start_play() -> void:
	if play_node != null:
		play_node.queue_free()
	play_node = Node2D.new()
	play_node.set_script(PlayScript)
	play_node.sfx = sfx
	play_node.best = best   # ยัดอู่ (car_pick + upgrades) ก่อน _ready สร้างรถ
	add_child(play_node)
	play_node.back_to_menu.connect(_to_title)
	if sfx != null:
		sfx.start_music()
		sfx.play("horn")
	screen = SCR.PLAY
	buttons = []

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.10, 0.12, 0.16))
	match screen:
		SCR.TITLE:
			_draw_title()
		SCR.STORY:
			_draw_story()
		SCR.HOWTO:
			_draw_howto()
		SCR.GUIDE:
			_draw_guide()
		SCR.OVER:
			_draw_stats()
		SCR.PLAY:
			if play_node == null or not play_node.playing:
				_to_title()

func _draw_title() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 330, 140), "แท็กซี่คู่ฟ้า", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 72, Color(1.0, 0.85, 0.25))
	draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 150, 190), "(Kubi Crazy Cab)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, Color(0.7, 0.9, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 210, 224), "หมดเวลา 120 วิ — รับส่งลูกค้าให้ได้เงินเยอะที่สุด", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.85, 0.85, 0.8))
	for b: Dictionary in buttons:
		var r: Rect2 = b["rect"]
		var hov: bool = r.has_point(mouse)
		draw_rect(r, Color(0.95, 0.78, 0.25) if hov else Color(0.16, 0.20, 0.28))
		draw_rect(r, Color(1.0, 1.0, 1.0, 0.35), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 24, r.position.y + 32), str(b["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(0.06, 0.07, 0.10) if hov else Color(0.92, 0.92, 0.9))
	var best_cash := int(best.get("best_cash", 0))
	draw_string(ThemeDB.fallback_font, Vector2(20, H - 22), "สถิติเงินดีสุด: %d บาท · เงินสะสมทุกกะ: %d บาท · ลูกค้าดีสุด: %d · รถปลดล็อก %d คัน (อู่ปุ่มรถและสถิติ)" % [best_cash, int(best.get("total_cash", 0)), int(best.get("best_rides", 0)), (best.get("unlocked", ["kubi"]) as Array).size()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.6, 0.85, 0.6))

func _page(title: String, lines: Array) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(90, 90), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 40, Color(1.0, 0.85, 0.25))
	var y := 140.0
	for line: Variant in lines:
		var text: String = str(line[0])
		var big: bool = line.size() > 1 and bool(line[1])
		draw_string(ThemeDB.fallback_font, Vector2(100, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20 if big else 16, Color(0.95, 0.93, 0.9) if big else Color(0.8, 0.85, 0.85))
		y += 42.0 if big else 30.0
	for b: Dictionary in buttons:
		var r: Rect2 = b["rect"]
		var hov: bool = r.has_point(mouse)
		draw_rect(r, Color(0.95, 0.78, 0.25) if hov else Color(0.16, 0.20, 0.28))
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 22, r.position.y + 29), str(b["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.06, 0.07, 0.10) if hov else Color(0.92, 0.92, 0.9))

func _draw_story() -> void:
	_page("เรื่องของเกม", [
		["หลังศึกปราสาทจบ (เกม 2) แผ่นดิน Kubi เริ่มฟื้น ประชาชนต้องการรถโดยสาร", true],
		["ฮีโร่หนุ่มจึงหันมาเปิดบริการแท็กซี่ชื่อ Kubi Cab รับส่งพลเมืองทุกสาย", false],
		["", false],
		["— วันนี้มีงานใหญ่: ลูกค้าเรียกรถกันทุกถนน เวลาแค่ 120 วิ", true],
		["สไลม์บานอยู่บนถนนทำให้รถหมดแรง โกเลมหินก็เดินข้ามรอบโค้ง", false],
		["ทำสถิติเงินใหม่ได้ช่วงหลัง รถ 'กิ้งก่าซิ่ง' และ 'โกเลมแท็กซี่' จะปลดล็อกลำดับถัดไป", false],
	])

func _draw_howto() -> void:
	_page("วิธีเล่น", [
		["ลูกศร/WASD = ขับ · Space = เบรกมือ (ดริฟท์ ได้ทิป)", true],
		["หยุดรถ (ช้ากว่า 70) ในวงหมุดเขียว = ลูกค้าขึ้นรถ", false],
		["หยุดในวงหมุดฟ้าก่อนเวลาหมด = ส่งสำเร็จ + ค่าโดยสาร", false],
		["", false],
		["ได้ทิปดีสุด: ส่งแล้วเหลือเวลา 50% ขึ้นไป = ค่าโดยสาร x2", true],
		["เฉียดรถคนอื่นเร็ว ๆ = +5 บาท · ดริฟท์ยาว = +10 · ผ่านแรมพ์เร็ว = +20", false],
		["ระวังของมีพิษ: แตะสไลม์ = รถช้า · ชนโกเลม = รถหมุน 1 วิ", false],
		["R = เริ่มใหม่ · ESC = กลับเมนู", false],
	])

func _draw_guide() -> void:
	_page("คู่มือค่าต่างๆ ของเกม", [
		["เวลา", true],
		["นาฬิกาเกม: 120 วิ · เวลาต่อทริป: 15 + ระยะ/60 วิ (18-45 วิ)", false],
		["", false],
		["ความเร็วรถ (px/วิ = มาในตัวเลขจะเปลี่ยนตามลำดับ)", true],
		["Kubi Cab: สูงสุด 380 · กิ้งก่าซิ่ง: 440 · โกเลมแท็กซี่: 310", false],
		["เร่ง: 520/480/620 · เบรก: 620/520/900 · เลี้ยว (rad/วิ): 2.6/3.1/2.0", false],
		["", false],
		["ค่าเงิน", true],
		["ค่าโดยสาร = 50 + (ระยะ/10) บาท · ทิปส่งเร็ว x2/x1.5/x1.0 ตาม % เวลาที่เหลือ", false],
		["ทิปลีลา: เฉียด +5 · ดริฟท์ทุก 0.8 วิ +10 · ผ่านแรมพ์เร็ว +20", false],
		["ปลดล็อก: เงินสะสม 500 = กิ้งก่าซิ่ง · 1,200 = โกเลมแท็กซี่", false],
		["", false],
		["อู่อัปเกรด (หน้ารถและอู่อัปเกรด)", true],
		["เงินทุกกะรวมกันสะสม = ซื้อเลเวลรถถาวร (ราคา 400/900/1800)", false],
		["แต่ละเลเวล: สปีด +8% · เร่ง/เบรก/เลี้ยว +6% · สูงสุด Lv3 — ใช้ทุกกะถัดไป", false],
	])

func _draw_stats() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(90, 90), "รถและอู่อัปเกรด", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 40, Color(1.0, 0.85, 0.25))
	draw_string(ThemeDB.fallback_font, Vector2(100, 126), "เงินสะสมทุกกะ: %d บาท · สถิติดีสุด: %d บาท · ส่งสำเร็จดีสุด: %d ตน" % [int(best.get("total_cash", 0)), int(best.get("best_cash", 0)), int(best.get("best_rides", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 19, Color(0.95, 0.85, 0.45))
	var unl: Array = best.get("unlocked", ["kubi"]) as Array
	var ups: Dictionary = best.get("upgrades", {}) as Dictionary
	var pick: String = str(best.get("car_pick", "kubi"))
	for i in CAR_IDS.size():
		var id: String = CAR_IDS[i]
		var lv: int = int(ups.get(id, 0))
		var y := 208.0 + 122.0 * float(i)
		draw_rect(Rect2(88, y - 32, 1000, 96), Color(0.14, 0.17, 0.24, 0.55))
		# สไปรต์รถ: ภาพหันลงซ้าย 135° => หมุนกลับ -CAR_ANG ให้หันขวา
		draw_set_transform(Vector2(148, y + 16), -CAR_ANG, Vector2(1.5, 1.5))
		draw_texture_rect(CAR_TEXES[id], Rect2(-24, -24, 48, 48), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if id in unl:
			var b: Array = CAR_BASE[id] as Array
			var nmc := Color(1.0, 0.9, 0.4) if pick == id else Color(0.93, 0.93, 0.9)
			var nm: String = str(CAR_NAMES[id]) + " · Lv%d" % lv
			if pick == id:
				nm += "  (รถประจำกะ)"
			draw_string(ThemeDB.fallback_font, Vector2(220, y - 2), nm, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 23, nmc)
			draw_string(ThemeDB.fallback_font, Vector2(220, y + 32), "สปีด %d · เร่ง %d · เบรก %d · เลี้ยว %.1f" % [float(b[0]) * (1.0 + 0.08 * float(lv)), float(b[1]) * (1.0 + 0.06 * float(lv)), float(b[2]) * (1.0 + 0.06 * float(lv)), float(b[3]) * (1.0 + 0.06 * float(lv))], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.72, 0.85, 0.9))
			if pick == id:
				draw_string(ThemeDB.fallback_font, Vector2(220, y + 56), "ระดับถัดไป: สปีด +8% · ที่เหลือ +6% ต่อเลเวล (สูงสุด Lv3)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.5, 0.62, 0.7))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(220, y), str(CAR_NAMES[id]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color(0.55, 0.6, 0.66))
			draw_string(ThemeDB.fallback_font, Vector2(220, y + 34), "ยังล็อก · ปลดล็อกตอนกะเดียวได้เงิน %d บาท" % int(CAR_UNLOCK[id]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.42, 0.48, 0.56))
	# ปุ่ม: ใช้คันนี้ / อัปเกรด / กลับเมนู (hover เหมือนหน้าแรก)
	for bt: Dictionary in buttons:
		var r: Rect2 = bt["rect"]
		var hov: bool = r.has_point(mouse)
		draw_rect(r, Color(0.95, 0.78, 0.25) if hov else Color(0.16, 0.20, 0.28))
		draw_rect(r, Color(1.0, 1.0, 1.0, 0.35), false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 14, r.position.y + 25), str(bt["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color(0.06, 0.07, 0.10) if hov else Color(0.92, 0.92, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(W * 0.5 - 260, 622), "ซื้อบ่อย ๆ — เลเวลรถถาวร ใช้ได้ทุกกะถัดไป", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color(0.55, 0.75, 0.6))

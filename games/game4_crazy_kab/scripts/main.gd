extends Node2D
# main.gd - title/menu: story, how-to, stats guide (per Game Director requirement)
# Thai strings kept on screen; kept short to avoid generation corruption

const PlayScript := preload("res://scripts/play.gd")
const SaveScript := preload("res://scripts/save.gd")

const W := 1152.0
const H := 648.0

enum SCR { TITLE, STORY, HOWTO, GUIDE, PLAY, OVER }

var screen: int = SCR.TITLE
var play_node: Node2D = null
var best := {}
var buttons := []            # [{rect, label, target}]
var mouse := Vector2.ZERO

func _ready() -> void:
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
	if t == SCR.PLAY:
		_start_play()
	elif t == SCR.OVER:
		screen = SCR.OVER
		buttons = [{"rect": Rect2(W * 0.5 - 160, 560, 320, 44), "label": "กลับเมนูหลัก", "target": SCR.TITLE}]
	else:
		screen = t
		buttons = [{"rect": Rect2(W * 0.5 - 160, 580, 320, 44), "label": "กลับเมนูหลัก", "target": SCR.TITLE}]

func _start_play() -> void:
	if play_node != null:
		play_node.queue_free()
	play_node = Node2D.new()
	play_node.set_script(PlayScript)
	add_child(play_node)
	play_node.back_to_menu.connect(_to_title)
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
	draw_string(ThemeDB.fallback_font, Vector2(20, H - 22), "สถิติเงินดีสุด: %d บาท · ลูกค้าดีสุด: %d · รถปลดล็อกแล้ว %d คัน" % [best_cash, int(best.get("best_rides", 0)), (best.get("unlocked", ["kubi"]) as Array).size()], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color(0.6, 0.85, 0.6))

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
	])

func _draw_stats() -> void:
	_page("รถและสถิติ", [
		["สถิติเงินดีสุด: %d บาท" % int(best.get("best_cash", 0)), true],
		["ลูกค้าส่งสำเร็จดีสุด: %d ตน" % int(best.get("best_rides", 0)), false],
		["รถที่ปลดล็อก:", true],
		[str(",".join(best.get("unlocked", ["kubi"]) as Array)), false],
		["", false],
		["กิ้งก่าซิ่ง: ปลดล็อกตอนได้เงินรอบ 500 ขึ้นไป", false],
		["โกเลมแท็กซี่: ปลดล็อกตอนได้เงินรอบ 1,200 ขึ้นไป", false],
	])

extends Control
## Title screen: เมนูหลัก 3 ตัว — เริ่มเล่น / วิธีเล่น (ตัวละคร+มอนสเตอร์) / เนื้อเรื่อง
## ↑↓ (หรือ W/S) เลือกเมนู · Space/Enter ยืนยัน · ←/→ (หรือ A/D) เปลี่ยนสกิน (เซฟทันที)
## เปิดแผงคู่มือ/เนื้อเรื่องแล้ว กด Esc หรือ Space เพื่อกลับเมนู

const MAIN_SCENE := "res://scenes/main.tscn"
const SAVE_PATH := "user://kubi_coin_dash_save.json"
const SAVE_VERSION := 1

# สกินฮีโร่ (ดัชนีกับ player.gd: 0=คลาสสิก, 1=สายน้ำฟ้า, 2=อัคคีราช, 3=ม่วงราตรี, 4=ใบไม้ระยิบ)
const SKIN_NAMES: Array[String] = ["คลาสสิก", "สายน้ำฟ้า", "อัคคีราช", "ม่วงราตรี", "ใบไม้ระยิบ"]
const SKIN_SHEETS: Array[String] = [
	"res://assets/art/sprites/kubi_hero_run_sheet.png",
	"res://assets/art/gen/kubi_hero_run_sheet_cyan.png",
	"res://assets/art/gen/kubi_hero_run_sheet_ember.png",
	"res://assets/art/gen/kubi_hero_run_sheet_violet.png",
	"res://assets/art/gen/kubi_hero_run_sheet_leaf.png",
]
# พรีวิวตัดเฟรมยืน (เฟรมที่ 9 จากชีต 9 เฟรมความกว้าง 64px) — ไม่ใช่ชีตทั้งแถว
const PREVIEW_FRAME := Rect2(512, 0, 64, 64)

const MENU_ITEMS: Array[String] = [
	"เริ่มเล่น",
	"วิธีเล่น · ตัวละคร & มอนสเตอร์",
	"Story · เนื้อเรื่องของเกม",
]

# ไอคอนสปรไตร์ที่ใช้ในแผงคู่มือ
const ICON_HERO := "res://assets/art/sprites/kubi_hero_run.png"
const ICON_COIN := "res://assets/art/sprites/coin_kub.png"
const ICON_WALKER := "res://assets/art/sprites/enemy_glitch_side.png"
const ICON_HOPPER := "res://assets/art/sprites/enemy_glitch_blue.png"
const ICON_BAT := "res://assets/art/gen/enemy_bat.png"
const ICON_CHARGER := "res://assets/art/gen/enemy_charger.png"

enum UiState { MENU, PANEL }

@onready var prompt: Label = $Prompt
@onready var hero: TextureRect = $Hero
@onready var stats_line: Label = $StatsLine

var _blink := 0.0
var _skin := 0
var _skin_line: Label
var _menu_box: VBoxContainer
var _menu_items: Array[Label] = []
var _sel := 0
var _state := UiState.MENU
var _dim: ColorRect
var _howto_panel: PanelContainer
var _story_panel: PanelContainer
var _panels: Array[PanelContainer] = []

func _ready() -> void:
	var stats := _load_stats()
	if stats.has("hi_score") and int(stats["hi_score"]) > 0:
		stats_line.text = "สถิติสูงสุด %d · ชนะ %d/%d" % [int(stats["hi_score"]), int(stats["wins"]), int(stats["plays"])]
	_skin = clampi(int(stats.get("skin", 0)), 0, SKIN_NAMES.size() - 1)
	_skin_line = Label.new()
	_skin_line.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_skin_line.position = Vector2(0, -96)
	_skin_line.offset_left = -260
	_skin_line.offset_right = 260
	_skin_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skin_line.add_theme_font_size_override("font_size", 24)
	_skin_line.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	_skin_line.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.02))
	_skin_line.add_theme_constant_override("outline_size", 8)
	add_child(_skin_line)
	_refresh_skin()
	_build_menu()
	_build_panels()
	var tw := create_tween().set_loops()
	tw.tween_property(hero, "position:y", -16.0, 1.1).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(hero, "position:y", 16.0, 1.1).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	_blink += delta
	prompt.modulate.a = 0.55 + 0.45 * absf(sin(_blink * 2.4))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match _state:
			UiState.MENU:
				if event.keycode in [KEY_UP, KEY_W]:
					_sel = wrapi(_sel - 1, 0, MENU_ITEMS.size())
					_refresh_menu()
				elif event.keycode in [KEY_DOWN, KEY_S]:
					_sel = wrapi(_sel + 1, 0, MENU_ITEMS.size())
					_refresh_menu()
				elif event.keycode in [KEY_LEFT, KEY_A]:
					_change_skin(-1)
				elif event.keycode in [KEY_RIGHT, KEY_D]:
					_change_skin(1)
				elif event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
					_confirm()
			UiState.PANEL:
				if event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
					_close_panel()
	elif event is InputEventMouseButton and event.pressed and _state == UiState.MENU:
		_persist_skin()
		_start()

# ---------- เมนูหลัก ----------

func _build_menu() -> void:
	_menu_box = VBoxContainer.new()
	_menu_box.name = "MainMenu"
	_menu_box.set_anchors_preset(Control.PRESET_CENTER)
	_menu_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_menu_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_menu_box.offset_left = -220.0
	_menu_box.offset_right = 220.0
	_menu_box.offset_top = 56.0
	_menu_box.offset_bottom = 176.0
	_menu_box.add_theme_constant_override("separation", 6)
	add_child(_menu_box)
	for text in MENU_ITEMS:
		var l := Label.new()
		l.text = text
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(440, 36)
		l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color(0.14, 0.08, 0.02))
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
		_menu_items.append(l)
		_menu_box.add_child(l)
	_refresh_menu()

func _refresh_menu() -> void:
	for i in range(_menu_items.size()):
		var l := _menu_items[i]
		var sel := i == _sel
		l.text = ("▶  %s" % MENU_ITEMS[i]) if sel else MENU_ITEMS[i]
		l.add_theme_font_size_override("font_size", 30 if sel else 26)
		l.add_theme_color_override("font_color", Color(1.0, 0.83, 0.28) if sel else Color(1, 1, 1, 0.72))

func _confirm() -> void:
	match _sel:
		0:
			_persist_skin()
			_start()
		1:
			_open_panel(_howto_panel)
		2:
			_open_panel(_story_panel)

# ---------- แผงคู่มือ / เนื้อเรื่อง ----------

func _build_panels() -> void:
	_dim = ColorRect.new()
	_dim.name = "PanelDim"
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.03, 0.08, 0.5)
	_dim.visible = false
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	_howto_panel = _make_panel("คู่มือการเล่น", _build_howto_text())
	_story_panel = _make_panel("เนื้อเรื่อง", _build_story_text())
	_panels.append(_howto_panel)
	_panels.append(_story_panel)

func _make_panel(head_text: String, body_text: String) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_FULL_RECT)
	pc.offset_left = 90.0
	pc.offset_right = -90.0
	pc.offset_top = 44.0
	pc.offset_bottom = -44.0
	pc.visible = false
	pc.add_theme_stylebox_override("panel", _panel_style())
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)
	var head := Label.new()
	head.text = "◆ %s" % head_text
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 32)
	head.add_theme_color_override("font_color", Color(1.0, 0.84, 0.3))
	head.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02))
	head.add_theme_constant_override("outline_size", 10)
	vb.add_child(head)
	var body := RichTextLabel.new()
	body.name = "Body"
	body.bbcode_enabled = true
	body.text = body_text
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0, 280)
	body.add_theme_font_size_override("normal_font_size", 21)
	body.add_theme_font_size_override("bold_font_size", 21)
	body.add_theme_color_override("default_color", Color(0.95, 0.95, 0.9))
	vb.add_child(body)
	var hint := Label.new()
	hint.text = "กด Esc หรือ Space เพื่อกลับเมนู"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	vb.add_child(hint)
	add_child(pc)
	return pc

func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.15, 0.97)
	sb.border_color = Color(1.0, 0.83, 0.32, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 14
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 22
	sb.content_margin_bottom = 18
	return sb

func _open_panel(p: PanelContainer) -> void:
	_state = UiState.PANEL
	_dim.visible = true
	for pp in _panels:
		pp.visible = false
	p.visible = true

func _close_panel() -> void:
	_state = UiState.MENU
	_dim.visible = false
	for pp in _panels:
		pp.visible = false

func _build_howto_text() -> String:
	return """[color=#ffd94a][b]ปุ่มควบคุม[/b][/color]
• A / D หรือ ← → : เดินซ้าย-ขวา
• Space / W / ↑ : กระโดด — [color=#7ee6a2][b]กดซ้ำกลางอากาศได้อีก 2 ชั้น[/b][/color] (กดค้าง = สูง, ปล่อยกลางคัน = กระโดดสั้น)
• Shift : วิ่งเร็ว — จำเป็นกับช่องกว้างในด่านท้าย
• R : เริ่มด่านใหม่ · Esc : กลับหน้าเมนู

[color=#ffd94a][b]เป้าหมาย[/b][/color]
[img=34x34]%s[/img] เหรียญเงิน 1 คะแนน · มี [color=#ffd94a]เหรียญทองคุ้ม 3 คะแนน[/color] ซ่อนในแต่ละด่าน
เก็บเหรียญ เหยียบหัวศัตรู แล้วไปแตะ[color=#ffd94a]เสาธงชัยทอง[/color]ตอนจบด่าน — ห้ามหมดเวลาและห้ามตกหุบเหว
ข้ามด้วย [b]ดับเบิลจัมพ์[/b]: กระโดดจากพื้น แล้วกด Space อีกสองระลอกกลางอากาศ เก็บเหรียญชั้นสูงได้สบาย

[color=#ffd94a][b]ตัวละคร[/b][/color]
[img=48x48]%s[/img]  [color=#7ee6a2][b]Kubi[/b][/color] — หุ่นเหรียญหัวใจอบอุ่นผู้รับภารกิจตามคืนเหรียญเมือง
เลือกสกินได้ 5 แบบ: คลาสสิก · สายน้ำฟ้า · อัคคีราช · ม่วงราตรี · ใบไม้ระยิบ (กด ← → ที่หน้าเมนูนี้)

[color=#ffd94a][b]มอนสเตอร์ทั้ง 5[/b][/color] (ทุกตัวเหยียบหัวได้!)
[img=44x44]%s[/img]  [b]ไวรัสกลิตช์[/b] — เดินกดขอบพื้นสลับทาง เหยียบหัวแล้วเด้งสูงพิเศษ ใช้ทำบันไดได้
[img=44x44]%s[/img]  [b]ฮอปเปอร์[/b] — กระโดดเข้าหาคุณเป็นจังหวะ จับจังหวะจ่อคิวลงเหยียบ
[img=44x44]%s[/img]  [b]บัตบิต[/b] — บินลอยขึ้นลงเหนือช่องทาง รอตอนมันลอยต่ำสุดแล้วกระโดดเหยียบ
[img=44x44]%s[/img]  [b]ชาร์เจอร์[/b] — แมลงแดงรุกไล่! เห็นคุณระดับเดียวจะวิ่งสุดตัว ให้มันชนกำแพงแล้วมึนงงสักครู่ ค่อยข้าม
[color=#ff8a8a][img=44x44]%s[/img]  [b]บิตคูผู้คุม[/b] (มินิบอส ด่าน 8) — ตัวมหึมา HP 3 ดำดิ่งพุ่งใส่ทุก 4 วิ ให้เหยียบครบ 3 ครั้ง ชนะแล้วเหรียญรางวัลกระจายเต็มยอดปราสาท[/color]

[color=#7ee6a2][b]เทคเด็ด[/b][/color]
ใช้ดับเบิลจัมพ์ครบ 2 ชั้นทันทีที่ร่วง = ไต่กลับขึ้นแพลตฟอร์มได้เกือบเท่าเดิมเสมอ · เหยียบศัตรูต่อกันเป็นบันไดเก็บเหรียญฟ้า
""" % [ICON_COIN, ICON_HERO, ICON_WALKER, ICON_HOPPER, ICON_BAT, ICON_CHARGER, ICON_BAT]

func _build_story_text() -> String:
	return """เมือง [color=#ffd94a]KUB[/color] — เมืองแห่งโรงหล่อเหรียญ... เย็นวันหนึ่ง ฝูงไวรัส [color=#ff8a8a][b]"Glitch Bugs"[/b][/color]
บุกโรงหล่อเหรียญ ขโมย [color=#ffd94a][b]เหรียญกองทุนเมืองทั้งกอง[/b][/color] แล้วหนีกระจายไปหลบ 3 ที่ลับ:
ท่อระบายน้ำใต้เมือง · แพลตฟอร์มลอยเหนือท้องฟ้า · [b]ปราสาทบิตคู[/b] ป้อมสุดท้ายของมัน

[color=#7ee6a2][b]Kubi[/b][/color] หุ่นเหรียญน้อยหัวใจอบอุ่น อาสาออกเดินทางตามคืนเหรียญทั้งกอง — 8 ด่านสู่ธงชัย
จาก[color=#ffd94a]ถนนสายเอิ้น[/color]ของเมือง ผ่าน[color=#7ee6a2]ทุ่งเหรียญเขียว[/color] ลงลึก[color=#6fc9d8]ป่าไวรัสหนา[/color]
ข้าม[color=#6fc9d8]หุบเหวแตกร้าว[/color]ที่พื้นแหกสลาย ไต่[color=#ffd94a]ยอดเขาโรงหล่อเหรียญ[/color]

แล้วดำลงสู่[color=#2fc9b0]ท่อระบายบิต[/color]ใต้เมือง — บัตบิตลอยระส่ำ ชาร์เจอร์พุ่งใส่พร่าเมฆ
ขึ้นสู่[color=#6db9ef]ท้องฟ้าเมฆเด้ง[/color]ที่แพลตฟอร์มลอยสั่น ก่อนไต่ยอด[color=#8a6bd8]ปราสาทบิตคู[/color]
ที่นั่น [color=#ff8a8a][b]บิตคูผู้คุม[/b][/color] มินิบอสตัวมหึมายืนขวางเสาธงชัยทอง — เหยียบให้จบ แล้วธงจะเป็นของคุณ

ชนะ = เหรียญกองทุนเมืองกลับมาครบทุกเหรียญ Kubi แจกโรงหล่อเหรียญ... และฝนเหรียญฉลองจะร่วงเต็มฟากฟ้า
ทุกเหรียญที่คืนมา คือรอยยิ้มของชาวเมือง KUB — และเรื่องราวของ Kubi จะถูกจารึกบนเสาอนุสาวรีย์ของเมืองนี้
"""

func _change_skin(step: int) -> void:
	_skin = wrapi(_skin + step, 0, SKIN_NAMES.size())
	_refresh_skin()

func _refresh_skin() -> void:
	if _skin_line != null:
		_skin_line.text = "◀ สกิน: %s ▶   (ลูกศรซ้าย/ขวาเปลี่ยน)" % SKIN_NAMES[_skin]
	var sheet: Texture2D = load(SKIN_SHEETS[_skin])
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = PREVIEW_FRAME
	hero.texture = at

func _persist_skin() -> void:
	var d := {}
	if FileAccess.file_exists(SAVE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary:
			d = parsed
	d["skin"] = _skin
	d["version"] = SAVE_VERSION
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
		f.close()

func _start() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)

func _load_stats() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return data if data is Dictionary else {}

extends Node2D
# หอคอยคู่ฟ้า (Kub Kingdom Rush) - ฉากหลัก
# ฉากเดียว 1152x648: มอนออกจากประตูซ้ายบน เดินอ้อมสนามหลายช่วงก่อนเข้าปราสาทขวาบน
# แก้เดินซ้อน: มอนแต่ละตัวเลื่อนข้างถนนสลับซ้าย/ขวา ±13px + สุ่มความเร็ว ±8%

const EnemyScript := preload("res://scripts/enemy.gd")
const TowerScript := preload("res://scripts/tower.gd")
const FROG_TEX := preload("res://assets/art/gen/frog.png")
const FROG_SHEET := preload("res://assets/art/gen/frog_sheet.png")
const LIZARD_TEX := preload("res://assets/art/gen/lizard_front.png")
const LIZARD_SHEET := preload("res://assets/art/gen/lizard_sheet.png")
const LIZARD_SIDE_SHEET := preload("res://assets/art/gen/lizard_side_sheet.png")  # T5.1 ชุดหันข้าง 8 ช่อง (หัวหันขวาโดยกำเนิด)
const GOLEM_TEX := preload("res://assets/art/gen/stone_golem.png")
# Phase C: มอนใหม่ — ค้างคาวบิน / สไลม์ปาแตก / แชแมนฮีล / บอส Kubit
const BAT_TEX := preload("res://assets/art/gen/bat_flyer.png")
const SLIME_TEX := preload("res://assets/art/gen/slime_splitter.png")
const SHAMAN_TEX := preload("res://assets/art/gen/shaman_healer.png")
const BOSS_TEX := preload("res://assets/art/gen/boss_kubit.png")
# NB: lizard_side_sheet.png เคยเก็บเป็น stock (ตัดสิน T3.2 ใช้ชุดหน้าตรง) — ฟีดแบ็ค T5.1 สลับกลับมาใช้จริง ช่วงเดินแนวนอน
const TOWER_ARCHER_TEX := preload("res://assets/art/gen/tower_archer.png")
const TOWER_CANNON_TEX := preload("res://assets/art/gen/tower_cannon.png")
const TOWER_MAGE_TEX := preload("res://assets/art/gen/tower_mage.png")
const TOWER_BARRACKS_TEX := preload("res://assets/art/gen/tower_barracks.png")  # Phase B ค่ายทหาร
const ICON_BOW := preload("res://assets/art/icons/bow.png")
const ICON_CANNON := preload("res://assets/art/icons/cannon.png")
const ICON_MAGE := TOWER_MAGE_TEX
const ICON_COIN := preload("res://assets/art/icons/coin.png")
const ICON_HEART := preload("res://assets/art/icons/heart.png")
const ICON_UPG_BOW := preload("res://assets/art/icons/upg_bow.png")       # T5 ไอคอนอัปเกรดป้อมธนู
const ICON_UPG_HAMMER := preload("res://assets/art/icons/upg_hammer.png") # T5 ไอคอนอัปเกรดปืนใหญ่
const ICON_SCROLL := preload("res://assets/art/icons/scroll.png")         # ย้ายจุดยืนทหาร
const ICON_TARGET := preload("res://assets/art/icons/target.png")        # Phase D: โหมดเล็ง (First/Last/Strong/Weak)
const MAP_A_TEX := preload("res://assets/art/kub_kingdom_map_v2.png")
const MAP_B_TEX := preload("res://assets/art/kub_kingdom_map_v3.png")     # Phase E: แผนที่ 2 (gen สุสาน+ปราสาท)
const BEST_PATH := "user://td_best.json"   # Phase E: save คลื่นสูงสุด (atomic write)

# แผนที่ต่อตัวเลือก: ชื่อ / ภาพ / เส้นทางมอน / ลานป้อม (4 จุด)
const MAPS := [
	{"name": "ป่า Kubi", "tex": MAP_A_TEX, "path": PATH_A, "spots": TOWER_SPOTS},
	{"name": "สุสานหลวง", "tex": MAP_B_TEX, "path": PATH_B, "spots": TOWER_SPOTS_B},
]
const HeroScript := preload("res://scripts/hero.gd")                     # T5 ฮีโร่ Kubi
const SfxScript := preload("res://scripts/sfx.gd")                       # T6 ระบบเสียง

var _audio                                                                # Sfx node (เรียกผ่าน method sfx())

# ตารางป้อม (T3): ค่าบาลานซ์รวมที่เดียวจูนง่าย - ราคา/ดาเมจ/คูลดาวน์/รัศมี/ความเร็วกระสุน/ระเบิดกระจุก
const TOWER_DEFS := {
	"archer": {
		"name": "ป้อมธนู", "cost": 90, "kind": TowerScript.ARCHER,
		"tex": TOWER_ARCHER_TEX, "icon": ICON_BOW,
		"dmg": 9.0, "interval": 0.75, "range": 170.0, "shot": 300.0, "splash": 0.0,
		# T5: อัปเกรด Lv2 (ยิงเร็วไกลขึ้น)
		"upg_cost": 70, "upg_icon": ICON_UPG_BOW,
		"upg": {"dmg": 15.0, "interval": 0.6, "range": 200.0, "shot": 330.0, "splash": 0.0},
	},
	"cannon": {
		"name": "ปืนใหญ่", "cost": 150, "kind": TowerScript.CANNON,
		"tex": TOWER_CANNON_TEX, "icon": ICON_CANNON,
		"dmg": 30.0, "interval": 1.7, "range": 200.0, "shot": 220.0, "splash": 70.0,
		# T5: อัปเกรด Lv2 (ระเบิดหนัก บอดใหญ่)
		"upg_cost": 110, "upg_icon": ICON_UPG_HAMMER,
		"upg": {"dmg": 50.0, "interval": 1.45, "range": 225.0, "shot": 220.0, "splash": 85.0},
	},
	"mage": {
		"name": "ป้อมเวท", "cost": 130, "kind": TowerScript.MAGE,
		"tex": TOWER_MAGE_TEX, "icon": ICON_MAGE,
		"dmg": 18.0, "interval": 1.1, "range": 185.0, "shot": 280.0, "splash": 0.0,
		"upg_cost": 100, "upg_icon": ICON_MAGE,
		"upg": {"dmg": 30.0, "interval": 0.95, "range": 210.0, "shot": 320.0, "splash": 0.0},
	},
	# Phase B: สายที่ 4 ตาม GDD (สีฟ้า) — ไม่ยิง แต่เจนทหารบล็อกทาง
	"barracks": {
		"name": "ค่ายทหาร", "cost": 110, "kind": TowerScript.BARRACKS,
		"tex": TOWER_BARRACKS_TEX, "icon": TOWER_BARRACKS_TEX,
		"dmg": 10.0, "interval": 0.8, "range": 130.0, "shot": 0.0, "splash": 0.0,
		"upg_cost": 90, "upg_icon": TOWER_BARRACKS_TEX,
		"upg": {"dmg": 16.0, "interval": 0.66, "range": 140.0, "shot": 0.0, "splash": 0.0},
	},
}
const SELL_REFUND := 0.6   # T5 ขายป้อมคืน 60% ของเงินที่ลงไป (สร้าง + อัปเกรด)

# หมุดโลก (ฉากเดียว 1152x648): ประตูม่วงซ้ายบน -> เส้นทางวกวน -> ประตูปราสาทขวาบน
const PATH_A: Array[Vector2] = [
	Vector2(258, 190),
	Vector2(258, 510),
	Vector2(390, 510),
	Vector2(390, 380),
	Vector2(540, 380),
	Vector2(540, 510),
	Vector2(700, 510),
	Vector2(850, 510),
	Vector2(850, 450),
	Vector2(810, 450),
]

# ลานจุดวางป้อม 4 จุด (หญ้าว่างการันตีบนฉากเดียว)
const TOWER_SPOTS: Array[Vector2] = [
	Vector2(160, 445),  # ยุ่มหญ้าทุ่งซ้าย (เลี่ยงต้นไม้กลุ่มบน - ว่างจริง)
	Vector2(420, 615),  # ใต้โค้งเลี้ยวขวา
	Vector2(395, 285),  # ยุ่มหญ้าระหว่างถนนตั้งกับต้นไม้ต้นใหญ่ (เดิม (620,350) ทับปราสาท - ฟีดแบ็ค T4.1)
	Vector2(815, 607),  # ช่องหญ้าด้านล่างต่อจากแขนถนนเข้าปราสาท (เลี่ยงต้นไม้สองกลุ่ม ล่างขวา)
]

const SPOT_HIT_R := 44.0    # T5.1 คลิกอ้อมเผื่อ (เดิม 32 = ต้องคลิกเป๊ะ ๆ หาจุดไม่เจอ)
const GATE_COLOR := Color(0.55, 0.25, 0.80, 0.80)
const CASTLE_COLOR := Color(1.0, 0.35, 0.15, 0.85)

# Phase E: แผนที่ 2 "สุสานหลวง" — ผังเลี่ยงสระ (ภาพ gen 256x144 ยืด ×4.5):
# สุสานซ้ายบน = ปากมอน, ตัวปราสาทใหญ่ขวาบน = ปลายทาง (ประตูปราสาท ≈ (850,380))
const PATH_B: Array[Vector2] = [
	Vector2(258, 140),
	Vector2(258, 460),
	Vector2(680, 460),
	Vector2(680, 240),
	Vector2(770, 240),
	Vector2(770, 380),
	Vector2(850, 380),
]
const TOWER_SPOTS_B: Array[Vector2] = [
	Vector2(340, 370),  # หญ้าใต้กุมภะเล็ก - คลุมแนวตั้งซ้าย + ตัดกลุ่มบน
	Vector2(490, 520),  # ใต้แนวนอน y460 กลางล่าง
	Vector2(760, 360),  # กลางขวา - คลุม 770 ตั้ง + สูงสุด 240
	Vector2(895, 455),  # หน้ารั้วปราสาทขวา (เลี่ยงถนนที่วิ่งเข้าประตู)
]

const FROG_SPEED := 35.0
const LIZARD_SPEED := 60.0
const GOLEM_SPEED := 27.0
const GOLEM_HP := 95.0
const GOLEM_RESIST := 0.65
# Phase C สเตตมอนใหม่ (hp คูณ hp_mult ตามคลื่นเหมือนเดิม)
const BAT_SPEED := 55.0
const SLIME_SPEED := 30.0
const SHAMAN_SPEED := 25.0
const BOSS_SPEED := 17.0
const BOSS_HP := 1200.0     # hp สุดท้าย ~ 1200 * hp_mult ; หัวหน้ากองคลื่นสุดท้าย
const START_LIVES := 20
const LANE_OFFSET := 13.0  # ระยะเลื่อนข้างถนนต่อมอน (กันซ้อนตึงตึว)

# T4 ระบบคลื่น: หัวใจคลื่นเป็นข้อมูล + เลือดโต 1.15^คลื่น + โบนัสจบคลื่น
# + ปุ่มเรียกคลื่นถัดไปก่อนได้โบนัสตามวินาทีคงเหลือ (ตัดสินใจเสี่ยง) + ชนะ/แพ้
const SPD_GAP := 1.3             # ช่วงห่างเกิดรายตัวในคลื่น (วิ)
const HP_GROWTH := 1.15          # เลือดโตต่อคลื่น
const WAVE_PREP := 7.0           # นับถอยหลังก่อนคลื่นถัดไป
const FIRST_PREP := 10.0         # ก่อนคลื่นแรก: เผื่อเวลาสร้างป้อมแรก
const EARLY_BONUS_PER_SEC := 3.0 # ทองโบนัสต่อวินาทีที่ยังเหลือตอนเรียกก่อน
const WAVE_BONUS_BASE := 25      # โบนัสจบคลื่น = base + (คลื่นที่ * step)
const WAVE_BONUS_STEP := 5
# คลื่น 13 รอบ: [ชนิด, จำนวน] — Phase C ใส่ hard-counter การแก้:
#   คลื่น 4 ค้างคาว = ปืนใหญ่/ทหารโม้ (ต้องมีธนู/เวท) · สไลม์แตกลุกชน
#   แชแมนฮีลกลุ่ม = ต้องเร่งเคลียร์เฟส · คลื่น 13 บอสคุ้มกันหนัก
const WAVES: Array = [
	[["frog", 5]],
	[["frog", 6]],
	[["frog", 4], ["lizard", 3]],
	[["bat", 5]],
	[["frog", 5], ["slime", 3]],
	[["lizard", 5], ["bat", 3]],
	[["frog", 6], ["slime", 3], ["shaman", 1]],
	[["lizard", 6], ["stone_golem", 2], ["bat", 3]],
	[["frog", 7], ["shaman", 2], ["slime", 4]],
	[["lizard", 8], ["stone_golem", 2], ["bat", 4]],
	[["frog", 8], ["slime", 5], ["shaman", 2], ["lizard", 5]],
	[["lizard", 8], ["stone_golem", 3], ["frog", 6], ["bat", 5]],
	[["kubit_boss", 1], ["lizard", 5], ["shaman", 2], ["bat", 4], ["frog", 5]],
]

var _state := "title"       # title | prep | wave | won | lost (Phase E: เริ่มที่หน้าเลือกแผนที่)
var _wave_idx := -1         # คลื่นปัจจุบัน (0-based, -1 = ยังไม่เริ่ม)
var _queue: Array = []      # คิวเกิดของคลื่นนี้ ["frog", ...]
var _spawn_seq := 0
var _gap_t := 0.0           # จับเวลาเกิดรายตัวในคลื่น
var _prep_t := FIRST_PREP   # นับถอยหลังระหว่างคลื่น
var _lives := START_LIVES
var _gold := 0              # เริ่มจากศูนย์ ต้องให้ Kubi ล่ามอนสเตอร์หาเงินก่อนสร้างป้อม
var _lives_label: Label
var _gold_label: Label
var _hud: CanvasLayer
var _towers: Array = [null, null, null, null]   # T5: node ป้อมต่อลาน (null = ว่าง, แทน _built เดิม)
var _lvl: Array[int] = [0, 0, 0, 0]             # T5: เลเวลต่อลาน (0=ว่าง 1 2)
var _inv: Array[int] = [0, 0, 0, 0]             # T5: เงินที่ลงทุนต่อลาน (สร้าง+อัปเกรด ใช้คิดคืนขาย)
var _free_towers: Array[Node2D] = []
var _menu: Control            # แผงเลือกป้อม (เปิดเมื่อคลิกลานว่าง)
var _menu_spot := -1          # ลานที่เมนูกำลังเปิด (สำหรับปุ่ม 1/2 เลือกป้อม)
var _menu_mode := ""          # T5: "build" = เลือกสร้าง / "built" = อัปเกรด-ขาย
var _menu_tower: Node2D
var _placement_mode := false
var _placement_position := Vector2.ZERO
var _rally_tower: Node2D       # Phase B: โหมดสั่งย้ายจุดยืนทหาร (ค่ายทหาร)
var _hero                     # T5: ฮีโร่ Kubi (คลิกขวาสั่งเดิน)
var _spots_layer: SpotsOverlay  # T5.1: ชั้นวาดวงทองลานป้อม (z 30 เหนือพื้นหลัง)
var _path_layer: PathOverlay
var _wave_label: Label        # แถวข้อมูลคลื่นบน HUD (T4)
var _wave_btn: Button         # ปุ่มเรียกคลื่นถัดไปก่อนพร้อมโบนัส (T4)
var _shake := 0.0             # Phase D juice: แรงเขย่าจอคงเหลือ
var _preview_box: HBoxContainer  # Phase D: แถวไอคอนพรีวิวคลื่นถัดไป
# Phase E: multi-map + save สถิติ + title
var _map_idx := 0
var _road: Array[Vector2] = PATH_A            # เส้นทางที่ใช้จริงของแผนที่ปัจจุบัน
var _spots: Array[Vector2] = TOWER_SPOTS      # ลานป้อมของแผนที่ปัจจุบัน
var _title_layer: CanvasLayer
var _best: Dictionary = {}                    # {"m0": 5, "m1": 3, "m0_won": true}
var _kills := 0
var _gold_earned := 0
var _prev_best := 0                           # สถิติเดิมของแผนที่ตอนเริ่มรอบ (โชว์ "สถิติใหม่")

class SpotsOverlay:
	extends Node2D
	# ฐานหกเหลี่ยมแทนวงทองขนาดใหญ่; เลขเล็กช่วยจับคู่กับปุ่มลัด 1-4
	const PAD_RADIUS := 23.0
	const PAD_EDGE := Color(0.13, 0.10, 0.06, 0.92)
	const PAD_FILL := Color(0.28, 0.34, 0.20, 0.90)
	const PAD_ACCENT := Color(1.0, 0.79, 0.24, 0.95)

	var spots: Array[Vector2] = []
	var busy: Array = []        # ผูกอ้างอิงสดกับ main._towers (ลานที่มีป้อมไม่วาดวง)
	var selected := -1
	var cursor_position := Vector2.ZERO
	var cursor_valid := false
	var gate := Vector2(258, 190)          # Phase E: ปากมอนของแผนที่ปัจจุบัน (main set ให้)
	var castle := Vector2(810, 450)        # Phase E: ปราสาทของแผนที่ปัจจุบัน

	func _draw() -> void:
		draw_circle(gate, 14.0, Color(0.55, 0.25, 0.80, 0.9))
		draw_circle(castle, 14.0, Color(1.0, 0.35, 0.15, 0.9))
		for i in range(spots.size()):
			if busy[i] != null:
				continue
			var center := spots[i]
			var vertices := PackedVector2Array()
			for corner in range(6):
				var angle := TAU * float(corner) / 6.0
				vertices.append(center + Vector2.from_angle(angle) * PAD_RADIUS)
			draw_colored_polygon(vertices, PAD_FILL)
			draw_polyline(vertices, PAD_EDGE, 3.0, true)
			draw_arc(center, 14.0, 0.0, TAU, 24, PAD_ACCENT, 1.5, true)
			draw_line(center + Vector2(-5.0, 0.0), center + Vector2(5.0, 0.0), PAD_ACCENT, 3.0, true)
			draw_line(center + Vector2(0.0, -5.0), center + Vector2(0.0, 5.0), PAD_ACCENT, 3.0, true)
			draw_rect(Rect2(center + Vector2(-7.0, -35.0), Vector2(14.0, 14.0)), PAD_EDGE)
			draw_string(ThemeDB.fallback_font, center + Vector2(-4.0, -24.0), str(i + 1),
				HORIZONTAL_ALIGNMENT_CENTER, 8, 11, PAD_ACCENT)
			if i == selected:
				draw_arc(center, PAD_RADIUS + 5.0, 0.0, TAU, 32, PAD_ACCENT, 2.0, true)
		if cursor_position != Vector2.ZERO:
			var cursor_color := Color(0.35, 0.95, 0.45, 0.8) if cursor_valid else Color(1.0, 0.25, 0.2, 0.8)
			draw_arc(cursor_position, 32.0, 0.0, TAU, 32, cursor_color, 3.0, true)
			draw_line(cursor_position + Vector2(-8.0, 0.0), cursor_position + Vector2(8.0, 0.0), cursor_color, 2.0, true)
			draw_line(cursor_position + Vector2(0.0, -8.0), cursor_position + Vector2(0.0, 8.0), cursor_color, 2.0, true)

class PathOverlay:
	extends Node2D

	var points: PackedVector2Array = []

	func _draw() -> void:
		if points.size() < 2:
			return
		draw_polyline(points, Color(0.30, 0.18, 0.10, 0.88), 78.0, true)
		draw_polyline(points, Color(0.70, 0.46, 0.25, 0.96), 68.0, true)
		draw_polyline(points, Color(0.91, 0.71, 0.44, 0.96), 58.0, true)
		draw_polyline(points, Color(0.98, 0.82, 0.57, 0.34), 2.0, true)
		for point in points:
			draw_circle(point, 29.0, Color(0.91, 0.71, 0.44, 0.96))

func _ready() -> void:
	y_sort_enabled = true  # มอนวาดเรียงตามแนวระดับ (ตัวล่างจอบนตัวบนจอ - แก้ทับซ้อนดูลอย)
	_audio = SfxScript.new()
	add_child(_audio)
	_audio.start_music()
	_build_lives_label()
	_path_layer = PathOverlay.new()
	_path_layer.points = PackedVector2Array(_road)
	_path_layer.position = Vector2.ZERO
	_path_layer.z_index = 0
	add_child(_path_layer)
	# ฮีโร่ Kubi เริ่มเฝ้าประตูปราสาท และต้องออกไปสู้เพื่อหาเงินสร้างป้อม
	_hero = HeroScript.new()
	_hero.position = _road[_road.size() - 1]
	add_child(_hero)
	# ชั้นวาดวงทอง (T5.1 fix): ประกาศใน SpotsOverlay การันตีวาดเหนือพื้นหลัง (สาเหตุรายแก้ไม่จบ: วงถูก Background ทับ)
	_spots_layer = SpotsOverlay.new()
	_spots_layer.z_index = 30
	_spots_layer.spots = _spots
	_spots_layer.busy = _towers   # อ้างอิงสด — สร้างป้อมที่ลานไหน วงลานนั้นเงียบ
	_spots_layer.gate = _road[0]
	_spots_layer.castle = _road[_road.size() - 1]
	add_child(_spots_layer)
	_load_best()
	_build_title()   # Phase E: เริ่มที่หน้าเลือกแผนที่ (หยุดจนกว่าผู้เล่นจะเลือก)
	queue_redraw()

## จุดเรียกเสียงจากโหนดลูก (tower/hero/projectile เรียก get_parent().sfx("arrow"))
func sfx(kind: String) -> void:
	if _audio != null:
		_audio.play(kind)

## Phase D juice: โหนดลูกเรียกเขย่าจอ (ปืนใหญ่ยิง/ระเบิด/มอนรั่ว)
func juice_shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func _process(delta: float) -> void:
	# Phase D juice: จอสั่นรวม (offset ทั้งฉาก; HUD เป็น CanvasLayer ไม่โยนตาม = แนว TD)
	if _shake > 0.03:
		_shake = maxf(_shake - delta * (14.0 + _shake * 6.0), 0.0)
		position = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	elif position != Vector2.ZERO:
		position = Vector2.ZERO
	if _spots_layer:
		_spots_layer.queue_redraw()   # วงทองลานป้อมเต้นกระพริบทุกเฟรม (T5.1)
		if _placement_mode:
			_placement_position = get_global_mouse_position()
			_spots_layer.cursor_position = _placement_position
			_spots_layer.cursor_valid = _valid_tower_position(_placement_position)
		else:
			_spots_layer.cursor_position = Vector2.ZERO
	# ตัวรันคลื่น (T4): prep = นับถอยหลังโชว์ปุ่มเรียกก่อน ; wave = เกิดตามคิวกันฉาวจนจบ
	if _state == "prep":
		_prep_t -= delta
		if _prep_t <= 0.0:
			_start_wave()
	elif _state == "wave":
		_gap_t -= delta
		while _queue.size() > 0 and _gap_t <= 0.0:
			if _spawn_point_clear():
				_spawn_kind(_queue.pop_front())
				_gap_t += SPD_GAP
			else:
				_gap_t = 0.45   # ปากประตูแน่น: เลื่อนเกิดไปก่อน 0.45 วิ
				break
		if _queue.size() == 0 and not _enemies_alive():
			_wave_cleared()
	if _state == "prep" or _state == "wave":
		_update_wave_hud()

func _enemies_alive() -> bool:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead:
			return true
	return false

func _remaining() -> int:
	var n := _queue.size()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead:
			n += 1
	return n

func _start_wave() -> void:
	_wave_idx += 1
	_state = "wave"
	sfx("horn")
	if _audio != null:
		_audio.set_wave_theme(true)
	_queue.clear()
	for entry in WAVES[_wave_idx]:
		for _i in range(int(entry[1])):
			_queue.append(entry[0])
	_gap_t = 0.6
	_wave_announce(_wave_idx + 1)
	queue_redraw()

func _spawn_kind(kind: String) -> void:
	# เส้นทางเลื่อนข้างสลับ ซ้าย/ขวา/กลาง + สุ่มความเร็วบาง ๆ (งานเดิม) เพิ่มเลือดโตตามคลื่น
	var lanes := [-LANE_OFFSET, LANE_OFFSET, 0.0]
	var lane: float = lanes[_spawn_seq % 3]
	_spawn_seq += 1
	var jitter := randf_range(0.94, 1.06)
	var hp_mult := pow(HP_GROWTH, _wave_idx)
	if kind == "frog":
		_spawn_enemy(FROG_TEX, FROG_SHEET, _shift_path(_road, lane), FROG_SPEED * jitter, true, false, 59, null, 43, 26.0 * hp_mult, 15, 0.0, 1.5, 8.0)
	elif kind == "lizard":
		# กิ้งก่า: ชุดหันข้าง 8 ช่องหัวหันขวาโดยกำเนิด (ฟีดแบ็ค T5.1: เดินขวาต้องเห็นหัวหันขวาจริง ไม่ใช่รูปหน้าตรงส่ายหัว)
		_spawn_enemy(LIZARD_TEX, LIZARD_SHEET, _shift_path(_road, lane), LIZARD_SPEED * jitter, true, false, 56, LIZARD_SIDE_SHEET, 43, 42.0 * hp_mult, 25, 0.0, 1.5, 11.0)
	elif kind == "stone_golem":
		_spawn_enemy(GOLEM_TEX, null, _shift_path(_road, lane), GOLEM_SPEED * jitter, true, false,
			59, null, 43, GOLEM_HP * hp_mult, 35, GOLEM_RESIST, 1.7, 18.0)
	elif kind == "bat":
		# Phase C ค้างคาว: บินลัดฟ้า — ปืนใหญ่/ทหารเก้อ (ต้องใช้ธนู/เวท) เลือดบางเร็วแต่ลัด
		_spawn_enemy(BAT_TEX, null, _shift_path(_road, lane), BAT_SPEED * jitter, true, false,
			52, null, 43, 30.0 * hp_mult, 20, 0.0, 1.35, 6.0, true)
	elif kind == "slime":
		# Phase C สไลม์: ตายแล้วแตกเป็น 2 ตัวจิ๋ววิ่งเร็วต่อ (ทหารตับมาช่วยบล็อกต่อ)
		_spawn_enemy(SLIME_TEX, null, _shift_path(_road, lane), SLIME_SPEED * jitter, true, false,
			59, null, 43, 34.0 * hp_mult, 22, 0.0, 1.5, 9.0, false, "mini_slime")
	elif kind == "mini_slime":
		_spawn_enemy(SLIME_TEX, null, _shift_path(_road, lane), 46.0 * jitter, true, false,
			59, null, 43, 12.0 * hp_mult, 8, 0.0, 0.95, 5.0)
	elif kind == "shaman":
		# Phase C แชแมน: ฮีลออร่าระยะ 95px ทุก 2.2 วิ — เกิดหลังกอง ฆ่าเสียแค่ "ก่อนเคลียร์เฟสมอนหมด"
		_spawn_enemy(SHAMAN_TEX, null, _shift_path(_road, lane), SHAMAN_SPEED * jitter, true, false,
			59, null, 43, 55.0 * hp_mult, 30, 0.0, 1.5, 8.0, false, "", 2, 0.045)
	else:
		if kind == "kubit_boss":
			# Phase C บอส Kubit: คลื่นสุดท้าย — อึดไม่มีเกราะ (เวท/ธนูลดเลือดได้เต็ม) ฟันทหารแตก
			_spawn_enemy(BOSS_TEX, null, _shift_path(_road, 0.0), BOSS_SPEED, true, false,
				92, null, 43, BOSS_HP * hp_mult, 250, 0.0, 2.1, 45.0, false, "", 0, 0.0, true)
		else:
			push_error("Unknown enemy type: %s" % kind)

func _spawn_point_clear() -> bool:
	# เว้นระยะเกิด: มอนหรือศพจางยังจอดปากประตู (< 80px) = ยังไม่เกิด
	var gate := _road[0]
	for child in get_children():
		if child is Node2D:
			var v: Node2D = child
			if v.position.distance_to(gate) < 80.0 and v.get_script() == EnemyScript:
				return false
	return true

func _wave_cleared() -> void:
	if _state != "wave":
		return
	var bonus := WAVE_BONUS_BASE + (_wave_idx + 1) * WAVE_BONUS_STEP
	_gold += bonus
	_update_gold()
	_gold_earned += bonus   # Phase E: incoming stat
	_gold_popup(bonus, _road[_road.size() - 1])
	if _wave_idx >= WAVES.size() - 1:
		_game_over(true)
	else:
		_state = "prep"
		_prep_t = WAVE_PREP
		if _audio != null:
			_audio.set_wave_theme(false)
	queue_redraw()

func _shift_path(path: Array[Vector2], off: float) -> Array[Vector2]:
	# เลื่อน waypoint ทั้งเส้นตามแนวตั้งฉากของแต่ละช่วง (สายเดินข้างกันไม่ทับถนนกลาง)
	var out: Array[Vector2] = []
	for i in range(path.size()):
		var dir: Vector2
		if i == 0:
			dir = path[1] - path[0]
		elif i == path.size() - 1:
			dir = path[i] - path[i - 1]
		else:
			dir = path[i + 1] - path[i - 1]
		if absf(dir.x) >= absf(dir.y):
			out.append(path[i] + Vector2(0, off))   # ช่วงเดินราบ -> เลื่อนตามแกน y
		else:
			out.append(path[i] + Vector2(off, 0))   # ช่วงเดินตั้ง -> เลื่อนตามแกน x
	return out

func _spawn_enemy(texture: Texture2D, sheet: Texture2D, path: Array[Vector2], speed: float, no_flip: bool, faces_left: bool, bottom_row: int, s_sheet: Texture2D = null, s_bottom: int = 43, hp: float = 26.0, gold: int = 15, resist: float = 0.0, enemy_scale: float = 1.5, atk: float = 8.0, fly := false, split_kind := "", split_count := 2, heal_pct := 0.0, boss := false) -> void:
	var e := EnemyScript.new()
	e.sheet = sheet          # เฟรมเดินจริงถ้ามี sheet (fallback texture นิ่ง)
	e.texture = texture
	e.waypoints = PackedVector2Array(path)
	e.speed = speed
	e.damage_resist = resist
	e.base_scale = enemy_scale
	e.no_flip = no_flip
	e.faces_left = faces_left
	e.body_bottom_row = bottom_row  # แถวเท้าจริงในเฟรม
	e.side_sheet = s_sheet          # ชุดหันข้าง (ช่วงเดินแนวนอน)
	e.side_bottom_row = s_bottom
	e.melee_dmg = atk      # แรงฟันเมื่อสู้กับทหาร้ (Phase B)
	e.max_hp = hp        # เลือดต่อชนิด (T3)
	e.reward = gold      # ทองต่อการฆ่า (T3)
	e.flying = fly               # Phase C ค้างคาว
	e.split_kind = split_kind    # Phase C สไลม์
	e.split_count = split_count
	e.heal_power = heal_pct      # Phase C แชแมน
	e.is_boss = boss
	add_child(e)
	e.reached_castle.connect(_on_enemy_leak)
	e.died.connect(_on_enemy_died)
	if e.split_kind != "":
		# Phase C: สไลม์ตาย → แตกลูกจากจุดที่ตาย (ต่อเส้นทางที่เหลือ)
		e.died.connect(_on_slime_died.bind(e))

func _on_enemy_leak() -> void:
	_lives -= 1
	sfx("leak")
	juice_shake(7.0)   # Phase D: มอนรั่วเข้าปราสาท = สั่นรุนแรง + แดง
	_update_lives()
	if _lives_label:
		_lives_label.modulate = Color(1.0, 0.4, 0.25)
		var t := _lives_label.create_tween()
		t.tween_property(_lives_label, "modulate", Color.WHITE, 0.4)
	# Phase D: ขอบจอแดงกะพริบสั้น ๆ เตือน (CanvasLayer วาดทับทั้งเกม)
	_blink_hurt()
	queue_redraw()
	if _lives <= 0:
		_game_over(false)

func _blink_hurt() -> void:
	if _hud == null:
		return
	var red := ColorRect.new()
	red.color = Color(0.85, 0.12, 0.08, 0.0)
	red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	red.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(red)
	var t := red.create_tween()
	t.tween_property(red, "color:a", 0.28, 0.06)
	t.tween_property(red, "color:a", 0.0, 0.35)
	t.tween_callback(red.queue_free)

func _on_enemy_died(reward: int, at: Vector2) -> void:
	# ทองรางวัลต่อการฆ่า + จุดป๊อบเงินลอยขึ้น (T3)
	_gold += reward
	_kills += 1               # Phase E: สถิติจบเกม
	_gold_earned += reward
	sfx("die")
	sfx("coin")
	_update_gold()
	_gold_popup(reward, at)

func _on_slime_died(reward: int, at: Vector2, slime: Node2D) -> void:
	# Phase C: แตก 2 ไอจิ๋วต่อเส้นทางจากจุดตาย (ความเร็วสูงกว่าตัวใหญ่)
	if slime == null or not is_instance_valid(slime) or slime.split_kind == "":
		return
	var way: PackedVector2Array = slime.waypoints
	var seg: int = maxi(slime._wp_index, 0)
	var rest: Array[Vector2] = []
	rest.append(at)
	for i in range(seg, way.size()):
		if way[i].distance_to(at) > 4.0:
			rest.append(way[i])
	for _i in range(int(slime.split_count)):
		_spawn_enemy(SLIME_TEX, null, rest, 46.0, true, false,
			59, null, 43, 12.0 * pow(HP_GROWTH, _wave_idx), 8, 0.0, 0.95, 5.0)

func _gold_popup(amount: int, at: Vector2) -> void:
	var lb := Label.new()
	lb.text = "+%d" % amount
	lb.z_index = 60
	lb.position = at + Vector2(-16, -44)
	var st := LabelSettings.new()
	st.font_size = 17
	st.font_color = Color(1.0, 0.85, 0.2)
	st.outline_size = 6
	st.outline_color = Color(0.15, 0.09, 0.02)
	lb.label_settings = st
	add_child(lb)
	var t := lb.create_tween()
	t.set_parallel(true)
	t.tween_property(lb, "position", lb.position + Vector2(0, -30), 0.8)
	t.tween_property(lb, "modulate:a", 0.0, 0.8).set_delay(0.3)
	t.chain().tween_callback(lb.queue_free)

func _update_gold() -> void:
	if _gold_label:
		_gold_label.text = "ทอง: %d" % _gold

func _flash_gold() -> void:
	# เงินไม่พอ: แฟลชแดงบอก
	if _gold_label == null:
		return
	_gold_label.modulate = Color(1.0, 0.35, 0.2)
	var t := _gold_label.create_tween()
	t.tween_property(_gold_label, "modulate", Color.WHITE, 0.5)

# ---------- ระบบคลื่น + จบเกม (T4) ----------
func _wave_text(idx: int) -> String:
	# แต้มคลื่นอ่านง่าย: "กบ 4, กิ้งก่า 3"
	var names := {"frog": "กบ", "lizard": "กิ้งก่า", "stone_golem": "โกเลมหิน",
		"bat": "ค้างคาว", "slime": "สไลม์", "mini_slime": "สไลม์จิ๋ว",
		"shaman": "แชแมน", "kubit_boss": "☠ บอส KUBIT ☠"}
	var parts: Array = []
	for entry in WAVES[idx]:
		parts.append("%s %d" % [names[entry[0]], entry[1]])
	return ", ".join(parts)

func _update_wave_hud() -> void:
	if _wave_label:
		if _state == "wave":
			_wave_label.text = "คลื่น %d/%d · เหลือมอน %d" % [_wave_idx + 1, WAVES.size(), _remaining()]
		else:
			var nxt := _wave_idx + 1
			if nxt < WAVES.size():
				_wave_label.text = "คลื่นถัดไป %d/%d · %s" % [nxt + 1, WAVES.size(), _wave_text(nxt)]
	_refresh_preview()
	if _wave_btn:
		if _state == "prep":
			_wave_btn.disabled = false
			var bonus := int(ceil(_prep_t * EARLY_BONUS_PER_SEC))
			_wave_btn.text = "เรียกคลื่น %d (%d วิ) +โบนัส %d" % [_wave_idx + 2, int(ceil(_prep_t)), bonus]
		elif _state == "wave":
			_wave_btn.disabled = true
			_wave_btn.text = "คลื่น %d กำลังบุก..." % [_wave_idx + 1]
		else:
			_wave_btn.visible = false

func _on_wave_btn() -> void:
	# เรียกคลื่นถัดไปก่อน: ได้โบนัส = วินาทีที่ยังเหลือ × อัตรา (ตัดสินใจเสี่ยงรับเงินก่อน)
	if _state != "prep":
		return
	var bonus := int(ceil(_prep_t * EARLY_BONUS_PER_SEC))
	if bonus > 0:
		_gold += bonus
		_gold_earned += bonus   # Phase E: incoming stat
		_update_gold()
		_gold_popup(bonus, Vector2(930, 96))
	_start_wave()

# Phase D: แถวไอคอนพรีวิวคลื่นถัดไป (Bloons-style: ผู้เล่นเห็นก่อน วางแผนได้จริง)
const PREVIEW_ICONS := {
	"frog": FROG_TEX,
	"lizard": LIZARD_TEX,
	"stone_golem": GOLEM_TEX,
	"bat": BAT_TEX,
	"slime": SLIME_TEX,
	"shaman": SHAMAN_TEX,
	"kubit_boss": BOSS_TEX,
}
const PREVIEW_NAMES := {
	"frog": "กบ", "lizard": "กิ้งก่า", "stone_golem": "โกเลมหิน",
	"bat": "ค้างคาว (ปืนใหญ่/ทหารยิงไม่โดน)", "slime": "สไลม์ (ตายแล้วแตก 2 ไอจิ๋ว)",
	"shaman": "แชแมน (ฮีลเพื่อนรอบตัว)", "kubit_boss": "บอส KUBIT",
}
var _preview_shown := -999   # คลื่นที่แถวไอคอนสะท้อนอยู่ (เตรียม rebuild แค่เปลี่ยนคลื่น)

func _refresh_preview() -> void:
	if _preview_box == null:
		return
	var want := _wave_idx + 1
	if _state != "prep" or want >= WAVES.size():
		_preview_box.visible = false
		_preview_shown = -999
		return
	_preview_box.visible = true
	if _preview_shown == want:
		return
	_preview_shown = want
	for child in _preview_box.get_children():
		child.queue_free()
	for entry in WAVES[want]:
		var kind: String = entry[0]
		var icon: Texture2D = PREVIEW_ICONS.get(kind, FROG_TEX)
		var tr := TextureRect.new()
		tr.texture = icon
		tr.custom_minimum_size = Vector2(32, 32)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.tooltip_text = "%s — %d ตัว" % [PREVIEW_NAMES.get(kind, kind), entry[1]]
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_preview_box.add_child(tr)
		var lb := Label.new()
		if kind == "kubit_boss":
			var bs := LabelSettings.new()
			bs.font_size = 16
			bs.font_color = Color(1.0, 0.32, 0.2)
			bs.outline_size = 5
			bs.outline_color = Color(0.1, 0.02, 0.02)
			lb.label_settings = bs
			lb.text = "☠×%d" % entry[1]
		else:
			lb.add_theme_font_size_override("font_size", 13)
			lb.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86))
			lb.add_theme_color_override("font_shadow_color", Color(0.08, 0.06, 0.04, 0.9))
			lb.add_theme_constant_override("shadow_offset_x", 1)
			lb.add_theme_constant_override("shadow_offset_y", 1)
			lb.text = "×%d" % entry[1]
		lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_preview_box.add_child(lb)

func _wave_announce(n: int) -> void:
	# ป้ายชื่อคลื่นกลางจอ จางหายหลังโชว์เภูมิมอนกลุ่มใหม่ (HUD ยังไม่พร้อม = ข้ามเงียบ)
	if _hud == null:
		return
	var lb := Label.new()
	var st := LabelSettings.new()
	st.font_size = 38
	st.font_color = Color(1.0, 0.85, 0.2)
	st.outline_size = 10
	st.outline_color = Color(0.15, 0.09, 0.02)
	lb.label_settings = st
	# Phase C: คลื่นบอส = สีแดงเตือนภัย (telegraph ก่อนเจอ = สิทธิของผู้เล่น)
	var boss_wave := false
	for entry in WAVES[n - 1]:
		if entry[0] == "kubit_boss":
			boss_wave = true
	if boss_wave:
		lb.text = "☠ บอส KUBIT เหยียบออกจากค่าย ☠"
		st.font_size = 46
		st.font_color = Color(1.0, 0.35, 0.2)
		st.outline_color = Color(0.1, 0.02, 0.02)
	else:
		lb.text = "คลื่นที่ %d" % n
	lb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lb.offset_top = 150.0
	lb.offset_bottom = 210.0
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.add_child(lb)
	var t := lb.create_tween()
	t.set_parallel(true)
	t.tween_property(lb, "modulate:a", 0.0, 1.2).set_delay(0.6)
	t.tween_property(lb, "position:y", lb.position.y - 22.0, 1.8)
	t.chain().tween_callback(lb.queue_free)

func _game_over(won: bool) -> void:
	# จบเกม: ป้ายกลางจอ + หยุดโลก + ปุ่มเริ่มใหม่ (คีย์ R ทำงานผ่าน Layer ที่นางจอทำงานต่อแม้ paused)
	if _state == "won" or _state == "lost":
		return
	_state = "won" if won else "lost"
	if _audio != null:
		_audio.game_over(won)
	get_tree().paused = true   # หยุดโลกทันที (มอน/ป้อม/เกิด) — เลเยอร์จอจบเกมตั้ง ALWAYS ทำงานต่อ
	_close_menu()
	if _wave_btn:
		_wave_btn.visible = false
	queue_redraw()
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.02, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	var title := Label.new()
	title.text = "ชนะ! ปราสาทคงยืนยง" if won else "แพ้... ปราสาทแตก"
	var ts := LabelSettings.new()
	ts.font_size = 48
	ts.font_color = Color(1.0, 0.85, 0.2) if won else Color(1.0, 0.4, 0.3)
	ts.outline_size = 12
	ts.outline_color = Color(0.15, 0.09, 0.02)
	title.label_settings = ts
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := Label.new()
	var ss := LabelSettings.new()
	ss.font_size = 20
	ss.font_color = Color(0.95, 0.93, 0.9)
	ss.outline_size = 7
	ss.outline_color = Color(0.1, 0.07, 0.04)
	sub.label_settings = ss
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if won:
		sub.text = "รอดครบ %d/%d คลื่น · ชีวิตคงเหลือ %d" % [WAVES.size(), WAVES.size(), _lives]
	else:
		sub.text = "ปราสาทแตกที่คลื่นที่ %d" % mini(_wave_idx + 1, WAVES.size())
	box.add_child(sub)
	# Phase E: บันทึกสถิติคลื่นสูงสุด (ทั้งชนะ/แพ้)
	_record_best(won)
	# Phase E: บล็อกสถิติการเล่นรอบนี้ (ฆ่า/ทอง/คลื่น/สถิติใหม่)
	var new_best := _wave_idx + 1 > _prev_best
	var stats := Label.new()
	var sts := LabelSettings.new()
	sts.font_size = 17
	sts.font_color = Color(0.98, 0.80, 0.35) if new_best else Color(0.85, 0.85, 0.85)
	sts.outline_size = 6
	sts.outline_color = Color(0.1, 0.07, 0.04)
	stats.label_settings = sts
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stat_line := "ฆ่าได้ %d ตัว · ทองได้รวม %d · คลื่นที่ทำได้ %d/%d" % [_kills, _gold_earned, mini(_wave_idx + 1, WAVES.size()), WAVES.size()]
	if new_best and _wave_idx + 1 >= 1:
		stat_line += "\n★ สถิติใหม่! คลื่นสูงสุด %d (เดิม %d)" % [_wave_idx + 1, _prev_best]
	stats.text = stat_line
	box.add_child(stats)
	var btn := Button.new()
	btn.text = "เริ่มใหม่ (R)"
	btn.custom_minimum_size = Vector2(190, 46)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.focus_mode = Control.FOCUS_NONE
	var sc := Shortcut.new()
	var ev := InputEventKey.new()
	ev.keycode = KEY_R
	sc.events = [ev]
	btn.shortcut = sc
	btn.pressed.connect(_restart)
	box.add_child(btn)
	if _hud:
		_hud.add_child(layer)

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# ---------- Phase E: title + เลือกแผนที่ + save สถิติคลื่นสูงสุด ----------
func _load_best() -> void:
	var f := FileAccess.open(BEST_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		_best = parsed

func _save_best() -> void:
	# เขียนไฟล์ชั่วคราวแล้วเปลี่ยนชื่อ (atomic) — ไฟล์เสียไม่ได้ถ้าเครื่องดับกลางทาง
	var f := FileAccess.open(BEST_PATH + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_best))
	f.flush()
	f.close()
	DirAccess.remove_absolute(BEST_PATH)
	DirAccess.rename_absolute(BEST_PATH + ".tmp", BEST_PATH)

func _record_best(won: bool) -> void:
	var key := "m%d" % _map_idx
	var reached := mini(_wave_idx + 1, WAVES.size())
	var prev := int(_best.get(key, 0))
	if reached > prev:
		_best[key] = reached
	if won:
		_best[key + "_won"] = true
	_save_best()

func _map_best_text(idx: int) -> String:
	var key := "m%d" % idx
	if _best.has(key):
		var won_txt := " ★ผ่านแล้ว" if _best.get(key + "_won", false) else ""
		return "คลื่นสูงสุด %d/%d%s" % [int(_best[key]), WAVES.size(), won_txt]
	return "ยังไม่มีสถิติ"

func _build_title() -> void:
	# Phase E: หน้าเลือกแผนที่ (CanvasLayer ซ้อนบน HUD; ปิดอินพุตเกมจนกว่าผู้เล่นเลือก)
	_title_layer = CanvasLayer.new()
	_title_layer.layer = 25
	_title_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_title_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.05, 0.03, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title_layer.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(box)
	var title := Label.new()
	title.text = "หอคอยคู่ฟ้า"
	var ts := LabelSettings.new()
	ts.font_size = 62
	ts.font_color = Color(1.0, 0.85, 0.2)
	ts.outline_size = 14
	ts.outline_color = Color(0.15, 0.09, 0.02)
	title.label_settings = ts
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var story := Label.new()
	story.text = "เหล่ามอนปลุกจากสุสานสาบานมุ่งหมายปราสาทหลวง\nจงตั้งป้อม ซ่อมแม่ทัพ Kubi และขับไล่ถึง %d คลื่น" % WAVES.size()
	var ss := LabelSettings.new()
	ss.font_size = 19
	ss.font_color = Color(0.95, 0.93, 0.9)
	ss.outline_size = 7
	ss.outline_color = Color(0.1, 0.07, 0.04)
	story.label_settings = ss
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(story)
	var pick := Label.new()
	pick.text = "เลือกแผนที่บุก"
	var ps := LabelSettings.new()
	ps.font_size = 23
	ps.font_color = Color(0.7, 0.95, 1.0)
	ps.outline_size = 7
	ps.outline_color = Color(0.1, 0.07, 0.04)
	pick.label_settings = ps
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(pick)
	for idx in range(MAPS.size()):
		var btn := Button.new()
		btn.text = "%s — %s" % [MAPS[idx]["name"], _map_best_text(idx)]
		btn.custom_minimum_size = Vector2(360, 52)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(_start_map.bind(idx))
		box.add_child(btn)

func _start_map(idx: int) -> void:
	# เปลี่ยนแผนที่: ภาพพื้นหลัง + เส้นทาง + ลานป้อม + ประตู/ปราสาท + จุดพักฮีโร่ -> แล้วเริ่มเกม
	if _state != "title":
		return
	_map_idx = clampi(idx, 0, MAPS.size() - 1)
	var cfg: Dictionary = MAPS[_map_idx]
	var road_tmp: Array[Vector2] = []
	for p in cfg["path"]:
		road_tmp.append(p)
	var spots_tmp: Array[Vector2] = []
	for s in cfg["spots"]:
		spots_tmp.append(s)
	_road = road_tmp
	_spots = spots_tmp
	var bg := get_node_or_null("Background")
	if bg != null and bg is Sprite2D:
		bg.texture = cfg["tex"]
		# พื้นหลัง gen อาจเล็ก (256x144) — ยืดเต็มจอ 1152 เสมอ (map A = ×1 อยู่แล้ว)
		var tex: Texture2D = cfg["tex"]
		var s := 1152.0 / float(tex.get_width())
		bg.scale = Vector2(s, s)
	_path_layer.points = PackedVector2Array(_road)
	_spots_layer.spots = _spots
	_spots_layer.gate = _road[0]
	_spots_layer.castle = _road[_road.size() - 1]
	_spots_layer.queue_redraw()
	_hero.home = _road[_road.size() - 1]
	_hero.position = _road[_road.size() - 1]
	_prev_best = int(_best.get("m%d" % _map_idx, 0))
	_kills = 0
	_gold_earned = 0
	if _title_layer != null:
		_title_layer.queue_free()
		_title_layer = null
	_state = "prep"
	_prep_t = WAVE_PREP
	sfx("build")
	queue_redraw()

# ---------- เมนูสร้างป้อม (T3) ----------
func _start_rally_move(tower: Node2D) -> void:
	_rally_tower = tower
	sfx("click")

func _cycle_targeting_menu(spot_idx: int, tower: Node2D) -> void:
	# Phase D: สลับโหมดเล็งของป้อมนี้แล้วเปิดเมนูใหม่ (รีเฟรชชื่อโหมดบนป้าย)
	if tower == null or not is_instance_valid(tower):
		return
	tower.cycle_targeting()
	sfx("click")
	if spot_idx >= 0:
		_open_menu(spot_idx)
	else:
		_open_menu(-1, Vector2.ZERO, tower)

func _unhandled_input(event: InputEvent) -> void:
	if _state == "title":
		return   # Phase E: อยู่หน้าเลือกแผนที่ = ปิดคลิก/คีย์เกมทั้งหมด (จัดการเฉพาะปุ่มบน title)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# คลิกขวาศัตรู = Kubi ไล่โจมตี; คลิกพื้น = เดินไปตำแหน่งนั้น
		if _hero != null and not _hero._dead:
			var command_pos := get_global_mouse_position()
			var enemy := _enemy_at(command_pos, 52.0)
			if enemy != null:
				_hero.attack_target(enemy)
			else:
				_hero.move_to(command_pos)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# NB: พิกัดคลิกมี 2 ระบบขึ้นกับ DPI - จอ 125% ย่อหน้าต่างจริงเป็น 921x518
		# เช็คทั้งพิกัดโลก, event.position ดิบ (หน้าต่าง=สเกลเดียว), และ event.position ยืดตามสเกลหน้าต่าง
		var candidates: Array[Vector2] = [event.position]
		if is_inside_tree():
			candidates.insert(0, get_global_mouse_position())
		var win := get_window()
		var wsize := Vector2(win.size) if win != null else Vector2.ZERO
		if wsize.x > 100.0 and wsize.y > 100.0 and (wsize.x < 1100.0 or wsize.y < 600.0):
			candidates.append(event.position * Vector2(1152.0, 648.0) / wsize)
		var clicked_tower: Node2D
		for p in candidates:
			clicked_tower = _tower_at(p)
			if clicked_tower != null:
				break
		# Phase B: โหมดย้ายจุดยืนทหาร — คลิกครั้งต่อไปกำหนด rally
		if _rally_tower != null and is_instance_valid(_rally_tower):
			var t_r: Node2D = _rally_tower
			var p_r: Vector2 = candidates[0]
			if p_r.distance_to(t_r.position) <= t_r.range_r * 1.25:
				t_r.rally_point = p_r
				t_r.rally_locked = true
				sfx("build")
			else:
				sfx("leak")   # ไกลเกิน: ใช้เสียงปฏิเสธแทนข้อความ
			_rally_tower = null
			return
		if clicked_tower != null:
			_open_tower_menu(clicked_tower)
			return
		var hit := -1
		for p in candidates:
			for i in range(_spots.size()):
				# T5: ลานที่มีป้อมแล้วก็คลิกได้ -> เมนูอัปเกรด/ขาย (เดิมกรองเฉพาะลานว่าง)
				if p.distance_to(_spots[i]) <= SPOT_HIT_R:
					hit = i
					break
			if hit >= 0:
				break
		if hit >= 0:
			_open_menu(hit)
		elif _placement_mode:
			for p in candidates:
				if _valid_tower_position(p):
					_open_menu(-1, p)
					_placement_mode = false
					break
		elif _menu != null:
			_close_menu()
	elif event is InputEventKey and event.pressed and not event.echo:
		# B เปิดโหมดวางอิสระ; 1-4 เปิดฐานเดิม
		var code: int = event.keycode
		if code == KEY_B and _menu == null:
			_placement_mode = not _placement_mode
			if not _placement_mode and _spots_layer:
				_spots_layer.cursor_position = Vector2.ZERO
		elif _state == "prep" and code == KEY_N:
			# ทางลัดเรียกคลื่นก่อน = เหมือนกดปุ่มมุมขวาบน (ได้โบนัสตามวินาทีคงเหลือ)
			_on_wave_btn()
		elif _menu == null:
			if code >= KEY_1 and code <= KEY_4:
				var idx := code - KEY_1
				print("OPEN_MENU spot=", idx, " (key)")  # DEBUG (console)
				_open_menu(idx)
		else:
			if _menu_mode == "build":
				if code == KEY_1:
					if _menu_spot >= 0:
						_build_tower(_menu_spot, "archer")
					else:
						_build_free_tower(_placement_position, "archer")
				elif code == KEY_2:
					if _menu_spot >= 0:
						_build_tower(_menu_spot, "cannon")
					else:
						_build_free_tower(_placement_position, "cannon")
				elif code == KEY_3:
					if _menu_spot >= 0:
						_build_tower(_menu_spot, "mage")
					else:
						_build_free_tower(_placement_position, "mage")
			elif _menu_mode == "built":
				if code == KEY_1 and _menu_tower != null and _menu_tower.level < 2:
					_upgrade_selected_tower()
				elif code == KEY_2:
					_sell_selected_tower()
				elif code == KEY_3 and _menu_tower != null and _menu_tower.kind == TowerScript.BARRACKS:
					_start_rally_move(_menu_tower)
				elif code == KEY_4 and _menu_tower != null:
					# Phase D: สลับโหมดเล็ง (ทุกสายป้อม)
					_menu_tower.cycle_targeting()
					sfx("click")
			if code == KEY_ESCAPE or code == KEY_X:
				_close_menu()
	elif event.is_action_pressed("ui_cancel") and _menu != null:
		_close_menu()

func _open_menu(spot_idx: int, free_position: Vector2 = Vector2.ZERO, selected_tower: Node2D = null) -> void:
	_close_menu()
	sfx("click")
	_menu_spot = spot_idx
	_menu_tower = selected_tower
	if _menu_tower == null and spot_idx >= 0 and _towers[spot_idx] != null:
		_menu_tower = _towers[spot_idx]
	_menu_mode = "built" if _menu_tower != null else "build"
	# T5: เมนู 2 โหมด - ลานว่าง = สร้างป้อม / ลานที่มีป้อม = อัปเกรด + ขาย
	if spot_idx < 0:
		_placement_position = _menu_tower.position if _menu_tower != null else free_position
	if _spots_layer:
		_spots_layer.selected = spot_idx
		_spots_layer.queue_redraw()
	if _menu_mode == "built":
		_menu_tower.show_range = true
		_menu_tower.queue_redraw()
	var panel := PanelContainer.new()
	var menu_width := 438.0 if _menu_mode == "build" else 218.0
	panel.custom_minimum_size.x = menu_width
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)
	var heading := Label.new()
	if _menu_mode == "build":
		heading.text = "สร้างป้อม · ลาน %d" % [spot_idx + 1] if spot_idx >= 0 else "สร้างป้อม · จุดอิสระ"
	else:
		heading.text = "จัดการป้อม · ลาน %d" % [spot_idx + 1] if spot_idx >= 0 else "จัดการป้อม"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var heading_style := LabelSettings.new()
	heading_style.font_size = 14
	heading_style.font_color = Color(1.0, 0.85, 0.45)
	heading_style.outline_size = 4
	heading_style.outline_color = Color(0.08, 0.06, 0.03)
	heading.label_settings = heading_style
	layout.add_child(heading)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(hb)
	if _menu_mode == "build":
		var option_number := 1
		for key in ["archer", "cannon", "mage", "barracks"]:
			var def: Dictionary = TOWER_DEFS[key]
			var tip: String = "%s (รัศมี %d, ดาเมจ %.0f)" % [def["name"], def["range"], def["dmg"]]
			var build_action := _build_tower.bind(spot_idx, key) if spot_idx >= 0 else _build_free_tower.bind(_placement_position, key)
			_menu_entry(hb, def["icon"], "%d %s" % [option_number, def["name"]], int(def["cost"]), tip, build_action)
			option_number += 1
	else:
		var t := _menu_tower
		var def: Dictionary = TOWER_DEFS[_tower_def_key(t)]
		if t.level < 2:
			# อัปเกรด Lv2: ไอคอนประจำป้อม + ราคาต่ำงาน
			var upg: Dictionary = def["upg"]
			var tip2: String = "อัปเกรด %s Lv2 (ดาเมจ %.0f, รัศมี %d)" % [def["name"], upg["dmg"], upg["range"]]
			var upgrade_action := _upgrade_tower.bind(spot_idx) if spot_idx >= 0 else _upgrade_selected_tower
			_menu_entry(hb, def["upg_icon"], "1 อัปเกรด", int(def["upg_cost"]), tip2, upgrade_action)
		if t.kind == TowerScript.BARRACKS:
			# Phase B: สั่งทหารย้ายจุดยืน (rally) คลิกจุดต่อไป
			var rally_action := _start_rally_move.bind(t)
			_menu_entry(hb, ICON_SCROLL, "3 ย้ายจุด", 0, "คลิกจุดบนสนามเพื่อสั่งทหารยืนกั้นทางที่นั่น", rally_action)
		# ขายคืน 60% ของเงินที่ลงไป (ไอคอนเหรียญ Kubi เดิม)
		var refund := _tower_refund(t)
		var sell_action := _sell_tower.bind(spot_idx) if spot_idx >= 0 else _sell_selected_tower
		_menu_entry(hb, ICON_COIN, "2 ขายคืน", refund, "ขายคืน 60%% ของเงินที่ลงไป (%d)" % refund, sell_action)
		# Phase D: ปุ่มสลับโหมดเล็ง (First/Last/Strong/Weak) — ทุกสายป้อม
		var tgt_action := _cycle_targeting_menu.bind(spot_idx, t)
		_menu_entry(hb, ICON_TARGET, "เล็ง: %s" % t.targeting_name(), 0, t.targeting_tip() + " (กดเพื่อสลับ)", tgt_action)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.07, 0.03, 0.9)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	var anchor := _spots[spot_idx] if spot_idx >= 0 else _placement_position
	panel.position = anchor + Vector2(-100, -78)
	panel.position.x = clampf(panel.position.x, 8.0, 1152.0 - menu_width - 8.0)
	panel.position.y = clampf(panel.position.y, 8.0, 648.0 - 178.0)
	panel.z_index = 100   # T5.1: เมนูต้องลอยเหนือตัวป้อม (เดิม y-sort ดันเมนูไปหลังป้อม = อ่านไม่รู้เรื่อง)
	_menu = panel
	add_child(panel)

func _menu_entry(hb: HBoxContainer, icon: Texture2D, title: String, price: int, tip: String, pressed: Callable) -> void:
	# แสดงชื่อและราคาใต้ไอคอน เพื่อให้รู้ว่ากำลังกดซื้อหรือจัดการอะไร
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	var btn := TextureButton.new()
	btn.texture_normal = icon
	btn.custom_minimum_size = Vector2(56, 56)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.tooltip_text = tip
	btn.pressed.connect(pressed)
	col.add_child(btn)
	var name_label := Label.new()
	name_label.text = title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.87))
	name_label.custom_minimum_size.x = 92.0
	col.add_child(name_label)
	var cost := Label.new()
	cost.text = "%d" % price
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cst := LabelSettings.new()
	cst.font_size = 15
	cst.font_color = Color(1.0, 0.35, 0.25) if price > _gold else Color(1.0, 0.85, 0.2)
	cst.outline_size = 5
	cst.outline_color = Color(0.15, 0.09, 0.02)
	cost.label_settings = cst
	col.add_child(cost)
	hb.add_child(col)

func _close_menu() -> void:
	if _menu != null:
		_menu.queue_free()
		_menu = null
	if _menu_tower != null and is_instance_valid(_menu_tower):
		_menu_tower.show_range = false
		_menu_tower.queue_redraw()
	if _spots_layer:
		_spots_layer.selected = -1
		_spots_layer.queue_redraw()
	_menu_spot = -1
	_menu_tower = null
	_menu_mode = ""

func _open_tower_menu(tower: Node2D) -> void:
	_open_menu(_towers.find(tower), tower.position, tower)

func _tower_def_key(t: Node2D) -> String:
	# T5: หาแถว def ของป้อมต่อลาน (จาก kind) สำหรับอัปเกรด/ขาย
	for key in TOWER_DEFS:
		if t.kind == int(TOWER_DEFS[key]["kind"]):
			return key
	return "archer"

func _refund(spot_idx: int) -> int:
	return int(round(float(_inv[spot_idx]) * SELL_REFUND))

func _tower_refund(tower: Node2D) -> int:
	return int(round(float(tower.invested_gold) * SELL_REFUND))

func _upgrade_selected_tower() -> void:
	_upgrade_tower_node(_menu_tower, _menu_spot)

func _sell_selected_tower() -> void:
	_sell_tower_node(_menu_tower, _menu_spot)

func _build_tower(spot_idx: int, key: String) -> void:
	if spot_idx < 0 or _towers[spot_idx] != null:
		return
	var def: Dictionary = TOWER_DEFS[key]
	if _gold < int(def["cost"]):
		_flash_gold()
		return
	_gold -= int(def["cost"])
	_update_gold()
	var t := TowerScript.new()
	t.setup(def["kind"], def["tex"], def["dmg"], def["interval"], def["range"], def["shot"], def["splash"])
	t.position = _spots[spot_idx]
	t.invested_gold = int(def["cost"])
	add_child(t)
	sfx("build")
	# T5: จำสถานะต่อลาน (node / เลเวล / เงินที่ลงไป ใช้คิดคืนขาย)
	_towers[spot_idx] = t
	_lvl[spot_idx] = 1
	_inv[spot_idx] = int(def["cost"])
	_close_menu()
	queue_redraw()

func _build_free_tower(at: Vector2, key: String) -> void:
	if not _valid_tower_position(at):
		_close_menu()
		_placement_mode = true
		return
	var def: Dictionary = TOWER_DEFS[key]
	if _gold < int(def["cost"]):
		_flash_gold()
		return
	_gold -= int(def["cost"])
	_update_gold()
	var tower := TowerScript.new()
	tower.setup(def["kind"], def["tex"], def["dmg"], def["interval"], def["range"], def["shot"], def["splash"])
	tower.position = at
	tower.invested_gold = int(def["cost"])
	add_child(tower)
	sfx("build")
	_free_towers.append(tower)
	_close_menu()
	queue_redraw()

func _upgrade_tower(spot_idx: int) -> void:
	if spot_idx < 0 or spot_idx >= _towers.size():
		return
	_upgrade_tower_node(_towers[spot_idx], spot_idx)

func _upgrade_tower_node(t: Node2D, spot_idx: int) -> void:
	if t == null or t.level >= 2:
		return
	var def: Dictionary = TOWER_DEFS[_tower_def_key(t)]
	var upg: Dictionary = def["upg"]
	var cost := int(def["upg_cost"])
	if _gold < cost:
		_flash_gold()
		return
	_gold -= cost
	t.invested_gold += cost
	if spot_idx >= 0:
		_inv[spot_idx] += cost
	_update_gold()
	sfx("build")
	t.apply_upgrade(float(upg["dmg"]), float(upg["interval"]), float(upg["range"]), float(upg["shot"]), float(upg["splash"]))
	if spot_idx >= 0:
		_lvl[spot_idx] = 2
	_close_menu()
	queue_redraw()

func _sell_tower(spot_idx: int) -> void:
	if spot_idx < 0 or spot_idx >= _towers.size():
		return
	_sell_tower_node(_towers[spot_idx], spot_idx)

func _sell_tower_node(t: Node2D, spot_idx: int) -> void:
	if t == null:
		return
	var refund := _tower_refund(t)
	_gold += refund
	sfx("sell")
	_update_gold()
	_gold_popup(refund, t.position)
	t.queue_free()
	if t.kind == TowerScript.BARRACKS:
		for s in t._soldiers:
			if s != null and is_instance_valid(s):
				s.queue_free()
	if spot_idx >= 0:
		_towers[spot_idx] = null
		_lvl[spot_idx] = 0
		_inv[spot_idx] = 0
	else:
		_free_towers.erase(t)
	_close_menu()
	queue_redraw()

func _tower_at(at: Vector2) -> Node2D:
	var nearest: Node2D
	var nearest_distance := 38.0
	for tower in _towers:
		if tower is Node2D and is_instance_valid(tower):
			var distance := at.distance_to(tower.position)
			if distance < nearest_distance:
				nearest = tower
				nearest_distance = distance
	for tower in _free_towers:
		if is_instance_valid(tower):
			var distance := at.distance_to(tower.position)
			if distance < nearest_distance:
				nearest = tower
				nearest_distance = distance
	return nearest

func _enemy_at(at: Vector2, radius: float) -> Node2D:
	var nearest: Node2D
	var nearest_distance := radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and not enemy.dead:
			var distance := at.distance_to(enemy.position)
			if distance < nearest_distance:
				nearest = enemy
				nearest_distance = distance
	return nearest

func _distance_to_path(at: Vector2) -> float:
	var nearest_distance := INF
	for i in range(_road.size() - 1):
		var closest := Geometry2D.get_closest_point_to_segment(at, _road[i], _road[i + 1])
		nearest_distance = minf(nearest_distance, at.distance_to(closest))
	return nearest_distance

func _valid_tower_position(at: Vector2) -> bool:
	if at.x < 52.0 or at.x > 1100.0 or at.y < 48.0 or at.y > 600.0:
		return false
	if _distance_to_path(at) < 62.0:
		return false
	for spot in _spots:
		if at.distance_to(spot) < 70.0:
			return false
	for tower in _towers:
		if tower is Node2D and is_instance_valid(tower) and at.distance_to(tower.position) < 72.0:
			return false
	for tower in _free_towers:
		if is_instance_valid(tower) and at.distance_to(tower.position) < 72.0:
			return false
	return true

func _update_lives() -> void:
	if _lives_label:
		_lives_label.text = "ชีวิต: %d" % _lives

func _build_lives_label() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 10
	add_child(_hud)
	# แถวชีวิต (T4.1): ไอคอนหัวใจ + ตัวเลข
	var heart := TextureRect.new()
	heart.texture = ICON_HEART
	heart.custom_minimum_size = Vector2(26, 26)
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.position = Vector2(16, 12)
	_hud.add_child(heart)
	_lives_label = Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 22
	ls.font_color = Color(1.0, 0.79, 0.24)
	ls.outline_size = 6
	ls.outline_color = Color(0.16, 0.09, 0.03)
	_lives_label.label_settings = ls
	_lives_label.position = Vector2(48, 12)
	_lives_label.text = "ชีวิต: %d" % _lives
	_hud.add_child(_lives_label)
	# แถวทอง (T3): ไอคอนเหรียญ + ตัวเลข
	var coin := TextureRect.new()
	coin.texture = ICON_COIN
	coin.custom_minimum_size = Vector2(26, 26)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.position = Vector2(16, 46)
	_hud.add_child(coin)
	_gold_label = Label.new()
	var gs := LabelSettings.new()
	gs.font_size = 20
	gs.font_color = Color(1.0, 0.85, 0.2)
	gs.outline_size = 6
	gs.outline_color = Color(0.16, 0.09, 0.03)
	_gold_label.label_settings = gs
	_gold_label.position = Vector2(48, 46)
	_gold_label.text = "ทอง: %d" % _gold
	_hud.add_child(_gold_label)
	# แถวข้อมูลคลื่น (T4): ใต้แถวชีวิต/ทอง (ข้อความวิธีเล่นล่างซ้ายถูกตัดออกตามฟีดแบ็ค T4.1)
	_wave_label = Label.new()
	var ws := LabelSettings.new()
	ws.font_size = 16
	ws.font_color = Color(0.92, 0.92, 0.95)
	ws.outline_size = 5
	ws.outline_color = Color(0.08, 0.06, 0.05)
	_wave_label.label_settings = ws
	_wave_label.position = Vector2(16, 80)
	_hud.add_child(_wave_label)
	var controls := Label.new()
	controls.text = "1-4: ฐาน/ป้อม · B+คลิก: วางอิสระ · เมนูป้อม: กด 4 สลับโหมดเล็ง · ค่ายทหาร: ปุ่ม 3 สั่งจุดยืน"
	controls.add_theme_font_size_override("font_size", 13)
	controls.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86))
	controls.add_theme_color_override("font_shadow_color", Color(0.08, 0.06, 0.04, 0.95))
	controls.add_theme_constant_override("shadow_offset_x", 1)
	controls.add_theme_constant_override("shadow_offset_y", 1)
	controls.position = Vector2(16, 108)
	_hud.add_child(controls)
	# Phase D: แถวไอคอนพรีวิวคลื่นถัดไป (ใต้แถววิธีเล่น)
	_preview_box = HBoxContainer.new()
	_preview_box.position = Vector2(16, 130)
	_preview_box.add_theme_constant_override("separation", 5)
	_preview_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_preview_box)
	# ปุ่มเรียกคลื่นถัดไปก่อนพร้อมโบนัส (มุมขวาบน - T4)
	_wave_btn = Button.new()
	_wave_btn.text = "เรียกคลื่น 1"
	_wave_btn.pressed.connect(_on_wave_btn)
	_wave_btn.focus_mode = Control.FOCUS_NONE
	_wave_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_wave_btn.offset_left = -270.0
	_wave_btn.offset_right = -8.0
	_wave_btn.offset_top = 8.0
	_wave_btn.offset_bottom = 42.0
	_hud.add_child(_wave_btn)
	_update_wave_hud()

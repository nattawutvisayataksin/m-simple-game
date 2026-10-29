extends Node2D
# มอนสเตอร์เดินตามถนน - หอคอยคู่ฟ้า (T2 + แอนิเมชันเดินลื่น)
# เดินตาม waypoint อย่างมี carry leftover distance (ระยะ step ค้างข้ามจุด -
# กันมอนเร็ว "หยุดหายใจ" ที่จุดกำหนดเพราะเดินเลยหัวไปแล้วใน 1 เฟรม)
# T2.6: วางเท้าที่ position (sprite offset -22) ให้ y-sort จัดลำดับถูกตามระดับจอ
# และวาดเงาวงรีใต้เท้า ยึดตัวมอนกับพื้น (แก้ภาพ "ลอย ๆ" เมื่อตัวทับกัน)

signal reached_castle

const FRAME_SIZE := 64
const ANIM_FPS := 9.0

var waypoints: PackedVector2Array = []
var speed := 60.0
var base_scale := 1.5
var no_flip := false
var faces_left := true    # สไปรต์หันข้าง (sheet_side) เกิดหัวไปทางไหน (กิ้งก่า = ซ้าย)
var body_bottom_row := 59  # แถวเท้าล่างสุดของชุดหน้าตรง (กบ=59 กิ้งก่าหน้าตรง=56) - tools/measure_feet.ps1
var side_sheet: Texture2D       # ชุดหันข้าง (ใช้ช่วงเดินแนวนอน) - null = ใช้หน้าตรงตลอด
var side_bottom_row := 43       # แถวเท้าล่างสุดของชุดหันข้าง (กิ้งก่าหันข้าง=43)
var texture: Texture2D        # ภาพนิ่ง (fallback)
var sheet: Texture2D          # spritesheet หน้าตรง แถวเดียว (เลือกใช้ถ้ามี)

var _wp_index := 0
var _bob := 0.0
var _anim_t := 0.0
var _sprite: Sprite2D

func _apply_sheet(tex: Texture2D, bottom_row: int) -> void:
	# สลับชุดสไปรต์ (หน้าตรง/หันข้าง) - ต้องเลื่อนเท้าตามแถวเท้าของชุดนั้นด้วย
	_sprite.texture = tex
	if tex != null and tex.get_width() > FRAME_SIZE:
		_sprite.hframes = tex.get_width() / FRAME_SIZE
	_sprite.offset = Vector2(0, 2.0 / base_scale - (bottom_row - 32))

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.scale = Vector2(base_scale, base_scale)
	# จุด reference อยู่เท้า: เลื่อนตามแถวเท้าจริงของแต่ละสายพันธุ์ (กันเหาะเหนือถนน)
	var front := sheet if sheet != null else texture
	_apply_sheet(front, body_bottom_row)
	add_child(_sprite)
	# ยืนจุดแรกของเส้นทาง
	if waypoints.size() > 0:
		position = waypoints[0]
	queue_redraw()

func _draw() -> void:
	# เงาใต้เท้า (วงรีโปร่งแสง) - วาดที่ position (เท้า)
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 17.0, Color(0.05, 0.09, 0.04, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _process(delta: float) -> void:
	if _wp_index >= waypoints.size() - 1:
		return
	var step := speed * delta
	while true:
		var target := waypoints[_wp_index + 1]
		var to_target := target - position
		var dist := to_target.length()
		if step < dist:
			if dist > 0.0:
				position += to_target.normalized() * step
			break
		# เหลือ step มากกว่าระยะถึงจุดถัดไป: ไปถึงจุดนั้นแล้วใช้ step ค้างต่อ
		position = target
		step -= dist
		_wp_index += 1
		if _wp_index >= waypoints.size() - 1:
			# ถึงจุดสุดท้าย (ปราสาท) = leak
			reached_castle.emit()
			queue_free()  # ปลอดภัย: ตัวนี้ถูกปล่อยท้ายเฟรม ไม่ใช่ระหว่าง signal ฟิสิกส์
			return
	# เฟรมเดิน + เลือกชุดท่าตามทิศเดิน
	var nxt := waypoints[_wp_index + 1]
	var d := nxt - position
	var horizontal := absf(d.x) > absf(d.y)
	var front: Texture2D = sheet if sheet != null else texture
	var animing := false
	if horizontal and side_sheet != null:
		# ช่วงเดินแนวนอน: ใช้ชุดหันข้าง แล้ว flip ให้หัวตามทิศเดิน
		if _sprite.texture != side_sheet:
			_apply_sheet(side_sheet, side_bottom_row)
		_sprite.flip_h = nxt.x > position.x and faces_left  # native หัวซ้าย -> เดินขวาต้องกลับ
		animing = side_sheet.get_width() > FRAME_SIZE
	else:
		# ช่วงเดินตรงเข้าหาเรา (แนวตั้ง/ทแยง): ชุดหน้าตรง ไม่ flip
		if _sprite.texture != front:
			_apply_sheet(front, body_bottom_row)
		_sprite.flip_h = false
		animing = front != null and front.get_width() > FRAME_SIZE
	if animing:
		_anim_t += delta * ANIM_FPS
		_sprite.frame = int(_anim_t) % _sprite.hframes
	else:
		# fallback: เด้งตัวเป็นจังหวะเดิน (scale-pulse trick)
		_bob += delta * 9.0
		var s := base_scale * (1.0 + 0.05 * sin(_bob))
		_sprite.scale = Vector2(s, s)

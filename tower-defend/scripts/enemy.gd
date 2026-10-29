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
var faces_left := false   # สไปรต์หันข้างเกิดหัวไปทางไหน (กิ้งก่า = ซ้าย)
var body_bottom_row := 59  # แถวเท้าล่างสุดในเฟรม 64px (กบ=59) - จาก tools/measure_feet.ps1
var texture: Texture2D        # ภาพนิ่ง (fallback)
var sheet: Texture2D          # spritesheet แถวเดียว (เลือกใช้ถ้ามี)

var _wp_index := 0
var _bob := 0.0
var _anim_t := 0.0
var _sprite: Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	var tex := sheet if sheet != null else texture
	_sprite.texture = tex
	if sheet != null and sheet.get_width() > FRAME_SIZE:
		_sprite.hframes = sheet.get_width() / FRAME_SIZE
	_sprite.scale = Vector2(base_scale, base_scale)
	# จุด reference อยู่เท้า: เลื่อนตามแถวเท้าจริงของแต่ละสายพันธุ์ (กันเหาะเหนือถนน)
	_sprite.offset = Vector2(0, 2.0 / base_scale - (body_bottom_row - 32))
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
	# เล่นเฟรมเดินจริงจาก sheet (ถ้ามี) — ด้านกบ/กิ้งก่าเห็นขา+ตัวขยับสอดคล้องกัน
	if sheet != null and sheet.get_width() > FRAME_SIZE:
		_anim_t += delta * ANIM_FPS
		_sprite.frame = int(_anim_t) % _sprite.hframes
	else:
		# fallback: เด้งตัวเป็นจังหวะเดิน (scale-pulse trick)
		_bob += delta * 9.0
		var s := base_scale * (1.0 + 0.05 * sin(_bob))
		_sprite.scale = Vector2(s, s)
	# หันหน้าตามทิศเดิน (sheet หน้าตรงไม่กลับ; หันข้าง flip ตาม native facing)
	var nxt := waypoints[_wp_index + 1]
	if not no_flip and absf(nxt.x - position.x) > 1.0:
		var moving_right := nxt.x > position.x
		_sprite.flip_h = faces_left == moving_right  # ทิศเดินสวน native จึงกลับ

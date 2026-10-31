extends Node2D
# มอนสเตอร์เดินตามถนน - หอคอยคู่ฟ้า (T2 + แอนิเมชันเดินลื่น)
# เดินตาม waypoint อย่างมี carry leftover distance (ระยะ step ค้างข้ามจุด -
# กันมอนเร็ว "หยุดหายใจ" ที่จุดกำหนดเพราะเดินเลยหัวไปแล้วใน 1 เฟรม)
# T2.6: วางเท้าที่ position (sprite offset -22) ให้ y-sort จัดลำดับถูกตามระดับจอ
# และวาดเงาวงรีใต้เท้า ยึดตัวมอนกับพื้น (แก้ภาพ "ลอย ๆ" เมื่อตัวทับกัน)

signal reached_castle
signal died(reward: int, at: Vector2)   # T3: ถูกป้อมฆ่า -> ให้ทอง + จุดป๊อบ (พิกัดตาย)

const FRAME_SIZE := 64
const ANIM_FPS := 9.0
const HEAL_RADIUS := 95.0    # รัศมีฮีลออร่าแชแมน (Phase C)

var waypoints: PackedVector2Array = []
var speed := 60.0
var base_scale := 1.5
var max_hp := 30.0
var reward := 15            # ทองที่ได้เมื่อฆ่าสำเร็จ
var damage_resist := 0.0
var dead := false
var flying := false          # กลางอากาศ: ปืนใหญ่/ทหารยิงไม่โดน (Phase C)
var blocker: Node2D = null   # บล็อก: soldier ที่ยืนกั้นหน้า (null = อิสระ)
var melee_dmg := 8.0         # แรงโจมตีที่ใช้ปะทะกับทหาร
var _atk_cd := 0.0
# Phase C: สไลม์ชดแตก
var split_kind := ""         # ชนิดลูกที่แตกออกเมื่อตาย ("" = ไม่แตก)
var split_count := 2         # จำนวนลูกที่แตก
# Phase C: แชแมนฮีล
var heal_power := 0.0        # 0 = ไม่ฮีล ; >0 = ฮีลเปอร์เซ็นต์เลือดของเป้ารอบตัวต่อจังหวะ
var _heal_cd := 0.0
var is_boss := false
var _hp := 30.0
var _progress := 0.0        # ระยะทางที่เดินมาแล้ว (ป้อมเลืองเป้า "ขึ้นหน้าสุด")
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
var _heal_pulse_t := 0.0    # Phase C: จับเวลาวงเขียวฮีล (วาดนาฬิกาลดลงใน _process)
var _fly_bob := 0.0         # Phase C: จังหวะลอยวนของมอนกลางอากาศ

func _apply_sheet(tex: Texture2D, bottom_row: int) -> void:
	# สลับชุดสไปรต์ (หน้าตรง/หันข้าง) - ต้องเลื่อนเท้าตามแถวเท้าของชุดนั้นด้วย
	_sprite.texture = tex
	@warning_ignore("integer_division")
	_sprite.hframes = tex.get_width() / FRAME_SIZE   # หารแบบ int ตั้งใจ (จำนวนเฟรม)
	_sprite.offset = Vector2(0, 2.0 / base_scale - (bottom_row - 32))

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemies")
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
	# เงาใต้เท้า (วงรีโปร่งแสง) - วาดที่ position (เท้า) ; ตายแล้วไม่วาด (ตัวจางหาย)
	if dead:
		return
	if flying:
		# กลางอากาศ: เงาโปร่งเล็กลง ลอยห่างตัว (Phase C ค้างคาว)
		draw_set_transform(Vector2(0, 20), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 12.0, Color(0.05, 0.09, 0.04, 0.22))
	else:
		draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, 17.0, Color(0.05, 0.09, 0.04, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _heal_pulse_t > 0.0:
		var a := 0.45 * clampf(_heal_pulse_t / 0.35, 0.0, 1.0)
		draw_arc(Vector2.ZERO, HEAL_RADIUS, 0.0, TAU, 40, Color(0.3, 1.0, 0.45, a), 2.0, true)
		draw_circle(Vector2.ZERO, HEAL_RADIUS * clampf(1.2 - _heal_pulse_t, 0.05, 1.0), Color(0.3, 1.0, 0.45, a * 0.18))
	# Phase C: บอส = แถบเลือดกว้างพิเศษ (เห็นชัดว่า "อึด" จริง)
	if is_boss and _hp < max_hp:
		var w := 78.0
		draw_rect(Rect2(-w / 2.0, -86.0, w, 8.0), Color(0.08, 0.05, 0.03, 0.88))
		var frac := clampf(_hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-w / 2.0 + 1.0, -85.0, (w - 2.0) * frac, 6.0), Color(0.92, 0.32, 0.18))

func _heal_flash() -> void:
	# เป้าที่โดนฮีล: ฟลาชเขียวสั้น ๆ บนตัวมอน (ผู้เล่นจับได้ว่าแชแมนฮีล)
	if _sprite == null or not is_instance_valid(_sprite):
		return
	_sprite.modulate = Color(0.5, 1.0, 0.55)
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color.WHITE, 0.4)

func _pulse_green() -> void:
	# แชแมน: วงเขียวลูปปั้ดตอนฮีล (วาดตอน _draw)
	_heal_pulse_t = 0.35
	queue_redraw()

func set_blocker(soldier: Node2D) -> void:
	if dead or flying:      # กลางอากาศ: บล็อกไม่ได้ (Phase C ค้างคาว)
		return
	blocker = soldier

func clear_blocker(soldier: Node2D) -> void:
	if blocker == soldier:
		blocker = null

func take_damage(amount: float, bypass_resistance := false) -> void:
	# T3: โดนกระสุนป้อม - แฟลชแดงสั้น ๆ ตายเมื่อหมดเลือด
	if dead:
		return
	var applied_damage := amount
	if not bypass_resistance:
		applied_damage *= 1.0 - clampf(damage_resist, 0.0, 0.85)
	_hp -= applied_damage
	_sprite.modulate = Color(1.0, 0.45, 0.45)
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color.WHITE, 0.14)
	if _hp <= 0.0:
		_die()

func _die() -> void:
	dead = true
	_progress = -1.0   # เลิกเป็นเป้าทันที
	died.emit(reward, position)
	queue_redraw()     # ลบเงาออก
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.35)
	t.tween_property(_sprite, "scale", base_scale * Vector2(0.75, 0.6), 0.35)
	t.chain().tween_callback(queue_free)

func _process(delta: float) -> void:
	if dead or _wp_index >= waypoints.size() - 1:
		return
	# Phase C: แชแมนฮีลออร่า — ฮีลเป้าหมายรอบตัวเป็นจังหวะ (บินยืนพื้นก็ฮีลได้)
	if heal_power > 0.0:
		_heal_pulse_t -= delta
		if _heal_pulse_t < 0.0:
			_heal_pulse_t = 0.0
		_heal_cd -= delta
		if _heal_cd <= 0.0:
			_heal_cd = 2.2
			_heal_nearby()
	# โดนทหารบล็อก: หยุดเดิน + ฟันทหารเป็นจังหวะ (Kingdom Rush style)
	if blocker != null and (not is_instance_valid(blocker) or blocker.dead):
		blocker = null
	if blocker != null:
		_atk_cd -= delta
		if _atk_cd <= 0.0:
			_atk_cd = 1.0
			var b: Node2D = blocker
			var to_b := b.position - position     # อ่านก่อนฟัน (การฟันอาจฆ่าทหาร → blocker ถูกล้างกลางอากาศ)
			if absf(to_b.x) > 0.05:
				_sprite.flip_h = to_b.x > 0.0
			b.take_damage(melee_dmg)
		return
	var step := speed * delta
	_progress += step
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
		# ชุดหน้าตรง (ก้บ/กิ้งก่าไม่มีชุดข้าง): ยังหันหัวตามทิศถนน - เดินขวา = หันขวา (ฟีดแบ็ค T4.1)
		if _sprite.texture != front:
			_apply_sheet(front, body_bottom_row)
		if absf(d.x) > 0.05:
			_sprite.flip_h = d.x > 0.0   # ต้นฉบับ (ไม่ flip) หันซ้ายอยู่แล้ว -> เดินขวาต้องกลับ
		animing = front != null and front.get_width() > FRAME_SIZE
	if animing:
		_anim_t += delta * ANIM_FPS
		_sprite.frame = int(_anim_t) % _sprite.hframes
	else:
		# fallback: เด้งตัวเป็นจังหวะเดิน (scale-pulse trick)
		_bob += delta * 9.0
		var s := base_scale * (1.0 + 0.05 * sin(_bob))
		_sprite.scale = Vector2(s, s)
	# Phase C: กลางอากาศ — ตัวลอยวนขึ้นลงบนถนน (เงาใต้ตัวยังอยู่พื้น)
	if flying:
		_fly_bob += delta * 3.4
		_sprite.position = Vector2(0.0, -18.0 + 5.0 * sin(_fly_bob))
	if heal_power > 0.0 and _heal_pulse_t > 0.0:
		queue_redraw()

func _heal_nearby() -> void:
	# Phase C: ฮีลเพื่อนรอบตัว (รวมใส่บอส) — เป้าฟื้นพร้อม "ฟลาชเขียว"
	if dead:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not e is Node2D or e.dead:
			continue
		if e.position.distance_to(position) > HEAL_RADIUS:
			continue
		# ฟื้นเป็น % ของเลือดเป้า + พื้นเล็ก (ค้างคาวเลือดบางก็ยังฟื้ได้)
		var missing: float = e.max_hp - e._hp
		if missing <= 0.0:
			continue
		e._hp += minf(missing, e.max_hp * heal_power + 2.0)
		e._heal_flash()
	_pulse_green()

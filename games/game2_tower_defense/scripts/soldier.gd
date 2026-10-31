extends Node2D
# ทหารจากค่ายทหาร (Phase B แรงบันดาลใจ Kingdom Rush)
# ยืนบล็อกทางมอน: มอนที่โดนบล็อกจะหยุดเดินแล้วสู้กัน จนฝ่ายหนึ่งตาย
# ค่ายสร้างทหารทดแทนเมื่อตาย (respawn ที่ค่าย) · ฟื้นเลือดเวลาไม่ได้สู้

signal died            # ค่ายใช้ตาราง respawn ต่อ slot

const HIT_FLASH := Color(1.0, 0.55, 0.45)

var barracks_path: Node2D    # ค่ายเจ้าของ
var rally_point := Vector2.ZERO   # พิกัดจุดยืนกลางของค่าย
var slot_index := 0          # ช่องที่ (0 = ซ้าย rally, 1 = ขวา rally)

var max_hp := 60.0
var damage := 10.0
var attack_interval := 0.8
var speed := 95.0
var engage_radius := 64.0    # รัศมีออกหาเป้าจากจุดยืน
var reach := 34.0            # ระยะฟาด
var dead := false

var _hp := 60.0
var _atk_cd := 0.0
var _target: Node2D
var _base_scale := 1.15
var _sprite: Sprite2D
var _bob := 0.0

func _ready() -> void:
	_hp = max_hp
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/art/gen/soldier_knight.png")
	_sprite.offset = Vector2(0.0, -(26.0 / _base_scale))
	_sprite.scale = Vector2(_base_scale, _base_scale)
	add_child(_sprite)
	add_to_group("soldiers")

func take_damage(amount: float) -> void:
	if dead:
		return
	_hp -= amount
	_sprite.modulate = HIT_FLASH
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color.WHITE, 0.12)
	if _hp <= 0.0:
		_die()

func _die() -> void:
	dead = true
	_drop_blocker()
	died.emit()
	queue_redraw()
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.32)
	t.tween_property(_sprite, "scale", _base_scale * Vector2(0.7, 0.65), 0.32)
	t.chain().tween_callback(queue_free)

func _drop_blocker() -> void:
	# ตาย/เปลี่ยนเป้า = ปล่อยมอนที่ถูกบล็อกให้เดินต่อ
	if _target != null and is_instance_valid(_target) and _target.blocker == self:
		_target.clear_blocker(self)

func home_position() -> Vector2:
	# จุดยืนตามช่อง: ค่าย 1 ทหารยืนกลาง, 2 ทหารแยกซ้าย-ขวา
	return _home()

func _process(delta: float) -> void:
	if dead:
		return
	queue_redraw()
	_atk_cd -= delta
	# เป้าหมายถูกแตะโดยตาย/ถูกแปลง = หาใหม่
	if _target != null and (not is_instance_valid(_target) or _target.dead):
		_drop_blocker()
		_target = null
	if _target == null:
		_target = _find_target()
	var goal: Vector2
	if _target != null:
		var to_e: Vector2 = _target.position - position
		goal = _target.position - to_e.normalized() * reach
	else:
		goal = _home()
	var d := goal - position
	if d.length() > 3.0:
		position += d.normalized() * minf(speed * delta, d.length())
		_bob += delta * 11.0
		_sprite.scale = _base_scale * Vector2(1.0 + 0.045 * sin(_bob), 1.0 - 0.045 * sin(_bob))
		if absf(d.x) > 2.0:
			_sprite.flip_h = d.x > 0.0
	else:
		# ฟื้นเลือดเมื่อไม่ติดต่อศัตรู
		_sprite.scale = _base_scale * Vector2.ONE
		_hp = minf(_hp + 4.0 * delta, max_hp)
	if _target != null:
		var dist := _target.position.distance_to(position)
		if dist <= reach + 6.0:
			# บล็อก: มอนยิ้มนี้ต้องหยุด (ค่ายบล็อกเส้นห้อตาม Kingdom Rush)
			if _target.blocker != self:
				_target.set_blocker(self)
			if _atk_cd <= 0.0:
				_atk_cd = attack_interval
				_sprite.scale = Vector2(_base_scale * 1.2, _base_scale * 0.92)
				var at := create_tween()
				at.tween_property(_sprite, "scale", Vector2(_base_scale, _base_scale), 0.15)
				_target.take_damage(damage)
		# เป้าวิ่งหนีออกนอกโลก: ปล่อยด้วย
		if dist > engage_radius + 26.0:
			_drop_blocker()
			_target = null

func _home() -> Vector2:
	if rally_point == Vector2.ZERO:
		return position
	var side := 0.0
	if barracks_path != null and is_instance_valid(barracks_path):
		side = barracks_path.slot_offset(slot_index)
	return rally_point + Vector2(side, 0.0)

func _find_target() -> Node2D:
	var best: Node2D = null
	var best_d := engage_radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead and not e.flying:
			var d: float = e.position.distance_to(_home())
			if d < best_d:
				best_d = d
				best = e
	return best

func _draw() -> void:
	if dead:
		return
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 11.0, Color(0.05, 0.09, 0.04, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _hp < max_hp - 0.01:
		var w := 34.0
		draw_rect(Rect2(-w / 2.0, -44.0, w, 5.5), Color(0.08, 0.05, 0.03, 0.85))
		var frac := clampf(_hp / max_hp, 0.0, 1.0)
		draw_rect(Rect2(-w / 2.0 + 1.0, -43.2, (w - 2.0) * frac, 4.0), Color(0.35, 0.85, 0.95))

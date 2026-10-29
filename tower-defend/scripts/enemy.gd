extends Node2D
# มอนสเตอร์เดินตามถนน - หอคอยคู่ฟ้า (T2)
# เดินตาม waypoint อย่างมี carry leftover distance (ระยะ step ค้างข้ามจุด -
# กันมอนเร็ว "หยุดหายใจ" ที่จุดกำหนดเพราะเดินเลยหัวไปแล้วใน 1 เฟรม)

signal reached_castle

var waypoints: PackedVector2Array = []
var speed := 60.0
var base_scale := 1.5
var texture: Texture2D

var _wp_index := 0
var _bob := 0.0
var _sprite: Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.scale = Vector2(base_scale, base_scale)
	add_child(_sprite)
	# ยืนจุดแรกของเส้นทาง
	if waypoints.size() > 0:
		position = waypoints[0]

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
	# เด้งตัวเป็นจังหวะเดิน (เกม 1 ใช้ scale-pulse trick แทนเฟรมจริง)
	_bob += delta * 9.0
	var s := base_scale * (1.0 + 0.05 * sin(_bob))
	_sprite.scale = Vector2(s, s)
	# หันหน้าตามทิศเดิน
	var nxt := waypoints[_wp_index + 1]
	if absf(nxt.x - position.x) > 1.0:
		_sprite.flip_h = nxt.x < position.x

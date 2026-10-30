extends CharacterBody2D
## บิตคูผู้คุม — มินิบอสยอดปราสาท (ด่าน 8)
## พฤติกรรม: ลอยจูงตามซ้าย-ขวาเหนือยอด แล้ว "กางดิ่ง" พุ่งลงที่ตำแหน่งผู้เล่นทุก 4 วิ
## จัดการ: เหยียบหัว 3 ครั้ง (ระหว่างมึนหลังโดนเหยียบจะเปลี่ยนเป้าหมาย), ข้าง/ล่างชน = แพ้
## ตาย: ระเบิดเหรียญรางวัล + จอสั่น + ปลดประตูสู่ธง (ธงจริงอยู่หลังจุดบอสอยู่แล้ว)

signal caught_player
signal defeated(boss: Node2D)

const HOVER_SPEED := 120.0
const HOVER_RANGE := 240.0
const DIVE_SPEED := 520.0
const DIVE_SETUP_TIME := 0.6
const RISE_SPEED := 260.0
const HP_MAX := 3
const STUN_TIME := 1.1

@onready var visual: Sprite2D = $Visual
@onready var hitbox: Area2D = $Hitbox
@onready var bar_hint: Label = get_node_or_null("BossBarHint")

enum Phase { HOVER, SETUP, DIVE, RISE, STUN, DEAD }

var hp := HP_MAX
var phase: int = Phase.HOVER
var dir := 1.0
var _t := 0.0
var _anchor := Vector2.ZERO
var _hover_right := 0.0
var _tired := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hitbox.body_entered.connect(_on_body_entered)
	_anchor = global_position
	_hover_right = _anchor.x + HOVER_RANGE
	_t = randf() * TAU

func _physics_process(delta: float) -> void:
	if phase == Phase.DEAD:
		return
	_t += delta
	var player := get_tree().get_first_node_in_group("player")
	match phase:
		Phase.HOVER:
			velocity.x = dir * HOVER_SPEED
			velocity.y = sin(_t * 2.6) * 40.0
			# เหยียบไปลอยถึงขอบหรือระยะจูงตามพ้น เหวี่ยงกลับ
			if global_position.x >= _hover_right:
				dir = -1.0
			if global_position.x <= _anchor.x - HOVER_RANGE:
				dir = 1.0
			if player != null and _tired <= 0.0:
				_begin_setup(player)
			_tired = maxf(_tired - delta, 0.0)
		Phase.SETUP:
			# ตั้งตัว: โหว่เวลาให้ผู้เล่นวางแผน (มุมขึ้นเล็กน้อย)
			velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
			velocity.y = -40.0
			if _phase_time >= DIVE_SETUP_TIME:
				_begin_dive(player)
		Phase.DIVE:
			# พุ่งลง 45 องศาตามเป้าที่ล็อกตอนตั้งตัว — ตีพุ่งชนพื้นแล้วลุกขึ้น
			velocity.y = DIVE_SPEED
			velocity.x = _dive_vx
			if is_on_floor():
				_shake(0.4)
				_enter(Phase.RISE)
		Phase.RISE:
			velocity.y = -RISE_SPEED
			velocity.x = clampf((_anchor.x - global_position.x) * 2.0, -160.0, 160.0)
			if global_position.y <= _anchor.y:
				_enter(Phase.HOVER)
		Phase.STUN:
			velocity.x = 0.0
			velocity.y = 60.0
			_stun_left -= delta
			if _stun_left <= 0.0:
				_enter(Phase.RISE)
	move_and_slide()
	visual.flip_h = velocity.x < 0.0
	_animate(delta)

var _phase_time := 0.0
var _dive_vx := 0.0
var _stun_left := 0.0

func _enter(p: int) -> void:
	phase = p
	_phase_time = 0.0

func _begin_setup(player: Node2D) -> void:
	_enter(Phase.SETUP)

func _begin_dive(player: Node2D) -> void:
	if player != null:
		var to_p: Vector2 = player.global_position - global_position
		_dive_vx = clampf(to_p.x * 1.4, -DIVE_SPEED, DIVE_SPEED) * 0.8
	else:
		_dive_vx = dir * 200.0
	_enter(Phase.DIVE)

func _animate(delta: float) -> void:
	var ang := 0.0
	match phase:
		Phase.SETUP:
			ang = -0.35
		Phase.DIVE:
			ang = 0.5
		Phase.STUN:
			ang = sin(_t * 40.0) * 0.25
	visual.rotation = ang

func _on_body_entered(body: Node2D) -> void:
	if phase == Phase.DEAD:
		return
	if not body.is_in_group("player"):
		return
	var from_above: bool = body.velocity.y > 0.0 and body.global_position.y < global_position.y - 10.0
	if from_above and phase != Phase.STUN:
		hp -= 1
		body.velocity.y = -480.0
		_stomp_hit()
	else:
		caught_player.emit()

var _last_stomp_id := 0

func _refresh_bar() -> void:
	if bar_hint != null:
		bar_hint.text = "♥".repeat(maxi(hp, 0))

func _stomp_hit() -> void:
	_shake(0.35)
	hit_stop(0.08)
	var p := get_node_or_null("../../SfxStomp")
	if p != null:
		p.play()
	_tired = 2.2
	_last_stomp_id = Time.get_ticks_msec()
	_refresh_bar()
	if hp <= 0:
		_enter(Phase.DEAD)
		velocity = Vector2.ZERO
		hitbox.set_deferred("monitoring", false)
		var tw := create_tween()
		tw.tween_property(visual, "scale", visual.scale * 1.9, 0.16)
		tw.parallel().tween_property(visual, "modulate:a", 0.0, 0.3)
		tw.tween_callback(func() -> void:
			defeated.emit(self)
			queue_free()
		)
	else:
		_enter(Phase.STUN)
		_stun_left = STUN_TIME
		# มึน = โอกาสสอง — วาดบาดแผล (จางสีตาม HP)
		visual.self_modulate = Color(1.0, 0.55 + 0.15 * hp, 0.55 + 0.15 * hp)

func _shake(amount: float) -> void:
	var main := get_tree().current_scene
	if main != null and main.has_method("add_trauma"):
		main.add_trauma(amount)

func hit_stop(duration := 0.06, slow := 0.05) -> void:
	var main := get_tree().current_scene
	if main != null and main.has_method("hit_stop"):
		main.hit_stop(duration, slow)

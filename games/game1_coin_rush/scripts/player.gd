extends CharacterBody2D
## Mario-style side-scroll platformer controller.

const MAX_SPEED := 235.0
const RUN_MULT := 1.4
const GROUND_ACCEL := 1500.0
const GROUND_DECEL := 2200.0
const AIR_ACCEL := 1100.0
const AIR_DECEL := 450.0
const SKID_DECEL := 3200.0

const JUMP_HEIGHT := 130.0
const TIME_TO_APEX := 0.34
const GRAVITY := 2.0 * JUMP_HEIGHT / (TIME_TO_APEX * TIME_TO_APEX)
const JUMP_VELOCITY := -2.0 * JUMP_HEIGHT / TIME_TO_APEX
const FALL_GRAVITY_MULT := 1.35
const MAX_FALL_SPEED := 760.0
const COYOTE_TIME := 0.12
const JUMP_BUFFER := 0.15
const JUMP_CUT := 0.55
# ดับเบิลจัมพ์สุดฟุ้ง: กดกระโดดกลางอากาศได้อีก 2 ชั้น (ช่วยตอนตกลงลึกแล้วต้องไต่กลับ)
const MAX_AIR_JUMPS := 2
const AIR_JUMP_SCALE := 0.9
const RUN_FPS := 12.0
const RUN_FRAME_COUNT := 8
const AIR_FRAME := 3
const IDLE_FRAME := 8

		# สกินฮีโร่ (ดัชนีกับ title.gd: 0=คลาสสิก, 1=สายน้ำฟ้า, 2=อัคคีราช, 3=ม่วงราตรี, 4=ใบไม้ระยิบ)
const SKIN_SHEETS: Array[String] = [
	"res://assets/art/sprites/kubi_hero_run_sheet.png",
	"res://assets/art/gen/kubi_hero_run_sheet_cyan.png",
	"res://assets/art/gen/kubi_hero_run_sheet_ember.png",
	"res://assets/art/gen/kubi_hero_run_sheet_violet.png",
	"res://assets/art/gen/kubi_hero_run_sheet_leaf.png",
]

@onready var visual: Sprite2D = $Visual
var _coyote := 0.0
var _buffer := 0.0
var _was_on_floor := false
var _air_used := 0
var _dust: CPUParticles2D
var _air_ring: CPUParticles2D
var _bob := 0.0
var _frame_t := 0.0
var _rest_scale := Vector2.ONE
var _dust_cd := 0.0

func _ready() -> void:
	_rest_scale = visual.scale
	add_to_group("player")
	_dust = CPUParticles2D.new()
	_dust.name = "Dust"
	_dust.emitting = false
	_dust.one_shot = true
	_dust.amount = 8
	_dust.lifetime = 0.3
	_dust.explosiveness = 0.9
	_dust.direction = Vector2(0, -1)
	_dust.spread = 70.0
	_dust.gravity = Vector2(0, 420)
	_dust.initial_velocity_min = 60.0
	_dust.initial_velocity_max = 140.0
	_dust.scale_amount_min = 0.5
	_dust.scale_amount_max = 1.2
	_dust.position = Vector2(0, 14)
	add_child(_dust)
	# วงแหวนลมพุ่งลงแตกกระจายเป็นวง ตอนดับเบิลจัมพ์
	_air_ring = CPUParticles2D.new()
	_air_ring.name = "AirRing"
	_air_ring.emitting = false
	_air_ring.one_shot = true
	_air_ring.explosiveness = 1.0
	_air_ring.amount = 16
	_air_ring.lifetime = 0.32
	_air_ring.direction = Vector2(0, 1)
	_air_ring.spread = 62.0
	_air_ring.gravity = Vector2(0, 260)
	_air_ring.initial_velocity_min = 150.0
	_air_ring.initial_velocity_max = 240.0
	_air_ring.scale_amount_min = 0.45
	_air_ring.scale_amount_max = 0.85
	_air_ring.color = Color(1.0, 0.96, 0.8, 0.8)
	_air_ring.position = Vector2(0, 10)
	add_child(_air_ring)

func _input(event: InputEvent) -> void:
	# Event-driven jump capture: a press can never be missed between frames.
	if event.is_echo():
		return
	if event.is_action_pressed("jump"):
		_buffer = JUMP_BUFFER
	elif event.is_action_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

func _physics_process(delta: float) -> void:
	# Coyote + gravity + dust cooldown
	_dust_cd = maxf(_dust_cd - delta, 0.0)
	if is_on_floor():
		_coyote = COYOTE_TIME
		_air_used = 0
	else:
		_coyote = maxf(_coyote - delta, 0.0)
		var g := GRAVITY * (FALL_GRAVITY_MULT if velocity.y > 0.0 else 1.0)
		velocity.y = minf(velocity.y + g * delta, MAX_FALL_SPEED)

	_buffer = maxf(_buffer - delta, 0.0)

	# Resolve jump (buffer + coyote = forgiving, always fires)
	# พื้น/โคโยตีมาก่อนเสมอ — หมดคิวแล้วกดซ้ำกลางอากาศใช้งบ MAX_AIR_JUMPS
	if _buffer > 0.0:
		if _coyote > 0.0:
			velocity.y = JUMP_VELOCITY
			_buffer = 0.0
			_coyote = 0.0
			_squash(Vector2(0.78, 1.22))
			_play_sfx("SfxJump")
		elif _air_used < MAX_AIR_JUMPS:
			_air_used += 1
			velocity.y = JUMP_VELOCITY * AIR_JUMP_SCALE
			_buffer = 0.0
			_squash(Vector2(0.82, 1.15))
			_air_ring.restart()
			_play_sfx("SfxJump")

	# Horizontal movement with skid/friction
	var dir := Input.get_axis("move_left", "move_right")
	var sprinting := Input.is_key_pressed(KEY_SHIFT)
	var speed := MAX_SPEED * (RUN_MULT if sprinting else 1.0)
	var turning := dir != 0.0 and signf(velocity.x) != 0.0 and signf(dir) != signf(velocity.x)
	if dir != 0.0:
		var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		if turning and is_on_floor():
			accel = SKID_DECEL
			_squash(Vector2(1.15, 0.9))
			if _dust_cd <= 0.0:
				_dust.restart()
				_dust_cd = 0.25
		velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
	else:
		var decel := GROUND_DECEL if is_on_floor() else AIR_DECEL
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	_animate(delta, dir)
	move_and_slide()

	# Landing
	if is_on_floor() and not _was_on_floor:
		_on_landed()
	_was_on_floor = is_on_floor()

func _animate(delta: float, dir: float) -> void:
	if dir != 0.0:
		visual.flip_h = dir < 0.0
	if visual.hframes > 1:
		if is_on_floor() and absf(velocity.x) > 20.0:
			_frame_t += delta * RUN_FPS * (1.0 + absf(velocity.x) / MAX_SPEED * 0.4)
			visual.frame = int(_frame_t) % RUN_FRAME_COUNT
		elif not is_on_floor():
			visual.frame = AIR_FRAME
		else:
			_frame_t = 0.0
			visual.frame = IDLE_FRAME
	if is_on_floor() and dir != 0.0:
		_bob += delta * 9.0
		visual.rotation = dir * 0.05
		visual.position.y = -absf(sin(_bob)) * 2.0
	elif not is_on_floor():
		visual.rotation = clampf(velocity.x / MAX_SPEED, -1.0, 1.0) * 0.10
		visual.position.y = 0.0
	else:
		visual.rotation = 0.0
		visual.position.y = 0.0

func _on_landed() -> void:
	_squash(Vector2(1.25, 0.75))
	_play_sfx("SfxLand")
	_dust.restart()

func set_skin(idx: int) -> void:
	visual.texture = load(SKIN_SHEETS[clampi(idx, 0, SKIN_SHEETS.size() - 1)])

func _squash(target: Vector2) -> void:
	visual.scale = _rest_scale * target
	var tw := create_tween()
	tw.tween_property(visual, "scale", _rest_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_sfx(node_name: String) -> void:
	var main := get_tree().current_scene
	if main:
		var p := main.get_node_or_null(node_name)
		if p:
			p.play()

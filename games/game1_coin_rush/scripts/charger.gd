extends CharacterBody2D
## ชาร์เจอร์ — แมลงดุจ่ากไล่: เดินกันในพื้นที่เดิน แล้วก็ตื่นวิ่งรุกแบบทันที
## เมื่อเห็นผู้เล่นอยู่ระดับเดียวกัน เมื่อวิ่งชนกำแพงจะมึนงงงันทันที (เคียงแนวความเข้าใจ platformer)

signal caught_player

const PACE := 55.0
const CHARGE_SPEED := 330.0
const CHARGE_TIME := 0.75
const STUN_TIME := 0.55
const COOL_TIME := 1.6
const SIGHT_DIST := 420.0
const SIGHT_HEIGHT := 48.0

const GRAVITY := 1800.0

@onready var visual: Sprite2D = $Visual
@onready var hitbox: Area2D = $Hitbox
@onready var edge_check: RayCast2D = $EdgeCheck

var dir := 1.0
var _dead := false
var _charge := 0.0
var _cool := 0.0
var _stun := 0.0
var _anim_timer := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hitbox.body_entered.connect(_on_body_entered)
	dir = 1.0 if randf() > 0.5 else -1.0

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)

	_stun = maxf(_stun - delta, 0.0)
	_cool = maxf(_cool - delta, 0.0)
	if _charge > 0.0:
		_charge -= delta
		if _charge <= 0.0:
			_cool = COOL_TIME
		velocity.x = dir * CHARGE_SPEED
	elif _stun > 0.0:
		velocity.x = 0.0
	else:
		velocity.x = dir * PACE

	edge_check.position.x = 12.0 * dir
	edge_check.force_raycast_update()

	move_and_slide()

	var hit_wall := is_on_wall()
	if hit_wall:
		dir *= -1.0
		if _charge > 0.0:
			_charge = 0.0
			_stun = STUN_TIME
			_squash(Vector2(1.3, 0.8))
			var main := get_tree().current_scene
			if main and main.has_method("add_trauma"):
				main.add_trauma(0.12)
	if is_on_floor() and not edge_check.is_colliding() and _charge <= 0.0:
		dir *= -1.0

	# จับสายตา: เห็นผู้เล่นระดับเดียว → ชาร์จ
	if _cool <= 0.0 and _stun <= 0.0 and _charge <= 0.0:
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			var d: Vector2 = player.global_position - global_position
			if absf(d.y) < SIGHT_HEIGHT and signf(d.x) == dir and absf(d.x) < SIGHT_DIST:
				_charge = CHARGE_TIME
				_squash(Vector2(0.75, 1.25))

	_animate(delta)
	visual.flip_h = dir < 0.0

func _animate(delta: float) -> void:
	var shake_t := 0.0
	if _charge > 0.0:
		shake_t = 4.0
	elif _stun > 0.0:
		shake_t = 1.5
	visual.rotation = sin(Time.get_ticks_msec() / 25.0) * 0.05 * shake_t

func _squash(target: Vector2) -> void:
	var rest := visual.scale
	visual.scale = rest * target
	var tw := create_tween()
	tw.tween_property(visual, "scale", rest, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if not body.is_in_group("player"):
		return
	if body.velocity.y > 0.0 and body.global_position.y < global_position.y - 6.0:
		_dead = true
		body.velocity.y = -420.0
		var main := get_tree().current_scene
		if main:
			if main.has_method("add_trauma"):
				main.add_trauma(0.3)
				main.hit_stop(0.06)
			var p := main.get_node_or_null("SfxStomp")
			if p:
				p.play()
		hitbox.set_deferred("monitoring", false)
		var tw := create_tween()
		tw.tween_property(visual, "scale", visual.scale * 1.6, 0.08)
		tw.parallel().tween_property(visual, "modulate:a", 0.0, 0.1)
		tw.tween_callback(queue_free)
	else:
		caught_player.emit()

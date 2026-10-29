extends Node2D
# ฮีโร่ Kubi (T5) - คลิกขวาสั่งเดิน / ฟาดศัตรูอัตโนมัติในรัศมี / ฟื้นเลือดเมื่อพักสู้
# โดนรุมใกล้ตัวจะเสียเลือด ; เลือดหมด = ล่ม 0.25 จาง แล้วเกิดใหม่หน้าปราสาทครบเลือด
# เฟรมเดิน: kubi_hero_sheet.png 8 ช่อง (512x64) / ยืน: kubi_hero_neutral.png

const WALK_TEX := preload("res://assets/art/gen/kubi_hero_sheet.png")
const IDLE_TEX := preload("res://assets/art/gen/kubi_hero_neutral.png")
const GATE := Vector2(816, 470)   # จุดเกิดใหม่ (หน้าปราสาท)

var speed := 110.0
var attack_range := 130.0
var attack_dmg := 18.0
var attack_interval := 0.9
var max_hp := 100.0
var contact_dmg := 7.0      # ความเจ็บจากศัตรูแนมตัววนจนอยู่ติดกัน (จังหวะ 0.9 วิ)
var respawn_time := 8.0

var _hp := 100.0
var _dead := false
var _respawn_t := 0.0
var _target := Vector2.ZERO
var _moving := false
var _attack_cd := 0.0
var _hurt_cd := 0.0
var _regen_cd := 0.0
var _anim_t := 0.0
var _sprite: Sprite2D

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = IDLE_TEX
	_sprite.offset = Vector2(0, -14)
	_sprite.scale = Vector2(1.35, 1.35)
	add_child(_sprite)
	add_to_group("hero")
	_hp = max_hp

func move_to(pos: Vector2) -> void:
	if _dead:
		return
	_target = pos
	_moving = true

func take_damage(amount: float) -> void:
	if _dead:
		return
	_hp -= amount
	if _hp <= 0.0:
		_die()

func _die() -> void:
	_dead = true
	_hp = 0.0
	_respawn_t = respawn_time
	_moving = false
	_sprite.texture = IDLE_TEX
	_sprite.hframes = 1
	_sprite.frame = 0
	_sprite.modulate = Color(1.0, 1.0, 1.0, 0.25)

func _respawn() -> void:
	_dead = false
	_hp = max_hp
	position = GATE
	_moving = false
	_sprite.modulate = Color.WHITE

func _process(delta: float) -> void:
	queue_redraw()   # แถบเลือดอยู่ใน _draw ต้องวาดใหม่ทุกเฟรม
	if _dead:
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			_respawn()
		return
	_attack_cd -= delta
	_hurt_cd -= delta
	# ฟื้นเลือดสู้ช้า ๆ ต่อวินาที
	_regen_cd += delta
	if _regen_cd >= 1.0:
		_regen_cd = 0.0
		_hp = minf(_hp + 3.0, max_hp)
	# เดินไปหมุดที่สั่ง
	if _moving:
		var to := _target - position
		var step := speed * delta
		if to.length() <= step:
			position = _target
			_moving = false
		else:
			position += to.normalized() * step
			if absf(to.x) > 0.05:
				_sprite.flip_h = to.x > 0.0   # ยืนกายหันตามทางที่เดิน
	# ภาพเฟรมเดิน/ยืน (sheet เดิน 8 ช่อง)
	if _moving:
		if _sprite.texture != WALK_TEX:
			_sprite.texture = WALK_TEX
			_sprite.hframes = 8
		_anim_t += delta * 10.0
		_sprite.frame = int(_anim_t) % 8
	else:
		_sprite.texture = IDLE_TEX
		_sprite.hframes = 1
		_sprite.frame = 0
	# เลือกตัวใกล้สุดในรัศมีฟาด
	var best: Node2D = null
	var bd := attack_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node2D and not e.dead:
			var d: float = e.position.distance_to(position)
			if d < bd:
				bd = d
				best = e
	if best != null and _attack_cd <= 0.0:
		_attack_cd = attack_interval
		best.take_damage(attack_dmg)
	# โดนรุม: ตัวใดยืนติดกันนานจนเย็น 0.9 วิ = บีบเลือดหนึ่งจังหวะ
	if _hurt_cd <= 0.0:
		for e2 in get_tree().get_nodes_in_group("enemies"):
			if e2 is Node2D and not e2.dead and e2.position.distance_to(position) <= 52.0:
				take_damage(contact_dmg)
				_hurt_cd = 0.9
				break

func _draw() -> void:
	# แถบเลือดเหนือหัว (โชว์เสมอเมื่อเลือดไม่เต็ม)
	if _dead or _hp >= max_hp - 0.01:
		return
	var w := 46.0
	draw_rect(Rect2(-w / 2.0, -52.0, w, 7.0), Color(0.08, 0.05, 0.03, 0.85))
	var frac := clampf(_hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(-w / 2.0 + 1.0, -51.0, (w - 2.0) * frac, 5.0), Color(0.35, 0.9, 0.3))

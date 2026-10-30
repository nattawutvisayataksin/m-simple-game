extends CharacterBody2D
## บัตบิต — ค้างคาวไวรัส: บินจริง (ไม่มีแรงโน้มถ่วง) ลอยขึ้นลงสไปน์ไปตามระยะ
## ตามเคืองเหมือน enemy.gd ถ้าเหียบจากข้างบนจะจม, ชนด้านอื่นจะแพ้

signal caught_player

const PACE := 66.0
const SQUASH_TIME := 0.09

@export var sway_amplitude := 34.0
@export var sway_speed := 2.4
@export var flap_fps := 7.0

@onready var visual: Sprite2D = $Visual
@onready var hitbox: Area2D = $Hitbox

var dir := 1.0
var _dead := false
var _t := 0.0
var _base_y := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hitbox.body_entered.connect(_on_body_entered)
	_base_y = global_position.y
	_t = randf() * TAU

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	velocity.x = dir * PACE
	# ความเร็วแนวตั้ง = อนุพันธ์ของ sine ทำให้ลอยขึ้นลงเนียน (ระยะเวีย=sway_amplitude)
	velocity.y = cos(_t * sway_speed) * sway_amplitude * sway_speed
	move_and_slide()
	if is_on_wall():
		dir *= -1.0
	_animate(delta)
	visual.flip_h = dir > 0.0

func _animate(delta: float) -> void:
	# กระพือปีก: บีบตัวแกน y แบบ cos และกลับหางเล็กน้อย
	var flap := cos(_t * flap_fps)
	visual.position.y = -2.0 - 2.0 * flap
	visual.scale = Vector2(1.3 + 0.12 * flap, 1.3 - 0.18 * flap)
	visual.rotation = clampf(velocity.x / 240.0, -1.0, 1.0) * 0.12

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

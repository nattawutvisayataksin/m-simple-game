extends CharacterBody2D
## Glitch Hopper: blue glitch bug that hops toward the player. Stompable from above.

signal caught_player

const HOP_CD_MIN := 0.7
const HOP_CD_MAX := 1.3
const HOP_VX := 200.0
const HOP_VY := -380.0
const GRAVITY := 1600.0
const MAX_FALL := 900.0

@onready var visual: Sprite2D = $Visual
@onready var hitbox: Area2D = $Hitbox
@onready var edge_check: RayCast2D = $EdgeCheck

var dir := 1.0
var _dead := false
var _cd := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hitbox.body_entered.connect(_on_body_entered)
	_cd = randf_range(0.2, HOP_CD_MAX)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	elif _cd <= 0.0:
		_hop()
	else:
		_cd = maxf(_cd - delta, 0.0)
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)

	move_and_slide()
	_animate()
	visual.flip_h = dir < 0.0

func _hop() -> void:
	# aim at the player when close; otherwise patrol direction; never hop off an edge
	var target_dir := dir
	var player := get_tree().get_first_node_in_group("player")
	if player and absf(player.global_position.x - global_position.x) < 420.0:
		target_dir = signf(player.global_position.x - global_position.x)
		if target_dir == 0.0:
			target_dir = dir
	edge_check.position.x = 16.0 * target_dir
	edge_check.force_raycast_update()
	if is_on_floor() and not edge_check.is_colliding():
		target_dir = -target_dir
	dir = target_dir
	velocity = Vector2(dir * HOP_VX, HOP_VY)
	_cd = randf_range(HOP_CD_MIN, HOP_CD_MAX)
	if is_on_floor():
		_squash(Vector2(0.8, 1.2))

func _on_body_entered(body: Node2D) -> void:
	if _dead or not body.is_in_group("player"):
		return
	# Stomp: player falling and above us
	if body.velocity.y > 0.0 and body.global_position.y < global_position.y - 6.0:
		_dead = true
		body.velocity.y = -460.0
		var main := get_tree().current_scene
		if main and main.has_method("add_trauma"):
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

func _animate() -> void:
	var squash := clampf(velocity.y / HOP_VY, -1.0, 1.0)
	visual.scale = Vector2(1.3, 1.3) * Vector2(1.0 - 0.12 * absf(squash), 1.0 + 0.14 * absf(squash))

func _squash(target: Vector2) -> void:
	visual.scale = Vector2(1.3, 1.3) * target
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector2(1.3, 1.3), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

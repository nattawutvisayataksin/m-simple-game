extends CharacterBody2D
## Platform enemy: walks on platforms, turns at walls/edges, damages player; stomped from above.

signal caught_player

const SPEED := 90.0
const GRAVITY := 1800.0
const MAX_FALL := 900.0

@export var anim_fps := 8.0

@onready var visual: Sprite2D = $Visual
@onready var hitbox: Area2D = $Hitbox
@onready var edge_check: RayCast2D = $EdgeCheck

var dir := 1.0
var _dead := false
var _anim_timer := 0.0

func _ready() -> void:
	add_to_group("enemies")
	hitbox.body_entered.connect(_on_body_entered)
	dir = 1.0 if randf() > 0.5 else -1.0

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	velocity.x = dir * SPEED

	edge_check.position.x = 12.0 * dir
	edge_check.force_raycast_update()

	move_and_slide()

	if is_on_wall():
		dir *= -1.0
	if is_on_floor() and not edge_check.is_colliding():
		dir *= -1.0

	_animate(delta)
	visual.flip_h = dir < 0.0

func _animate(delta: float) -> void:
	if visual.hframes > 1:
		_anim_timer += delta
		if _anim_timer >= 1.0 / anim_fps:
			_anim_timer = 0.0
			visual.frame = 1 + (visual.frame % (visual.hframes - 1))

func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if not body.is_in_group("player"):
		return
	# Stomp: player falling and above enemy
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
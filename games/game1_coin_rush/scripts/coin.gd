extends Area2D

signal collected(value: int)

@export var value := 1

@onready var visual: Sprite2D = $Visual

var _taken := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if visual.hframes > 1:
		# rotate frames
		pass
	# simple spin via frame timer handled below
	_anim_timer += delta
	if _anim_timer >= 1.0 / 10.0:
		_anim_timer = 0.0
		if visual.hframes > 1:
			visual.frame = (visual.frame + 1) % visual.hframes
	if value >= 3:
		visual.modulate.a = 0.75 + 0.25 * sin(Time.get_ticks_msec() / 120.0)

var _anim_timer := 0.0

func _on_body_entered(body: Node2D) -> void:
	if _taken:
		return
	if body.is_in_group("player"):
		_taken = true
		collected.emit(value)
		set_deferred("monitoring", false)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.2)
		tw.tween_property(self, "modulate:a", 0.0, 0.2)
		tw.chain().tween_callback(queue_free)

func disable() -> void:
	_taken = true
	set_deferred("monitoring", false)
	set_process(false)
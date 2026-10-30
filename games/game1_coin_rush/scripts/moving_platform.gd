extends AnimatableBody2D

@export var point_a := Vector2.ZERO
@export var point_b := Vector2.ZERO
@export var move_speed := 80.0

func _ready() -> void:
	if point_a == Vector2.ZERO and point_b == Vector2.ZERO:
		point_a = position
		point_b = position + Vector2(120, 0)
	position = point_a
	_loop()

func _loop() -> void:
	var dist := point_a.distance_to(point_b)
	var dur := dist / move_speed if move_speed > 0 else 1.0
	var tw := create_tween()
	tw.tween_property(self, "position", point_b, dur)
	tw.tween_property(self, "position", point_a, dur)
	tw.set_loops()
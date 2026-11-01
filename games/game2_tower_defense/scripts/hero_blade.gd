extends "res://scripts/hero.gd"
## Alternate playable hero: a high-fantasy JRPG swordmaster.
## The arm, wrist, and blade are drawn from one animated pose, so the sword is
## always attached to the hand instead of being a separately rotating sprite.

class SwordmasterVisual extends Node2D:
	var _time := 0.0
	var _walk_phase := 0.0
	var _swing_progress := -1.0
	var _moving := false
	var _facing := Vector2.RIGHT
	var _attack_dir := Vector2.RIGHT

	func _process(delta: float) -> void:
		_time += delta
		var hero: Variant = get_parent()
		if hero == null or not is_instance_valid(hero):
			return
		_moving = hero._velocity.length() > 5.0
		if _moving:
			_walk_phase += delta * lerpf(8.0, 13.0, clampf(hero._velocity.length() / hero.speed, 0.0, 1.0))
			_facing = hero._velocity.normalized()
		elif hero._swing_t <= 0.0:
			_facing = hero._facing_direction
		_swing_progress = 1.0 - hero._swing_t / 0.44 if hero._swing_t > 0.0 else -1.0
		_attack_dir = hero._attack_direction
		queue_redraw()

	func _polygon(points: PackedVector2Array, fill: Color, edge := Color(0.12, 0.12, 0.19), width := 2.0) -> void:
		draw_colored_polygon(points, fill)
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, edge, width, true)

	func _draw() -> void:
		var stride := sin(_walk_phase)
		var bounce := absf(stride) * 1.2 if _moving else sin(_time * 2.2) * 0.55
		var attack_angle := _attack_dir.angle()
		var swing := smoothstep(0.08, 0.76, clampf(_swing_progress, 0.0, 1.0)) if _swing_progress >= 0.0 else 0.0
		var blade_angle := attack_angle + lerpf(-1.35, 1.05, swing) if _swing_progress >= 0.0 else _facing.angle() - 0.9
		var root_y := -bounce

		# Grounding shadow and short royal-blue cape, behind the body.
		draw_set_transform(Vector2(0.0, 3.0), 0.0, Vector2(1.0, 0.36))
		draw_circle(Vector2.ZERO, 16.0, Color(0.035, 0.045, 0.065, 0.35))
		draw_set_transform(Vector2(0.0, root_y), 0.0, Vector2.ONE)
		_polygon(PackedVector2Array([Vector2(-7, -37), Vector2(8, -38), Vector2(15, -19), Vector2(5, -12), Vector2(-13, -17)]), Color(0.18, 0.32, 0.65), Color(0.08, 0.10, 0.19), 2.0)
		_polygon(PackedVector2Array([Vector2(-8, -23), Vector2(-1, -20), Vector2(-11, -15)]), Color(0.91, 0.69, 0.27), Color(0.36, 0.22, 0.12), 1.0)

		# Stepping legs and reinforced boots.
		var leg_swing := stride * 2.2 if _moving else 0.0
		draw_line(Vector2(-4, -21), Vector2(-5 + leg_swing, -8), Color(0.16, 0.23, 0.39), 7.0, true)
		draw_line(Vector2(4, -21), Vector2(5 - leg_swing, -8), Color(0.16, 0.23, 0.39), 7.0, true)
		draw_line(Vector2(-8 + leg_swing, -8), Vector2(-2 + leg_swing, -5), Color(0.13, 0.15, 0.22), 6.0, true)
		draw_line(Vector2(2 - leg_swing, -8), Vector2(8 - leg_swing, -5), Color(0.13, 0.15, 0.22), 6.0, true)
		draw_line(Vector2(-7 + leg_swing, -9), Vector2(-2 + leg_swing, -8), Color(0.83, 0.63, 0.27), 2.0, true)
		draw_line(Vector2(3 - leg_swing, -9), Vector2(8 - leg_swing, -8), Color(0.83, 0.63, 0.27), 2.0, true)

		# Armored torso with a bright chest plate and gold trim.
		_polygon(PackedVector2Array([Vector2(-10, -37), Vector2(8, -37), Vector2(11, -23), Vector2(0, -19), Vector2(-12, -24)]), Color(0.27, 0.43, 0.68), Color(0.09, 0.13, 0.23), 2.0)
		_polygon(PackedVector2Array([Vector2(-5, -34), Vector2(4, -34), Vector2(6, -26), Vector2(0, -23), Vector2(-7, -27)]), Color(0.74, 0.83, 0.88), Color(0.24, 0.31, 0.39), 1.5)
		_polygon(PackedVector2Array([Vector2(-1, -33), Vector2(2, -30), Vector2(-1, -26), Vector2(-4, -30)]), Color(0.99, 0.76, 0.28), Color(0.48, 0.27, 0.10), 1.0)
		draw_line(Vector2(-9, -25), Vector2(8, -25), Color(0.91, 0.68, 0.26), 2.0, true)

		# Head, swept golden hair, and a small sapphire circlet.
		draw_circle(Vector2(0.0, -45.0), 9.2, Color(0.92, 0.70, 0.47))
		_polygon(PackedVector2Array([Vector2(-9, -48), Vector2(-7, -56), Vector2(-1, -59), Vector2(7, -55), Vector2(10, -48), Vector2(4, -51), Vector2(0, -47), Vector2(-5, -50)]), Color(0.95, 0.72, 0.24), Color(0.37, 0.22, 0.10), 1.5)
		draw_line(Vector2(-7, -51), Vector2(7, -51), Color(0.20, 0.56, 0.88), 2.0, true)
		draw_circle(Vector2(0.0, -52.0), 1.8, Color(0.45, 0.85, 1.0))
		draw_circle(Vector2(-3.4, -45.0), 0.9, Color(0.12, 0.18, 0.24))
		draw_circle(Vector2(3.4, -45.0), 0.9, Color(0.12, 0.18, 0.24))
		draw_line(Vector2(-2.0, -41.0), Vector2(2.0, -41.0), Color(0.62, 0.25, 0.20), 1.1, true)

		# Sweep trail is rendered behind the arm/blade and flashes blue-white at impact.
		if _swing_progress >= 0.0:
			var trail_end := attack_angle - 1.65 + swing * 2.85
			var trail_start := trail_end - lerpf(0.35, 1.35, sin(clampf(_swing_progress, 0.0, 1.0) * PI))
			var trail := PackedVector2Array()
			for i in range(18):
				var a := lerpf(trail_start, trail_end, float(i) / 17.0)
				trail.append(Vector2(5.0, -30.0) + Vector2.RIGHT.rotated(a) * 30.0)
			var flash := sin(clampf(_swing_progress, 0.0, 1.0) * PI)
			draw_polyline(trail, Color(0.10, 0.72, 1.0, 0.20 * flash), 12.0, true)
			draw_polyline(trail, Color(0.30, 0.91, 1.0, 0.58 * flash), 6.0, true)
			draw_polyline(trail, Color(0.93, 1.0, 1.0, 0.94 * flash), 2.0, true)
			if _swing_progress > 0.48 and _swing_progress < 0.76:
				var spark := Vector2(5.0, -30.0) + _attack_dir * 30.0
				for j in range(6):
					var ray := Vector2.RIGHT.rotated(float(j) * TAU / 6.0 + _time * 4.0)
					draw_line(spark - ray * 2.0, spark + ray * (5.0 + flash * 5.0), Color(0.70, 0.95, 1.0, flash), 1.5, true)

		# Shoulder, articulated forearm, grip, guard, and blade share the same hand pose.
		var shoulder := Vector2(8.0, -33.0)
		var hand := Vector2(5.0, -30.0) + Vector2.RIGHT.rotated(blade_angle) * 13.0
		var elbow := shoulder.lerp(hand, 0.58) + Vector2(0.0, -2.0)
		draw_line(shoulder, elbow, Color(0.14, 0.23, 0.39), 7.0, true)
		draw_line(shoulder + Vector2(0, -1), elbow + Vector2(0, -1), Color(0.82, 0.87, 0.87), 2.0, true)
		draw_line(elbow, hand, Color(0.91, 0.70, 0.46), 5.0, true)
		draw_circle(hand, 3.0, Color(0.91, 0.70, 0.46))
		var sword_dir := Vector2.RIGHT.rotated(blade_angle)
		var sword_side := sword_dir.orthogonal()
		var guard_a := hand - sword_side * 5.0
		var guard_b := hand + sword_side * 5.0
		draw_line(guard_a, guard_b, Color(0.98, 0.73, 0.24), 3.0, true)
		draw_line(hand - sword_dir * 8.0, hand, Color(0.30, 0.18, 0.12), 4.0, true)
		draw_line(hand - sword_dir * 7.0, hand - sword_dir, Color(0.92, 0.71, 0.28), 1.5, true)
		var blade_base := hand + sword_dir * 2.0
		var blade_tip := hand + sword_dir * 34.0
		var blade_shape := PackedVector2Array([
			blade_base - sword_side * 2.5,
			blade_tip - sword_side * 0.5,
			blade_tip + sword_side * 0.5,
			blade_base + sword_side * 2.5
		])
		_polygon(blade_shape, Color(0.61, 0.85, 0.96), Color(0.13, 0.30, 0.48), 1.0)
		draw_line(blade_base + sword_side * 0.7, blade_tip - sword_side * 0.2, Color(0.96, 1.0, 1.0), 1.2, true)
		if _swing_progress > 0.48 and _swing_progress < 0.76:
			draw_circle(blade_base, 3.2, Color(0.32, 0.86, 1.0, 0.72))

		# Final foreground pass keeps the slash readable over the body and target.
		if _swing_progress >= 0.0:
			var hit_flash := sin(clampf(_swing_progress, 0.0, 1.0) * PI)
			var slash_end := attack_angle - 1.65 + swing * 2.85
			var slash_start := slash_end - lerpf(0.35, 1.35, hit_flash)
			var slash_points := PackedVector2Array()
			for i in range(18):
				var a := lerpf(slash_start, slash_end, float(i) / 17.0)
				slash_points.append(Vector2(5.0, -30.0) + Vector2.RIGHT.rotated(a) * 32.0)
			draw_polyline(slash_points, Color(0.08, 0.63, 1.0, hit_flash * 0.52), 12.0, true)
			draw_polyline(slash_points, Color(0.31, 0.88, 1.0, hit_flash * 0.92), 5.0, true)
			draw_polyline(slash_points, Color(0.96, 1.0, 1.0, hit_flash), 1.8, true)
			if _swing_progress > 0.4 and _swing_progress < 0.78:
				var impact := hand + sword_dir * 28.0
				for j in range(8):
					var ray := Vector2.RIGHT.rotated(float(j) * TAU / 8.0 + _time * 4.0)
					draw_line(impact - ray * 2.0, impact + ray * (7.0 + hit_flash * 5.0), Color(0.77, 0.96, 1.0, hit_flash), 1.8, true)

class SwordSlashOverlay extends Node2D:
	var _progress := -1.0
	var _direction := Vector2.RIGHT
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		var hero: Variant = get_parent()
		if hero == null or not is_instance_valid(hero):
			return
		_progress = 1.0 - hero._swing_t / 0.44 if hero._swing_t > 0.0 else -1.0
		_direction = hero._attack_direction
		queue_redraw()

	func _draw() -> void:
		if _progress < 0.0:
			return
		var power := sin(clampf(_progress, 0.0, 1.0) * PI)
		var facing_angle := _direction.angle()
		var sweep := smoothstep(0.08, 0.82, clampf(_progress, 0.0, 1.0))
		var end_angle := facing_angle - 1.65 + sweep * 2.85
		var start_angle := end_angle - lerpf(0.35, 1.5, power)
		var points := PackedVector2Array()
		for i in range(22):
			var a := lerpf(start_angle, end_angle, float(i) / 21.0)
			points.append(Vector2(5.0, -30.0) + Vector2.RIGHT.rotated(a) * 36.0)
		draw_polyline(points, Color(0.04, 0.56, 1.0, power * 0.55), 18.0, true)
		draw_polyline(points, Color(0.30, 0.90, 1.0, power * 0.9), 8.0, true)
		draw_polyline(points, Color(0.94, 1.0, 1.0, power), 2.6, true)
		if _progress > 0.38 and _progress < 0.82:
			var impact := Vector2(5.0, -30.0) + _direction * 36.0
			for j in range(10):
				var ray := Vector2.RIGHT.rotated(float(j) * TAU / 10.0 + _time * 4.0)
				draw_line(impact - ray * 2.0, impact + ray * (8.0 + power * 8.0), Color(0.80, 0.97, 1.0, power), 2.0, true)

var _swordmaster_visual: SwordmasterVisual
var _slash_overlay: SwordSlashOverlay

func _ready() -> void:
	super._ready()
	_sprite.visible = false
	_weapon.visible = false
	_swordmaster_visual = SwordmasterVisual.new()
	add_child(_swordmaster_visual)
	_slash_overlay = SwordSlashOverlay.new()
	_slash_overlay.z_index = 3
	add_child(_slash_overlay)

func _die() -> void:
	super._die()
	if _swordmaster_visual != null:
		_swordmaster_visual.visible = false
		_slash_overlay.visible = false

func _respawn() -> void:
	super._respawn()
	if _swordmaster_visual != null:
		_swordmaster_visual.visible = true
		_slash_overlay.visible = true

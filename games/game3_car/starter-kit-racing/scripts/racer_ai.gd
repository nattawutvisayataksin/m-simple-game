extends Node
class_name RacerAI

var vehicle: Vehicle
var player: Vehicle
var path_points: Array[Vector3] = []
var waypoint_index := 0
var laps := 0
var lane_offset := 0.0
var held_item := ""
var _item_cooldown := 0.0


func configure(racer: Vehicle, player_racer: Vehicle, points: Array[Vector3],
		start_index: int, lane: float) -> void:
	vehicle = racer
	player = player_racer
	path_points = points.duplicate()
	waypoint_index = posmod(start_index, maxi(path_points.size(), 1))
	lane_offset = lane


func _physics_process(delta: float) -> void:
	if vehicle == null or path_points.size() < 3:
		return
	_item_cooldown = maxf(_item_cooldown - delta, 0.0)

	var target: Vector3 = _lane_target(waypoint_index)
	var to_target: Vector3 = target - vehicle.sphere.global_position
	to_target.y = 0.0
	if to_target.length() < 6.0:
		waypoint_index = (waypoint_index + 1) % path_points.size()
		if waypoint_index == 0:
			laps += 1
		target = _lane_target(waypoint_index)
		to_target = target - vehicle.sphere.global_position
		to_target.y = 0.0

	var forward: Vector3 = vehicle.vehicle_model.global_basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001 or to_target.length_squared() < 0.001:
		return
	var angle: float = forward.normalized().signed_angle_to(to_target.normalized(), Vector3.UP)
	var steering := clampf(-angle * 1.7, -1.0, 1.0)
	var throttle := 1.0 if absf(angle) < 0.7 else 0.7
	vehicle.set_ai_control(steering, throttle)
	_try_use_item(angle)


func give_item(item_name: String) -> void:
	if held_item.is_empty():
		held_item = item_name


func get_race_progress() -> float:
	return float(laps * path_points.size() + waypoint_index)


func _lane_target(index: int) -> Vector3:
	var point := path_points[index]
	var forward: Vector3 = path_points[(index + 1) % path_points.size()] \
		- path_points[(index - 1 + path_points.size()) % path_points.size()]
	forward.y = 0.0
	if forward.length_squared() > 0.001:
		point += forward.normalized().cross(Vector3.UP) * lane_offset
	return point + Vector3(0, 0.6, 0)


func _try_use_item(steering_angle: float) -> void:
	if held_item.is_empty() or _item_cooldown > 0.0:
		return
	if held_item == "boost" and absf(steering_angle) < 0.45:
		vehicle.apply_boost()
		held_item = ""
		_item_cooldown = 1.5
	elif held_item == "oil" and _player_is_close_behind():
		get_parent().get_parent().call("drop_oil_slick", vehicle)
		held_item = ""
		_item_cooldown = 2.0


func _player_is_close_behind() -> bool:
	if player == null:
		return false
	var forward: Vector3 = vehicle.vehicle_model.global_basis.z
	var relative: Vector3 = player.sphere.global_position - vehicle.sphere.global_position
	var behind_distance: float = relative.dot(forward)
	var lateral_distance: float = (relative - forward * behind_distance).length()
	return behind_distance < -2.0 and behind_distance > -18.0 and lateral_distance < 4.0

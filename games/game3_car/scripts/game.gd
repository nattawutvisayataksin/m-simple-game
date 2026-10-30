extends Node3D
## Kubi Grand Prix - ราชวงศ์ทอง (Game 3, 3D racing)
## ระบบเกมบน Starter Kit Racing: นับรอบผ่านประตู (gate), เก็บเหรียญทอง, จับเวลา, respawn
## อ่านโครงสนามจาก GridMap (item ชื่อ track-*) แล้วเรียงเส้นทางรอบ centroid โดยมุม

const LAPS_TO_WIN := 3          # ครบ 3 รอบ = ชนะ
const COIN_STEP := 2            # วางเหรียญทุก N จุดของเส้นทาง
const FALL_Y := -8.0            # ต่ำกว่านี้ = ร่วงสนาม -> respawn
const OPPONENT_COUNT := 3
const ITEM_BOX_STEPS := [5, 15, 26, 36]
const ITEM_TYPES := ["boost", "oil", "boost", "oil"]
const CAR_OPTIONS := [
	{"name": "Racer", "model": "res://models/race-future.glb", "speed": 1.08, "handling": 1.0},
	{"name": "Yellow Truck", "model": "res://models/vehicle-truck-yellow.glb", "speed": 1.0, "handling": 1.12},
	{"name": "Red Truck", "model": "res://models/vehicle-truck-red.glb", "speed": 1.12, "handling": 0.92},
	{"name": "Purple Truck", "model": "res://models/vehicle-truck-purple.glb", "speed": 0.94, "handling": 1.2},
	{"name": "Green Truck", "model": "res://models/vehicle-truck-green.glb", "speed": 1.04, "handling": 1.04},
]

var laps := 0
var coins_collected := 0
var next_gate := 0
var _passed_full_lap := false
var elapsed := 0.0
var race_finished := false
var race_started := false
var held_item := ""
var selected_car_index := 0

var _grid: GridMap
var _player: Vehicle
var _ai_racers: Array[Vehicle] = []
var _path_points: Array[Vector3] = []
var _props_root: Node3D
var _item_boxes_root: Node3D
var _car_select_layer: CanvasLayer
var _car_description: Label
var _car_buttons: Array[Button] = []
var _spawn_point: Vector3
var _spawn_yaw := 0.0
var _coin_roots: Array[Node3D] = []

# HUD
var _hud: CanvasLayer
var _hud_lap: Label
var _hud_coin: Label
var _hud_time: Label
var _hud_rank: Label
var _hud_checkpoint: Label
var _hud_item: Label
var _hud_hint: Label
var _win_label: Label

# Functions

func _ready() -> void:
	_grid = $GridMap
	_player = $Vehicle
	_build_track_and_spawnables()
	_place_player()
	_player.set_race_enabled(false)
	_spawn_ai_racers()
	_build_item_boxes()
	_build_hud()
	_build_car_selection()


func _process(delta: float) -> void:
	for coin in _coin_roots:
		if is_instance_valid(coin):
			coin.rotate_y(delta * 2.5)
	if _item_boxes_root != null:
		for item_box in _item_boxes_root.get_children():
			item_box.rotate_y(delta * 1.4)


func _physics_process(delta: float) -> void:
	if not race_started or race_finished:
		return
	elapsed += delta
	if Input.is_action_just_pressed("use_item"):
		_use_player_item()
	if _player.sphere.global_position.y < FALL_Y:
		respawn()
	for racer in _ai_racers:
		if racer.sphere.global_position.y < FALL_Y:
			_reset_ai_racer(racer)
		var ai := racer.get_node_or_null("RacerAI")
		if ai != null and int(ai.get("laps")) >= LAPS_TO_WIN:
			_finish_race(str(racer.name))
			return
	_update_hud()


func respawn() -> void:
	var sphere := _player.sphere
	_player.global_transform = Transform3D(Basis(), _spawn_point)
	sphere.global_transform = Transform3D(Basis(), _spawn_point + Vector3(0, 1.5, 0))
	sphere.linear_velocity = Vector3.ZERO
	sphere.angular_velocity = Vector3.ZERO
	_player.vehicle_model.rotation = Vector3(0, _spawn_yaw, 0)


func _spawn_ai_racers() -> void:
	var vehicle_scene := load("res://scenes/vehicle.tscn") as PackedScene
	if vehicle_scene == null or _path_points.is_empty():
		push_error("KubiGP: unable to load vehicles or racing path for AI")
		return
	var ai_script := load("res://scripts/racer_ai.gd") as Script
	if ai_script == null:
		push_error("KubiGP: unable to load racer AI script")
		return
	var tangent := _tangent_at(_path_points[0])
	var right := tangent.cross(Vector3.UP).normalized()
	var ai_car_indices := [1, 2, 4]
	var lane_offsets := [-1.35, 1.35, 0.0]
	var row_back_distances := [3.4, 3.4, 6.8]
	for i in OPPONENT_COUNT:
		var racer := vehicle_scene.instantiate() as Vehicle
		if racer == null:
			push_error("KubiGP: vehicle scene root must be Vehicle")
			return
		racer.name = "Opponent%d" % (i + 1)
		add_child(racer)
		var option: Dictionary = CAR_OPTIONS[ai_car_indices[i]]
		racer.set_car_model(option["model"])
		racer.set_drive_profile(option["speed"], option["handling"])
		racer.ai_controlled = true
		var row_back: Vector3 = tangent * -float(row_back_distances[i])
		var start: Vector3 = _path_points[0] + right * lane_offsets[i] + row_back
		var spawn := Vector3(start.x, start.y + 0.6, start.z)
		racer.global_transform = Transform3D(Basis(), spawn)
		racer.vehicle_model.rotation.y = _yaw_for_direction(tangent)
		racer.sphere.global_transform = Transform3D(Basis(), spawn + Vector3(0, 1.5, 0))
		racer.set_race_enabled(false)

		var ai := ai_script.new() as Node
		ai.name = "RacerAI"
		ai.call("configure", racer, _player, _path_points, 0, lane_offsets[i])
		racer.add_child(ai)
		ai.set_physics_process(false)
		_ai_racers.append(racer)


func _reset_ai_racer(racer: Vehicle) -> void:
	var ai := racer.get_node_or_null("RacerAI")
	if ai == null or _path_points.is_empty():
		return
	var point := _path_points[int(ai.get("waypoint_index"))]
	var tangent := _tangent_at(point)
	var spawn := Vector3(point.x, point.y + 0.6, point.z)
	racer.global_transform = Transform3D(Basis(), spawn)
	racer.vehicle_model.rotation.y = _yaw_for_direction(tangent)
	racer.sphere.global_transform = Transform3D(Basis(), spawn + Vector3(0, 1.5, 0))
	racer.sphere.linear_velocity = Vector3.ZERO
	racer.sphere.angular_velocity = Vector3.ZERO


func _start_race() -> void:
	if race_started:
		return
	race_started = true
	if _car_select_layer != null:
		_car_select_layer.queue_free()
	_player.set_race_enabled(true)
	for racer in _ai_racers:
		racer.set_race_enabled(true)
		var ai := racer.get_node_or_null("RacerAI")
		if ai != null:
			ai.set_physics_process(true)


func _build_item_boxes() -> void:
	_item_boxes_root = Node3D.new()
	_item_boxes_root.name = "ItemBoxes"
	add_child(_item_boxes_root)
	var chosen_points: Array[Vector3] = []
	for i in mini(ITEM_BOX_STEPS.size(), ITEM_TYPES.size()):
		var step: int = ITEM_BOX_STEPS[i]
		if _path_points.size() < 3:
			continue
		step = posmod(step, _path_points.size())
		var placed := false
		for _attempt in _path_points.size():
			var candidate := _path_points[step]
			var clear_of_start := candidate.distance_to(_path_points[0]) >= 14.0
			var clear_of_other_items := true
			for previous in chosen_points:
				if candidate.distance_to(previous) < 12.0:
					clear_of_other_items = false
					break
			if clear_of_start and clear_of_other_items:
				chosen_points.append(candidate)
				placed = true
				break
			step = (step + 1) % _path_points.size()
		if not placed:
			continue
		var box := Area3D.new()
		box.name = "ItemBox%d" % i
		box.collision_mask = 8
		box.position = chosen_points.back() + Vector3(0, 1.2, 0)
		var trigger := CollisionShape3D.new()
		var trigger_shape := SphereShape3D.new()
		trigger_shape.radius = 1.5
		trigger.shape = trigger_shape
		box.add_child(trigger)

		var visual := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.9, 0.9, 0.9)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.95, 0.62, 0.12) if ITEM_TYPES[i] == "boost" \
			else Color(0.25, 0.75, 0.82)
		material.metallic = 0.15
		material.roughness = 0.3
		mesh.material = material
		visual.mesh = mesh
		box.add_child(visual)
		box.body_entered.connect(_on_item_box_body_entered.bind(box, ITEM_TYPES[i]))
		_item_boxes_root.add_child(box)


func _on_item_box_body_entered(body: Node3D, box: Area3D, item_name: String) -> void:
	if not body is RigidBody3D:
		return
	var racer := body.get_parent() as Vehicle
	if racer == null:
		return
	if racer == _player:
		if not held_item.is_empty():
			return
		held_item = item_name
	else:
		var ai := racer.get_node_or_null("RacerAI")
		if ai == null or not str(ai.get("held_item")).is_empty():
			return
		ai.call("give_item", item_name)
	box.queue_free()
	_update_hud()


func _use_player_item() -> void:
	if held_item == "boost":
		_player.apply_boost()
	elif held_item == "oil":
		drop_oil_slick(_player)
	else:
		return
	held_item = ""
	_update_hud()


func drop_oil_slick(owner: Vehicle) -> void:
	var forward: Vector3 = owner.vehicle_model.global_basis.z
	var slick := Area3D.new()
	slick.name = "OilSlick"
	slick.collision_mask = 8
	slick.position = owner.sphere.global_position - forward * 3.8
	slick.position.y = 0.06
	var trigger := CollisionShape3D.new()
	var trigger_shape := SphereShape3D.new()
	trigger_shape.radius = 2.0
	trigger.shape = trigger_shape
	slick.add_child(trigger)

	var visual := MeshInstance3D.new()
	var puddle := CylinderMesh.new()
	puddle.top_radius = 1.25
	puddle.bottom_radius = 1.35
	puddle.height = 0.05
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.075, 0.085, 0.09, 0.92)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.18
	puddle.material = material
	visual.mesh = puddle
	slick.add_child(visual)
	slick.body_entered.connect(_on_oil_body_entered.bind(slick, owner.get_instance_id()))
	add_child(slick)

	var lifetime := Timer.new()
	lifetime.one_shot = true
	lifetime.wait_time = 8.0
	lifetime.timeout.connect(slick.queue_free)
	slick.add_child(lifetime)
	lifetime.start()


func _on_oil_body_entered(body: Node3D, slick: Area3D, owner_id: int) -> void:
	if not body is RigidBody3D:
		return
	var racer := body.get_parent() as Vehicle
	if racer == null or racer.get_instance_id() == owner_id:
		return
	racer.apply_oil_slowdown()
	slick.queue_free()


# Track building

func _build_track_and_spawnables() -> void:
	_path_points.clear()
	# หลัก: อ่านจุดเซลล์ถนนจากเมือง (Town วาดเอง ไม่พึ่ง GridMap)
	var town := get_node_or_null("Town")
	if town != null and town.has_method("get_track_points"):
		for tp in town.get_track_points():
			_path_points.append(tp)
	if _path_points.is_empty():
		_grid_path_fallback()
	if _path_points.is_empty():
		push_warning("KubiGP: not found track pieces in GridMap")
		return

	_props_root = Node3D.new()
	_props_root.name = "Props"
	add_child(_props_root)

	# เรียงจุดตามมุมรอบจุดศูนย์กลาง (กันเหรียญซ้อนวงขนานด้วยมุมขั้นต่ำ)
	var centroid := Vector2.ZERO
	for p in _path_points:
		centroid += Vector2(p.x, p.z)
	centroid /= _path_points.size()

	var ordered := _path_points.duplicate()
	ordered.sort_custom(func(a, b):
		var aa := _point_angle(a, centroid)
		var bb := _point_angle(b, centroid)
		return aa < bb)
	_path_points = ordered

	_build_track_barriers()

	var coins := Node3D.new()
	coins.name = "Coins"
	coins.position = Vector3.ZERO
	add_child(coins)
	var coin_scene: PackedScene = load("res://models/town/deco/coin-gold.glb")
	var coin_shape := SphereShape3D.new()
	coin_shape.radius = 1.8
	for i in range(0, _path_points.size(), COIN_STEP):
		var area := Area3D.new()
		area.name = "Coin%d" % i
		area.collision_mask = 8          # เจอ sphere ของรถ (layer 8) เท่านั้น
		area.position = _path_points[i] + Vector3(0, 1.1, 0)
		if coin_scene != null:
			var coin: Node3D = coin_scene.instantiate()
			var s := 1.0 / 0.4           # เหรียญวัดได้ 0.4 ม. -> ยืดเป็น ~1 ม.
			coin.scale = Vector3(s, s, s)
			coin.rotation.x = PI / 2     # ตั้งเหรียญแนวตั้งแล้วหมุนรอบแกน Y
			area.add_child(coin)
		var cs := CollisionShape3D.new()
		cs.shape = coin_shape
		area.add_child(cs)
		area.body_entered.connect(_on_coin_body_entered.bind(area))
		coins.add_child(area)
		_coin_roots.append(area)

	var gates := Node3D.new()
	gates.name = "Gates"
	add_child(gates)
	var gate_steps := [0, _path_points.size() / 3, _path_points.size() * 2 / 3]
	for gi in 3:
		var p: Vector3 = _path_points[gate_steps[gi]]
		var area := Area3D.new()
		area.name = "Gate%d" % gi
		area.collision_mask = 8
		area.position = p + Vector3(0, 1.8, 0)
		var tangent := _tangent_at(p)
		if tangent.length() > 0.01:
			area.rotation.y = _yaw_for_direction(tangent)
		var shape := BoxShape3D.new()
		shape.size = Vector3(7, 3.6, 2.8)
		var cs := CollisionShape3D.new()
		cs.name = "CollisionShape3D"
		cs.shape = shape
		area.add_child(cs)
		area.body_entered.connect(_on_gate_body_entered.bind(gi))
		_spawn_gate_visual(area, gi)
		gates.add_child(area)

	var center := Vector3.ZERO
	for p in _path_points:
		center += p
	center /= _path_points.size()
	_spawn_kart_fleet(center)

func _build_track_barriers() -> void:
	var barriers := Node3D.new()
	barriers.name = "TrackBarriers"
	add_child(barriers)
	var straight_runs := [
		["OuterSouth", Vector3(10.5, 0.48, 0.12), Vector3(87.5, 0.48, 0.12)],
		["OuterEast", Vector3(97.88, 0.48, 10.5), Vector3(97.88, 0.48, 52.5)],
		["OuterNorth", Vector3(87.5, 0.48, 62.88), Vector3(10.5, 0.48, 62.88)],
		["OuterWest", Vector3(0.12, 0.48, 52.5), Vector3(0.12, 0.48, 10.5)],
		["InnerSouth", Vector3(10.5, 0.48, 7.12), Vector3(87.5, 0.48, 7.12)],
		["InnerEast", Vector3(90.88, 0.48, 10.5), Vector3(90.88, 0.48, 52.5)],
		["InnerNorth", Vector3(87.5, 0.48, 55.88), Vector3(10.5, 0.48, 55.88)],
		["InnerWest", Vector3(7.12, 0.48, 52.5), Vector3(7.12, 0.48, 10.5)],
	]
	for run in straight_runs:
		_add_barrier_run(barriers, str(run[0]), run[1], run[2])

	var corners := [
		["SE", Vector2(87.5, 10.5), -PI * 0.5, 0.0],
		["NE", Vector2(87.5, 52.5), 0.0, PI * 0.5],
		["NW", Vector2(10.5, 52.5), PI * 0.5, PI],
		["SW", Vector2(10.5, 10.5), PI, PI * 1.5],
	]
	for corner in corners:
		var corner_name := str(corner[0])
		var center: Vector2 = corner[1]
		var start_angle: float = corner[2]
		var end_angle: float = corner[3]
		_add_barrier_arc(barriers, "Outer_Corner_" + corner_name,
			center, 10.38, start_angle, end_angle)
		_add_barrier_arc(barriers, "Inner_Corner_" + corner_name,
			center, 3.38, start_angle, end_angle)


func _add_barrier_run(parent: Node3D, label: String,
		start: Vector3, end: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "Barrier_" + label
	parent.add_child(body)
	var run := end - start
	var length := run.length()
	var tangent := run / length
	var segment_count := ceili(length / 2.8)
	for index in segment_count:
		var segment_length := length / segment_count
		var center := start + tangent * (segment_length * (float(index) + 0.5))
		_add_barrier_piece(body, "Segment_%02d" % index,
			center, tangent, segment_length, index)


func _add_barrier_arc(parent: Node3D, label: String, center: Vector2,
		radius: float, start_angle: float, end_angle: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Barrier_" + label
	parent.add_child(body)
	var arc_length := radius * absf(end_angle - start_angle)
	var segment_count := maxi(ceili(arc_length / 2.2), 4)
	var segment_angle := (end_angle - start_angle) / segment_count
	for index in segment_count:
		var angle := start_angle + segment_angle * (float(index) + 0.5)
		var point := center + Vector2(cos(angle), sin(angle)) * radius
		var tangent := Vector3(-sin(angle), 0, cos(angle))
		var segment_length := 2.0 * radius * sin(absf(segment_angle) * 0.5)
		_add_barrier_piece(body, "Segment_%02d" % index,
			Vector3(point.x, 0.48, point.y), tangent, segment_length, index)


func _add_barrier_piece(parent: StaticBody3D, piece_name: String, center: Vector3,
		tangent: Vector3, segment_length: float, color_index: int) -> void:
	var segment_rotation := atan2(-tangent.z, tangent.x)

	var collision := CollisionShape3D.new()
	collision.name = piece_name + "_Collision"
	collision.position = center
	collision.rotation.y = segment_rotation
	var shape := BoxShape3D.new()
	shape.size = Vector3(segment_length + 0.08, 0.96, 0.4)
	collision.shape = shape
	parent.add_child(collision)

	var section := MeshInstance3D.new()
	section.name = piece_name
	section.position = center
	section.rotation.y = segment_rotation
	var mesh := BoxMesh.new()
	mesh.size = Vector3(segment_length, 0.7, 0.42)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.88, 0.82, 0.70) if color_index % 2 == 0 \
		else Color(0.72, 0.22, 0.15)
	material.roughness = 0.82
	mesh.material = material
	section.mesh = mesh
	parent.add_child(section)


func _spawn_gate_visual(area: Area3D, gate_index: int) -> void:
	var visual := Node3D.new()
	visual.name = "GateVisual"
	area.add_child(visual)
	var accent_colors := [
		Color(0.98, 0.68, 0.16),
		Color(0.20, 0.78, 0.88),
		Color(0.94, 0.32, 0.24),
	]
	var accent: Color = accent_colors[gate_index]
	for side in [-1.0, 1.0]:
		_add_gate_box(visual, Vector3(0.42, 3.5, 0.42),
			Vector3(side * 4.0, 1.75, 0), Color(0.86, 0.82, 0.70))
	_add_gate_box(visual, Vector3(8.4, 0.55, 0.5),
		Vector3(0, 3.55, 0), accent)

	var label := Label3D.new()
	label.name = "GateLabel"
	label.text = "FINISH" if gate_index == 0 else "CHECKPOINT %d" % gate_index
	label.font_size = 48
	label.pixel_size = 0.008
	label.outline_size = 8
	label.modulate = Color(0.10, 0.10, 0.10)
	label.position = Vector3(0, 3.5, -0.27)
	visual.add_child(label)


func _add_gate_box(parent: Node3D, dimensions: Vector3, at: Vector3, tint: Color) -> void:
	var post := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.72
	mesh.material = material
	post.mesh = mesh
	post.position = at
	parent.add_child(post)

func _spawn_kart_fleet(center: Vector3) -> void:
	# เหล่า Kubi รุ่น kart จอดต้อนรับแถวเส้นชัย (3 คัน)
	var kart_paths := ["res://models/kart-oobi.glb"
		, "res://models/kart-oodi.glb"
		, "res://models/kart-oozi.glb"]
	for i in kart_paths.size():
		var scene: PackedScene = load(kart_paths[i])
		if scene == null:
			continue
		var instance: Node3D = scene.instantiate()
		_props_root.add_child(instance)
		var s := 1.1 / maxf(_measure_height(instance), 0.05)
		instance.scale = Vector3(s, s, s)
		var p := _path_points[2 + i * 2] if _path_points.size() > 2 else center
		var out := Vector3(p.x - center.x, 0, p.z - center.z)
		out = out.normalized() if out.length() > 0.01 else Vector3(0, 0, 1)
		instance.position = p + out * 9.5
		var tangent := _tangent_at(p)
		if tangent.length() > 0.01:
			instance.rotation.y = atan2(tangent.x, tangent.z)


# Lap / coin logic

func _on_coin_body_entered(body: Node3D, area: Area3D) -> void:
	if body == _player.sphere:
		_collect_coin(area)


func _collect_coin(area: Area3D) -> void:
	if not is_instance_valid(area):
		return
	coins_collected += 1
	_coin_roots.erase(area)
	area.queue_free()


func _on_gate_body_entered(body: Node3D, gate_index: int) -> void:
	if body == _player.sphere:
		_advance_gate(gate_index)


## รอบสมบูรณ์ = ครบ 0->1->2 แล้วกลับมาแตะ 0 (ประตูเส้นชัย) จึง +1 รอบ
func _advance_gate(gate_index: int) -> void:
	if race_finished:
		return
	if gate_index != next_gate:
		return
	if next_gate == 0 and _passed_full_lap:
		_passed_full_lap = false
		laps += 1
		if laps >= LAPS_TO_WIN:
			_finish_race()
			return
	next_gate += 1
	if next_gate >= 3:
		next_gate = 0
		_passed_full_lap = true


func _finish_race(winner_name: String = "ผู้เล่น") -> void:
	race_finished = true
	_win_label.text = "%s ชนะการแข่งขัน!\nเวลา: %s  |  เหรียญทอง: %d" % [
		winner_name, _format_time(elapsed), coins_collected]
	_win_label.get_parent().visible = true
	get_tree().paused = true


# Player placement

func _place_player() -> void:
	if _path_points.is_empty():
		return
	var p0 := _path_points[0]
	var tangent := _tangent_at(p0)
	_spawn_point = Vector3(p0.x, p0.y + 0.6, p0.z)
	var yaw := 0.0
	if tangent.length() > 0.01:
		yaw = _yaw_for_direction(tangent)
	_spawn_yaw = yaw
	_player.global_transform = Transform3D(Basis(), _spawn_point)
	_player.vehicle_model.rotation = Vector3(0, yaw, 0)
	_player.sphere.global_transform = Transform3D(Basis(), _spawn_point + Vector3(0, 1.5, 0))


func _tangent_at(p: Vector3) -> Vector3:
	if _path_points.size() < 2:
		return Vector3(0, 0, 1)
	var best := 0
	var best_d := INF
	for i in _path_points.size():
		var d: float = (_path_points[i] - p).length_squared()
		if d < best_d:
			best_d = d
			best = i
	var nxt := _path_points[(best + 1) % _path_points.size()]
	var prv := _path_points[(best - 1 + _path_points.size()) % _path_points.size()]
	var t := nxt - prv
	t.y = 0
	return t.normalized()


func _yaw_for_direction(direction: Vector3) -> float:
	return atan2(direction.x, direction.z)


# Helpers

func _point_angle(p: Vector3, center: Vector2) -> float:
	return atan2(p.z - center.y, p.x - center.x)


## ทางเลือกเมืองไม่มี (เลิกใช้ GridMap เป็นหลักแล้ว): อ่านจากเซลล์ road-* ใน GridMap
func _grid_path_fallback() -> void:
	var cells: Array[Vector3i] = []
	for c in _grid.get_used_cells():
		var item := _grid.get_cell_item(c)
		if item < 0:
			continue
		if _grid.mesh_library.get_item_name(item).begins_with("road"):
			cells.append(c)
	if cells.is_empty():
		return
	for c in cells:
		_path_points.append(_grid.to_global(_grid.map_to_local(c)))


## วัดความสูง (ช่วง Y) ของ mesh ทั้งอินสแตนซ์ในพิกัด local ของ root
func _measure_height(node: Node3D) -> float:
	var aabb := _mesh_aabb_local(node)
	return aabb.size.y


func _mesh_aabb_local(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	# เดิน transform แบบ local ล้วน (ใช้ได้ทั้งตอนยังไม่ add_child เข้า tree)
	var stack: Array = [[node, Transform3D.IDENTITY]]
	while stack.size() > 0:
		var entry: Array = stack.pop_back()
		var n: Node = entry[0]
		var acc: Transform3D = entry[1]
		if n is Node3D and n != node:
			acc = acc * (n as Node3D).transform
		if n is MeshInstance3D and n.mesh != null:
			var c: AABB = acc * (n as MeshInstance3D).mesh.get_aabb()
			if first:
				result = c
				first = false
			else:
				result = result.merge(c)
		for child in n.get_children():
			stack.append([child, acc])
	return result


func _format_time(t: float) -> String:
	var minutes := int(t) / 60
	var seconds := int(t) % 60
	return "%d:%02d" % [minutes, seconds]


func _build_car_selection() -> void:
	_car_select_layer = CanvasLayer.new()
	_car_select_layer.name = "CarSelection"
	_car_select_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_car_select_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.035, 0.045, 0.72)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_car_select_layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_car_select_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(940, 390)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.075, 0.085, 0.97)
	panel_style.border_color = Color(0.85, 0.56, 0.16, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := _make_label(layout, 34)
	title.text = "KUBI GRAND PRIX"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var subtitle := _make_label(layout, 20)
	subtitle.text = "เลือกรถของคุณ  |  แข่งกับคู่แข่ง AI 3 คัน  |  เก็บไอเท็มแล้วกด Q"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var choices := HBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 10)
	layout.add_child(choices)
	_car_buttons.clear()
	for i in CAR_OPTIONS.size():
		var option: Dictionary = CAR_OPTIONS[i]
		var button := Button.new()
		button.text = str(option["name"])
		button.custom_minimum_size = Vector2(164, 64)
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_select_car.bind(i))
		choices.add_child(button)
		_car_buttons.append(button)

	_car_description = _make_label(layout, 19)
	_car_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var start_button := Button.new()
	start_button.text = "เริ่มแข่ง"
	start_button.custom_minimum_size = Vector2(220, 54)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.focus_mode = Control.FOCUS_ALL
	start_button.pressed.connect(_start_race)
	layout.add_child(start_button)
	start_button.grab_focus()
	_select_car(selected_car_index)


func _select_car(index: int) -> void:
	selected_car_index = clampi(index, 0, CAR_OPTIONS.size() - 1)
	var option: Dictionary = CAR_OPTIONS[selected_car_index]
	_player.set_car_model(option["model"])
	_player.set_drive_profile(option["speed"], option["handling"])
	if _car_description != null:
		_car_description.text = "ความเร็ว %.0f%%    |    การควบคุม %.0f%%" % [
			float(option["speed"]) * 100.0, float(option["handling"]) * 100.0]
	for i in _car_buttons.size():
		_car_buttons[i].button_pressed = i == selected_car_index


# HUD

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.name = "HUD"
	_hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_hud)

	var box := VBoxContainer.new()
	box.position = Vector2(14, 12)
	_hud.add_child(box)

	_hud_lap = _make_label(box, 30)
	_hud_rank = _make_label(box, 24)
	_hud_checkpoint = _make_label(box, 22)
	_hud_coin = _make_label(box, 30)
	_hud_time = _make_label(box, 30)
	_hud_item = _make_label(box, 24)
	_hud_hint = _make_label(box, 17)
	_hud_hint.text = "W เร่ง  S เบรก  A/D เลี้ยว  Q ใช้ไอเท็ม  |  ผ่านจุดตรวจตามลำดับให้ครบ %d รอบ" % LAPS_TO_WIN

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.add_child(center)
	var win_panel := PanelContainer.new()
	center.add_child(win_panel)
	win_panel.visible = false
	_win_label = _make_label(win_panel, 40)
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_update_hud()


func _make_label(parent: Node, size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(1, 0.96, 0.7))
	label.add_theme_color_override("font_outline_color", Color(0.18, 0.1, 0))
	label.add_theme_constant_override("outline_size", 10)
	parent.add_child(label)
	return label


func _update_hud() -> void:
	if _hud_lap == null:
		return
	_hud_lap.text = "รอบ: %d/%d" % [laps, LAPS_TO_WIN]
	var player_index := _nearest_path_index(_player.sphere.global_position)
	var player_progress := float(laps * _path_points.size() + player_index)
	var position := 1
	for racer in _ai_racers:
		var ai := racer.get_node_or_null("RacerAI")
		if ai != null and float(ai.call("get_race_progress")) > player_progress:
			position += 1
	_hud_rank.text = "อันดับ: %d/%d" % [position, OPPONENT_COUNT + 1]
	var checkpoint_names := ["FINISH", "CHECKPOINT 1", "CHECKPOINT 2"]
	_hud_checkpoint.text = "ประตูถัดไป: " + checkpoint_names[next_gate]
	_hud_coin.text = "เหรียญทอง: %d" % coins_collected
	_hud_time.text = "เวลา: " + _format_time(elapsed)
	_hud_item.text = "ไอเท็ม: %s  (Q)" % _item_display_name(held_item)


func _nearest_path_index(position: Vector3) -> int:
	var best_index := 0
	var best_distance := INF
	for i in _path_points.size():
		var distance := Vector2(position.x, position.z).distance_squared_to(
			Vector2(_path_points[i].x, _path_points[i].z))
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


func _item_display_name(item_name: String) -> String:
	match item_name:
		"boost":
			return "บูสต์"
		"oil":
			return "คราบน้ำมัน"
		_:
			return "ไม่มี"

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

const PROP_TARGET_HEIGHT := {
	"res://models/props/traffic-light.glb": 1.9,
	"res://models/props/sign-highway.glb": 1.6,
	"res://models/props/construction-cone.glb": 0.45,
}

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
	var lane_offsets := [-2.0, 2.0, 1.4]
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
		var row_back := tangent * (-4.2 if i == 2 else 0.0)
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

	_set_center_hint(Vector3(centroid.x, 0, centroid.y))
	var gates := Node3D.new()
	gates.name = "Gates"
	add_child(gates)
	var gate_steps := [0, _path_points.size() / 3, _path_points.size() * 2 / 3]
	var gate_props := ["res://models/props/traffic-light.glb"
		, "res://models/props/sign-highway.glb"
		, "res://models/props/construction-cone.glb"]
	for gi in 3:
		var p: Vector3 = _path_points[gate_steps[gi]]
		var area := Area3D.new()
		area.name = "Gate%d" % gi
		area.collision_mask = 8
		area.position = p + Vector3(0, 2.4, 0)
		var shape := BoxShape3D.new()
		shape.size = Vector3(9, 7, 9)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		area.add_child(cs)
		area.body_entered.connect(_on_gate_body_entered.bind(gi))
		gates.add_child(area)
		_spawn_prop(gate_props[gi], p, gi)

	var center := Vector3.ZERO
	for p in _path_points:
		center += p
	center /= _path_points.size()
	_spawn_kart_fleet(center)

var _center_hint := Vector3.ZERO

func _set_center_hint(c := Vector3.ZERO) -> void:
	_center_hint = c


## side >= 0 = วางประตู (เลือกด้านตามประตู), -1 = ของประดับด้านนอกสนาม
func _spawn_prop(path: String, at: Vector3, side: int) -> void:
	var scene: PackedScene = load(path)
	if scene == null:
		return
	var target: float = PROP_TARGET_HEIGHT.get(path, 1.5)
	var instance: Node3D = scene.instantiate()
	var h := _measure_height(instance)
	var s := target / maxf(h, 0.05)
	_props_root.add_child(instance)
	instance.scale = Vector3(s, s, s)

	# จุดวาง: ดันออกด้านนอกสนามตามแนวรัศมีจากจุดศูนย์กลาง
	var out := Vector3(at.x - _center_hint.x, 0, at.z - _center_hint.z)
	out = out.normalized() if out.length() > 0.01 else Vector3(0, 0, 1)
	var offset := out * 12.0
	instance.position = at + offset
	instance.position.y = -_mesh_aabb_local(instance).position.y * s   # ให้ฐานแตะพื้น
	if side >= 0:
		# ของถ้าเป็นประตู: หันหน้าตามแนวทางเดิน
		var tangent := _tangent_at(at)
		if tangent.length() > 0.01:
			instance.rotation.y = atan2(tangent.x, tangent.z)


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

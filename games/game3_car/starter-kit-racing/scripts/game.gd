extends Node3D
## Kubi Grand Prix - ราชวงศ์ทอง (Game 3, 3D racing)
## ระบบเกมบน Starter Kit Racing: นับรอบผ่านประตู (gate), เก็บเหรียญทอง, จับเวลา, respawn
## อ่านโครงสนามจาก GridMap (item ชื่อ track-*) แล้วเรียงเส้นทางรอบ centroid โดยมุม

const LAPS_TO_WIN := 3          # ครบ 3 รอบ = ชนะ
const COIN_STEP := 2            # วางเหรียญทุก N จุดของเส้นทาง
const POLE_STEP := 5            # เสาไฟฟ้าทุก N จุด (ด้านนอกสนาม)
const BARRIER_STEP := 9         # แบร์ริเออร์ทุก N จุด
const COIN_DUP_ANGLE := 0.13    # มุมต่างขั้นต่ำระหว่างจุด (กันเหรียญซ้อนวงขนาน)
const FALL_Y := -8.0            # ต่ำกว่านี้ = ร่วงสนาม -> respawn

const PROP_TARGET_HEIGHT := {
	"res://models/props/electricity-pole.glb": 4.2,
	"res://models/props/traffic-light.glb": 2.6,
	"res://models/props/sign-highway.glb": 2.0,
	"res://models/props/road-side-barrier.glb": 0.9,
	"res://models/props/construction-cone.glb": 0.7,
}

var laps := 0
var coins_collected := 0
var next_gate := 0
var _passed_full_lap := false
var elapsed := 0.0
var race_finished := false

var _grid: GridMap
var _player: Vehicle
var _path_points: Array[Vector3] = []
var _props_root: Node3D
var _spawn_point: Vector3
var _spawn_yaw := 0.0
var _coin_roots: Array[Node3D] = []

# HUD
var _hud: CanvasLayer
var _hud_lap: Label
var _hud_coin: Label
var _hud_time: Label
var _hud_hint: Label
var _win_label: Label

# Functions

func _ready() -> void:
	_grid = $GridMap
	_player = $Vehicle
	_build_track_and_spawnables()
	_place_player()
	_build_hud()


func _process(delta: float) -> void:
	for coin in _coin_roots:
		if is_instance_valid(coin):
			coin.rotate_y(delta * 2.5)


func _physics_process(delta: float) -> void:
	if race_finished:
		return
	elapsed += delta
	if _player.sphere.global_position.y < FALL_Y:
		respawn()
	_update_hud()


func respawn() -> void:
	var sphere := _player.sphere
	_player.global_transform = Transform3D(Basis(), _spawn_point)
	sphere.global_transform = Transform3D(Basis(), _spawn_point + Vector3(0, 1.5, 0))
	sphere.linear_velocity = Vector3.ZERO
	sphere.angular_velocity = Vector3.ZERO
	_player.vehicle_model.rotation = Vector3(0, _spawn_yaw, 0)


# Track building

func _build_track_and_spawnables() -> void:
	var cells: Array[Vector3i] = []
	for c in _grid.get_used_cells():
		var item := _grid.get_cell_item(c)
		if item < 0:
			continue
		if _grid.mesh_library.get_item_name(item).begins_with("track"):
			cells.append(c)
	if cells.is_empty():
		push_warning("KubiGP: not found track pieces in GridMap")
		return

	_props_root = Node3D.new()
	_props_root.name = "Props"
	add_child(_props_root)

	var centroid := Vector2.ZERO
	for c in cells:
		centroid += Vector2(c.x, c.z)
	centroid /= cells.size()

	cells.sort_custom(func(a, b):
		var aa := _cell_angle(a, centroid)
		var bb := _cell_angle(b, centroid)
		return aa < bb)

	var points: Array[Vector3] = []
	var used_angles: Array[float] = []
	for c in cells:
		var ang := _cell_angle(c, centroid)
		var dup := false
		for ua in used_angles:
			if absf(_angle_diff(ang, ua)) < COIN_DUP_ANGLE:
				dup = true
				break
		if dup:
			continue
		used_angles.append(ang)
		points.append(_grid.to_global(_grid.map_to_local(c)))
	_path_points = points

	var coins := Node3D.new()
	coins.name = "Coins"
	coins.position = Vector3.ZERO
	add_child(coins)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.85, 0.2)
	gold.emission_enabled = true
	gold.emission = Color(1.0, 0.7, 0.1)
	gold.emission_energy_multiplier = 0.8
	var coin_mesh := CylinderMesh.new()
	coin_mesh.top_radius = 0.55
	coin_mesh.bottom_radius = 0.55
	coin_mesh.height = 0.12
	coin_mesh.material = gold
	var coin_shape := SphereShape3D.new()
	coin_shape.radius = 1.8
	for i in range(0, _path_points.size(), COIN_STEP):
		var area := Area3D.new()
		area.name = "Coin%d" % i
		area.collision_mask = 8          # เจอ sphere ของรถ (layer 8) เท่านั้น
		area.position = _path_points[i] + Vector3(0, 1.4, 0)
		var mi := MeshInstance3D.new()
		mi.mesh = coin_mesh
		mi.rotation.x = PI / 2           # ยาบเหรียญให้ตั้งตึงแล้วหมุนแบบเหรียญ
		area.add_child(mi)
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
	_set_center_hint(center)
	for i in range(0, _path_points.size(), POLE_STEP):
		_spawn_prop("res://models/props/electricity-pole.glb"
			, _path_points[i], -1)
	for i in range(3, _path_points.size(), BARRIER_STEP):
		_spawn_prop("res://models/props/road-side-barrier.glb"
			, _path_points[i], -1)
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
	var offset := out * (9.5 if side < 0 else 6.5)
	if side == 1:
		offset = offset.rotated(Vector3.UP, PI)   # ประตูที่ 2 วางด้านตรงข้าม
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
		var s := 1.5 / maxf(_measure_height(instance), 0.05)
		instance.scale = Vector3(s, s, s)
		var p := _path_points[2 + i * 2] if _path_points.size() > 2 else center
		var out := Vector3(p.x - center.x, 0, p.z - center.z)
		out = out.normalized() if out.length() > 0.01 else Vector3(0, 0, 1)
		instance.position = p + out * 5.6
		var tangent := _tangent_at(p)
		if tangent.length() > 0.01:
			instance.rotation.y = atan2(tangent.x, tangent.z)


# Lap / coin logic

func _on_coin_body_entered(body: Node3D, area: Area3D) -> void:
	if body is RigidBody3D:
		_collect_coin(area)


func _collect_coin(area: Area3D) -> void:
	if not is_instance_valid(area):
		return
	coins_collected += 1
	_coin_roots.erase(area)
	area.queue_free()


func _on_gate_body_entered(body: Node3D, gate_index: int) -> void:
	if body is RigidBody3D:
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


func _finish_race() -> void:
	race_finished = true
	_win_label.text = " ชน! คุณคือแชมป์ Kubi Grand Prix 3 รอบ\n เวลา: " + _format_time(elapsed) + "  |  เหรียญทอง: %d\n ปิดหน้าต่างเพื่อออก" % coins_collected
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
		yaw = atan2(tangent.x, tangent.z)
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


# Helpers

func _cell_angle(c: Vector3i, center: Vector2) -> float:
	return atan2(c.z - center.y, c.x - center.x)


func _angle_diff(a: float, b: float) -> float:
	var d := fmod(a - b, TAU)
	if d > PI:
		d -= TAU
	if d < -PI:
		d += TAU
	return d


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
	_hud_coin = _make_label(box, 30)
	_hud_time = _make_label(box, 30)
	_hud_hint = _make_label(box, 18)
	_hud_hint.text = "W = เร่ง  /  S = เบรก  /  A D = เลี้ยว  |  ผ่านประตูตามลำดับเพื่อนับรอบ ครบ %d รอบชนะ" % LAPS_TO_WIN

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
	_hud_coin.text = "เหรียญทอง: %d" % coins_collected
	_hud_time.text = "เวลา: " + _format_time(elapsed)

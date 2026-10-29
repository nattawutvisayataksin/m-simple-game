extends Node3D
## เมือง Kubi: สนามแข่งล้อมด้วยย่านเมืองและสวนสาธารณะตรงกลาง

const TILE_SCALE := 7.0          # 1 เซลล์ถนน = 7 ม. (กว้างพอ 2 เลน)
const RING_W := 14               # ความกว้างวงถนน (เซลล์)
const RING_H := 9                # ความลึกวงถนน (เซลล์)
const ROAD_TOP := 0.0            # ผิวถนนอยู่ระดับ y=0
const BENDING_BASE := 0          # ชดเชยมุม road-bend (จูนจากภาพจริง, +1 ต่อ 90°)
const STRAIGHT_TUNE := 0.0       # ชดเชยทิศถนนตรง (จูนจากภาพจริง, +1 ต่อ 90°)

const ROAD_STRAIGHT := "res://models/town/roads/road-straight.glb"
const ROAD_BEND := "res://models/town/roads/road-bend.glb"

const BUILDINGS := [
	["res://models/town/industrial/building-g.glb", 14.0],
	["res://models/town/industrial/building-l.glb", 12.0],
	["res://models/town/industrial/building-n.glb", 13.0],
	["res://models/town/industrial/building-j.glb", 11.0],
	["res://models/town/industrial/building-q.glb", 15.0],
]

const DECOS := [
	["res://models/town/deco/tree-pine-small.glb", 4.0],
	["res://models/town/deco/flowers.glb", 1.0],
	["res://models/town/deco/tree-pine-small.glb", 3.2],
]

const KUBI_WALKERS := [
	"res://models/town/deco/character-oobi.glb",
	"res://models/town/deco/character-oodi.glb",
	"res://models/town/deco/character-ooli.glb",
	"res://models/town/deco/character-oopi.glb",
	"res://models/town/deco/character-oozi.glb",
]

var _town: Node3D
var _path_cells: Array[Vector3] = []
var _straight_scene: PackedScene
var _bend_scene: PackedScene


func _ready() -> void:
	_town = self
	# ลบฉากสนามเก่าของ Starter Kit ใน GridMap ออกทั้งหมด (เมือง Kubi แทนที่)
	get_parent().get_node("GridMap").clear()
	_straight_scene = load(ROAD_STRAIGHT)
	_bend_scene = load(ROAD_BEND)
	_paint_ring()
	_city_blocks()
	_central_park()
	_start_line_decor()
	_track_props()
	_bonus_props()
	_ground_catcher()


## จุดกลางเซลล์ถนน (โลก) — y อยู่บนผิวถนน (ROAD_TOP)
func _cell_world(cx: int, cz: int) -> Vector3:
	return Vector3((cx + 0.5) * TILE_SCALE, ROAD_TOP, (cz + 0.5) * TILE_SCALE)


## สำหรับ game.gd: จุดกลางเซลล์ถนนทั้งวง (เรียงวนครบลูป)
func get_track_points() -> Array[Vector3]:
	return _path_cells.duplicate()


# --- วงถนนเมือง ---

func _paint_ring() -> void:
	var w := RING_W
	var h := RING_H
	_path_cells.clear()
	# ขอบล่าง (วิ่งตามแกน X) -> ขอบขวา (ตามแกน Z) -> บน -> ซ้าย
	for x in range(1, w - 1):
		_lay_road(Vector3i(x, 0, 0), false, 0, true)
	for z in range(1, h - 1):
		_lay_road(Vector3i(w - 1, 0, z), false, 0, false)
	for x in range(w - 2, 0, -1):
		_lay_road(Vector3i(x, 0, h - 1), false, 0, true)
	for z in range(h - 2, 0, -1):
		_lay_road(Vector3i(0, 0, z), false, 0, false)
	# มุม 4 จุด (โค้ง 90°)
	_lay_road(Vector3i(w - 1, 0, 0), true, 0, false)   # ขวาล่าง
	_lay_road(Vector3i(w - 1, 0, h - 1), true, 1, false)  # ขวาบน
	_lay_road(Vector3i(0, 0, h - 1), true, 2, false)   # ซ้ายบน
	_lay_road(Vector3i(0, 0, 0), true, 3, false)       # ซ้ายล่าง


func _lay_road(cell: Vector3i, corner: bool, corner_index: int, along_x: bool) -> void:
	var scene: PackedScene = _bend_scene if corner else _straight_scene
	if scene == null:
		return
	var inst: Node3D = scene.instantiate()
	inst.name = "Road_%d_%d" % [cell.x, cell.z]
	inst.position = _cell_world(cell.x, cell.z)
	inst.scale = Vector3.ONE * TILE_SCALE
	if corner:
		inst.rotation.y = (BENDING_BASE + corner_index) * PI / 2.0
	else:
		inst.rotation.y = STRAIGHT_TUNE * PI / 2.0 + (0.0 if along_x else PI / 2.0)
	# GLB ผิวถนนหนา 0.02 ลอยเหนือ origin — ทับลงให้ผิวบนเท่า ROAD_TOP
	inst.position.y = ROAD_TOP - 0.02 * TILE_SCALE
	add_child(inst)
	_path_cells.append(Vector3(inst.position.x, ROAD_TOP, inst.position.z))
	_paint_road_tile(cell, along_x, corner)
	# กล่องชนพื้นบาง (ขับได้)
	var body := StaticBody3D.new()
	body.name = "RoadCollision_%d_%d" % [cell.x, cell.z]
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(TILE_SCALE, 0.3, TILE_SCALE)
	cs.shape = shape
	cs.position = Vector3(0, ROAD_TOP - 0.15, 0)
	body.add_child(cs)
	body.position = Vector3(inst.position.x, ROAD_TOP, inst.position.z)
	add_child(body)


func _paint_road_tile(cell: Vector3i, along_x: bool, corner: bool) -> void:
	var surface := MeshInstance3D.new()
	surface.name = "RoadSurface_%d_%d" % [cell.x, cell.z]
	var asphalt := PlaneMesh.new()
	asphalt.size = Vector2(TILE_SCALE, TILE_SCALE)
	var asphalt_material := StandardMaterial3D.new()
	asphalt_material.albedo_color = Color(0.16, 0.19, 0.22)
	asphalt_material.roughness = 0.95
	asphalt.material = asphalt_material
	surface.mesh = asphalt
	surface.position = _cell_world(cell.x, cell.z) + Vector3(0, ROAD_TOP + 0.025, 0)
	add_child(surface)
	_paint_outer_sidewalk(cell)

	if corner:
		return
	var marking := MeshInstance3D.new()
	marking.name = "LaneDash"
	var dash := BoxMesh.new()
	dash.size = Vector3(0.16, 0.035, 2.0)
	var marking_material := StandardMaterial3D.new()
	marking_material.albedo_color = Color(1.0, 0.78, 0.2)
	marking_material.emission_enabled = true
	marking_material.emission = Color(0.6, 0.28, 0.03)
	dash.material = marking_material
	marking.mesh = dash
	marking.position.y = 0.025
	marking.rotation.y = PI / 2.0 if along_x else 0.0
	surface.add_child(marking)


func _paint_outer_sidewalk(cell: Vector3i) -> void:
	var center := _cell_world(cell.x, cell.z)
	var outward := Vector3(center.x - 49.0, 0, center.z - 31.5).normalized()
	var is_corner := (cell.x == 0 or cell.x == RING_W - 1) \
		and (cell.z == 0 or cell.z == RING_H - 1)
	if not is_corner:
		if cell.z == 0:
			outward = Vector3(0, 0, -1)
		elif cell.z == RING_H - 1:
			outward = Vector3(0, 0, 1)
		elif cell.x == 0:
			outward = Vector3(-1, 0, 0)
		else:
			outward = Vector3(1, 0, 0)
	var tangent := Vector3(-outward.z, 0, outward.x)
	var paving := BoxMesh.new()
	paving.size = Vector3(1.7, 0.14, 6.5)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.58, 0.56, 0.49)
	material.roughness = 0.95
	paving.material = material
	var sidewalk := MeshInstance3D.new()
	sidewalk.name = "Sidewalk_%d_%d" % [cell.x, cell.z]
	sidewalk.mesh = paving
	sidewalk.position = center + outward * 4.2 + Vector3(0, 0.07, 0)
	sidewalk.rotation.y = atan2(tangent.x, tangent.z)
	add_child(sidewalk)


## Large, neutral paved city block with a soft green park as the focal point.
func _ground_catcher() -> void:
	var city_center := Vector3(49.0, 0, 31.5)
	var body := StaticBody3D.new()
	body.name = "CityGround"
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(300, 0.2, 260)
	cs.shape = shape
	cs.position = Vector3(0, ROAD_TOP - 0.12, 0)
	body.add_child(cs)
	body.position = city_center
	add_child(body)

	var mi := MeshInstance3D.new()
	mi.name = "CityGroundVisual"
	var plane := PlaneMesh.new()
	plane.size = Vector2(300, 260)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.48, 0.46, 0.40)
	mat.roughness = 1.0
	plane.material = mat
	mi.mesh = plane
	mi.position = Vector3(city_center.x, ROAD_TOP - 0.05, city_center.z)
	add_child(mi)

# --- ตึกเมือง (ชนได้) ---

func _city_blocks() -> void:
	var perimeter := [
		[Vector3(20.0, 0, -20.0), 0],
		[Vector3(48.0, 0, -22.0), 1],
		[Vector3(77.0, 0, -20.0), 2],
		[Vector3(20.0, 0, 83.0), 3],
		[Vector3(49.0, 0, 85.0), 4],
		[Vector3(78.0, 0, 83.0), 0],
		[Vector3(-19.0, 0, 14.0), 1],
		[Vector3(-21.0, 0, 48.0), 2],
		[Vector3(116.0, 0, 14.0), 3],
		[Vector3(118.0, 0, 48.0), 4],
	]
	for i in perimeter.size():
		var building: Array = BUILDINGS[i % BUILDINGS.size()]
		var placement: Array = perimeter[i]
		var structure := _spawn_static_prop(building[0], placement[0], building[1], deg_to_rad(90 * placement[1]))
		if structure != null:
			structure.name = "CityPerimeter_%02d" % i


func _central_park() -> void:
	var park := Node3D.new()
	park.name = "CentralPark"
	add_child(park)
	var center := Vector3(49.0, 0, 31.5)

	var lawn := PlaneMesh.new()
	lawn.size = Vector2(48, 32)
	var lawn_material := StandardMaterial3D.new()
	lawn_material.albedo_color = Color(0.30, 0.39, 0.27)
	lawn_material.roughness = 1.0
	lawn.material = lawn_material
	var lawn_mesh := MeshInstance3D.new()
	lawn_mesh.name = "ParkLawn"
	lawn_mesh.mesh = lawn
	lawn_mesh.position = center + Vector3(0, 0.015, 0)
	park.add_child(lawn_mesh)

	var path_material := StandardMaterial3D.new()
	path_material.albedo_color = Color(0.70, 0.66, 0.56)
	path_material.roughness = 0.9
	_add_park_path(park, "ParkPathEastWest", center, Vector2(43, 2.6), path_material)
	_add_park_path(park, "ParkPathNorthSouth", center, Vector2(2.6, 27), path_material)

	var fountain := CylinderMesh.new()
	fountain.top_radius = 4.0
	fountain.bottom_radius = 4.5
	fountain.height = 0.55
	var fountain_material := StandardMaterial3D.new()
	fountain_material.albedo_color = Color(0.72, 0.69, 0.60)
	fountain.material = fountain_material
	var fountain_mesh := MeshInstance3D.new()
	fountain_mesh.name = "ParkFountain"
	fountain_mesh.mesh = fountain
	fountain_mesh.position = center + Vector3(0, 0.30, 0)
	park.add_child(fountain_mesh)

	var water := CylinderMesh.new()
	water.top_radius = 3.3
	water.bottom_radius = 3.3
	water.height = 0.12
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.22, 0.55, 0.63)
	water_material.metallic = 0.18
	water_material.roughness = 0.22
	water.material = water_material
	var water_mesh := MeshInstance3D.new()
	water_mesh.mesh = water
	water_mesh.position = center + Vector3(0, 0.62, 0)
	park.add_child(water_mesh)

	for i in 8:
		var angle := TAU * float(i) / 8.0
		var tree_pos := center + Vector3(cos(angle) * 20.0, 0, sin(angle) * 13.0)
		var tree := _spawn_static_prop("res://models/town/deco/tree-pine-small.glb",
			tree_pos, 5.0, angle)
		if tree != null:
			tree.name = "ParkTree_%02d" % i

	for i in 4:
		var angle := PI / 4.0 + TAU * float(i) / 4.0
		var planter := CylinderMesh.new()
		planter.top_radius = 2.3
		planter.bottom_radius = 2.5
		planter.height = 0.35
		var planter_material := StandardMaterial3D.new()
		planter_material.albedo_color = Color(0.38, 0.46, 0.31)
		planter.material = planter_material
		var bed := MeshInstance3D.new()
		bed.name = "ParkPlanter_%02d" % i
		bed.mesh = planter
		bed.position = center + Vector3(cos(angle) * 14.0, 0.19, sin(angle) * 10.0)
		park.add_child(bed)


func _add_park_path(parent: Node3D, node_name: String, center: Vector3,
		size: Vector2, material: StandardMaterial3D) -> void:
	var path_mesh := PlaneMesh.new()
	path_mesh.size = size
	path_mesh.material = material
	var path := MeshInstance3D.new()
	path.name = node_name
	path.mesh = path_mesh
	path.position = center + Vector3(0, 0.04, 0)
	parent.add_child(path)

# --- จุดสตาร์ต/เส้นชัย: รั้ว + เหล่า Kubi เดิน + ต้นไม้ใบไม้ ---

func _start_line_decor() -> void:
	var start := _cell_world(1, 0)
	# รั้วต่ำเรียงหลังเส้นชัยฝั่งนอกสนาม
	for i in 6:
		var p := start + Vector3(-6.0 + i * 2.2, 0, -6.5)
		_spawn_static_prop("res://models/town/deco/fence-low-straight.glb", p, 1.1, 0.0)
	# เหล่า Kubi 5 ตัวเชียร์หลังรั้ว
	for i in KUBI_WALKERS.size():
		var p := start + Vector3(-5.5 + i * 2.6, 0.05, -7.6)
		_spawn_static_prop(KUBI_WALKERS[i], p, 2.2, deg_to_rad(15 * i - 30))
	# ต้นไม้และดอกไม้กระจายรอบนอกสนาม โดยเว้นเลนแข่งไว้
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260229
	var zones := [
		Rect2(-48, -24, 36, 112),
		Rect2(110, -24, 36, 112),
		Rect2(-12, -34, 124, 26),
		Rect2(-12, 72, 124, 26),
	]
	for i in 24:
		var deco: Array = DECOS[i % DECOS.size()]
		var zone: Rect2 = zones[rng.randi_range(0, zones.size() - 1)]
		var rx := rng.randf_range(zone.position.x, zone.end.x)
		var rz := rng.randf_range(zone.position.y, zone.end.y)
		var body := _spawn_static_prop(deco[0], Vector3(rx, ROAD_TOP, rz), deco[1], rng.randf() * TAU)
		if body != null:
			body.name = "TownDecor_%02d" % i

# --- ของแถวทางวิ่ง: กล่องซ้อน (ชนได้) + เป้าโบนัส ---

func _track_props() -> void:
	var corner_aa := _cell_world(4, 0)   # ข้างถนนล่าง
	_spawn_static_prop("res://models/town/props/crate-medium.glb", corner_aa + Vector3(0, 0, 3.6), 1.5, deg_to_rad(8))
	var p2 := _cell_world(10, 0)
	_spawn_static_prop("res://models/town/props/crate-small.glb", p2 + Vector3(0, 0, 3.6), 1.2, deg_to_rad(95))
	_spawn_static_prop("res://models/town/props/crate-medium.glb", p2 + Vector3(0.4, 0, 3.4), 1.5, deg_to_rad(-20))

func _bonus_props() -> void:
	# เป้าโบนัสหลังจุดเริ่ม (ทางออกจากเมือง)
	var start := _cell_world(1, 0)
	_spawn_static_prop("res://models/town/props/target-large.glb", start + Vector3(5.2, 0, -3.4), 2.6, deg_to_rad(45))

# --- ตัวช่วยวางของทั่วเมือง (มีชน = StaticBody3D) ---

func _spawn_static_prop(path: String, at: Vector3, target_height: float, yaw: float) -> Node3D:
	var scene: PackedScene = load(path)
	if scene == null:
		return null
	var body := StaticBody3D.new()
	var holder := Node3D.new()
	body.add_child(holder)
	var instance: Node3D = scene.instantiate()
	holder.add_child(instance)
	var aabb := _mesh_aabb_local(instance)
	var s := target_height / maxf(aabb.size.y, 0.05)
	holder.scale = Vector3(s, s, s)
	holder.position.y = -aabb.position.y * s       # ฐานแตะพื้น
	body.position = at
	body.rotation.y = yaw
	# กล่องชนแนวตัว (รวมกล่อง AABB)
	var shape := BoxShape3D.new()
	shape.size = (Vector3(aabb.size.x, aabb.size.y, aabb.size.z) * s).limit_length(40.0)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3((aabb.position.x + aabb.size.x * 0.5) * s, aabb.size.y * 0.5 * s, (aabb.position.z + aabb.size.z * 0.5) * s)
	body.add_child(cs)
	_town.add_child(body)
	return body

func _mesh_aabb_local(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [[node, Transform3D.IDENTITY]]
	while stack.size() > 0:
		var entry: Array = stack.pop_back()
		var n: Node = entry[0]
		var acc: Transform3D = entry[1]
		if n is Node3D and n != node:
			acc = acc * (n as Node3D).transform
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var c: AABB = acc * (n as MeshInstance3D).mesh.get_aabb()
			if first:
				result = c
				first = false
			else:
				result = result.merge(c)
		for child in n.get_children():
			stack.append([child, acc])
	return result

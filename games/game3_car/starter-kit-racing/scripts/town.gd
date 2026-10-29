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
	["res://models/town/industrial/building-g.glb", 5.2],
	["res://models/town/industrial/building-l.glb", 4.7],
	["res://models/town/industrial/building-n.glb", 5.6],
	["res://models/town/industrial/building-j.glb", 4.9],
	["res://models/town/industrial/building-q.glb", 6.0],
]

const DECOS := [
	["res://models/town/deco/tree-pine-small.glb", 3.0],
	["res://models/town/deco/flowers.glb", 0.6],
	["res://models/town/deco/tree-pine-small.glb", 2.6],
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
	_paint_city_streets()
	_city_blocks()
	_central_park()
	_start_line_decor()
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

	var edge_material := StandardMaterial3D.new()
	edge_material.albedo_color = Color(0.78, 0.79, 0.75)
	edge_material.roughness = 0.85
	for side in [-1.0, 1.0]:
		var edge := MeshInstance3D.new()
		edge.name = "TrackEdge"
		var edge_mesh := BoxMesh.new()
		edge_mesh.size = Vector3(TILE_SCALE, 0.035, 0.1) if along_x \
			else Vector3(0.1, 0.035, TILE_SCALE)
		edge_mesh.material = edge_material
		edge.mesh = edge_mesh
		edge.position = Vector3(0, 0.025, side * 3.2) if along_x \
			else Vector3(side * 3.2, 0.025, 0)
		surface.add_child(edge)


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


func _paint_city_streets() -> void:
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.20, 0.22, 0.23)
	asphalt.roughness = 0.95
	var road_layouts := [
		["CityStreet_South", Vector3(49.0, 0.012, -10.0), Vector2(110.0, 4.5), true],
		["CityStreet_North", Vector3(49.0, 0.012, 73.0), Vector2(110.0, 4.5), true],
		["CityStreet_West", Vector3(-10.0, 0.012, 31.5), Vector2(4.5, 75.0), false],
		["CityStreet_East", Vector3(108.0, 0.012, 31.5), Vector2(4.5, 75.0), false],
	]
	for layout in road_layouts:
		var road_mesh := PlaneMesh.new()
		road_mesh.size = layout[2]
		road_mesh.material = asphalt
		var road := MeshInstance3D.new()
		road.name = layout[0]
		road.mesh = road_mesh
		road.position = layout[1]
		add_child(road)
		_paint_city_street_markings(str(layout[0]), road.position, layout[2], layout[3])


func _paint_city_street_markings(street_name: String, center: Vector3,
		size: Vector2, runs_east_west: bool) -> void:
	var centerline_material := StandardMaterial3D.new()
	centerline_material.albedo_color = Color(0.91, 0.72, 0.28)
	centerline_material.roughness = 0.8
	var edge_material := StandardMaterial3D.new()
	edge_material.albedo_color = Color(0.76, 0.77, 0.73)
	edge_material.roughness = 0.8
	var line_length := size.x if runs_east_west else size.y
	var centerline := MeshInstance3D.new()
	centerline.name = street_name + "_Centerline"
	var solid_line := BoxMesh.new()
	solid_line.size = Vector3(line_length, 0.035, 0.12) if runs_east_west \
		else Vector3(0.12, 0.035, line_length)
	solid_line.material = centerline_material
	centerline.mesh = solid_line
	centerline.position = center + Vector3(0, 0.035, 0)
	add_child(centerline)

	for side in [-1.0, 1.0]:
		for segment in range(1, int(line_length / 7.0)):
			var dash := MeshInstance3D.new()
			dash.name = street_name + "_EdgeDash"
			var dash_mesh := BoxMesh.new()
			dash_mesh.size = Vector3(2.4, 0.035, 0.1) if runs_east_west \
				else Vector3(0.1, 0.035, 2.4)
			dash_mesh.material = edge_material
			dash.mesh = dash_mesh
			var along := -line_length * 0.5 + float(segment) * 7.0
			dash.position = center + Vector3(along, 0.035, side * 1.75) if runs_east_west \
				else center + Vector3(side * 1.75, 0.035, along)
			add_child(dash)


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
	mat.albedo_color = Color(0.43, 0.42, 0.38)
	mat.roughness = 1.0
	plane.material = mat
	mi.mesh = plane
	mi.position = Vector3(city_center.x, ROAD_TOP - 0.05, city_center.z)
	add_child(mi)

# --- ตึกเมือง (ชนได้) ---

func _city_blocks() -> void:
	var perimeter := [
		[Vector3(13.0, 0, -18.5), 0],
		[Vector3(31.0, 0, -18.5), 1],
		[Vector3(49.0, 0, -18.5), 2],
		[Vector3(67.0, 0, -18.5), 3],
		[Vector3(85.0, 0, -18.5), 4],
		[Vector3(13.0, 0, 82.5), 0],
		[Vector3(31.0, 0, 82.5), 1],
		[Vector3(49.0, 0, 82.5), 2],
		[Vector3(67.0, 0, 82.5), 3],
		[Vector3(85.0, 0, 82.5), 4],
		[Vector3(-18.5, 0, 13.0), 0],
		[Vector3(-18.5, 0, 31.5), 1],
		[Vector3(-18.5, 0, 50.0), 2],
		[Vector3(116.5, 0, 13.0), 3],
		[Vector3(116.5, 0, 31.5), 4],
		[Vector3(116.5, 0, 50.0), 0],
	]
	for i in perimeter.size():
		var building: Array = BUILDINGS[i % BUILDINGS.size()]
		var placement: Array = perimeter[i]
		_add_city_lot(i, placement[0], i >= 6)
		var structure := _spawn_static_prop(building[0], placement[0], building[1], deg_to_rad(90 * placement[1]))
		if structure != null:
			structure.name = "CityPerimeter_%02d" % i


func _add_city_lot(index: int, center: Vector3, side_lot: bool) -> void:
	var lot := MeshInstance3D.new()
	lot.name = "CityLot_%02d" % index
	var lot_mesh := PlaneMesh.new()
	lot_mesh.size = Vector2(12.0, 12.0) if side_lot else Vector2(16.0, 12.0)
	var material := StandardMaterial3D.new()
	var lot_colors := [
		Color(0.34, 0.35, 0.34),
		Color(0.51, 0.48, 0.42),
		Color(0.40, 0.41, 0.40),
	]
	material.albedo_color = lot_colors[index % lot_colors.size()]
	material.roughness = 0.95
	lot_mesh.material = material
	lot.mesh = lot_mesh
	lot.position = center + Vector3(0, 0.012, 0)
	add_child(lot)


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
			tree_pos, 3.2, angle)
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
		var flowers_scene := load("res://models/town/deco/flowers.glb") as PackedScene
		if flowers_scene != null:
			var flowers := flowers_scene.instantiate() as Node3D
			flowers.name = "ParkFlowers_%02d" % i
			var flower_bounds := _mesh_aabb_local(flowers)
			var flower_scale := 0.75 / maxf(flower_bounds.size.y, 0.05)
			flowers.scale = Vector3.ONE * flower_scale
			flowers.position = bed.position + Vector3(
				0, 0.18 - flower_bounds.position.y * flower_scale, 0)
			park.add_child(flowers)


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
	# Landscape rows create a deliberate buffer between the circuit and local streets.
	for i in 24:
		var side := i / 6
		var slot := i % 6
		var along := 10.0 + slot * 16.0
		var at := Vector3.ZERO
		match side:
			0:
				at = Vector3(along, ROAD_TOP, -5.0)
			1:
				at = Vector3(along, ROAD_TOP, 68.0)
			2:
				at = Vector3(-5.0, ROAD_TOP, 8.0 + slot * 9.0)
			_:
				at = Vector3(103.0, ROAD_TOP, 8.0 + slot * 9.0)
		var deco: Array = DECOS[i % DECOS.size()]
		var body := _spawn_static_prop(deco[0], at, deco[1], 0.0)
		if body != null:
			body.name = "TownDecor_%02d" % i

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

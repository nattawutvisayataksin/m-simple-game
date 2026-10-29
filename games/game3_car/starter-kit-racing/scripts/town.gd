extends Node3D
## เมือง Kubi (T1.1) — สนามใหม่มีเอกลักษณ์ของเกม
## วาดวงถนนเมือง (city-kit-roads) ระดับ 7 ม./เซลล์ + ตึกเมือง (city-kit-industrial)
## + กล่องกีดขวาง/เป้าโบนัส (blaster-kit) + เหล่า Kubi เดิน/รั้ว/ต้นไม้ (platformer-kit)
## วางถนนเป็นโหนดตรง ๆ (ไม่พึ่ง GridMap) — GLB ของ Kenney นอนแบนพร้อมใช้แล้ว
## วัดแล้วด้วย probe: road-straight = X 1 × Y 0.02 (ผิว) × Z 1 — ผิวบนอยู่เหนือ 0 ถึง +0.02

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
	inst.position = _cell_world(cell.x, cell.z)
	if corner:
		inst.rotation.y = (BENDING_BASE + corner_index) * PI / 2.0
	else:
		inst.rotation.y = STRAIGHT_TUNE * PI / 2.0 + (0.0 if along_x else PI / 2.0)
	# GLB ผิวถนนหนา 0.02 ลอยเหนือ origin — ทับลงให้ผิวบนเท่า ROAD_TOP
	inst.position.y = ROAD_TOP - 0.02 * TILE_SCALE
	add_child(inst)
	_path_cells.append(Vector3(inst.position.x, ROAD_TOP, inst.position.z))
	# กล่องชนพื้นบาง (ขับได้)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(TILE_SCALE, 0.3, TILE_SCALE)
	cs.shape = shape
	cs.position = Vector3(0, ROAD_TOP - 0.15, 0)
	body.add_child(cs)
	body.position = inst.position
	add_child(body)


## พื้นตัวรับเมืองทั้งผืน (ขับชื่นในเมืองระหว่างตึกได้ ไม่ตกฉาก) + อาณาเขตใหญ่
func _ground_catcher() -> void:
	var body := StaticBody3D.new()
	body.name = "CityGround"
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(240, 0.2, 180)
	cs.shape = shape
	cs.position = Vector3(0, ROAD_TOP - 0.12, 0)
	body.add_child(cs)
	add_child(body)
	# พื้นหญ้าของเมือง (เอกลักษณ์สีธรรมชาติ Kenney)
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(240, 180)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.70, 0.42)
	plane.material = mat
	mi.mesh = plane
	mi.position = Vector3(0, ROAD_TOP - 0.05, 0)
	add_child(mi)

# --- ตึกเมือง (ชนได้) ---

func _city_blocks() -> void:
	var spots := [
		[4, 3], [8, 3], [11, 3],
		[4, 5], [8, 5], [11, 5],
		[3, 4], [7, 4], [12, 4],
	]
	for i in spots.size():
		var path: String = BUILDINGS[i % BUILDINGS.size()][0]
		var target: float = BUILDINGS[i % BUILDINGS.size()][1]
		var c: Array = spots[i]
		var p := _cell_world(c[0], c[1])
		_spawn_static_prop(path, Vector3(p.x, ROAD_TOP, p.z), target, deg_to_rad(90 * (i % 4)))
	# กังหันลม + แท้งค์น้ำมุมเมือง
	_spawn_static_prop("res://models/town/industrial/windmill.glb", _cell_world(6, 4) + Vector3(3.5, 0, 3.5), 14.0, 0.0)
	_spawn_static_prop("res://models/town/industrial/water-tower.glb", _cell_world(13, 6) + Vector3(3.5, 0, 3.5), 13.0, deg_to_rad(180))
	# คอนเทนเนอร์กองข้ามถนนข้างซ้าย
	for cz in [4, 5]:
		var p := _cell_world(-2, cz)
		_spawn_static_prop("res://models/town/industrial/shipping-container-a.glb", Vector3(p.x, ROAD_TOP, p.z), 3.4, deg_to_rad(90))
	# ปล่องโรงงานโผล่หลังซ้ายบน
	_spawn_static_prop("res://models/town/industrial/chimney-large.glb", _cell_world(0, 6) + Vector3(-4, 0, -6), 12.0, 0.0)

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
	# ต้นไม้ใบไม้กระจายรอบเมือง
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260229
	for i in 24:
		var deco: Array = DECOS[i % DECOS.size()]
		var rx := rng.randf_range(-46.0, 46.0)
		var rz := rng.randf_range(-34.0, 34.0)
		_spawn_static_prop(deco[0], Vector3(rx, ROAD_TOP, rz), deco[1], rng.randf() * TAU)

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

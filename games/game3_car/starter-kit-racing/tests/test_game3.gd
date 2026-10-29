extends SceneTree
## Test runner: Kubi Grand Prix (Game 3) - รัน headless:
## godot --headless --path . --script res://tests/test_game3.gd
## ครอบคลุม: โครงสนาม, เก็บเหรียญ, นับรอบ, respawn, ขับได้จริง

var frames := 0
var game: Node3D
var failures: Array = []
var passed: Array = []
var stage := 0
var drive_start := Vector3.ZERO
var ai_start_position := Vector3.ZERO
var ai_progress_start := 0.0


func _initialize() -> void:
	print("=== KubiGP test: boot")
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		_check("main.tscn โหลดได้", false, "load fail")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	game = root.get_node("Main")
	if game == null:
		_check("หาโหนด Main ได้", false, "null")
		quit(1)


func _check(name: String, condition: bool, detail: String = "") -> void:
	if condition:
		passed.append(name)
		print("  PASS: ", name)
	else:
		failures.append(name)
		print("  FAIL: ", name, " ", detail)


func _process(_delta: float) -> bool:
	frames += 1
	if stage == 0 and frames >= 5:
		stage = 1
		_stage_structure()
	elif stage == 1:
		stage = 2
		_stage_coins()
	elif stage == 2:
		stage = 3
		_stage_laps()
	elif stage == 3:
		stage = 4
		_stage_respawn_setup()
	elif stage == 4 and frames > 300:
		stage = 5
		_stage_respawn_check()
	elif stage == 5:
		stage = 6
		_stage_drive_setup()
	elif stage == 6 and frames > 520:
		stage = 7
		_stage_drive_check()
		_finish()
	return false


# 1) โครงสร้างที่สร้างโดย game.gd

func _stage_structure() -> void:
	print("[1] โครงสร้างระบบเกม")
	_check("มีเมนูเลือกรถก่อนเริ่มแข่ง",
		game.get_node_or_null("CarSelection") != null)
	_check("รอผู้เล่นกดเริ่มก่อนปล่อยรถ",
		game.get("race_started") == false)
	_check("มีคู่แข่ง AI 3 คัน",
		game.get("_ai_racers").size() == 3)
	var route_points: Array = game.get("_path_points")
	var first_ai: Vehicle = game.get("_ai_racers")[0]
	var route_tangent: Vector3 = game.call("_tangent_at", route_points[0])
	_check("หัวรถ AI หันตามทิศทางสนาม",
		first_ai.vehicle_model.global_basis.z.dot(route_tangent) > 0.98)
	var item_boxes: Node3D = game.get_node_or_null("ItemBoxes")
	var item_box_names: Array[String] = []
	if item_boxes != null:
		for item_box in item_boxes.get_children():
			item_box_names.append(str(item_box.name))
	_check("มีจุดเก็บไอเท็มบนสนาม",
		item_boxes != null and item_boxes.get_child_count() == 4,
		"boxes=%d names=%s" % [
			item_boxes.get_child_count() if item_boxes != null else -1, item_box_names])
	game.call("_start_race")
	var town := game.get_node_or_null("Town")
	var coins := game.get_node_or_null("Coins")
	var gates := game.get_node_or_null("Gates")
	var props := game.get_node_or_null("Props")
	var track_points: Array = town.call("get_track_points") if town != null else []
	_check("เมืองสร้างวงถนนครบ 42 จุด", track_points.size() == 42,
		"points=%d" % track_points.size())
	var decorations_clear := true
	var decoration_count := 0
	if town != null:
		for child in town.get_children():
			if not child.name.begins_with("TownDecor_"):
				continue
			decoration_count += 1
			for point in track_points:
				if Vector2(child.position.x, child.position.z).distance_to(Vector2(point.x, point.z)) < 5.0:
					decorations_clear = false
	_check("ของตกแต่ง 24 ชิ้นอยู่นอกเลนแข่ง", decoration_count == 24 and decorations_clear,
		"count=%d clear=%s" % [decoration_count, decorations_clear])
	var city_street_count := 0
	if town != null:
		for child in town.get_children():
			if child.name.begins_with("CityStreet_"):
				city_street_count += 1
	_check("มีถนนย่านเมืองล้อมรอบสนาม 4 ด้าน", city_street_count == 4,
		"streets=%d" % city_street_count)
	var sidewalk_count := 0
	var sidewalks_aligned := true
	if town != null:
		for child in town.get_children():
			if not child.name.begins_with("Sidewalk_"):
				continue
			sidewalk_count += 1
			var cell := child.name.trim_prefix("Sidewalk_").split("_")
			var cell_x := int(cell[0])
			var cell_z := int(cell[1])
			if (cell_z == 0 or cell_z == 8) and cell_x > 0 and cell_x < 13:
				sidewalks_aligned = sidewalks_aligned and absf(child.position.x - (cell_x + 0.5) * 7.0) < 0.01
			elif (cell_x == 0 or cell_x == 13) and cell_z > 0 and cell_z < 8:
				sidewalks_aligned = sidewalks_aligned and absf(child.position.z - (cell_z + 0.5) * 7.0) < 0.01
	_check("ทางเท้าขนานขอบถนน ไม่ยื่นเข้าเลน",
		sidewalk_count == 42 and sidewalks_aligned,
		"count=%d aligned=%s" % [sidewalk_count, sidewalks_aligned])
	var road: Node3D = town.get_node_or_null("Road_1_0") if town != null else null
	_check("โมเดลถนนขยายตามขนาดช่อง 7 ม.", road != null and road.scale.is_equal_approx(Vector3.ONE * 7.0))
	var road_surface: MeshInstance3D = town.get_node_or_null("RoadSurface_1_0") if town != null else null
	var road_mesh := road_surface.mesh as PlaneMesh if road_surface != null else null
	_check("ถนนมีผิวแอสฟัลต์และเส้นประ", road_mesh != null
		and road_mesh.size.is_equal_approx(Vector2(7.0, 7.0))
		and road_surface.get_node_or_null("LaneDash") != null)
	var road_collision: StaticBody3D = town.get_node_or_null("RoadCollision_1_0") if town != null else null
	var road_shape: CollisionShape3D
	if road_collision != null and road_collision.get_child_count() > 0:
		road_shape = road_collision.get_child(0) as CollisionShape3D
	var box_shape := road_shape.shape as BoxShape3D if road_shape != null else null
	_check("ถนนมี collider ครอบคลุมช่อง", box_shape != null
		and road_collision.position.y == 0.0
		and is_equal_approx(box_shape.size.x, 7.0)
		and is_equal_approx(box_shape.size.z, 7.0))
	var perimeter_count := 0
	var buildings_in_scale := true
	if town != null:
		for child in town.get_children():
			if not child.name.begins_with("CityPerimeter_"):
				continue
			perimeter_count += 1
			var outside_track: bool = (child.position.x < 0.0 or child.position.x > 98.0
				or child.position.z < 0.0 or child.position.z > 63.0)
			if not outside_track:
				perimeter_count = -100
			if child.get_child_count() < 2:
				buildings_in_scale = false
				continue
			var body_shape := child.get_child(1) as CollisionShape3D
			var building_box := body_shape.shape as BoxShape3D if body_shape != null else null
			buildings_in_scale = buildings_in_scale and building_box != null \
				and building_box.size.y <= 6.1 and building_box.size.y >= 4.5
	_check("อาคารเตี้ยสมส่วนและอยู่นอกวงสนาม",
		perimeter_count == 10 and buildings_in_scale,
		"buildings=%d scale_ok=%s" % [perimeter_count, buildings_in_scale])
	var park := town.get_node_or_null("CentralPark") if town != null else null
	_check("กลางสนามเป็นสวนสาธารณะ มีลานและน้ำพุ",
		park != null and park.get_node_or_null("ParkPathEastWest") != null
		and park.get_node_or_null("ParkFountain") != null)
	var ground: MeshInstance3D = town.get_node_or_null("CityGroundVisual") if town != null else null
	var ground_material := ground.mesh.surface_get_material(0) if ground != null else null
	_check("พื้นเมืองใช้โทนหินธรรมชาติแทนเขียวสด",
		ground_material is StandardMaterial3D
		and (ground_material as StandardMaterial3D).albedo_color.is_equal_approx(Color(0.36, 0.35, 0.31)))
	_check("ไม่มีเสาไฟฟ้าหรือสิ่งกีดขวางกลางเลน",
		props != null and props.get_child_count() == 6)
	_check("Coins ถูกสร้าง", coins != null and coins.get_child_count() > 0,
		"children=%s" % (coins.get_child_count() if coins else -1))
	_check("Gates ครบ 3 ประตู", gates != null and gates.get_child_count() == 3,
		"children=%s" % (gates.get_child_count() if gates else -1))
	_check("Props ของประดับถูกวาง", props != null and props.get_child_count() > 0,
		"children=%s" % (props.get_child_count() if props else -1))
	var gate_props_are_roadside := props != null and props.get_child_count() >= 3
	var gate_prop_details: Array[String] = []
	if gate_props_are_roadside:
		for i in 3:
			var marker: Node3D = props.get_child(i)
			var marker_height: float = game.call("_measure_height", marker) * marker.scale.y
			var nearest_track_distance := INF
			for point in track_points:
				nearest_track_distance = minf(nearest_track_distance,
					Vector2(marker.position.x, marker.position.z).distance_to(Vector2(point.x, point.z)))
			gate_prop_details.append("h=%.2f d=%.2f" % [marker_height, nearest_track_distance])
			gate_props_are_roadside = gate_props_are_roadside \
				and marker_height <= 1.95 and nearest_track_distance >= 8.0
	_check("ป้ายจุดตรวจขนาดพอดีและอยู่นอกขอบถนน", gate_props_are_roadside,
		"; ".join(gate_prop_details))
	if coins != null and coins.get_child_count() > 0:
		var coin: Area3D = coins.get_child(0)
		_check("เหรียญ set collision_mask=8", coin.collision_mask == 8)

	var next_gate: int = game.get("next_gate")
	_check("รอบเริ่ม 0/3", (game.get("laps") as int) == 0 and next_gate <= 1,
		"laps=%s next_gate=%s (spawn เส้นชัยขยับได้)" % [game.get("laps"), next_gate])
	# รถต้องถูกวางจุดสตาร์ตพอดีเส้นชัย (path[0])
	var sphere: RigidBody3D = game.get_node("Vehicle/Sphere")
	_check("รถถูกวางจุดเริ่ม", sphere.global_position.distance_to(game.get("_path_points")[0]) < 8.0,
		"sphere=%s" % sphere.global_position)


# 2) เก็บเหรียญ

func _stage_coins() -> void:
	print("[2] ระบบเหรียญทอง")
	var coins := game.get_node("Coins")
	var before: int = game.get("coins_collected")
	var count_before := coins.get_child_count()
	var coin: Area3D = coins.get_child(0)
	game.call("_collect_coin", coin)
	_check("เก็บเหรียญ +1", game.get("coins_collected") == before + 1)
	_check("เหรียญถูกลบออกเฉลียม", coins.get_child_count() == count_before - 1 or coin.is_queued_for_deletion())
	game.call("_on_item_box_body_entered", game.get_node("Vehicle/Sphere"),
		game.get_node("ItemBoxes/ItemBox0"), "boost")
	_check("รับไอเท็มบูสต์แล้วเก็บไว้", game.get("held_item") == "boost")
	game.call("_use_player_item")
	_check("ใช้บูสต์แล้วเพิ่มความเร็วชั่วคราว",
		(game.get_node("Vehicle") as Vehicle).boost_time > 0.0)
	var ai_node := (game.get("_ai_racers")[0] as Vehicle).get_node("RacerAI")
	ai_node.call("give_item", "boost")
	ai_node.call("_try_use_item", 0.0)
	_check("AI ใช้บูสต์แล้วเก็บไอเท็ม", str(ai_node.get("held_item")).is_empty()
		and (game.get("_ai_racers")[0] as Vehicle).boost_time > 0.0)


# 3) นับรอบ

func _stage_laps() -> void:
	print("[3] ระบบนับรอบ")
	game.set("next_gate", 0)
	game.set("laps", 0)
	game.set("_passed_full_lap", false)
	game.call("_advance_gate", 1)   # กดผิดลำดับ - ต้องไม่นับ
	_check("ข้ามลำดับไม่นับ", (game.get("next_gate") as int) == 0)
	game.call("_advance_gate", 0)
	game.call("_advance_gate", 1)
	_check("ผ่าน 0->1 ยังไม่ครบรอบ", game.get("laps") == 0 and game.get("next_gate") == 2)
	game.call("_advance_gate", 2)
	_check("ครบ 0->1->2 รอบกลับ 0 แต่ยังไม่ +1", game.get("laps") == 0 and game.get("next_gate") == 0)
	# กลับมาแตะ 0 = +1 รอบ (3 รอบพอดี)
	for lap in 3:
		game.call("_advance_gate", 0)
		game.call("_advance_gate", 1)
		game.call("_advance_gate", 2)
		game.call("_advance_gate", 0)
	_check("ครบ 3 รอบ = ชนะ", game.get("laps") == 3 and game.get("race_finished") == true)


# 4) respawn เมื่อร่วง

func _stage_respawn_setup() -> void:
	print("[4] ระบบ respawn (ตั้ง: โยนรถลงเหว)")
	paused = false                   # เทสรอบก่อนหน้าชนะแล้ว pause เพื่อเล่นต่อต้องปลด
	game.set("race_finished", false)
	var sphere := game.get_node("Vehicle/Sphere")
	sphere.global_transform = Transform3D(Basis(), sphere.global_position + Vector3(0, -30, 0))
	drive_start = sphere.global_position


func _stage_respawn_check() -> void:
	var sphere := game.get_node("Vehicle/Sphere")
	var at_spawn: bool = sphere.global_position.distance_to(game.get("_spawn_point")) < 6.0
	print("    debug: elapsed=%s y=%s race_finished=%s" % [game.get("elapsed"), sphere.global_position.y, game.get("race_finished")])
	_check("รถกลับจุดเริ่มหลังร่วง", at_spawn, "pos=%s" % sphere.global_position)


# 5) ขับได้จริง (กดปุ่ม W)

func _stage_drive_setup() -> void:
	print("[5] ขับได้จริง (กด W 60 เฟรม)")
	Input.action_press("forward")
	drive_start = game.get_node("Vehicle/Sphere").global_position
	var first_ai: Vehicle = game.get("_ai_racers")[0]
	ai_progress_start = float(first_ai.get_node("RacerAI").call("get_race_progress"))
	ai_start_position = first_ai.sphere.global_position


func _stage_drive_check() -> void:
	Input.action_release("forward")
	var now: Vector3 = game.get_node("Vehicle/Sphere").global_position
	var moved: float = (now - drive_start).length()
	_check("รถวิ่งไปได้ > 2 ม.", moved > 2.0, "moved=%.2f" % moved)
	var first_ai: Vehicle = game.get("_ai_racers")[0]
	var ai_node := first_ai.get_node("RacerAI")
	var ai_progress := float(ai_node.call("get_race_progress"))
	var ai_distance_travelled: float = first_ai.sphere.global_position.distance_to(ai_start_position)
	var ai_waypoint := int(ai_node.get("waypoint_index"))
	var ai_target: Vector3 = ai_node.call("_lane_target", ai_waypoint)
	var ai_distance := first_ai.sphere.global_position.distance_to(ai_target)
	_check("AI ขับตามเส้นทางและเพิ่มความคืบหน้า", ai_progress > ai_progress_start,
		"progress=%.1f start=%.1f pos=%s target=%s d=%.1f speed=%.2f input=%s frozen=%s" % [
			ai_progress, ai_progress_start, first_ai.sphere.global_position, ai_target,
			ai_distance, first_ai.linear_speed, first_ai.input, first_ai.sphere.freeze])
	_check("AI เคลื่อนที่จริงระหว่างแข่ง", ai_distance_travelled > 2.0,
		"distance=%.2f" % ai_distance_travelled)


func _finish() -> void:
	print("=== ผลรวม: %d PASS / %d FAIL" % [passed.size(), failures.size()])
	if failures.size() > 0:
		for f in failures:
			print("  FAILED: ", f)
		quit(1)
	else:
		print("ALL PASS - KubiGP core systems")
		quit(0)

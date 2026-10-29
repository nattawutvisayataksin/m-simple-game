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
var ai_start_positions: Array[Vector3] = []
var ai_progress_start_values: Array[float] = []
var collision_pair_hits := 0
var collision_player: Vehicle
var collision_opponent: Vehicle
var barrier_test_start_z := 0.0
var corner_test_center := Vector2(87.5, 10.5)
var corner_test_start_radius := 9.0
var pending_motion_bodies: Array[RigidBody3D] = []
var pending_motion_velocities: Array[Vector3] = []
var gate_approach_hit := ""


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
		return
	physics_frame.connect(_on_physics_frame)


func _check(name: String, condition: bool, detail: String = "") -> void:
	if condition:
		passed.append(name)
		print("  PASS: ", name)
	else:
		failures.append(name)
		print("  FAIL: ", name, " ", detail)


func _on_physics_frame() -> void:
	frames += 1
	for i in pending_motion_bodies.size():
		pending_motion_bodies[i].freeze = false
		pending_motion_bodies[i].linear_velocity = pending_motion_velocities[i]
	pending_motion_bodies.clear()
	pending_motion_velocities.clear()
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
	elif stage == 6 and frames > 1000:
		stage = 7
		_stage_drive_check()
		_stage_vehicle_collision_setup()
	elif stage == 7 and frames > 1060:
		stage = 8
		_stage_vehicle_collision_check()
		_stage_barrier_collision_setup()
	elif stage == 8 and frames > 1100:
		stage = 9
		_stage_barrier_collision_check()
		_stage_corner_barrier_collision_setup()
	elif stage == 9 and frames > 1140:
		stage = 10
		_stage_corner_barrier_collision_check()
		_stage_clear_gate_overlap()
	elif stage == 10 and frames > 1160:
		stage = 11
		_stage_gate_crossing_setup(0)
	elif stage == 11 and frames > 1180:
		stage = 12
		_stage_gate_crossing_check(0)
		_stage_clear_gate_overlap()
	elif stage == 12 and frames > 1200:
		stage = 13
		_stage_gate_crossing_setup(1)
	elif stage == 13 and frames > 1220:
		stage = 14
		_stage_gate_crossing_check(1)
		_stage_clear_gate_overlap()
	elif stage == 14 and frames > 1240:
		stage = 15
		_stage_gate_crossing_setup(2)
	elif stage == 15 and frames > 1260:
		stage = 16
		_stage_gate_crossing_check(2)
		_stage_clear_gate_overlap()
	elif stage == 16 and frames > 1280:
		stage = 17
		_stage_gate_crossing_setup(0, true)
	elif stage == 17 and frames > 1300:
		stage = 18
		_stage_gate_crossing_check(0, true)
		_finish()


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
	var all_racers: Array[Vehicle] = [game.get_node("Vehicle")]
	all_racers.append_array(game.get("_ai_racers"))
	var spawn_spacing_ok := true
	for i in all_racers.size():
		for j in range(i + 1, all_racers.size()):
			spawn_spacing_ok = spawn_spacing_ok \
				and all_racers[i].sphere.global_position.distance_to(
					all_racers[j].sphere.global_position) > 2.2
	_check("รถทุกคันเริ่มแข่งโดยไม่ซ้อนกัน", spawn_spacing_ok)
	var vehicle_collisions_enabled := true
	for racer in all_racers:
		vehicle_collisions_enabled = vehicle_collisions_enabled \
			and (racer.sphere.collision_layer & 8) != 0 \
			and (racer.sphere.collision_mask & 9) == 9 \
			and racer.sphere.continuous_cd \
			and racer.sphere.contact_monitor \
			and racer.sphere.max_contacts_reported > 0
	_check("รถชนกันได้และยังชนพื้นสนาม", vehicle_collisions_enabled)
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
	var barriers := game.get_node_or_null("TrackBarriers")
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
	var city_marking_count := 0
	if town != null:
		for child in town.get_children():
			if child.name in ["CityStreet_South", "CityStreet_North",
					"CityStreet_West", "CityStreet_East"]:
				city_street_count += 1
			if child.name.ends_with("_Centerline"):
				city_marking_count += 1
	_check("มีถนนย่านเมืองล้อมรอบสนาม 4 ด้าน", city_street_count == 4,
		"streets=%d" % city_street_count)
	_check("ถนนเมืองมีเส้นแบ่งเลนชัดเจน", city_marking_count == 4,
		"centerlines=%d" % city_marking_count)
	var city_roads_join := true
	if town != null:
		for horizontal_name in ["CityStreet_South", "CityStreet_North"]:
			var horizontal := town.get_node_or_null(horizontal_name) as MeshInstance3D
			var horizontal_mesh := horizontal.mesh as PlaneMesh if horizontal != null else null
			city_roads_join = city_roads_join and horizontal_mesh != null \
				and horizontal_mesh.size.is_equal_approx(Vector2(122.5, 4.5))
			if horizontal_mesh == null:
				continue
			for vertical_name in ["CityStreet_West", "CityStreet_East"]:
				var vertical := town.get_node_or_null(vertical_name) as MeshInstance3D
				var vertical_mesh := vertical.mesh as PlaneMesh if vertical != null else null
				if vertical_mesh == null:
					city_roads_join = false
					continue
				var overlap_x := minf(horizontal.position.x + horizontal_mesh.size.x * 0.5,
					vertical.position.x + vertical_mesh.size.x * 0.5) \
					- maxf(horizontal.position.x - horizontal_mesh.size.x * 0.5,
					vertical.position.x - vertical_mesh.size.x * 0.5)
				var overlap_z := minf(horizontal.position.z + horizontal_mesh.size.y * 0.5,
					vertical.position.z + vertical_mesh.size.y * 0.5) \
					- maxf(horizontal.position.z - horizontal_mesh.size.y * 0.5,
					vertical.position.z - vertical_mesh.size.y * 0.5)
				city_roads_join = city_roads_join \
					and vertical_mesh.size.is_equal_approx(Vector2(4.5, 87.5)) \
					and overlap_x > 0.0 and overlap_z > 0.0 \
					and horizontal.position.y < vertical.position.y
	_check("ถนนเมืองต่อถึงกันที่สี่แยก ไม่มีช่องว่าง", city_roads_join)
	var city_lot_count := 0
	if town != null:
		for child in town.get_children():
			if child.name.begins_with("CityLot_"):
				city_lot_count += 1
	_check("มีลานพื้นต่างวัสดุรอบย่านอาคาร", city_lot_count == 16,
		"lots=%d" % city_lot_count)
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
		and road_surface.get_node_or_null("LaneDash") != null
		and road_surface.get_child_count() == 3)
	var road_collision: StaticBody3D = town.get_node_or_null("RoadCollision_1_0") if town != null else null
	var road_shape: CollisionShape3D
	if road_collision != null and road_collision.get_child_count() > 0:
		road_shape = road_collision.get_child(0) as CollisionShape3D
	var box_shape := road_shape.shape as BoxShape3D if road_shape != null else null
	_check("ถนนมี collider ครอบคลุมช่อง", box_shape != null
		and road_collision.position.y == 0.0
		and is_equal_approx(box_shape.size.x, 7.0)
		and is_equal_approx(box_shape.size.z, 7.0))
	var barriers_are_solid := barriers != null and barriers.get_child_count() == 16
	var barrier_details: Array[String] = []
	if barriers_are_solid:
		for barrier in barriers.get_children():
			var segment_count := 0
			for segment in barrier.get_children():
				if not segment is CollisionShape3D:
					continue
				segment_count += 1
				barriers_are_solid = barriers_are_solid \
					and segment.shape is BoxShape3D
			barrier_details.append("%s:%d" % [barrier.name, segment_count])
			barriers_are_solid = barriers_are_solid \
				and segment_count > 0 and barrier is StaticBody3D
	_check("มีรั้วชนได้ล้อมรอบขอบในและขอบนอกสนาม", barriers_are_solid,
		"barriers=%d %s" % [
			barriers.get_child_count() if barriers != null else -1, "; ".join(barrier_details)])
	var space := game.get_world_3d().direct_space_state
	var inner_query := PhysicsRayQueryParameters3D.create(
		Vector3(49, 0.5, 3.5), Vector3(49, 0.5, 12.0), 1)
	var outer_query := PhysicsRayQueryParameters3D.create(
		Vector3(49, 0.5, 3.5), Vector3(49, 0.5, -5.0), 1)
	var inner_hit := space.intersect_ray(inner_query)
	var outer_hit := space.intersect_ray(outer_query)
	_check("กำแพงหยุดการตัดเข้าและออกจากสนาม",
		not inner_hit.is_empty() and not outer_hit.is_empty()
		and str(inner_hit["collider"].name).begins_with("Barrier_Inner")
		and str(outer_hit["collider"].name).begins_with("Barrier_Outer"),
		"inner=%s outer=%s" % [
			inner_hit.get("collider", null), outer_hit.get("collider", null)])
	var corner_barriers_solid := true
	var corner_lane_clear := true
	var corners := [
		["SE", Vector2(87.5, 10.5), -PI * 0.25],
		["NE", Vector2(87.5, 52.5), PI * 0.25],
		["NW", Vector2(10.5, 52.5), PI * 0.75],
		["SW", Vector2(10.5, 10.5), PI * 1.25],
	]
	for corner in corners:
		var corner_name: String = corner[0]
		var center: Vector2 = corner[1]
		var angle: float = corner[2]
		var radial := Vector3(cos(angle), 0, sin(angle))
		var lane_point := Vector3(center.x, 0.5, center.y) + radial * 7.0
		var inner_query_corner := PhysicsRayQueryParameters3D.create(
			lane_point, Vector3(center.x, 0.5, center.y) + radial * 2.2, 1)
		var outer_query_corner := PhysicsRayQueryParameters3D.create(
			lane_point, Vector3(center.x, 0.5, center.y) + radial * 11.8, 1)
		var inner_corner_hit := space.intersect_ray(inner_query_corner)
		var outer_corner_hit := space.intersect_ray(outer_query_corner)
		var inner_corner_collider := inner_corner_hit.get("collider") as Node3D
		var outer_corner_collider := outer_corner_hit.get("collider") as Node3D
		corner_barriers_solid = corner_barriers_solid \
			and inner_corner_collider != null \
			and inner_corner_collider.name.contains("Barrier_Inner_Corner_" + corner_name) \
			and outer_corner_collider != null \
			and outer_corner_collider.name.contains("Barrier_Outer_Corner_" + corner_name)
		var lane_shape := SphereShape3D.new()
		lane_shape.radius = 0.35
		var lane_query := PhysicsShapeQueryParameters3D.new()
		lane_query.shape = lane_shape
		lane_query.transform = Transform3D(Basis(), lane_point)
		lane_query.collision_mask = 1
		corner_lane_clear = corner_lane_clear \
			and space.intersect_shape(lane_query, 32).is_empty()
	_check("กำแพงโค้งทั้งสี่มุมชนได้ แต่ไม่กินเข้าเลน",
		corner_barriers_solid and corner_lane_clear,
		"barriers=%s lane_clear=%s" % [corner_barriers_solid, corner_lane_clear])
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
		perimeter_count == 16 and buildings_in_scale,
		"buildings=%d scale_ok=%s" % [perimeter_count, buildings_in_scale])
	var park := town.get_node_or_null("CentralPark") if town != null else null
	_check("กลางสนามเป็นสวนสาธารณะ มีลานและน้ำพุ",
		park != null and park.get_node_or_null("ParkPathEastWest") != null
		and park.get_node_or_null("ParkFountain") != null
		and park.get_node_or_null("ParkFlowers_00") != null)
	var ground: MeshInstance3D = town.get_node_or_null("CityGroundVisual") if town != null else null
	var ground_material := ground.mesh.surface_get_material(0) if ground != null else null
	_check("พื้นเมืองใช้โทนหินธรรมชาติแทนเขียวสด",
		ground_material is StandardMaterial3D
		and (ground_material as StandardMaterial3D).albedo_color.is_equal_approx(Color(0.43, 0.42, 0.38)))
	var roadside_props_clear := true
	if town != null:
		for child in town.get_children():
			if not child is StaticBody3D or child.name.begins_with("RoadCollision_") \
					or child.name == "CityGround":
				continue
			var obstacle := child as StaticBody3D
			var shape_node := obstacle.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if shape_node == null or not shape_node.shape is BoxShape3D:
				continue
			var box := shape_node.shape as BoxShape3D
			var horizontal_radius := Vector2(box.size.x, box.size.z).length() * 0.5
			for point in track_points:
				var distance := Vector2(shape_node.global_position.x - point.x,
					shape_node.global_position.z - point.z).length()
				if distance - horizontal_radius < 4.6:
					roadside_props_clear = false
	_check("พร็อพชนได้ไม่ล้ำเข้าพื้นที่รถแข่ง", roadside_props_clear)
	_check("ไม่มีเสาไฟฟ้าหรือสิ่งกีดขวางกลางเลน",
		props != null and props.get_child_count() == 3)
	_check("Coins ถูกสร้าง", coins != null and coins.get_child_count() > 0,
		"children=%s" % (coins.get_child_count() if coins else -1))
	_check("Gates ครบ 3 ประตู", gates != null and gates.get_child_count() == 3,
		"children=%s" % (gates.get_child_count() if gates else -1))
	_check("Props ของประดับถูกวาง", props != null and props.get_child_count() > 0,
		"children=%s" % (props.get_child_count() if props else -1))
	var finish_label := gates.get_node_or_null("Gate0/GateVisual/GateLabel") as Label3D \
		if gates != null else null
	var gate_one_label := gates.get_node_or_null("Gate1/GateVisual/GateLabel") as Label3D \
		if gates != null else null
	var gate_two_label := gates.get_node_or_null("Gate2/GateVisual/GateLabel") as Label3D \
		if gates != null else null
	_check("เห็นซุ้มเส้นชัยและป้าย checkpoint ตามลำดับ",
		finish_label != null and finish_label.text == "FINISH"
		and gate_one_label != null and gate_one_label.text == "CHECKPOINT 1"
		and gate_two_label != null and gate_two_label.text == "CHECKPOINT 2")
	var gate_shape := gates.get_node("Gate0/CollisionShape3D").shape as BoxShape3D \
		if gates != null else null
	_check("เส้นตรวจนับรอบเป็นแถบขวางถนน ไม่ใช่พื้นที่กว้าง",
		gate_shape != null and gate_shape.size.is_equal_approx(Vector3(7, 3.6, 2.8)))
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
	ai_start_positions.clear()
	ai_progress_start_values.clear()
	for racer in game.get("_ai_racers"):
		ai_start_positions.append(racer.sphere.global_position)
		ai_progress_start_values.append(float(
			racer.get_node("RacerAI").call("get_race_progress")))


func _stage_drive_check() -> void:
	Input.action_release("forward")
	var now: Vector3 = game.get_node("Vehicle/Sphere").global_position
	var moved: float = (now - drive_start).length()
	_check("รถวิ่งไปได้ > 2 ม.", moved > 2.0, "moved=%.2f" % moved)
	var all_ai_advanced := true
	var all_ai_moved := true
	var ai_details: Array[String] = []
	var racers: Array = game.get("_ai_racers")
	for i in racers.size():
		var racer: Vehicle = racers[i]
		var ai_node := racer.get_node("RacerAI")
		var ai_progress := float(ai_node.call("get_race_progress"))
		var distance_travelled := racer.sphere.global_position.distance_to(ai_start_positions[i])
		all_ai_advanced = all_ai_advanced and ai_progress > ai_progress_start_values[i]
		all_ai_moved = all_ai_moved and distance_travelled > 2.0
		ai_details.append("%s: progress %.1f, distance %.1f" % [
			racer.name, ai_progress, distance_travelled])
	_check("AI ทุกคันขับตามเส้นทางและเพิ่มความคืบหน้า", all_ai_advanced,
		"; ".join(ai_details))
	_check("AI ทุกคันเคลื่อนที่จริงระหว่างแข่ง", all_ai_moved,
		"; ".join(ai_details))


func _stage_vehicle_collision_setup() -> void:
	print("[6] ชนรถจริงด้วย Jolt Physics")
	paused = false
	game.set("race_finished", false)
	game.set("race_started", true)
	collision_player = game.get_node("Vehicle") as Vehicle
	collision_opponent = game.get("_ai_racers")[0] as Vehicle
	collision_player.set_race_enabled(false)
	collision_opponent.set_race_enabled(false)
	for racer in game.get("_ai_racers"):
		racer.set_race_enabled(false)
		racer.get_node("RacerAI").set("laps", 0)
	collision_pair_hits = 0
	collision_player.sphere.body_entered.connect(
		_on_test_collision_body_entered.bind(collision_opponent.sphere))
	collision_opponent.sphere.body_entered.connect(
		_on_test_collision_body_entered.bind(collision_player.sphere))

	var points: Array = game.get("_path_points")
	var contact_point: Vector3 = points[5]
	var tangent: Vector3 = game.call("_tangent_at", contact_point)
	var spawn_height := contact_point.y + 1.5
	collision_player.sphere.global_position = Vector3(
		contact_point.x - tangent.x * 2.5, spawn_height,
		contact_point.z - tangent.z * 2.5)
	collision_opponent.sphere.global_position = Vector3(
		contact_point.x + tangent.x * 2.5, spawn_height,
		contact_point.z + tangent.z * 2.5)
	_schedule_motion(collision_player.sphere, tangent * 8.0)
	_schedule_motion(collision_opponent.sphere, -tangent * 8.0)


func _schedule_motion(body: RigidBody3D, velocity: Vector3) -> void:
	body.freeze = true
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	pending_motion_bodies.append(body)
	pending_motion_velocities.append(velocity)


func _on_test_collision_body_entered(body: Node3D, expected: Node3D) -> void:
	if body == expected:
		collision_pair_hits += 1


func _stage_vehicle_collision_check() -> void:
	var distance := collision_player.sphere.global_position.distance_to(
		collision_opponent.sphere.global_position)
	var player_shape := collision_player.sphere.get_node("CollisionShape").shape as SphereShape3D
	var opponent_shape := collision_opponent.sphere.get_node("CollisionShape").shape as SphereShape3D
	var minimum_separation := (player_shape.radius + opponent_shape.radius) * 0.9
	_check("รถสองคันชนกันจริงและ physics รายงาน contact",
		collision_pair_hits > 0 and distance >= minimum_separation,
		"contacts=%d separation=%.2f minimum=%.2f" % [
			collision_pair_hits, distance, minimum_separation])


func _stage_barrier_collision_setup() -> void:
	collision_opponent.set_race_enabled(false)
	var sphere := collision_player.sphere
	sphere.freeze = true
	sphere.global_position = Vector3(49.0, 0.5, 3.5)
	barrier_test_start_z = sphere.global_position.z
	_schedule_motion(sphere, Vector3(0, 0, -8.0))


func _stage_barrier_collision_check() -> void:
	var sphere := collision_player.sphere
	_check("รถชนกำแพงขอบนอกจริงและไม่ทะลุออกนอกสนาม",
		sphere.global_position.z > 0.45
		and sphere.global_position.z < barrier_test_start_z - 1.0,
		"start_z=%.2f end_z=%.2f" % [barrier_test_start_z, sphere.global_position.z])


func _stage_corner_barrier_collision_setup() -> void:
	var radial := Vector3(cos(-PI * 0.25), 0, sin(-PI * 0.25))
	var sphere := collision_player.sphere
	sphere.freeze = true
	sphere.global_position = Vector3(corner_test_center.x, 0.5, corner_test_center.y) \
		+ radial * corner_test_start_radius
	_schedule_motion(sphere, radial * 8.0)


func _stage_corner_barrier_collision_check() -> void:
	var sphere := collision_player.sphere
	var current_position := sphere.global_position
	var current_radius := Vector2(current_position.x - corner_test_center.x,
		current_position.z - corner_test_center.y).length()
	var shape := sphere.get_node("CollisionShape").shape as SphereShape3D
	_check("ฟิสิกส์หยุดรถที่กำแพงโค้งมุมสนามจริง",
		current_radius > corner_test_start_radius + 0.05 and current_radius < 10.0,
		"start_radius=%.2f end_radius=%.2f y=%.2f radius=%.2f velocity=%s contacts=%s" % [
			corner_test_start_radius, current_radius, current_position.y,
			shape.radius, sphere.linear_velocity, sphere.get_colliding_bodies()])


func _stage_gate_crossing_check(index: int, final_lap := false) -> void:
	var expected_next := (index + 1) % 3
	var gate_progress_valid := int(game.get("next_gate")) == expected_next
	var gate := game.get_node("Gates/Gate%d" % index) as Area3D
	if index == 0 and final_lap:
		gate_progress_valid = gate_progress_valid and int(game.get("laps")) == 1 \
			and not bool(game.get("_passed_full_lap"))
	elif index == 0:
		gate_progress_valid = gate_progress_valid and int(game.get("laps")) == 0
	elif index == 2:
		gate_progress_valid = gate_progress_valid and int(game.get("laps")) == 0 \
			and bool(game.get("_passed_full_lap"))
	else:
		gate_progress_valid = gate_progress_valid and int(game.get("laps")) == 0
	var detail := ("next=%s laps=%s full_lap=%s finished=%s pos=%s gate=%s " \
	+ "normal=%s mask=%d layer=%d monitoring=%s overlaps=%s blocker=%s velocity=%s") % [
			game.get("next_gate"), game.get("laps"), game.get("_passed_full_lap"),
			game.get("race_finished"), collision_player.sphere.global_position,
			gate.global_position, gate.global_basis.z,
			gate.collision_mask, collision_player.sphere.collision_layer,
			gate.monitoring, gate.get_overlapping_bodies().has(collision_player.sphere),
			gate_approach_hit, collision_player.sphere.linear_velocity]
	_check("รถขับผ่าน Gate%d จริงตามลำดับ" % index, gate_progress_valid, detail)


func _stage_clear_gate_overlap() -> void:
	var sphere := collision_player.sphere
	sphere.freeze = true
	sphere.global_position = Vector3(250.0, 20.0, 250.0)
	_schedule_motion(sphere, Vector3.ZERO)


func _stage_gate_crossing_setup(index: int, final_lap := false) -> void:
	paused = false
	game.set("race_finished", false)
	game.set("race_started", true)
	for i in game.get("_ai_racers").size():
		var racer: Vehicle = game.get("_ai_racers")[i]
		racer.get_node("RacerAI").set("laps", 0)
		racer.sphere.freeze = true
		racer.sphere.global_position = Vector3(500.0 + i * 5.0, 50.0, 500.0)
	if index == 0 and not final_lap:
		game.set("laps", 0)
		game.set("_passed_full_lap", false)
	game.set("next_gate", index)
	var gate := game.get_node("Gates/Gate%d" % index) as Area3D
	var sphere := collision_player.sphere
	sphere.freeze = true
	var forward: Vector3 = gate.global_basis.z.normalized()
	var approach := gate.global_position - forward * 3.0
	var query := PhysicsRayQueryParameters3D.create(approach, gate.global_position, 1)
	query.exclude = [sphere.get_rid()]
	query.collide_with_areas = false
	var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
	gate_approach_hit = str(hit.get("collider", "none"))
	sphere.global_position = approach
	sphere.linear_velocity = Vector3.ZERO
	sphere.angular_velocity = Vector3.ZERO
	_schedule_motion(sphere, forward * 12.0)


func _finish() -> void:
	print("=== ผลรวม: %d PASS / %d FAIL" % [passed.size(), failures.size()])
	if failures.size() > 0:
		for f in failures:
			print("  FAILED: ", f)
		quit(1)
	else:
		print("ALL PASS - KubiGP core systems")
		quit(0)

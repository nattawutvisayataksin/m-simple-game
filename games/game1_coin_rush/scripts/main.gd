extends Node2D
## Platformer with 3 levels + moving platforms + juice + save.

const LEVELS := [
	{
		"width": 2400.0, "height": 720.0, "time": 120.0, "start": Vector2(120, 600),
		"platforms": [
			{"pos": Vector2(1200, 680), "size": Vector2(2400, 80)},
			{"pos": Vector2(420, 560), "size": Vector2(180, 24)},
			{"pos": Vector2(720, 470), "size": Vector2(180, 24)},
			{"pos": Vector2(1020, 380), "size": Vector2(180, 24)},
			{"pos": Vector2(1320, 500), "size": Vector2(220, 24)},
			{"pos": Vector2(1620, 420), "size": Vector2(180, 24)},
			{"pos": Vector2(1920, 340), "size": Vector2(180, 24)},
			{"pos": Vector2(2180, 480), "size": Vector2(260, 24)},
		],
		"coins": [Vector2(420,524), Vector2(720,434), Vector2(1020,344), Vector2(1320,464), Vector2(1620,384), Vector2(1920,304), Vector2(2180,444), Vector2(900,616), Vector2(1500,616)],
		"gold_index": 2,
		"enemies": [Vector2(600,626), Vector2(1100,354), Vector2(1700,394), Vector2(2050,454)],
		"hazards": [Vector2(860,632), Vector2(1450,632), Vector2(1980,632)],
		"moving": [],
	},
	{
		"width": 3200.0, "height": 720.0, "time": 120.0, "start": Vector2(120, 600),
		"platforms": [
			{"pos": Vector2(1600, 680), "size": Vector2(3200, 80)},
			{"pos": Vector2(400, 560), "size": Vector2(180, 24)},
			{"pos": Vector2(680, 480), "size": Vector2(180, 24)},
			{"pos": Vector2(960, 400), "size": Vector2(180, 24)},
			{"pos": Vector2(1240, 500), "size": Vector2(200, 24)},
			{"pos": Vector2(1520, 420), "size": Vector2(180, 24)},
			{"pos": Vector2(1800, 340), "size": Vector2(180, 24)},
			{"pos": Vector2(2080, 480), "size": Vector2(200, 24)},
			{"pos": Vector2(2360, 400), "size": Vector2(180, 24)},
			{"pos": Vector2(2640, 500), "size": Vector2(200, 24)},
			{"pos": Vector2(2920, 420), "size": Vector2(180, 24)},
		],
		"coins": [Vector2(400,524), Vector2(680,444), Vector2(960,364), Vector2(1240,464), Vector2(1520,384), Vector2(1800,304), Vector2(2080,444), Vector2(2360,364), Vector2(2640,464), Vector2(2920,384), Vector2(1100,616), Vector2(2000,616)],
		"gold_index": 5,
		"enemies": [Vector2(520,626), Vector2(1000,374), Vector2(1600,394), Vector2(2200,454), Vector2(2800,394)],
		"hazards": [Vector2(820,632), Vector2(1400,632), Vector2(1960,632), Vector2(2520,632), Vector2(3080,632)],
		"moving": [{"a": Vector2(1380, 460), "b": Vector2(1560, 460), "speed": 70.0}],
	},
	{
		"width": 4000.0, "height": 720.0, "time": 150.0, "start": Vector2(120, 600),
		"platforms": [
			{"pos": Vector2(2000, 680), "size": Vector2(4000, 80)},
			{"pos": Vector2(400, 560), "size": Vector2(160, 24)},
			{"pos": Vector2(660, 470), "size": Vector2(160, 24)},
			{"pos": Vector2(920, 380), "size": Vector2(160, 24)},
			{"pos": Vector2(1180, 490), "size": Vector2(180, 24)},
			{"pos": Vector2(1440, 400), "size": Vector2(160, 24)},
			{"pos": Vector2(1700, 310), "size": Vector2(160, 24)},
			{"pos": Vector2(1960, 430), "size": Vector2(180, 24)},
			{"pos": Vector2(2220, 340), "size": Vector2(160, 24)},
			{"pos": Vector2(2480, 460), "size": Vector2(180, 24)},
			{"pos": Vector2(2740, 370), "size": Vector2(160, 24)},
			{"pos": Vector2(3000, 490), "size": Vector2(180, 24)},
			{"pos": Vector2(3260, 400), "size": Vector2(160, 24)},
			{"pos": Vector2(3520, 310), "size": Vector2(160, 24)},
			{"pos": Vector2(3780, 440), "size": Vector2(200, 24)},
		],
		"coins": [Vector2(400,524), Vector2(660,434), Vector2(920,344), Vector2(1180,454), Vector2(1440,364), Vector2(1700,274), Vector2(1960,394), Vector2(2220,304), Vector2(2480,424), Vector2(2740,334), Vector2(3000,454), Vector2(3260,364), Vector2(3520,274), Vector2(3780,404), Vector2(1000,616), Vector2(2200,616), Vector2(3400,616)],
		"gold_index": 8,
		"enemies": [Vector2(500,626), Vector2(900,354), Vector2(1500,374), Vector2(2100,314), Vector2(2700,344), Vector2(3300,374)],
		"hazards": [Vector2(780,632), Vector2(1320,632), Vector2(1860,632), Vector2(2400,632), Vector2(2940,632), Vector2(3480,632)],
		"moving": [
			{"a": Vector2(1280, 450), "b": Vector2(1440, 450), "speed": 80.0},
			{"a": Vector2(2380, 420), "b": Vector2(2560, 420), "speed": 90.0},
		],
	},
]

const SAVE_VERSION := 1
const SAVE_PATH := "user://kubi_coin_dash_save.json"
const DEFAULT_STATS: Dictionary = {"hi_score": 0, "best_win_time": 0.0, "wins": 0, "plays": 0, "level": 0}
var stats: Dictionary = DEFAULT_STATS.duplicate(true)

enum GameState { PLAYING, WON, LOST, LEVEL_DONE }
var state := GameState.PLAYING
var score := 0
var time_left := 0.0
var current_level := 0
var gameover_reason := ""
var _total_time_used := 0.0

var _trauma := 0.0
var _shake_time := 0.0
var _hit_stop_id := 0
var _camera: Camera2D
var _bg_far: Sprite2D
var _bg_near: Sprite2D

@onready var player: CharacterBody2D = $Player
@onready var platforms: Node2D = $Platforms
@onready var coins_container: Node2D = $Coins
@onready var enemies_container: Node2D = $Enemies
@onready var hazards_container: Node2D = $Hazards
@onready var moving_container: Node2D = $MovingPlatforms
@onready var goal: Area2D = $Goal
@onready var score_label: Label = $HUD/ScoreLabel
@onready var time_label: Label = $HUD/TimeLabel
@onready var stats_label: Label = $HUD/BestLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var win_label: Label = $HUD/WinLabel
@onready var gameover_label: Label = $HUD/GameoverLabel
@onready var leveldone_label: Label = $HUD/LevelDoneLabel
@onready var coin_scene: PackedScene = preload("res://scenes/coin.tscn")
@onready var coin_gold_scene: PackedScene = preload("res://scenes/coin_gold.tscn")
@onready var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@onready var hazard_scene: PackedScene = preload("res://scenes/hazard.tscn")
@onready var moving_scene: PackedScene = preload("res://scenes/moving_platform.tscn")
@onready var sfx_pickup: AudioStreamPlayer = $SfxPickup
@onready var sfx_win: AudioStreamPlayer = $SfxWin
@onready var sfx_lose: AudioStreamPlayer = $SfxLose

func _ready() -> void:
	randomize()
	_load_stats()
	_setup_background()
	_setup_camera()
	_setup_sfx()
	goal.reached.connect(_on_goal_reached)
	_load_level(0)

func _exit_tree() -> void:
	if has_node("Music"):
		($Music as AudioStreamPlayer).stop()

func _process(delta: float) -> void:
	if state == GameState.PLAYING:
		time_left = maxf(time_left - delta, 0.0)
		_update_time_label()
		if time_left <= 0.0:
			_lose("หมดเวลา!")
	# camera follow
	if is_instance_valid(_camera) and is_instance_valid(player):
		var lvl: Dictionary = LEVELS[current_level]
		var target := player.global_position + Vector2(0, -40)
		var t := 1.0 - exp(-6.0 * delta)
		_camera.global_position = _camera.global_position.lerp(target, t)
	# parallax strips (screen-space layers, horizontal manual scroll)
	if is_instance_valid(_bg_far) and is_instance_valid(_camera):
		var cam_x := _camera.global_position.x
		_update_strip(_bg_far, cam_x)
		_update_strip(_bg_near, cam_x)
	# shake
	if _trauma > 0.0:
		_trauma = maxf(_trauma - 1.2 * delta, 0.0)
		_shake_time += delta * 30.0
		var shake := _trauma * _trauma
		_camera.offset = Vector2(12.0 * shake * sin(_shake_time * 1.7), 8.0 * shake * sin(_shake_time * 2.3))
	else:
		_camera.offset = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/title.tscn")

func _load_level(idx: int) -> void:
	current_level = idx
	var lvl: Dictionary = LEVELS[idx]
	# clear
	for c in platforms.get_children(): c.queue_free()
	for c in coins_container.get_children(): c.queue_free()
	for c in enemies_container.get_children(): c.queue_free()
	for c in hazards_container.get_children(): c.queue_free()
	for c in moving_container.get_children(): c.queue_free()
	# platforms
	for p in lvl["platforms"]:
		var body := StaticBody2D.new()
		body.position = p["pos"]
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = p["size"]
		col.shape = shape
		body.add_child(col)
		_build_platform(body, p["size"])
		platforms.add_child(body)
	# moving
	for m in lvl["moving"]:
		var mp: AnimatableBody2D = moving_scene.instantiate()
		mp.point_a = m["a"]
		mp.point_b = m["b"]
		mp.move_speed = m["speed"]
		mp.position = m["a"]
		moving_container.add_child(mp)
	# coins
	var gold_idx: int = int(lvl["gold_index"])
	for i in range(lvl["coins"].size()):
		var pos: Vector2 = lvl["coins"][i]
		var scene: PackedScene = coin_gold_scene if (i == gold_idx) else coin_scene
		var coin: Area2D = scene.instantiate()
		coin.position = pos
		coin.collected.connect(_on_coin_collected)
		coins_container.add_child(coin)
	# enemies
	for pos in lvl["enemies"]:
		var e: CharacterBody2D = enemy_scene.instantiate()
		e.position = pos
		enemies_container.add_child(e)
		e.caught_player.connect(_on_player_caught)
	# hazards
	for pos in lvl["hazards"]:
		var h: Area2D = hazard_scene.instantiate()
		h.position = pos
		hazards_container.add_child(h)
	# goal
	goal.position = Vector2(float(lvl["width"]) - 120.0, 600.0)
	# player
	player.position = lvl["start"]
	player.velocity = Vector2.ZERO
	player.set_physics_process(true)
	# camera bounds
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(lvl["width"])
	_camera.limit_bottom = int(lvl["height"])
	_camera.global_position = player.global_position + Vector2(0, -40)
	# state
	score = 0
	time_left = float(lvl["time"])
	state = GameState.PLAYING
	win_label.visible = false
	gameover_label.visible = false
	leveldone_label.visible = false
	_update_score_label()
	_update_time_label()
	_update_level_label()
	_update_stats_label()

func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.name = "Camera"
	add_child(cam)
	cam.make_current()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.zoom = Vector2(1.5, 1.5)
	_camera = cam

func _setup_background() -> void:
	# 1) Sky: screen-fixed vertical gradient (always fills the view)
	var sky := CanvasLayer.new()
	sky.layer = -100
	sky.name = "SkyLayer"
	add_child(sky)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color("#3fa9e8"), Color("#8fd3f4"), Color("#ffe9c2")])
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill_from = Vector2.ZERO
	gtex.fill_to = Vector2(0, 1)
	var sky_rect := TextureRect.new()
	sky_rect.texture = gtex
	sky_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_rect.stretch_mode = TextureRect.STRETCH_SCALE
	sky.add_child(sky_rect)
	# 2) Far backdrop: full sunny scene (clouds + coin sun + city), bottom-anchored
	var far_layer := CanvasLayer.new()
	far_layer.layer = -90
	far_layer.name = "BGFar"
	add_child(far_layer)
	_bg_far = _make_strip("res://assets/art/gen/bg_sunny.png", far_layer, 2.9, 0.18)
	# 3) Near row: small mountains + trees along a low horizon (nothing cut by strip top)
	var near_layer := CanvasLayer.new()
	near_layer.layer = -80
	near_layer.name = "BGNear"
	add_child(near_layer)
	_bg_near = _make_strip("res://assets/art/gen/hills_near.png", near_layer, 2.2, 0.45)

func _make_strip(path: String, layer: CanvasLayer, s: float, factor: float) -> Sprite2D:
	var tex: Texture2D = load(path)
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.centered = false
	sp.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sp.region_enabled = true
	var tile_w := float(tex.get_width()) * s
	var view := get_viewport_rect().size
	var reps := ceili((view.x + tile_w) / tile_w)
	sp.region_rect = Rect2(0, 0, float(tex.get_width()) * reps, float(tex.get_height()))
	sp.scale = Vector2(s, s)
	sp.position = Vector2(0, view.y - float(tex.get_height()) * s - 24.0)
	layer.add_child(sp)
	sp.set_meta("factor", factor)
	sp.set_meta("tile_w", tile_w)
	return sp

func _update_strip(sp: Sprite2D, cam_x: float) -> void:
	sp.position.x = -fposmod(cam_x * float(sp.get_meta("factor")), float(sp.get_meta("tile_w")))

func _setup_sfx() -> void:
	for name in ["jump", "land", "stomp"]:
		var p := AudioStreamPlayer.new()
		p.name = "Sfx" + name.capitalize()
		p.stream = load("res://assets/audio/%s.wav" % name)
		p.bus = &"SFX"
		add_child(p)

func _on_coin_collected(coin_value: int) -> void:
	if state != GameState.PLAYING:
		return
	score += coin_value
	_update_score_label()
	sfx_pickup.play()
	add_trauma(0.08)

func _on_player_caught() -> void:
	if state == GameState.PLAYING:
		_lose("โดนศัตรู!")

func _on_hazard_hit() -> void:
	if state == GameState.PLAYING:
		_lose("ตกหนาม!")

func _on_goal_reached() -> void:
	if state != GameState.PLAYING:
		return
	if current_level < LEVELS.size() - 1:
		_total_time_used += float(LEVELS[current_level]["time"]) - time_left
		state = GameState.LEVEL_DONE
		leveldone_label.visible = true
		leveldone_label.text = "ด่าน %d ผ่าน! กำลังไปด่านถัดไป..." % (current_level + 1)
		_end_round_soft()
		await get_tree().create_timer(1.5).timeout
		_load_level(current_level + 1)
	else:
		_win()

func _end_round_soft() -> void:
	player.set_physics_process(false)
	for enemy in enemies_container.get_children():
		enemy.set_physics_process(false)

func _win() -> void:
	state = GameState.WON
	_record_win(_total_time_used + float(LEVELS[current_level]["time"]) - time_left)
	_end_round_soft()
	win_label.visible = true
	sfx_win.play()

func TIME_LIMIT_TOTAL() -> float:
	var total := 0.0
	for lvl in LEVELS:
		total += float(lvl["time"])
	return total - time_left

func _lose(reason: String) -> void:
	state = GameState.LOST
	gameover_reason = reason
	add_trauma(0.8)
	_record_loss()
	_end_round_soft()
	gameover_label.visible = true
	gameover_label.text = "เกมจบแล้ว! %s\nคะแนน: %d · สถิติ: %d\nกด R เริ่มใหม่ · Esc กลับเมนู" % [reason, score, int(stats["hi_score"])]
	sfx_lose.play()

func _record_win(time_used: float) -> void:
	stats["plays"] = int(stats["plays"]) + 1
	stats["wins"] = int(stats["wins"]) + 1
	if score > int(stats["hi_score"]):
		stats["hi_score"] = score
	var best := float(stats["best_win_time"])
	if best <= 0.0 or time_used < best:
		stats["best_win_time"] = time_used
	stats["level"] = current_level
	_save_stats()
	_update_stats_label()
	win_label.text = "คุณชนะทุกด่าน! (%.1f วิ)\nคะแนน: %d · กด R เล่นใหม่ · Esc กลับเมนู" % [time_used, score]

func _record_loss() -> void:
	stats["plays"] = int(stats["plays"]) + 1
	if score > int(stats["hi_score"]):
		stats["hi_score"] = score
	stats["level"] = current_level
	_save_stats()
	_update_stats_label()

func _load_stats() -> void:
	for path in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.has("version") and int(data["version"]) <= SAVE_VERSION:
			stats["hi_score"] = int(data["hi_score"])
			stats["best_win_time"] = float(data["best_win_time"])
			stats["wins"] = int(data["wins"])
			stats["plays"] = int(data["plays"])
			if data.has("level"):
				stats["level"] = int(data["level"])
			return
	if FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_PATH + ".bak"):
		push_warning("ไฟล์สถิติพัง — เริ่มนับใหม่")

func _save_stats() -> void:
	var payload: Dictionary = stats.duplicate(true)
	payload["version"] = SAVE_VERSION
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("เซฟสถิติไม่สำเร็จ: %d" % FileAccess.get_open_error())
		return
	if not f.store_string(JSON.stringify(payload)):
		f.close()
		push_warning("เซฟสถิติไม่สำเร็จ (เขียน)")
		return
	f.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.rename_absolute(SAVE_PATH, SAVE_PATH + ".bak")
	var err := DirAccess.rename_absolute(tmp, SAVE_PATH)
	if err != OK:
		push_warning("เซฟสถิติไม่สำเร็จ (rename): %d" % err)

func _update_score_label() -> void:
	score_label.text = "เหรียญ: %d" % [score]

func _update_time_label() -> void:
	var seconds := int(ceil(time_left))
	time_label.text = "เวลา: %d วิ" % seconds
	if time_left <= 10.0:
		var flash := seconds % 2 == 0
		time_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35) if flash else Color(1.0, 0.55, 0.2))
	else:
		time_label.remove_theme_color_override("font_color")

func _update_level_label() -> void:
	level_label.text = "ด่าน %d / %d" % [current_level + 1, LEVELS.size()]

func _build_platform(body: StaticBody2D, size: Vector2) -> void:
	# dark rim around the whole block so every platform pops on the bright sky
	var outline := ColorRect.new()
	outline.color = Color(0.25, 0.14, 0.05)
	outline.size = size + Vector2(4, 6)
	outline.position = -size / 2.0 - Vector2(2, 3)
	outline.z_index = -1
	body.add_child(outline)
	var top_h := 32.0
	var top_tex := "res://assets/art/gen/tile_ground_cap.png"
	if size.y < 40.0:
		top_h = 24.0
		top_tex = "res://assets/art/gen/tile_plank.png"
	# top band (grass cap / plank) auto-tiles horizontally
	var top := Sprite2D.new()
	top.texture = load(top_tex)
	top.centered = false
	top.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	top.region_enabled = true
	top.region_rect = Rect2(0, 0, size.x + 4.0, top_h)
	top.position = Vector2(-size.x / 2.0 - 2.0, -size.y / 2.0)
	body.add_child(top)
	# dirt fill below the cap (ground blocks only)
	if size.y - top_h > 0.0:
		var fill := Sprite2D.new()
		fill.texture = load("res://assets/art/gen/tile_ground_fill.png")
		fill.centered = false
		fill.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		fill.region_enabled = true
		fill.region_rect = Rect2(0, 0, size.x + 4.0, size.y - top_h)
		fill.position = Vector2(-size.x / 2.0 - 2.0, -size.y / 2.0 + top_h)
		body.add_child(fill)

func _update_stats_label() -> void:
	var fastest_text := "%.1f วิ" % float(stats["best_win_time"]) if float(stats["best_win_time"]) > 0.0 else "—"
	stats_label.text = "สถิติ %d · ชนะ %d/%d · เร็วสุด %s" % [int(stats["hi_score"]), int(stats["wins"]), int(stats["plays"]), fastest_text]

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func hit_stop(duration := 0.06, slow := 0.05) -> void:
	_hit_stop_id += 1
	var my_id := _hit_stop_id
	Engine.time_scale = slow
	await get_tree().create_timer(duration, true, false, true).timeout
	if my_id == _hit_stop_id:
		Engine.time_scale = 1.0
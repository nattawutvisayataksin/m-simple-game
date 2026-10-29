extends Node2D
## ฉากหลักของเกม "ชิงเหรียญทอง (Coin Rush)" — ตัวเกมทั้งหมดคุมจากไฟล์นี้:
##  1) สุ่มวางเหรียญ + รับ signal เพื่อนับ score
##  2) นับเวลาถอยหลัง 30 วิ หมดเวลา = แพ้
##  3) รับ signal จากศัตรูลูกเหล็ก โดน = แพ้
##  4) เล่นเสียงเอฟเฟกต์ (เก็บเหรียญ / ชนะ / แพ้)
## โจทย์ฝึกหัดต่อไป:
##  - ผูก Input Map "sprint" ให้ผู้เล่นกด Shift ถูกจับแบบ action ชัด ๆ
##  - ช่องว่างหลังกำแพง 32px ล่างซ้าย/ขวา (มุมสนาม) — ไวรัสเด้งมุมตัวเห็นชัด

## จำนวนเหรียญทั้งหมดที่ต้องเก็บให้ครบ
const COIN_COUNT := 10

## เหรียญทองพิเศษต่อรอบ — ให้ 3 คะแนน (โผล่แบบสุ่มตำแหน่งเโสงเดียวกับเหรียญปกติ สร้างแคตตาลินอจให้เลือกไป "แค่ไหนคุ้มเสี่ยง")
const GOLD_COINS := 1

## เวลาเล่นรอบนี้ (วินาที) — ทำให้เกมมีเงื่อนไขแพ้
const TIME_LIMIT := 30.0

## ระยะตำแหน่งเหรียญห่างกันขั้นน้อย
const SPAWN_MIN_DIST := 90.0

## คิวไวรัสเพิ่มตามเวลา (ระยะ B): เขียว = เด้งบ้าคลั่ง / น้ำเงิน = ไล่ตาม
const VIRUS_SPAWN_SCHEDULE := [
	{ "time": 10.0, "scene": preload("res://scenes/enemy_green.tscn") },
	{ "time": 20.0, "scene": preload("res://scenes/enemy_blue.tscn") },
]

## ระยะห่างขั้นต่ำจากผู้เล่นตอน spawn ไวรัสใหม่ (กันตายฟรีจากของทับตัว)
const VIRUS_SPAWN_DIST := 280.0

var _virus_spawn_done := 0


## ---- ระยะ D: สถิติ hi-score (บันทึกลง user:// โดยจบรอบ = จุดเซฟที่ปลอดภัย) ----
## schema: {"version": 1, "hi_score", "best_win_time" (0 = ยังไม่ชนะ), "wins", "plays"}
const SAVE_VERSION := 1
const SAVE_PATH := "user://coin_rush_save.json"
const DEFAULT_STATS: Dictionary = {
	"hi_score": 0,
	"best_win_time": 0.0,
	"wins": 0,
	"plays": 0,
}
var stats: Dictionary = DEFAULT_STATS.duplicate(true)
var gameover_reason := ""

## สถานะเกม ใช้สอยเทียบใน _process และ _on_* ต่าง ๆ
enum GameState { PLAYING, WON, LOST }

var score := 0
var time_left := TIME_LIMIT
var state := GameState.PLAYING

@onready var player: CharacterBody2D = $Player
@onready var coins_container: Node2D = $Coins
@onready var enemies_container: Node2D = $Enemies
@onready var score_label: Label = $HUD/ScoreLabel
@onready var time_label: Label = $HUD/TimeLabel
@onready var stats_label: Label = $HUD/BestLabel
@onready var win_label: Label = $HUD/WinLabel
@onready var gameover_label: Label = $HUD/GameoverLabel
@onready var coin_scene: PackedScene = preload("res://scenes/coin.tscn")
@onready var coin_gold_scene: PackedScene = preload("res://scenes/coin_gold.tscn")
@onready var sfx_pickup: AudioStreamPlayer = $SfxPickup
@onready var sfx_win: AudioStreamPlayer = $SfxWin
@onready var sfx_lose: AudioStreamPlayer = $SfxLose


func _ready() -> void:
	randomize()
	score = 0
	time_left = TIME_LIMIT
	state = GameState.PLAYING
	win_label.visible = false
	gameover_label.visible = false
	_load_stats()
	_update_stats_label()
	_update_score_label()
	_update_time_label()
	_spawn_coins()

	# เก็บ signal จากศัตรูทุกตัวในฉาก
	for enemy in enemies_container.get_children():
		enemy.caught_player.connect(_on_player_caught)


## หยุดเสียงก่อนออกจากต้นไม้ฉาก — กัน AudioStreamPlayback ค้างตอน quit (ObjectDB leak warning)
func _exit_tree() -> void:
	($Music as AudioStreamPlayer).stop()


## เพลงประกอบวนลูปถูกตั้งใน .import (edit/loop_mode=1 จนหมดเพลง) ไม่ต้องผูกมือในโค้ด


func _process(delta: float) -> void:
	if state != GameState.PLAYING:
		return
	time_left = maxf(time_left - delta, 0.0)
	_update_time_label()
	_check_virus_spawns()
	if time_left <= 0.0:
		_lose("หมดเวลา!")


## ระยะ B: "ไวรัสเพิ่มตามเวลา" — เขียว (เด้งบ้าคลั่ง) ที่ 10 วิ / น้ำเงิน (ไล่ตาม) ที่ 20 วิ
func _check_virus_spawns() -> void:
	var elapsed := TIME_LIMIT - time_left
	while _virus_spawn_done < VIRUS_SPAWN_SCHEDULE.size():
		var due: float = float(VIRUS_SPAWN_SCHEDULE[_virus_spawn_done]["time"])
		if elapsed < due:
			break
		_spawn_virus(VIRUS_SPAWN_SCHEDULE[_virus_spawn_done]["scene"])
		_virus_spawn_done += 1


## เกิดไวรัสตัวใหม่ — spawn ห่างผู้เล่น + เฟดอิน ก่อนเปิดกล่องชน (กันตายแบบไม่ตั้งใจ)
func _spawn_virus(scene: PackedScene) -> void:
	if state != GameState.PLAYING:
		return
	var virus: Area2D = scene.instantiate()
	virus.position = _pick_coin_position([player.position] as Array[Vector2], VIRUS_SPAWN_DIST)
	virus.caught_player.connect(_on_player_caught)
	enemies_container.add_child(virus)

	# เล่นเข้านุ่ม ๆ: โปร่งจาง 0 → 1 จากนั้นค่อยเปิดรับการชน
	virus.modulate.a = 0.0
	virus.monitoring = false
	var tween := virus.create_tween()
	tween.tween_property(virus, "modulate:a", 1.0, 0.5)
	tween.tween_callback(func() -> void: virus.monitoring = true)


func _input(event: InputEvent) -> void:
	# กด R เพื่อ reload ฉาก = เริ่มเกมใหม่
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()


## สุ่มวางเหรียญให้เกมพร้อมเล่น — ในชุดมีเหรียญทอง GOLD_COINS อัน (คะแนน 3) เจืออยู่
func _spawn_coins() -> void:
	var placed_positions: Array[Vector2] = []
	placed_positions.append(player.position)

	# สุ่มสโปนให้อันไหนเป็นเหรียญทอง (อย่างเติมแบบชิ้นข้างกันซรอนตำแหน่งซ้ำ)
	var gold_slots := {}
	for i in range(GOLD_COINS):
		gold_slots[randi() % COIN_COUNT] = true

	for i in range(COIN_COUNT):
		var coin := (coin_gold_scene if gold_slots.has(i) else coin_scene).instantiate()

		var pos := _pick_coin_position(placed_positions)
		placed_positions.append(pos)
		coin.position = pos

		# เชื่อมสัญญาณจากเหรียญไปยังฟังก์ชันนี้
		coin.collected.connect(_on_coin_collected)

		coins_container.add_child(coin)


## สุ่มตำแหน่ง 1 จุด ไม่ให้ซ้อนกันใกล้เกิน min_dist (ใช้หาจุดวางเหรียญ + จุด spawn ไวรัส)
func _pick_coin_position(taken: Array[Vector2], min_dist: float = SPAWN_MIN_DIST) -> Vector2:
	var arena := Rect2(110.0, 110.0, 932.0, 428.0)

	for attempt in range(100):
		var candidate := Vector2(
			randf_range(arena.position.x, arena.end.x),
			randf_range(arena.position.y, arena.end.y)
		)

		var too_close := false
		for p in taken:
			if candidate.distance_to(p) < min_dist:
				too_close = true
				break

		if not too_close:
			return candidate

	# พื้นที่ตอนท้ายไม่วางได้ ให้วางกลางสนาม
	return Vector2(576, 324)


## เมื่อเก็บเหรียญ (signal จาก coin.tscn)
func _on_coin_collected(coin_value: int) -> void:
	if state != GameState.PLAYING:
		return

	# เก็บเหรียญได้ = ได้คะแนนตามชนิดเหรียญ (ปกติ 1 / ทอง 3)
	score += coin_value
	_update_score_label()
	sfx_pickup.play()

	if score >= COIN_COUNT:
		_win()


## เมื่อศัตรูจับผู้เล่นได้ (signal จาก enemy.tscn)
func _on_player_caught() -> void:
	if state == GameState.PLAYING:
		_lose("โดนลูกเหล็กชน!")


## โหลดสถิติจาก user:// — ตรวจซ้ำไฟล์ .bak เมื่อไฟล์หลักพัง, ตัวเลขจาก JSON คืน int/float ให้ตรง schema
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
			return
	# ถึงจุดนี้แปลว่า: (a) ยังไม่เคยเล่นมาก่อน (ข้ามเงียบ ๆ = ปกติครั้งแรก) หรือ
	# (b) มีไฟล์แต่อ่านไม่ได้ทั้งหลักและ .bak → เตือนชัดเจนว่าสถิติหายและเริ่มนับใหม่
	if FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_PATH + ".bak"):
		push_warning("ไฟล์สถิติพังหรือจากเวอร์ชันใหม่กว่านี้ — hi-score เริ่มนับใหม่")


## เขียนไฟล์แบบ atomic: เขียน .tmp → เก็บไฟล์เดิมเป็น .bak → rename ทับ
## ถ้าเครื่องแครกหรือดับกลางทาง จะเหลือ "ไฟล์เก่าฉบับสมบูรณ์" อยู่ตลอด ไม่มีไฟล์ครึ่ง ๆ กลาง ๆ
func _save_stats() -> void:
	var payload: Dictionary = stats.duplicate(true)
	payload["version"] = SAVE_VERSION
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("เซฟสถิติไม่สำเร็จ (เปิดไฟล์ไม่ได้): %d" % FileAccess.get_open_error())
		return
	if not f.store_string(JSON.stringify(payload)):
		f.close()
		push_warning("เซฟสถิติไม่สำเร็จ (เขียนไฟล์ไม่ได้)")
		return
	f.close()  # flush บัฟเฟอร์ลงดิสก์ก่อน rename
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.rename_absolute(SAVE_PATH, SAVE_PATH + ".bak")
	var err := DirAccess.rename_absolute(tmp, SAVE_PATH)
	if err != OK:
		push_warning("เซฟสถิติไม่สำเร็จ (rename): %d" % err)


func _update_stats_label() -> void:
	var fastest_text := "%.1f วิ" % float(stats["best_win_time"]) if float(stats["best_win_time"]) > 0.0 else "—"
	stats_label.text = "สถิติ %d · ชนะ %d/%d · เร็วสุด %s" % [
		int(stats["hi_score"]), int(stats["wins"]), int(stats["plays"]), fastest_text
	]


## จบรอบด้วยชนะ: อัปเดตสถิติ (คะแนนสูงสุด / เวลาเร็วสุด) เซฟ แล้วแจ้งบนจอ
func _record_win(time_used: float) -> void:
	var notes: Array[String] = []
	stats["plays"] = int(stats["plays"]) + 1
	stats["wins"] = int(stats["wins"]) + 1
	if score > int(stats["hi_score"]):
		stats["hi_score"] = score
		notes.append("สถิติคะแนนใหม่!")
	var best := float(stats["best_win_time"])
	if best <= 0.0 or time_used < best:
		stats["best_win_time"] = time_used
		notes.append("เร็วที่สุดเท่าที่เคยเป็นมา (%.1f วิ)" % time_used)
	_save_stats()
	_update_stats_label()
	var summary := " · ".join(PackedStringArray(notes))
	win_label.text = "คุณชนะ! เก็บเหรียญครบแล้ว (%.1f วิ)%s\nกด R เพื่อเริ่มเกมใหม่" % [
		time_used, "\n" + summary if summary != "" else ""
	]


## จบรอบด้วยแพ้: นับรอบ + อัปเดต hi-score (ถ้าเก็บได้มากกว่าเดิมก่อนแพ้)
func _record_loss() -> void:
	stats["plays"] = int(stats["plays"]) + 1
	if score > int(stats["hi_score"]):
		stats["hi_score"] = score
	_save_stats()
	_update_stats_label()
	gameover_label.text = "เกมจบแล้ว! %s\nสถิติส่วนตัว: %d คะแนน · ชนะมาแล้ว %d รอบ\nกด R เพื่อเริ่มเกมใหม่" % [
		gameover_reason, int(stats["hi_score"]), int(stats["wins"])
	]


func _win() -> void:
	state = GameState.WON
	_record_win(TIME_LIMIT - time_left)
	_end_round()
	win_label.visible = true
	sfx_win.play()


func _lose(reason: String) -> void:
	state = GameState.LOST
	gameover_reason = reason
	_record_loss()
	_end_round()
	gameover_label.visible = true
	sfx_lose.play()


## หยุดเกมทุกอย่างเมื่อจบรอบ (ชนะหรือแพ้ก็ตาม)
func _end_round() -> void:
	player.set_physics_process(false)
	for enemy in enemies_container.get_children():
		enemy.set_physics_process(false)
	# เหรียญที่ยังอยู่บนสนามปิดรับการเก็บทันที (โจทย์ระยะ A: จบรอบแล้วห้ามเก็บ)
	for coin in coins_container.get_children():
		if coin.has_method("disable"):
			coin.disable()


func _update_score_label() -> void:
	score_label.text = "เหรียญ: %d / %d" % [score, COIN_COUNT]


func _update_time_label() -> void:
	var seconds := int(ceil(time_left))
	time_label.text = "เวลา: %d วิ" % seconds
	if time_left <= 10.0:
		# โจทย์ระยะ A: 10 วิสุดท้ายตัวเลขเปลี่ยนแดงกระพริบทุกวินาที
		var flash := seconds % 2 == 0
		time_label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.35, 0.35) if flash else Color(1.0, 0.55, 0.2)
		)

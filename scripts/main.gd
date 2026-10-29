extends Node2D
## ฉากหลักของเกม "ชิงเหรียญทอง (Coin Rush)" — ตัวเกมทั้งหมดคุมจากไฟล์นี้:
##  1) สุ่มวางเหรียญ + รับ signal เพื่อนับ score
##  2) นับเวลาถอยหลัง 30 วิ หมดเวลา = แพ้
##  3) รับ signal จากศัตรูลูกเหล็ก โดน = แพ้
##  4) เล่นเสียงเอฟเฟกต์ (เก็บเหรียญ / ชนะ / แพ้)
## โจทย์ฝึกหัดต่อไป:
##  - เพิ่มจำนวนศัตรูทีละด่าน (กระดาษแจกเป็นระบบ level)
##  - เก็บเวลาที่ใช้ไปสร้าง hi-score ด้วยไฟล์ user://

## จำนวนเหรียญทั้งหมดที่ต้องเก็บให้ครบ
const COIN_COUNT := 10

## เวลาเล่นรอบนี้ (วินาที) — ทำให้เกมมีเงื่อนไขแพ้
const TIME_LIMIT := 30.0

## ระยะตำแหน่งเหรียญห่างกันขั้นน้อย
const SPAWN_MIN_DIST := 90.0

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
@onready var win_label: Label = $HUD/WinLabel
@onready var gameover_label: Label = $HUD/GameoverLabel
@onready var coin_scene: PackedScene = preload("res://scenes/coin.tscn")
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
	if time_left <= 0.0:
		_lose("หมดเวลา!")


func _input(event: InputEvent) -> void:
	# กด R เพื่อ reload ฉาก = เริ่มเกมใหม่
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()


## สุ่มวางเหรียญให้เกมพร้อมเล่น
func _spawn_coins() -> void:
	var placed_positions: Array[Vector2] = []
	placed_positions.append(player.position)

	for i in range(COIN_COUNT):
		var coin := coin_scene.instantiate()

		var pos := _pick_coin_position(placed_positions)
		placed_positions.append(pos)
		coin.position = pos

		# เชื่อมสัญญาณจากเหรียญไปยังฟังก์ชันนี้
		coin.collected.connect(_on_coin_collected)

		coins_container.add_child(coin)


## สุ่มตำแหน่งเหรียญ 1 จุด ไม่ให้ซ้อนกันใกล้เกิน SPAWN_MIN_DIST
func _pick_coin_position(taken: Array[Vector2]) -> Vector2:
	var arena := Rect2(110.0, 110.0, 932.0, 428.0)

	for attempt in range(100):
		var candidate := Vector2(
			randf_range(arena.position.x, arena.end.x),
			randf_range(arena.position.y, arena.end.y)
		)

		var too_close := false
		for p in taken:
			if candidate.distance_to(p) < SPAWN_MIN_DIST:
				too_close = true
				break

		if not too_close:
			return candidate

	# พื้นที่ตอนท้ายไม่วางได้ ให้วางกลางสนาม
	return Vector2(576, 324)


## เมื่อเก็บเหรียญ (signal จาก coin.tscn)
func _on_coin_collected() -> void:
	if state != GameState.PLAYING:
		return

	score += 1
	_update_score_label()
	sfx_pickup.play()

	if score >= COIN_COUNT:
		_win()


## เมื่อศัตรูจับผู้เล่นได้ (signal จาก enemy.tscn)
func _on_player_caught() -> void:
	if state == GameState.PLAYING:
		_lose("โดนลูกเหล็กชน!")


func _win() -> void:
	state = GameState.WON
	_end_round()
	win_label.visible = true
	sfx_win.play()


func _lose(reason: String) -> void:
	state = GameState.LOST
	_end_round()
	gameover_label.text = "เกมจบแล้ว! %s\nกด R เพื่อเริ่มเกมใหม่" % reason
	gameover_label.visible = true
	sfx_lose.play()


## หยุดเกมทุกอย่างเมื่อจบรอบ (ชนะหรือแพ้ก็ตาม)
func _end_round() -> void:
	player.set_physics_process(false)
	for enemy in enemies_container.get_children():
		enemy.set_physics_process(false)


func _update_score_label() -> void:
	score_label.text = "เหรียญ: %d / %d" % [score, COIN_COUNT]


func _update_time_label() -> void:
	time_label.text = "เวลา: %d วิ" % int(ceil(time_left))

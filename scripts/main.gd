extends Node2D
## ฉากหลักวิดีโอเกม — ฝึกหัดนี้ควบคุม:
##  1) ยุบแรงจากเหรียญ (signal)
##  2) แรงดันมาแสดงบน HUD (Label)
##  3) สุ่มตำแหน่งมาเป็นเหรียญ
##  4) โหมดชนะ + ปุ่ม R เพื่อรีเฟรชเกมใหม่
## โจทย์ไปเรื่อย:
##  - เพิ่มเสียงกลิ้งเมื่อเก็บเหรียญ (AudioStreamPlayer)
##  - ทำเวลา countdown 30 วิ ด้วย Timer + Label

## จำนวนเหรียญทั้งหมดที่ต้องเก็บให้ครบ
const COIN_COUNT := 10

## พื้นที่จัดวางเหรียญ (ไม่ต้องไวโดนกำแพง)
const SPAWN_MARGIN := 70.0

var score := 0

@onready var player: CharacterBody2D = $Player
@onready var coins_container: Node2D = $Coins
@onready var score_label: Label = $HUD/ScoreLabel
@onready var win_label: Label = $HUD/WinLabel
@onready var coin_scene: PackedScene = preload("res://scenes/coin.tscn")


func _ready() -> void:
	score = 0
	_update_score_label()
	win_label.visible = false
	_spawn_coins()


func _input(event: InputEvent) -> void:
	# กด R เพื่อ reload ฉาก = เริ่มเกมใหม่
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()


## สุ่มวางเหรียญหลาย ๆ อัน ไม่ให้ตำแหน่งซ้ำกันและไม่ติดผู้เล่น
func _spawn_coins() -> void:
	var placed_positions: Array[Vector2] = []
	placed_positions.append(player.position)

	for i in range(COIN_COUNT):
		var coin := coin_scene.instantiate()

		# ลองหาตำแหน่งว่าง สูงสุด 100 ครั้ง
		var pos := _pick_coin_position(placed_positions)
		placed_positions.append(pos)
		coin.position = pos

		# เชื่อมสัญญาณจากเหรียญ → วิธีบันทัด _on_coin_collected
		coin.collected.connect(_on_coin_collected)

		coins_container.add_child(coin)


## สุ่มตำแหน่งเหรียญ 1 จุด ไม่ให้ซ้อนกันใกล้เกิน 90 px และไม่ใกล้ตัวผู้เล่น
func _pick_coin_position(taken: Array[Vector2]) -> Vector2:
	var arena := Rect2(
		SPAWN_MARGIN + 40,
		SPAWN_MARGIN + 40,
		1152.0 - (SPAWN_MARGIN + 40) * 2,
		648.0 - (SPAWN_MARGIN + 40) * 2
	)

	for attempt in range(100):
		var candidate := Vector2(
			randf_range(arena.position.x, arena.end.x),
			randf_range(arena.position.y, arena.end.y)
		)

		var too_close := false
		for p in taken:
			if candidate.distance_to(p) < 90.0:
				too_close = true
				break

		if not too_close:
			return candidate

	# ขัดตับพื้นที่ไม่ว่างสักที เดี๋ยวให้ ตรงกลาง
	return Vector2(576, 324)


## เมื่อเก็บเหรียญ (signal จาก coin.tscn)
func _on_coin_collected() -> void:
	score += 1
	_update_score_label()

	if score >= COIN_COUNT:
		win_label.visible = true
		# ปิดการเคลื่อนท่องของผู้เล่น (กันค่าขยับหลังจบเกม)
		player.set_physics_process(false)


func _update_score_label() -> void:
	score_label.text = "เหรียญ: %d / %d" % [score, COIN_COUNT]

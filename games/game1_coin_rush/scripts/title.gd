extends Control
## Title screen: press Space/Enter/click to start the game.
## เลือกสกินด้วยปุ่มลูกศรซ้าย/ขวา (หรือ A/D) — เก็บลงไฟล์เซฟทันที

const MAIN_SCENE := "res://scenes/main.tscn"
const SAVE_PATH := "user://kubi_coin_dash_save.json"
const SAVE_VERSION := 1

const SKIN_NAMES: Array[String] = ["คลาสสิก", "สายน้ำฟ้า", "อัคคีราช"]
const SKIN_SHEETS: Array[String] = [
	"res://assets/art/sprites/kubi_hero_run_sheet.png",
	"res://assets/art/gen/kubi_hero_run_sheet_cyan.png",
	"res://assets/art/gen/kubi_hero_run_sheet_ember.png",
]

@onready var prompt: Label = $Prompt
@onready var hero: TextureRect = $Hero
@onready var stats_line: Label = $StatsLine

var _blink := 0.0
var _skin := 0
var _skin_line: Label

func _ready() -> void:
	var stats := _load_stats()
	if stats.has("hi_score") and int(stats["hi_score"]) > 0:
		stats_line.text = "สถิติสูงสุด %d · ชนะ %d/%d" % [int(stats["hi_score"]), int(stats["wins"]), int(stats["plays"])]
	_skin = clampi(int(stats.get("skin", 0)), 0, SKIN_NAMES.size() - 1)
	_skin_line = Label.new()
	_skin_line.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_skin_line.position = Vector2(0, -96)
	_skin_line.offset_left = -260
	_skin_line.offset_right = 260
	_skin_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skin_line.add_theme_font_size_override("font_size", 24)
	_skin_line.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	_skin_line.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.02))
	_skin_line.add_theme_constant_override("outline_size", 8)
	add_child(_skin_line)
	_refresh_skin()
	var tw := create_tween().set_loops()
	tw.tween_property(hero, "position:y", -16.0, 1.1).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(hero, "position:y", 16.0, 1.1).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	_blink += delta
	prompt.modulate.a = 0.55 + 0.45 * absf(sin(_blink * 2.4))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_persist_skin()
			_start()
		elif event.keycode in [KEY_LEFT, KEY_A]:
			_change_skin(-1)
		elif event.keycode in [KEY_RIGHT, KEY_D]:
			_change_skin(1)
	elif event is InputEventMouseButton and event.pressed:
		_persist_skin()
		_start()

func _change_skin(step: int) -> void:
	_skin = wrapi(_skin + step, 0, SKIN_NAMES.size())
	_refresh_skin()

func _refresh_skin() -> void:
	if _skin_line != null:
		_skin_line.text = "◀ สกิน: %s ▶   (ลูกศรซ้าย/ขวาเปลี่ยน)" % SKIN_NAMES[_skin]
	hero.texture = load(SKIN_SHEETS[_skin])

func _persist_skin() -> void:
	var d := {}
	if FileAccess.file_exists(SAVE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if parsed is Dictionary:
			d = parsed
	d["skin"] = _skin
	d["version"] = SAVE_VERSION
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
		f.close()

func _start() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)

func _load_stats() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return data if data is Dictionary else {}

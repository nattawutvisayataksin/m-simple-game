extends Control
## Title screen: press Space/Enter/click to start the game.

const MAIN_SCENE := "res://scenes/main.tscn"
const SAVE_PATH := "user://kubi_coin_dash_save.json"

@onready var prompt: Label = $Prompt
@onready var hero: TextureRect = $Hero

var _blink := 0.0

func _ready() -> void:
	var stats := _load_stats()
	if stats.has("hi_score") and int(stats["hi_score"]) > 0:
		$StatsLine.text = "สถิติสูงสุด %d · ชนะ %d/%d" % [int(stats["hi_score"]), int(stats["wins"]), int(stats["plays"])]
	var tw := create_tween().set_loops()
	tw.tween_property(hero, "position:y", -16.0, 1.1).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(hero, "position:y", 16.0, 1.1).as_relative().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	_blink += delta
	prompt.modulate.a = 0.55 + 0.45 * absf(sin(_blink * 2.4))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			_start()
	elif event is InputEventMouseButton and event.pressed:
		_start()

func _start() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)

func _load_stats() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return data if data is Dictionary else {}

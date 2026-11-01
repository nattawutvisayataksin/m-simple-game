extends Node
# ระบบเสียงของเกม 4 (แท็กซี่คู่ฟ้า): เพลงขับเมืองลูป + SFX พูลเล่นซ้ำได้
# ไฟล์ synth ล้วนจาก tools/generate_audio.ps1 (ไม่กินโควตา PixelLab)

const MUSIC_DAY := preload("res://assets/audio/music_day.wav")

const STREAMS := {
	"pickup": preload("res://assets/audio/sfx_pickup.wav"),
	"drop": preload("res://assets/audio/sfx_drop.wav"),
	"fail": preload("res://assets/audio/sfx_fail.wav"),
	"squeal": preload("res://assets/audio/sfx_squeal.wav"),
	"whoosh": preload("res://assets/audio/sfx_whoosh.wav"),
	"boing": preload("res://assets/audio/sfx_boing.wav"),
	"thud": preload("res://assets/audio/sfx_thud.wav"),
	"squish": preload("res://assets/audio/sfx_squish.wav"),
	"horn": preload("res://assets/audio/sfx_horn.wav"),
	"click": preload("res://assets/audio/sfx_click.wav"),
	"win": preload("res://assets/audio/sfx_win.wav"),
	"lose": preload("res://assets/audio/sfx_lose.wav"),
}

# เดซิเบล + throttle กันยิงรัวจนตอแหล (วิ)
const PROFILE := {
	"pickup": [-4.0, 0.3], "drop": [-3.0, 0.25], "fail": [-4.0, 0.5],
	"squeal": [-9.0, 0.5], "whoosh": [-8.0, 0.4], "boing": [-6.0, 0.5],
	"thud": [-4.0, 0.4], "squish": [-8.0, 0.4], "horn": [-6.0, 1.0],
	"click": [-14.0, 0.04], "win": [-3.0, 1.2], "lose": [-3.0, 1.2],
}
const POOL_SIZE := 10

var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _last_t := {}
var _music: AudioStreamPlayer
var _muted := false

func _ready() -> void:
	for _i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -10.0
	add_child(_music)
	_music.finished.connect(func(): _music.play())

func start_music() -> void:
	if _music.stream == null:
		_music.stream = MUSIC_DAY
		_music.play()

func game_over(won: bool) -> void:
	# จบ 120 วิ: ตัดเพลง เปิดจิงเกิลสรุป
	if _music != null and is_instance_valid(_music):
		_music.stop()
	play("win" if won else "lose")

func resume_music() -> void:
	if _music != null and is_instance_valid(_music) and not _music.playing:
		_music.play()

func play(kind: String) -> void:
	if _muted or not STREAMS.has(kind):
		return
	var prof: Array = PROFILE.get(kind, [-10.0, 0.0])
	var throttle: float = prof[1]
	if throttle > 0.0:
		var now := Time.get_ticks_msec()
		var last: int = _last_t.get(kind, -1000000)
		if now - last < int(throttle * 1000.0):
			return
		_last_t[kind] = now
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % POOL_SIZE
	p.stream = STREAMS[kind]
	p.volume_db = prof[0]
	p.play()

func toggle_mute() -> bool:
	_muted = not _muted
	if _music != null:
		_music.stream_paused = _muted
	return _muted

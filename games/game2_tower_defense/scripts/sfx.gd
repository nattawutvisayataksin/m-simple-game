extends Node
# ระบบเสียงของเกม 2 (T6): เพลง 2 อารมณ์ (สงบระหว่างเตรียม / ตึงระหว่างคลื่นบุก สลับไหลลื่น)
# + SFX พูลเสียงซ้ำได้จากงานสังเคราะห์ (generate_td_audio.ps1)
# วิธีใช้จากโหนดใด ๆ: get_parent().sfx("arrow") ถ้าแม่เป็น main หรือ Sfx.node ใดที่มีเมทอด sfx

const MUSIC_PREP := preload("res://assets/audio/music_prep.wav")
const MUSIC_WAVE := preload("res://assets/audio/music_wave.wav")

const STREAMS := {
	"arrow": preload("res://assets/audio/sfx_arrow.wav"),
	"cannon": preload("res://assets/audio/sfx_cannon.wav"),
	"mage": preload("res://assets/audio/sfx_mage.wav"),
	"explosion": preload("res://assets/audio/sfx_explosion.wav"),
	"die": preload("res://assets/audio/sfx_die.wav"),
	"coin": preload("res://assets/audio/sfx_coin.wav"),
	"leak": preload("res://assets/audio/sfx_leak.wav"),
	"horn": preload("res://assets/audio/sfx_horn.wav"),
	"build": preload("res://assets/audio/sfx_build.wav"),
	"sell": preload("res://assets/audio/sfx_sell.wav"),
	"slash": preload("res://assets/audio/sfx_slash.wav"),
	"click": preload("res://assets/audio/sfx_click.wav"),
	"win": preload("res://assets/audio/sfx_win.wav"),
	"lose": preload("res://assets/audio/sfx_lose.wav"),
}

# เสียงต่อชนิด: เดซิเบล + ช่วง throttle กันเสียงดับก้อนขยะน้ำ (ยิงถี่ดามากจนทุบ)
const PROFILE := {
	"arrow": [-12.0, 0.06], "cannon": [-5.0, 0.1], "mage": [-10.0, 0.08],
	"explosion": [-4.0, 0.12], "die": [-13.0, 0.05], "coin": [-9.0, 0.05],
	"leak": [-2.0, 0.4], "horn": [-3.0, 1.0], "build": [-5.0, 0.1],
	"sell": [-7.0, 0.2], "slash": [-11.0, 0.08], "click": [-14.0, 0.04],
	"win": [-3.0, 1.2], "lose": [-3.0, 1.2],
}
const POOL_SIZE := 8

var _svo: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _last_t := {}
var _music_on: AudioStreamPlayer
var _music_off: AudioStreamPlayer
var _wave_theme := false
var _muted := false

func _ready() -> void:
	# พูล SFX: วนจับผู้เล่นเสมอ (เสียงยิงรัวรอบเกินก็แค่ตัดต่อเนอร์ที่เสียงเบาลงไปเอง)
	for _i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_svo.append(p)
	_music_on = AudioStreamPlayer.new()
	_music_on.volume_db = -7.0
	add_child(_music_on)
	_music_on.finished.connect(func(): _music_on.play())
	_music_off = AudioStreamPlayer.new()
	_music_off.volume_db = -60.0
	add_child(_music_off)
	_music_off.finished.connect(func(): _music_off.play())

func start_music() -> void:
	# เริ่มเพลงสงบ (เรียกครั้งเดียวจาก main._ready)
	if _music_on.stream == null:
		_music_on.stream = MUSIC_PREP
		_music_on.play()

func set_wave_theme(active: bool) -> void:
	# สลับเพลงสงบ<->คลื่นบุก: เปิดเพลงใหม่เนียนเดซิเบลขึ้น ปิดเพลงเก่าลงเดซิเบลลดแล้วหยุด
	if active == _wave_theme:
		return
	_wave_theme = active
	var top := _music_on if active else _music_off
	var low := _music_off if active else _music_on
	if top.stream == null:
		top.stream = MUSIC_WAVE if active else MUSIC_PREP
	if low.stream == null:
		low.stream = MUSIC_PREP if active else MUSIC_WAVE
	top.volume_db = -60.0
	top.play()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(top, "volume_db", -7.0, 0.9)
	tw.tween_property(low, "volume_db", -60.0, 0.9)
	tw.chain().tween_callback(low.stop)

func game_over(won: bool) -> void:
	# จบเกม: หยุดเพลง + เพลงประกอบชนะ/แพ้
	if _music_on != null and is_instance_valid(_music_on):
		_music_on.stop()
	if _music_off != null and is_instance_valid(_music_off):
		_music_off.stop()
	play("win" if won else "lose")

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
	var p := _svo[_pool_i]
	_pool_i = (_pool_i + 1) % POOL_SIZE
	p.stream = STREAMS[kind]
	p.volume_db = prof[0]
	p.play()

func toggle_mute() -> bool:
	_muted = not _muted
	if _music_on != null:
		_music_on.stream_paused = _muted
		if _wave_theme and _music_off != null:
			_music_off.stream_paused = _muted
	return _muted

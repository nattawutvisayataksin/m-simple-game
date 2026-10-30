extends SceneTree
## One-shot: build hero run sheet from 9 downloaded frames -> kubi_hero_run_sheet.png

const DIR := "C:/m-simple-game/games/game1_coin_rush/assets/art/sprites/"
const FRAMES := 9
const FW := 64

func _init() -> void:
	var sheet := Image.create(FW * FRAMES, FW, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in range(FRAMES):
		var img := Image.load_from_file(DIR + "run_frames/f%d.png" % i)
		if img == null:
			push_error("frame %d load fail" % i)
			quit(1)
			return
		img.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(img, Rect2i(0, 0, FW, FW), Vector2i(i * FW, 0))
	var err := sheet.save_png(DIR + "kubi_hero_run_sheet.png")
	print("save err=", err, " size=", sheet.get_width(), "x", sheet.get_height())
	quit(0)

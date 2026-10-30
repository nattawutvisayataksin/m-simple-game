extends SceneTree
## Diagnostic: per-band opaque coverage + topmost opaque row of a PNG (probes live pixels)

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var path := args[0] if args.size() > 0 else "C:/m-simple-game/games/game1_coin_rush/assets/art/gen/hills_strip.png"
	var img := Image.load_from_file(path)
	if img == null:
		push_error("load fail: " + path)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	print(path.get_file(), " ", w, "x", h, " fmt=", img.get_format())
	# topmost opaque row (alpha > 8)
	var top_y := -1
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 8:
				top_y = y
				break
		if top_y >= 0:
			break
	print("topmost opaque row y=", top_y)
	for band in range(0, h, 32):
		var opq := 0
		var tot := 0
		var y_end := mini(band + 31, h - 1)
		for y in range(band, y_end + 1):
			for x in range(w):
				tot += 1
				if img.get_pixel(x, y).a > 200:
					opq += 1
		print("rows %3d-%3d: opaque %d/%d" % [band, y_end, opq, tot])
	quit(0)

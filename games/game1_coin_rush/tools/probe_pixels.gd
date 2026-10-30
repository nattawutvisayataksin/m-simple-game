extends SceneTree
## Probe: print raw pixel colors of hills_strip and hills_low at sample points

func _init() -> void:
	var base := "C:/m-simple-game/games/game1_coin_rush/assets/art/gen/"
	for path in ["hills_strip.png", "hills_low.png", "bg_sunny.png"]:
		var img := Image.load_from_file(base + path)
		if img == null:
			print(path, ": LOAD FAIL")
			continue
		print(path, ": ", img.get_width(), "x", img.get_height(), " format=", img.get_format(), " mipmaps=false")
		for pt in [Vector2i(10, 10), Vector2i(120, 8), Vector2i(232, 6), Vector2i(60, 150), Vector2i(120, 218), Vector2i(200, 140)]:
			var c := img.get_pixel(pt.x, pt.y)
			print("   ", pt, " -> rgba(", c.r8, ",", c.g8, ",", c.b8, ",", c.a8, ")")
	quit(0)

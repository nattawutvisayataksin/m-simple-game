extends Node2D
# เกมที่ 3: เกมรถ — โครงตั้งต้น (ฉากว่าง + ป้ายบอกสถานะ)
# รอผู้อำนวยการกำหนดแนวเกม: แข่งหน้าขวา / top-down / รวยถนนหลบเรี่ยว / เก็บของ

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color(0.13, 0.15, 0.20))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(386, 320),
		"เกมที่ 3: เกมรถ — โครงตั้งต้น", HORIZONTAL_ALIGNMENT_CENTER, 380, 24, Color(0.92, 0.92, 0.95))
	draw_string(font, Vector2(386, 356),
		"รอกำหนดแนวเกม (แข่งเร็ว / หลบรถ / เก็บของ)", HORIZONTAL_ALIGNMENT_CENTER, 380, 15, Color(0.60, 0.66, 0.72))

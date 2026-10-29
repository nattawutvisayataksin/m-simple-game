# Asset vendor inventory — Game 3 (Kubi Grand Prix ราชวงศ์ทอง)

เอกสารนี้บันทึกชุด asset ที่ vendor เข้ามาในโปรเจกต์ ไม่ได้หมายความว่าทุกไฟล์ถูกวาง
ในสนาม รายการที่ใช้งานจริงและ license แยกตามระบบดูที่
[`docs/game3_car/ASSETS.md`](../../../docs/game3_car/ASSETS.md)

## ที่มาและไฟล์ที่ vendor ลงโปรเจกต์

| ชุดไฟล์ในโปรเจกต์ | ที่มา | สถานะในฉากแข่งปัจจุบัน |
|---|---|---|
| `models/race-future.glb`, `models/vehicle-*.glb`, `models/kart-*.glb` | Kenney Car Kit | เมนูเลือก race-future และ truck 4 สี; kart 3 คันตกแต่งเส้นชัย |
| `models/props/*.glb` และ `Textures/colormap.png` | Kenney City Kit (Roads) | เก็บไว้เป็น vendor files; ไม่ได้วางในเลนแข่ง |
| `models/town/roads/*.glb` และ `Textures/colormap.png` | [City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) | ใช้ถนนตรงและโค้ง |
| `models/town/industrial/*.glb` และ `Textures/colormap.png` | [City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) | ใช้อาคารบางแบบรอบนอกสนาม |
| `models/town/deco/*.glb` และ `Textures/colormap.png` | [Platformer Kit](https://kenney.nl/assets/platformer-kit) | ใช้ตัวละคร ต้นไม้ รั้วเตี้ย ดอกไม้ และเหรียญ |
| `models/town/props/*.glb` และ `Textures/colormap.png` | [Blaster Kit](https://kenney.nl/assets/blaster-kit) | ลังและเป้าเก็บเป็น vendor files; ไม่ใช้บนถนน |

- ใบอนุญาตครบทั้งสองชุดอยู่ที่ `models/props/LICENSE_car-kit.txt` และ `LICENSE_city-kit-roads.txt` (CC0)
- ชุด asset ของ Kenney ที่ใช้ในเมืองระบุ CC0 บนหน้าแหล่งที่มาด้านบน
- ชุดฐาน Starter Kit Racing (Kenney NL) ใช้โค้ด MIT และโมเดล/เสียง CC0 ตาม README และ LICENSE ที่มากับชุด
- เสียง skid ระบุเครดิต Landeplage และ CC0 ไว้ใน README ต้นฉบับของ Starter Kit

## เมือง Kubi

`scripts/town.gd` ใช้เฉพาะโมเดลถนน อาคาร และของตกแต่งที่ระบุไว้ข้างต้นเพื่อสร้างฉากเมืองสำหรับสนามแข่ง ไม่ได้นำโปรเจกต์หรือระบบควบคุมจาก Starter Kit City Builder มาใช้

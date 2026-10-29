# Assets ที่ใช้ในเกม 3 (Kubi Grand Prix ราชวงศ์ทอง)

ทุกชิ้นเป็นของฟรีลิขสิทธิ์ CC0 (Kenney NL) — ไม่มีการใช้ gen AI ในชุด asset นี้

## ที่มาและไฟล์ที่ vendor ลงโปรเจกต์

| ไฟล์ในโปรเจกต์ | ที่มา |
|---|---|
| `models/race-future.glb` (รถผู้เล่น) | kenney_car-kit — `Models/GLB format/race-future.glb` |
| `models/kart-oobi.glb`, `kart-oodi.glb`, `kart-oozi.glb` (เหล่า kart ตกแต่งเส้นชัย) | kenney_car-kit |
| `models/props/electricity-pole.glb`, `traffic-light.glb`, `sign-highway.glb`, `construction-cone.glb`, `road-side-barrier.glb` (ของประดับสนาม) | kenney_city-kit-roads |
| `models/props/Textures/colormap.png` | kenney_city-kit-roads (GLB อ้างไฟล์ texture ภายนอกแบบ relative path) |
| `models/town/roads/*.glb` และ `Textures/colormap.png` | [City Kit (Roads)](https://kenney.nl/assets/city-kit-roads) |
| `models/town/industrial/*.glb` และ `Textures/colormap.png` | [City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial) |
| `models/town/deco/*.glb` และ `Textures/colormap.png` | [Platformer Kit](https://kenney.nl/assets/platformer-kit) (ตัวละคร ต้นไม้ รั้ว และเหรียญ) |
| `models/town/props/*.glb` และ `Textures/colormap.png` | [Blaster Kit](https://kenney.nl/assets/blaster-kit) (ลังและเป้า) |

- ใบอนุญาตครบทั้งสองชุดอยู่ที่ `models/props/LICENSE_car-kit.txt` และ `LICENSE_city-kit-roads.txt` (CC0)
- ชุด asset ของ Kenney ที่ใช้ในเมืองระบุ CC0 บนหน้าแหล่งที่มาด้านบน
- ชุดฐาน Starter Kit Racing (Kenney NL) ใช้โค้ด MIT และโมเดล/เสียง CC0 ตาม README และ LICENSE ที่มากับชุด
- ขนาดของ prop ถูกจัดที่รันไทม์ (`scripts/game.gd` — `PROP_TARGET_HEIGHT` + วัด AABB เอาอัตโนมัติ) ไม่ต้องแก้ไฟล์โมเดล

## เมือง Kubi

`scripts/town.gd` ใช้เฉพาะโมเดลถนน อาคาร และของตกแต่งที่ระบุไว้ข้างต้นเพื่อสร้างฉากเมืองสำหรับสนามแข่ง ไม่ได้นำโปรเจกต์หรือระบบควบคุมจาก Starter Kit City Builder มาใช้

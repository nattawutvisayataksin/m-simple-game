# Assets ที่ใช้ในเกม 3 (Kubi Grand Prix ราชวงศ์ทอง)

ทุกชิ้นเป็นของฟรีลิขสิทธิ์ CC0 (Kenney NL) — ไม่มีการใช้ gen AI ใด ๆ ในขั้น T1.0

## ที่มาและไฟล์ที่ vendor ลงโปรเจกต์

| ไฟล์ในโปรเจกต์ | ที่มา |
|---|---|
| `models/race-future.glb` (รถผู้เล่น) | kenney_car-kit — `Models/GLB format/race-future.glb` |
| `models/kart-oobi.glb`, `kart-oodi.glb`, `kart-oozi.glb` (เหล่า kart ตกแต่งเส้นชัย) | kenney_car-kit |
| `models/props/electricity-pole.glb`, `traffic-light.glb`, `sign-highway.glb`, `construction-cone.glb`, `road-side-barrier.glb` (ของประดับสนาม) | kenney_city-kit-roads |
| `models/props/Textures/colormap.png` | kenney_city-kit-roads (GLB อ้างไฟล์ texture ภายนอกแบบ relative path) |

- ใบอนุญาตครบทั้งสองชุดอยู่ที่ `models/props/LICENSE_car-kit.txt` และ `LICENSE_city-kit-roads.txt` (CC0)
- ต้นฉบับทั้งหมด: https://kenney.nl/assets (Kenney Studio, CC0 1.0 Universal)
- ชุดฐาน Starter Kit Racing (Kenney NL) — MIT/CC0 เดิมตาม README ของ kit
- ขนาดของ prop ถูกจัดที่รันไทม์ (`scripts/game.gd` — `PROP_TARGET_HEIGHT` + วัด AABB เอาอัตโนมัติ) ไม่ต้องแก้ไฟล์โมเดล

## สิ่งที่ยังไม่เอามา (ไว้แผนถัดไป)

ชุด `kenney_city-kit-roads` ยังมีชิ้นถนนเมืองครบ (road-straight, road-curve, intersection, roundabout, ไฟจราจรติดตั้ง เป็นต้น) เก็บไว้ทำ T1.1: สร้าง MeshLibrary ถนนเมือง Kubi แทนชุดสนาม kit เดิม = สนามเอกลักษณ์เป็นเมือง Kubi

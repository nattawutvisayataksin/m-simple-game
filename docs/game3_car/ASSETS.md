# Assets — Kubi Grand Prix

เอกสารนี้เป็นทะเบียนการใช้ asset ใน Game 3; รายการ source และ license แบบ vendor
ดู [ASSETS.md ของ Starter Kit](../../games/game3_car/ASSETS.md)
และ [LICENSE](../../games/game3_car/LICENSE)

## Asset ที่ใช้งานในเกม

| สิ่งที่เห็น/ใช้ | ไฟล์หรือแหล่งในโปรเจกต์ | ต้นทาง / License |
|---|---|---|
| รถผู้เล่นที่เลือกได้ 5 แบบ | `models/race-future.glb`, `models/vehicle-truck-{yellow,red,purple,green}.glb` | Kenney Car Kit; โมเดล CC0 |
| Kubi kart ตกแต่งเส้นชัย | `models/kart-oobi.glb`, `kart-oodi.glb`, `kart-oozi.glb` | Kenney Car Kit; โมเดล CC0 |
| ถนนตรง/ถนนโค้ง | `models/town/roads/road-straight.glb`, `road-bend.glb` และ texture ของชุด | Kenney City Kit (Roads); CC0 |
| อาคารรอบเมือง | `models/town/industrial/building-{g,j,l,n,q}.glb` และ texture ของชุด | Kenney City Kit (Industrial); CC0 |
| ต้นไม้ ดอกไม้ ตัวละคร และรั้ว | `models/town/deco/` เฉพาะ `tree-pine-small.glb`, `flowers.glb`, `character-*.glb`, `fence-low-straight.glb` | Kenney Platformer Kit; CC0 |
| เหรียญ | `models/town/deco/coin-gold.glb` | Kenney Platformer Kit; CC0 |
| เสียงรถ/ควัน | `audio/engine.ogg`, `audio/skid.ogg`, `audio/impact.ogg`, `sprites/smoke.png` | Starter Kit Racing; README ระบุโมเดล/เสียงส่วนใหญ่ CC0 และ skid โดย Landeplage CC0 |
| รั้วกำแพง เส้นถนน ป้าย Gate และไอเท็ม | สร้างด้วย `BoxMesh`, `PlaneMesh`, `Area3D` และวัสดุใน GDScript | สร้างในโปรเจกต์; ไม่มีภาพ AI |

## License และการให้เครดิต

- โค้ด Starter Kit Racing ใช้ MIT; เก็บประกาศไว้ใน `games/game3_car/LICENSE`
- โมเดล/เสียงของ Kenney ที่ใช้ในชุดระบุ CC0 ตาม README และ license ที่ vendor มา
- ไฟล์ license ที่เก็บในโฟลเดอร์เกม: `models/props/LICENSE_car-kit.txt` และ
  `models/props/LICENSE_city-kit-roads.txt`
- Kenney asset pages: [Car Kit](https://kenney.nl/assets/car-kit),
  [City Kit (Roads)](https://kenney.nl/assets/city-kit-roads),
  [City Kit (Industrial)](https://kenney.nl/assets/city-kit-industrial),
  [Platformer Kit](https://kenney.nl/assets/platformer-kit)
- รวม attribution ของ Landeplage สำหรับ skid sound ตาม README ต้นฉบับ
- ไม่ฝัง API key หรือ credentials ไว้ในทะเบียน asset หรือในเกม

ไฟล์มอเตอร์ไซค์จาก Starter Kit ยังคงอยู่ แต่ไม่ได้อยู่ในตัวเลือกเมนูของเกมปัจจุบัน;
รถที่เลือกได้จริงคือ race-future และ truck 4 สีตามตารางด้านบน

## Vendor files ที่ไม่ได้ใช้งานในฉากแข่งปัจจุบัน

ไฟล์ที่ vendor มาพร้อม Starter Kit/asset kit ไม่ได้แปลว่าทุกไฟล์ถูกวางในฉาก:
`models/props/` (เสาไฟ, ไฟจราจร, ป้าย, กรวยและแบริเออร์) ไม่ได้ instantiate โดยฉากแข่งปัจจุบัน
และ `models/town/props/` (ลัง/เป้า) ไม่ได้ใช้บนสนาม หลังพบว่าพร็อพทำให้ดูเหมือนมีสิ่งกีดขวาง
บนเลน ให้นำออกจากการวางในสนาม แต่เก็บไฟล์ vendor และ license เดิมไว้

## กฎเพิ่มหรือเปลี่ยน asset

1. ใช้เฉพาะ asset ที่ license ชัดเจนและเก็บหลักฐาน license/ที่มาไว้กับชุด vendor
2. ระบุว่าชิ้นงานนั้นถูกใช้ในฉากจริงหรือเป็นไฟล์สำรอง ไม่เหมารวมสองสถานะ
3. วัดสเกลเทียบรถและระยะชนก่อนวางลงสนาม; ห้ามวาง collider ที่ซ่อนทางหรือบัง Gate
4. ถ้าเพิ่ม asset ภายนอก ให้เพิ่มแหล่งที่มาและ license ในตารางนี้กับทะเบียน vendor
5. ตรวจ import และรัน regression test หลังเพิ่ม GLB/texture/audio:

   ```powershell
   godot --headless --path games/game3_car --import
   godot --headless --path games/game3_car `
     --scene res://tests/test_game3_runner.tscn
   ```

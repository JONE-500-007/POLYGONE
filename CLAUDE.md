# Just Some Test v2 — บันทึกสำหรับ Claude Code

## เป้าหมายโปรเจกต์
เกม 3D มุมมอง top-down (กล้อง orthographic) ที่ render เป็นลุคพิกเซลอาร์ตด้วย shader
แนวเกม: bullet heaven + co-op ออนไลน์ 1 ถึง 4 คน — **ดีไซน์ทั้งหมดอยู่ใน `GAME_DESIGN.md` (อ่านก่อนเริ่มทำฟีเจอร์ใหม่)**
Godot 4.7.2, Forward+ renderer (ต้องใช้ Forward+ หรือ Mobile เพราะ shader อ่าน `hint_normal_roughness_texture`)

แหล่งอ้างอิง:
- Godot docs: Advanced post-processing (full screen quad + depth texture)
- three.js pixelation pass (Kody King): https://threejs.org/examples/webgl_postprocessing_pixel.html
- โปรเจกต์ตัวอย่าง 3DPixelArt_Tutorial (Eduardo Schildt, MIT) ใช้เทียบ (shader ของผู้ใช้เขียนเองใน `my_outline.gdshader`; แต่ในโฟลเดอร์ shaders มีไฟล์ `edge_detection.gdshader` ที่เป็นสำเนาของเขา ดูหัวข้อสถานะล่าสุด)

## วิธีทำงานกับผู้ใช้ (สำคัญ)
- ผู้ใช้ต้องการ **เรียนรู้**: สอนทีละขั้น ให้ผู้ใช้ลงมือเองใน Godot แล้วค่อยอ่านไฟล์ตรวจให้ ("พาทำ" ไม่ใช่ "ทำให้")
- อย่าแก้โค้ดหรือฉากของผู้ใช้แทน ถ้าไม่ได้ขอ (ผู้ใช้เคยบอกชัดว่า "ยังไม่ต้องแก้ด้วยตัวคุณ" ให้บอกว่าผิดตรงไหนแล้วรอ) ไฟล์เอกสาร `.md` ผู้ใช้ขอให้ผมอัปเดตให้ได้
- ตอบเป็นภาษาไทย อธิบายว่า "ทำไม" ไม่ใช่แค่ "ทำอะไร"
- **รูปแบบการบอกที่ผู้ใช้ชอบตอนนี้:** บอกขั้นตอนยาวๆ หลายขั้นในข้อความเดียวได้ แต่ **ต้องบอกผลที่ควรเห็นหลังแต่ละขั้น** ผู้ใช้จะลองทำเองแล้วถามถ้าติด และจะบอกให้ "ฝากเช็ค" → อ่านไฟล์/จำลอง headless แล้วรายงานว่าถูกหรือขาดอะไร
- "ฝากทำ"/"ฝากเช็ค" ในบริบทนี้: **ฝากเช็ค = ตรวจให้**, ส่วน "ฝากทำ" ผู้ใช้เคยหมายถึง "พาทำ" (ไม่ใช่ให้ผมสร้างไฟล์แทน) — ถ้าไม่ชัดให้ถามหรือยึด "พาทำ" (เคยพลาดสร้างไฟล์ HUD แทนแล้วต้องลบ)
- ตรวจงานโดยอ่านไฟล์ `.tscn`/`.gd` ที่ผู้ใช้เพิ่งทำ: เช็กชื่อโหนด การผูกสคริปต์ว่าผูกกับโหนดถูกตัวไหม (ผูกกับโหนดบนสุดหรือโหนดที่ตั้งใจ) เส้นทาง `$...` ในสคริปต์ให้ตรงกับฉาก และดูว่าบันทึกแล้วหรือยัง (เวลาไฟล์เก่ากว่าที่ผู้ใช้บอกว่าแก้ = ยังไม่ได้ Ctrl+S)
- เมื่อเป็นพฤติกรรมในเกมที่ดูด้วยตาไม่ได้ ให้ **จำลองเกมแบบไม่เปิดหน้าต่าง** (ดูหัวข้อ "ทดสอบเกมแบบ headless") แทนการเดา

## โครงสร้างฉากเกม (`scenes/main.tscn`)
```
Main (Node)
├─ Hud (instance scenes/hud.tscn, CanvasLayer — ต้องอยู่ต่ำกว่า PixelContainer)
├─ LevelUpPanel (instance scenes/level_up_panel.tscn, CanvasLayer layer 10 — ต่ำกว่า Hud)
└─ PixelContainer (SubViewportContainer: stretch on, stretch_shrink 4, texture_filter Nearest, Full Rect)
   (หมายเหตุ: ในไฟล์ `.tscn` Hud และ LevelUpPanel ถูกเรียงต่อท้าย PixelContainer ใน Scene tree)
   └─ SubViewport (320x180, ขยาย 4 เท่าให้พอดี 1280x720)
	  └─ World (Node3D)
		 ├─ Camera3D (Orthogonal, size 14, near 0.1, far 60; script camera_follow.gd)
		 │   └─ PostProcess (MeshInstance3D: QuadMesh 2x2 flip_faces, extra_cull_margin 16384, ShaderMaterial -> my_outline.gdshader)
		 ├─ DirectionalLight3D (shadow on)
		 ├─ Player (instance scenes/player.tscn, อยู่นอก NavigationRegion3D)
		 ├─ EnemySpawner (Node3D + scripts/enemy_spawner.gd, ช่อง enemy_scene = scenes/enemy_cube.tscn, อยู่นอก NavigationRegion3D)
		 └─ NavigationRegion3D (navigation mesh bake จาก Static Colliders)
			 ├─ Floor (พื้น 128x128, StaticBody3D)
			 └─ Crate1..Crate5 (กล่อง/กำแพงทดสอบ มี StaticBody3D)
```
Project Settings: viewport 1280x720, stretch mode canvas_items, scale_mode integer, soft shadow filter quality = Hard (0), main scene = `main_menu.tscn`, autoload `GameState` (`scripts/game_state.gd`)
Collision layers (3D physics): 1 = World, 2 = Player, 3 = Enemy

## Shader ที่ผู้ใช้เขียนเอง (`shaders/my_outline.gdshader`) — ทำครบ 5 ชั้นแล้ว
1. quad เต็มจอ (`POSITION = vec4(VERTEX.xy, 1.0, 1.0)`)
2. อ่านภาพฉาก (`hint_screen_texture`, filter_nearest)
3. อ่านความลึก (`hint_depth_texture` -> linear depth ด้วย `INV_PROJECTION_MATRIX`)
4. ขอบจาก depth: นับเฉพาะเพื่อนบ้านที่ "ไกลกว่า" -> เส้นดำหนา 1 พิกเซล
5. ขอบจาก normal (`hint_normal_roughness_texture`): ไฮไลต์เฉพาะมุมนูน และเฉพาะเพื่อนบ้านที่อยู่ผิวเดียวกัน
ค่าปรับได้ใน Inspector: `edge_threshold`, `line_darkness`, `normal_threshold`, `line_highlight`, `same_surface_depth` (มีคอมเมนต์อังกฤษกำกับ)
- **`render_mode unshaded, depth_draw_never;`** จำเป็น: ถ้าไม่ใส่ แผ่นเต็มจอจะเขียน depth ที่ใกล้สุด ทำให้ของโปร่งใสทั้งหมด (debug navigation, แถบเลือด ฯลฯ) มองไม่เห็น

## สถานะล่าสุด
- **ทำเสร็จแล้ว (ผู้ใช้ลงมือเอง ผมพาทำ):**
  - เมนูหลัก (Play/Settings/Quit), เมนู Play (Solo/Co-op), หน้า Co-op (Create Room/Join)
  - หน้าเลือกตัวละครพร้อมโมเดลหมุน + `CharacterData`/`GameState`
  - ผู้เล่นเดิน WASD + กระโดด Space + แรงโน้มถ่วง, กล้องตามผู้เล่น
  - **ศัตรู Cube** (สุ่มความสูง 1.5–3.5 ม., เดินอ้อมสิ่งกีดขวางด้วย navigation), **ตัวเกิดศัตรูเป็นคลื่น**, **ระบบเลือด** (ผู้เล่น 100 / ศัตรู 20, ศัตรูแตะทำดาเมจ 10 ทุก 1 วินาทีต่อตัว), **แถบเลือดลอยเหนือหัว** (ไม่แสดงตัวเลข) — ผู้ใช้ปรับขนาด/ตำแหน่งแถบเอง
  - **อาวุธแบบที่ 1 (ทำแล้ว): กระสุนกล่องของคลาสสี่เหลี่ยม** — ยิงอัตโนมัติใส่ศัตรูที่ใกล้ที่สุดเป็นเส้นตรง ดาเมจ 15 (ศัตรูตายใน 2 นัด) ยิงทุก 1.0 วินาที ความเร็ว 14 ม./วินาที ระยะ 18 ม. กระสุน 1 นัดโดนศัตรู 1 ตัวแล้วหาย; บรรทัดทดสอบชั่วคราวในศัตรูถูกลบแล้ว
  - **ผูกอาวุธตามคลาส (ทำแล้ว):** `CharacterData.starting_weapon` (เป็น `CardData`) → `Player.gain_card(card)` สร้างฉากอาวุธเป็นลูกของผู้เล่น (ถ้าได้ซ้ำ = เลเวลอัป ไม่สร้างกระบอกใหม่); Cube เริ่มด้วย **Weapon A** (`data/cards/weapon_a.tres` → `scenes/weapon_cube.tscn`), Sphere/Pyramid ยังไม่มีอาวุธ (ช่องว่าง ไม่ error)
  - **EXP + เลเวล (ทำแล้ว):** ศัตรูตายดรอปออร์บ EXP เขียว 10 (ลอยขึ้นลง เดินชนเก็บ), เลเวลเริ่ม 0 ต้องใช้ 100 EXP แล้วเพิ่มทีละ ×1.15 (100 → 115 → 132 ...)
  - **HUD (ทำแล้ว):** ช่องไอคอนอาวุธ/พาสซีฟ 6+6 ช่องบนซ้าย (ว่างจนมีของ), แถบ EXP ล่างจอ (มี %), ข้อความ Level ขวาบน
  - **การ์ดเลเวลอัป + เลเวลของไอเทม (ทำแล้ว):** เลเวลอัปขึ้นการ์ด 3 ใบ เลือกด้วย 1/2/3 หรือเมาส์ (ผู้ใช้ไม่ต้องการเลือกด้วย WASD/ลูกศร/Space แล้ว), เล่นคนเดียวหยุดเวลา, เลเวลอัปซ้อนเข้าคิว; ได้ซ้ำ = ไอเทมเลเวลอัปตามโบนัสที่ผู้ใช้เขียนไว้เป็นแถวๆ ใน `CardData.levels` (ไม่สุ่ม สะสมแบบบวก); เลเวลเต็มแล้วไม่ถูกสุ่มเข้ากอง; HUD ช่องแสดง `Lv.x`
  - **ลูกศรเดินได้ (ทำแล้ว):** เพิ่มปุ่มลูกศรเข้า `move_*` ใน Input Map (เป้าหมาย: เล่นมือเดียวได้)
  - **Weapon A อัปเกรดได้ (ทำแล้ว):** โบนัสต่อเลเวล = ดาเมจ / ขนาดกระสุน / ความถี่ยิง / **จำนวนกระสุน (`projectile_bonus`)** กระสุนหลายนัดยิงเรียงกันห่าง `shot_interval` 0.1 วินาที แต่ละนัดเล็งศัตรูที่ใกล้สุดขณะนั้น; **cooldown แยกตามอาวุธแต่ละกระบอก** (แต่ละโหนด `Weapon` มีตัวจับเวลาของตัวเอง)
- **การตัดสินใจของผู้ใช้ (ทำแล้ว ยกเว้นเลเวล 6–10):** เลเวลสูงสุดของอาวุธ/พาสซีฟทุกชิ้นที่ตั้งใจ = **10** (เขียนโบนัสเอง 9 แถวต่อชิ้น — ตอนนี้ทำไว้แค่ 4 แถว = Lv.5); เลเวลสูงสุดของตัวละคร = **4444** (cap ใน `Experience.max_level` ชั่วคราว จริงๆ อยากให้ไม่จำกัด) ✅; **พาสซีฟ A** (`data/cards/passive_a.tres`) = เพิ่มดาเมจของอาวุธทุกกระบอก x% ✅; **Weapon B** (`data/cards/weapon_b.tres` → `weapon_fan.tscn`) = ยิงกระสุนเป็นพัดพร้อมกัน ✅ (ไว้เป็นอาวุธอีกชนิด ไม่ใช่การเปลี่ยน Weapon A; ตรวจด้วยการจำลองแล้ว: Lv.1 = 3 นัด มุม −12/0/+12°, Lv.3 = 5 นัด)
- **ขั้นถัดไป (ยังไม่ได้ทำ) ตามลำดับที่แนะนำ:**
  1. **(ทำแล้ว)** cap เลเวลตัวละคร 4444 (`Experience.max_level`); **พาสซีฟ A** (`CardData.base_bonus` = โบนัสเลเวล 1, `Player.get_damage_bonus()` รวมดาเมจจากพาสซีฟทุกชิ้น, `Weapon._fire_at` คูณตอนยิง); **Weapon B** กระสุนพัด
  2. ตอนนี้ผู้ใช้เขียนข้อมูลเลเวลไว้แค่ **5 เลเวล** (4 แถว) ต่อไอเทมเพื่อประหยัดเวลาทดสอบ — เลเวลสูงสุดจริงที่ตัดสินใจไว้คือ 10 (9 แถว) ค่อยเติมทีหลัง; ค่าของ `weapon_fan.tscn` (Damage 8, Fire Interval 1.2, Max Range 14) ที่เสนอไว้ผู้ใช้ยังไม่ได้ตั้ง (ตอนนี้เป็นค่าตั้งต้นเหมือน A)
  3. **ออร์บแดง 30 EXP** และพาสซีฟชนิดอื่น (ตอนนี้ `CardLevel` มีแต่โบนัสดาเมจ/ขนาด/ความถี่/จำนวนกระสุน) (ทำเป็น Inherited Scene ของ `exp_orb.tscn` เปลี่ยน `exp_value` กับสี) และให้ศัตรูต่างระดับดรอปต่างสี (`orb_scene` เป็น `@export` อยู่แล้ว)
  5. อาวุธคลาสวงกลม (ลูกบอลเด้งไปมา: ผู้ใช้**พักไว้ก่อน**) และคลาสสามเหลี่ยม (เลเซอร์ ดาเมจเบากว่า); ค่าที่เสนอไว้สำหรับลูกบอล: ดาเมจ 10, เด้งสูงสุด 4 ครั้ง, ยิงทุก 1.5 วินาที, ความเร็ว 10 ม./วินาที (ผู้ใช้ยังไม่ได้ตอบรับ)
- ปุ่มที่ยังเป็นตัวสำรอง (พิมพ์ข้อความใน Output อย่างเดียว): Settings, Create Room, Join (ออนไลน์ยังไม่ได้ทำ)
- ผู้เล่นตาย: ตอนนี้แค่ตั้ง `is_dead` และพิมพ์ "Player died" (ควบคุมไม่ได้, ศัตรูเลิกไล่) ยังไม่มีหน้า Game Over / ระบบชุบ
- ยังไม่ได้ทำ: ให้ตัวละครหันไปทางที่เดิน, pixel snapping กล้อง, ผลจริงของการ์ด (อัปเกรด/พาสซีฟ), ออร์บแดง 30 EXP, ฟอนต์พิกเซลใน HUD (ผู้ใช้ปรับขนาดฟอนต์ Level เอง)
- ผู้ใช้ปรับตัวชน (Shape) และตำแหน่งโมเดลของ Sphere/Pyramid เอง ถ้าจะเก็บเป็นค่าเฉพาะตัวละคร อาจเพิ่ม field ใน `CharacterData` (collision shape, model offset)
- จุดค้างเล็กๆ: จุดขาว/ดำประปรายที่ขอบวัตถุ (ผู้ใช้ตัดสินใจ "ใช้แบบนี้ไปก่อน") ถ้าจะแก้: ปรับ `same_surface_depth`, `normal_threshold`, `edge_threshold` ทีละค่า หรือทำให้เช็กมุมนูนแม่นขึ้น + pixel snapping
- `shaders/edge_detection.gdshader` เป็นไฟล์เดียวกับของ 3DPixelArt_Tutorial (Eduardo Schildt, MIT) ไม่ได้ใช้ในฉาก — **ถ้าจะเก็บ ต้องแนบ LICENSE (MIT) ของเขาด้วย ถ้าไม่ใช้แล้วลบทิ้งได้** (ยังไม่ได้ตัดสินใจ)
- มีไฟล์แม่แบบว่างๆ `scenes/health.gd` (ไม่ได้ใช้ ลบได้) ตัวจริงคือ `scripts/health.gd`
- ระยะยาว: ดูลำดับการทำใน `GAME_DESIGN.md`; พื้นผิวตาราง/โมเดล Blender ของตัวเองใส่ทีหลัง

## ภาพรวมโค้ดและฉาก
- ฉากแรกของเกม: `scenes/main_menu.tscn` (สคริปต์ `scenes/main_menu.gd`) สลับ 4 แผงในฉากเดียว (`MainPanel`, `PlayPanel`, `CoopPanel`, `JoinPanel`) ด้วย `show_panel()`
- Solo -> `scenes/character_select.tscn` (`scripts/character_select.gd`): พรีวิว 3D เต็มจอใน SubViewport แยก (`PreviewContainer`, Stretch Shrink 4, Nearest, กล้อง Orthogonal มี `H Offset` เลื่อนโมเดลไปซ้าย, มี shader เส้นขอบ) + UI ขวา -> Play เก็บตัวที่เลือกใน `GameState.selected_character` แล้วไป `scenes/main.tscn`
- ข้อมูลตัวละคร: `scripts/character_data.gd` (`class_name CharacterData`: id, display_name, description, model_scene) + `data/characters/{cube,sphere,pyramid}.tres` (โมเดลใน `model/character/*.fbx`; `syramid01.fbx` พิมพ์ผิดจาก pyramid)
- **ผู้เล่น** `scenes/player.tscn` + `scripts/player.gd` (`class_name Player`, `CharacterBody3D`, layer 2 mask 1): `ModelPivot` สร้างโมเดลจาก `GameState` ตอน `_ready` (ไม่มีก็ใช้ cube); `CollisionShape3D` ต้องเป็นลูก `Player` โดยตรง; อยู่ในกลุ่ม `player`; เดินตามทิศกล้อง (อ่านจาก `get_viewport().get_camera_3d()`); `external_velocity` รับแรงผลักจากศัตรู (รีเซ็ตทุกเฟรม); `is_dead`; มีโหนดลูก `Health` และ `HealthBar3D`. Input Map: `move_forward/back/left/right` = W/S/A/D, `jump` = Space
- **กล้องเกม** `scripts/camera_follow.gd` บน `Camera3D` (ตั้ง `target` ชี้ `Player`; ตามเฉพาะแกน X/Z, จำ offset ตอน `_ready`; ที่มุมก้ม -55° ความสูง y 10.58 ตำแหน่ง x -4.5, z 4.5 ทำให้ผู้เล่นอยู่กลางจอตอนเกิด)
- **เลือด** `scripts/health.gd` (`class_name Health` มีไฟล์เดียวใช้ร่วมกันทุกที่ — ห้ามสร้างสำเนาที่มี class_name เดียวกัน): signal `changed(current, maximum)` และ `died`, `take_damage(amount)`
- **แถบเลือด** `scenes/health_bar_3d.tscn` + `scripts/health_bar_3d.gd`: ควอด 2 ชั้น (Back/Fill) วัสดุ Unshaded + Alpha + No Depth Test, คัดลอกทิศของกล้องทุกเฟรม, หาโหนดพี่น้องชื่อ `Health` เอง (ต้องเป็นลูกของตัวละครเดียวกับ `Health`), `hide_when_full` (ศัตรูเปิด, ผู้เล่นปิด)
- **ศัตรู** `scenes/enemy_cube.tscn` + `scripts/enemy_cube.gd` (`Enemy_Cube`: `CharacterBody3D`, layer 3 mask 1+3, กลุ่ม `enemy`):
  - `Body` (BoxMesh ปรับ scale.y = ความสูงสุ่ม), `CollisionShape3D` (แคปซูล ทำสำเนาใน `_randomize_height` แล้วตั้ง height ให้ตรงกับ Body — ต้องทำสำเนาเสมอ ไม่งั้นทุกตัวใช้ Shape ร่วมกัน), `Feet` (Node3D ที่ y = -height/2) เป็นพ่อของ `NavigationAgent3D` เพื่อให้ระบบนำทางวัดจากเท้า (ถ้าวัดจากกึ่งกลาง ตัวสูงจะหาเส้นทางไม่ได้และยืนนิ่ง), `Health` (max 20), `HealthBar3D` (ความสูง = height/2 + 0.6 ตั้งใน `_randomize_height`)
  - เดินตามเส้นทาง `NavigationAgent3D` (ขอเส้นทางใหม่ทุก `repath_interval` 0.25 วินาที กระจายเวลาเริ่มแบบสุ่ม)
  - แรงผลักไม่สมมาตร: เมื่อซ้อนกับผู้เล่นในระยะ `contact_distance` (ผู้ใช้ตั้ง 2.0) ศัตรูถูกผลักด้วย `shove_from_player` 12 ผู้เล่นถูกผลักด้วย `shove_on_player` 1 (ผู้เล่นกับศัตรูไม่ชนกันจริง แยกด้วย layer แล้วผลักด้วยโค้ด)
  - โจมตีเมื่อแตะ: `damage` 10 ทุก `attack_interval` 1.0 วินาทีต่อตัว; ข้ามผู้เล่นที่ตายแล้ว; ศัตรูเลือดหมด `queue_free()`
- **อาวุธ (สร้างจาก `CharacterData.starting_weapon` ตอน `Player._ready` ไม่ได้ติดใน `player.tscn` แล้ว)** ฉาก `scenes/weapon_cube.tscn` (= Weapon A) โหนดราก `Weapon` (`Node3D`, `scripts/weapon.gd`) ถูกเพิ่มเป็นลูกโดยตรงของ `Player` โดย `Player.gain_card()` (ใช้ `get_parent() as Player`) ผู้เล่นเก็บ `items: Dictionary` (CardData → เลเวล) กับ `_weapon_nodes`, มี `get_item_level(card)` และสัญญาณ `item_changed(card, level)` ที่ HUD ฟัง; **โครงสร้างอาวุธ (แยกไฟล์):** `scripts/weapon.gd` = แม่แบบ `class_name Weapon` (เลเวล/โบนัส `apply_level`, cooldown `_cooldown = fire_interval / _rate_mult`, `_find_nearest_enemy`, `_fire_at(target, player, angle_offset)`; จุด override: `_is_firing()`, `_continue_firing()`, `_start_firing()`) → `scripts/weapon_a.gd` (ยิงเรียงเป็นชุดห่าง `shot_interval` 0.1 วินาที จำนวน = 1 + `_extra_projectiles`; ฉาก `weapon_cube.tscn`) และ `scripts/weapon_b.gd` (ยิงพร้อมกันเป็นพัด `base_projectiles` 3 + โบนัส ห่างกัน `fan_angle_degrees` 12°; ฉาก `weapon_fan.tscn`). **เตือน:** เปลี่ยนสคริปต์ของโหนดในฉากแล้วค่า `@export` เดิมหาย (เคยทำให้ `projectile_scene` เป็น null) ต้องตั้ง Projectile Scene ใหม่ทุกครั้ง; สคริปต์ทดสอบ headless ที่อ้าง `Weapon`/`Player` ตรงๆ จะ error เรื่อง `GameState` ให้ใช้ duck typing (`"projectile_scene" in node`). ช่อง `projectile_scene` (ต้องลาก `scenes/projectile_cube.tscn` ใส่ใน Inspector — เคยลืมทำให้ error `instantiate` บน Nil), `damage` 15, `projectile_speed` 14, `fire_interval` 1.0, `max_range` 18; ทุก `fire_interval` หาศัตรูกลุ่ม `enemy` ที่ใกล้สุดในระนาบ XZ แล้วสร้างกระสุนเป็นลูกของ `player.get_parent()` (คือ `World` — ห้ามเพิ่มที่รากฉาก เพราะอยู่นอก SubViewport); ผู้เล่นที่ตายแล้วไม่ยิง
  - กระสุน `scenes/projectile_cube.tscn` + `scripts/projectile.gd` (`class_name Projectile`, `Area3D`): layer 0, mask 1+3 (ชนพื้น/กำแพงและศัตรู ไม่ชนผู้เล่น), วิ่งตาม `direction` เป็นเส้นตรง, `body_entered` -> ถ้าเป็นกลุ่ม `enemy` เรียก `Health.take_damage(damage)` แล้ว `queue_free()` (ชนอะไรก็หาย), หายเองเมื่อครบ `lifetime` 3 วินาที; กล่อง 0.5 ม. วัสดุ Toon สีเหลืองอ่อน ตัวชนทรงกลมรัศมี 0.45
  - ตรวจแล้วด้วยการจำลอง: ศัตรู 3 ตัวระยะ 10/13/16 ม. ถูกยิงตายที่ 1.5/3.4/5.3 วินาที (เลือด 20 → 5 → ตาย)
- **EXP/เลเวล** `scripts/experience.gd` (`class_name Experience`, โหนดลูกของ Player ชื่อ `Experience`): `level` เริ่ม 0, `base_exp_needed` 100, `growth` 1.15, signal `exp_changed(current, needed)` และ `leveled_up(new_level)`, `add_exp(amount)` ใช้ `while` ให้ข้ามหลายเลเวลได้
- **ออร์บ EXP** `scenes/exp_orb.tscn` + `scripts/exp_orb.gd` (`Area3D` layer 0 / mask 2 = Player; `exp_value` 10 เขียว; ลอยขึ้นลงด้วยการขยับเฉพาะโหนดลูก `Body`; เก็บเมื่อ `body_entered` และหาโหนดลูก `Experience` ของผู้เล่น; `_collected` กันเก็บซ้ำ). ศัตรู `enemy_cube.gd` มี `@export orb_scene` และ `_on_died()` สร้างออร์บที่เท้าด้วย `get_parent().add_child.call_deferred(orb)` (ต้อง deferred ไม่งั้น error "flushing queries"; ใช้ `orb.position` เพราะ World อยู่ที่ (0,0,0))
- **HUD** `scenes/hud.tscn` (`CanvasLayer`, อยู่ใต้ `Main` ต่ำกว่า `PixelContainer` เพื่อให้ผู้เล่นถูกสร้างก่อน และอยู่นอก SubViewport จึงคมเต็มความละเอียด) + `scripts/hud.gd` (กลุ่ม `hud`): สร้างช่อง `hud_slot.tscn` 6+6 ช่องด้วยโค้ด (`slot_count`), `add_item(card, level)` ใส่ไอคอนในช่องว่างแรกตาม `CardData.kind` (จำช่องไว้ใน `_slots` ครั้งต่อไปอัปเดตข้อความ `Lv.x` ที่ `LevelLabel` ในช่อง), ตอนเริ่มอ่าน `player.items` มาแสดง และฟัง `item_changed`, ฟังสัญญาณ `Experience`
- **การ์ดเลเวลอัป** `scripts/card_data.gd` (`class_name CardData`: id, display_name, description, icon, kind {WEAPON, PASSIVE}, weapon_scene, `levels: Array[CardLevel]` — index 0 = เลเวล 2 และ `max_level` = จำนวนแถว + 1) + `scripts/card_level.gd` (`class_name CardLevel`: description, damage_bonus, size_bonus, fire_rate_bonus เป็นเศษส่วน 0.05 = 5%, `projectile_bonus: int`) + `data/cards/*.tres` (`weapon_a.tres` = Weapon A ของ Cube; `test_weapon_*`/`test_passive_*` เป็นการ์ดทดสอบ) + `scenes/level_up_panel.tscn`/`scripts/level_up_panel.gd` (`CanvasLayer` layer 10, `process_mode` Always; `card_scene`, `card_pool`, `choices` ตั้งใน Inspector ของ `level_up_panel.tscn`; `_pending` คือคิว; ผู้เล่นคนเดียว → `get_tree().paused = true`) + `scenes/card_button.tscn`. Input Map: `card_1/2/3` = ปุ่ม 1/2/3
- **ตัวเกิดศัตรู** `scripts/enemy_spawner.gd`: คลื่นทุก `wave_interval` 8 วินาที (คลื่นแรกหลัง 2 วินาที), ศัตรู `base_enemies` 5 + `extra_per_wave` 2 ต่อคลื่น, คูณ (1 + 0.10 × (จำนวนผู้เล่น − 1)), เพดาน `max_alive` 60, เกิดที่วงแหวนห่างผู้เล่น 18–22 ม. ทิศสุ่มกระจาย ±50°, ดูดจุดเกิดเข้าหาจุดบน navmesh (`NavigationServer3D.map_get_closest_point`), ยกสูง 3.0 ม. ให้ตกลงมายืนเอง
- **ระบบนำทาง:** `NavigationRegion3D` ครอบ `Floor` และสิ่งกีดขวางทั้งหมด (Player/ศัตรู/กล้อง/ตัวเกิดต้องอยู่นอก), Parsed Geometry Type = Static Colliders, **Agent Radius 1.0** (Godot ปัดขึ้นเป็นผลคูณของ cell size 0.25), navmesh อยู่ที่ y≈1.5 (ผิวพื้น 1.0)
  - **ต้อง bake ใหม่ (ปุ่ม Bake NavigationMesh) และ Ctrl+S ทุกครั้งที่ย้าย/แก้กำแพงหรือกล่อง** — ข้อมูล navmesh ไม่อัปเดตเอง และการเปลี่ยนรัศมีโดยไม่ bake ไม่มีผล
  - Crate4/Crate5 (กำแพงทดสอบ) ตั้งอยู่ layer 3 โดยตั้งใจ เพื่อให้ผู้เล่นเดินทะลุไปทดสอบว่าศัตรูหาเจอ

## บทเรียน/ข้อควรจำ (เจอมาแล้ว)
- ฉาก UI ต้องดูในแท็บ 2D ของ editor ไม่ใช่ 3D
- ผูกสคริปต์กับโหนดราก (หรือโหนดที่ตั้งใจ) ไม่ใช่ลูก; สร้างไฟล์สคริปต์ใน FileSystem ไม่ได้ผูกให้เอง ต้อง Attach/ลากไปวางที่โหนด
- คัดลอกโหนดที่มี Shape แล้วต้อง Make Unique; ตัวชนต้องเป็นลูกโดยตรงของโหนดฟิสิกส์ (CharacterBody3D/StaticBody3D)
- **ห้ามบันทึกฉากตอนสคริปต์ที่ผูกอยู่มี error** Godot จะเขียน `= null` ทับค่าตั้งต้นของตัวแปร `@export` ลงในไฟล์ `.tscn` (ต้องกด ↶ รีเซ็ตทีละช่องหรือพิมพ์ค่าคืน)
- `class_name` ซ้ำกัน = ข้อผิดพลาด "hides a global script class"; `class_name` ห้ามใช้ในสคริปต์ที่ฝังในฉาก (built-in)
- เมนู Debug → Visible Navigation/Collision Shapes ช่วยดูตอนรัน (เห็นเพราะ shader มี `depth_draw_never`)
- ตัวชนทรงกลม/แคปซูลของศัตรูไม่เกี่ยวมุมกำแพงเหมือนกล่อง (ทดสอบแล้ว: กล่องติด 3/30 รอบ, ทรงกระบอก 0/30)
- โหนดรากที่ต้องมีช่อง Collision Layer/Mask ต้องเป็น `Area3D`/ฟิสิกส์บอดี้จริง (เคยสร้างออร์บเป็น `Node3D` แล้วไม่เห็นช่อง Collision แก้ด้วยคลิกขวา → Change Type)
- ห้ามเพิ่ม `Area3D`/ตัวชนกลางการประมวลผลฟิสิกส์ (เช่นตอนศัตรูตายจากกระสุน) ให้ใช้ `add_child.call_deferred(...)`
- `var x := GameState.selected_character` ใน editor อาจฟ้อง "Cannot infer the type" (autoload ยังไม่ถูกวิเคราะห์) → ระบุชนิดเอง `var x: CharacterData = ...`
- UI ใน Button/Container: ลูกที่เป็น `TextureRect` ต้องตั้ง Mouse Filter = Ignore ไม่งั้นแย่งคลิกจากปุ่ม; แผงที่ต้องใช้ตอนหยุดเกมต้องตั้ง `process_mode` = Always
- ระวังสร้างโหนดซ้ำผิดที่ใน scene UI (เคยมี `ExpBar` สองตัวทำให้ตัวบนวาดทับตัวจริง ดูแผง Scene ให้ดี)
- ฝาก: สคริปต์ที่สร้างในโฟลเดอร์ไม่ผูกกับโหนดให้เอง (เคยลืมผูก `exp_orb.gd` → ออร์บไม่ลอยและเก็บไม่ได้ทั้งที่ไม่มี error)

## ทดสอบเกมแบบ headless (สำหรับ Claude)
- สั่ง: `Godot_v4.7.2-stable_win64_console.exe --headless --path <โฟลเดอร์โปรเจกต์> -s <สคริปต์.gd> -- <อาร์กิวเมนต์>` (สคริปต์ `extends SceneTree` เก็บไว้นอกโปรเจกต์ เช่นโฟลเดอร์ scratchpad ไม่แตะไฟล์ผู้ใช้)
- โหลด `main.tscn` แล้วตั้งตำแหน่งผู้เล่น/ศัตรู (ตั้ง `position` ก่อน `root.add_child`), ปิด `EnemySpawner` ถ้าไม่ต้องการ, ตั้ง `player.set_physics_process(false)` ถ้าไม่ต้องการให้ผู้เล่นขยับ, พิมพ์ตำแหน่ง/ค่าในทุกๆ N เฟรมของ `_physics_process`
- bake navmesh ใหม่ในสคริปต์ต้องทำหลัง `add_child` และใน `_physics_process` เฟรมแรก (ไม่ใช่ใน `_initialize`)
- `--check-only` ไม่รู้จัก autoload (`GameState` จะขึ้น "Identifier not found" ซึ่งเป็นผลลวง)
- ถ้าจะทดลองแก้ไฟล์เพื่อเปรียบเทียบ ให้ก๊อปโปรเจกต์ไปโฟลเดอร์ชั่วคราวแล้วทดสอบที่สำเนา ไม่แตะของผู้ใช้
- Godot MCP: ถ้า tool ของ MCP ไม่โหลดในเซสชัน แต่ server ที่พอร์ต 3000 ทำงานอยู่ สามารถยิง JSON-RPC ตรงด้วย `curl` ได้ (`tools/call` ชื่อ tool + arguments)

## เวอร์ชัน Godot
- ใช้ Godot **4.7.2** ตลอดการพัฒนา (portable จากเว็บทางการ ติดตั้งแยกโฟลเดอร์ต่อเวอร์ชัน; ที่ออฟฟิศ: `D:\Just Some Test v2\Godot_v4.7.2-stable\`) เปิดโปรเจกต์ด้วยเวอร์ชันใหม่กว่าแล้วไฟล์จะถูกแปลงย้อนกลับไม่ได้ — **ห้ามอัปเดตกลางทาง** ถ้าจะอัปเดตเมื่อจบฟีเจอร์ใหญ่ ต้อง commit ลง Git ก่อน
- ปลั๊กอิน Godot MCP ถูกแก้ให้ใช้กับ 4.7.x ถ้าอัปเดต Godot ต้องตรวจก่อนว่ายังใช้ได้

## Godot MCP (ใช้ให้ Claude สั่งงาน/ตรวจ editor)
- ปลั๊กอิน: `addons/godot_mcp` (จาก DaxianLee/godot-mcp, MIT) — **แก้บั๊กเอง** ให้ใช้กับ Godot 4.7: `plugin.gd` เก็บ `get_editor_interface()` ไว้ใน `Engine.set_meta("godot_mcp_editor_interface", ...)` และ `tools/base_tools.gd` ดึงจาก meta นั้น (เพราะ `Engine.has_singleton("EditorInterface")` คืน false)
- เปิดโปรเจกต์ -> แผง GodotMCP ขวา -> **Start Server** (พอร์ต 3000) -> เปิด Claude Code ในโฟลเดอร์นี้ (`.mcp.json` ชี้ไป `http://127.0.0.1:3000/mcp`) แล้วอนุมัติ server `godot-mcp`
- เปิดได้ทีละโปรเจกต์เท่านั้น (พอร์ตชนกัน) และ Godot ที่ค้างบ่อยต้องเปิดใหม่ + Start Server ใหม่ทุกครั้ง
- ถ้า tool ตอบ "Editor interface not available" หรือ "Unknown tool category" ให้ปิด/เปิดปลั๊กอินใน Project Settings -> Plugins แล้ว Start Server ใหม่
- `.mcp.json` อยู่ที่ `D:\The Godot\POLYGONE` (และสำเนาที่ `D:\The Godot` ที่ผมเพิ่มไว้) ชี้ `http://127.0.0.1:3000/mcp`; ปลั๊กอินตั้ง Auto Start ไว้ แต่ server ขึ้นหลัง Godot เปิดโปรเจกต์ ถ้าเซสชัน Claude Code เริ่มก่อน Godot จะขึ้น `ECONNREFUSED` ให้เปิด Godot ก่อนแล้วเริ่มเซสชันใหม่; ตัวอย่าง curl: header `Accept: application/json, text/event-stream`, `tools/call` ชื่อ tool เช่น `editor_status` กับ `arguments: {"action":"get_info"}`, `scene_hierarchy` กับ `{"action":"get_tree"}` (ดูฉากที่เปิดอยู่)
- ตัวถามเส้นทาง navigation ของ MCP (`get_path`) ในตัว editor ไม่ตรงกับในเกมจริงเสมอไป ให้ใช้การจำลอง headless ยืนยัน

## หมายเหตุเครื่องทำงาน
- เครื่องที่ทำงาน (GT 730) เมนู/ดรอปดาวน์ใน Godot เปิดไม่ขึ้น (error "Failed to create sub window") แก้โดยเปิด Editor Settings -> Interface -> Editor -> **Single Window Mode** (ค่านี้เก็บในเครื่อง ไม่ได้อยู่ในโปรเจกต์; ตั้งในไฟล์ `editor_data/editor_settings-4.7.tres` ได้ตอนปิด Godot)
- เครื่องที่บ้าน (RTX 2060) ปกติ ไม่ต้องตั้ง

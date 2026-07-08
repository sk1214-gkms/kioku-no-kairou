# Stable Diffusion 用プロンプト集（コピペ・全13室＋ズーム＋差分）

SD（SDXL推奨）で背景を作るための**最新プロンプト**。Gemini版の反省（設定＝白慈館・グリミー・全室タイルでない・文字焼き込み禁止）を反映済み。
手順の土台は [SDローカル生成手順](StableDiffusion_ローカル生成手順.md)。**本ファイルのプロンプトを優先**（アセット仕様書§8より新しい）。

> ⚠ SDはGeminiと違い **2×2シートにしない**。**各壁・各ズームを9:16で1枚ずつ**生成し、**seed固定＋同一モデル＋STYLE_BASE固定**で「同じ館」に揃える。

---

## 1. STYLE_BASE（Positive の先頭に毎回貼る・固定）
```
dark painterly semi-realistic illustration, mobile escape-mystery game background, a decaying 1950s grand hall converted into a psychiatric institution, elegant old dark wood and cold clinical fixtures uneasily coexisting, unsettling but beautiful, unreliable dying-memory atmosphere, muted teal and sepia palette, near-black shadows, a single faint blood-red accent, dim cinematic single-source lighting, deep shadows, heavy vignette, subtle film grain, heavy decay (cracked peeling walls, black mold, water-damage streaks, rust, dust and debris), layered atmospheric depth, dust motes, faint low fog, first-person point of view, vertical 9:16 composition
```

## 1.5 奥行きのある部屋にする（森の洋館風・推奨オプション）
平坦な正面壁でなく、立体感のある室内にしたいとき。**STYLE_BASE の後ろ・各SUBJECTの前**にこれを足す：

**A｜層で出す（前景＋中景＋背景／おすすめ・整合ラク）**
```
interior seen with depth, a foreground element close to the camera, the focal furniture in the midground clearly visible, walls and floor receding into shadow, layered atmospheric haze between foreground midground and background
```
**B｜隅からのフルパース（最大の立体感・手間増）**
```
first-person view into a corner of the room, strong one/two-point perspective, floor and two walls receding deep into shadow, the focal furniture prominent in the midground
```

- **4方向の一貫性（奥行きを足すとき必須）**：`ControlNet`（**depth** か **mlsd/lineart**）に"部屋の隅"の簡単なレイアウト（ラフな線画/深度）を与えて**構図を固定**＋`IP-Adapter`（基準画=R1）＋**Seed固定**。→ 4枚が「同じ立体の部屋の別の角」に見える。
- **注意**：奥行きを強めるほど主役が小さく/斜めになりがち → `focal furniture prominent and clearly visible in the midground` を保つ。タップ位置(rect)は**主役が写った場所**に置けばOK（斜めでも可）。
- **迷ったら A**（正面寄り＋層）。破綻しにくく、それでも立体感は十分出る。

## 2. NEGATIVE（毎回そのまま）
```
text, letters, words, numbers, captions, label, watermark, signature, logo, ui, framing border, people, person, human, face, portrait of a real person, crowd, hands, fingers, deformed, mutated, extra limbs, bright, cheerful, high saturation, colorful, cartoon, anime, cel shaded, flat lighting, lowres, blurry, out of focus, jpeg artifacts, modern objects, smartphone, plastic, clean, pristine, brand new
```
※記号（○△□●）は描いてOK＝NEGATIVEには入れない。血・染みは各SUBJECTで指定（SDは検閲なし）。

## 3. 推奨設定（SDXL）
- 解像度：**832×1216**（縦9:16）。仕上げ Hires.fix：4x-UltraSharp / x1.5 / denoise 0.4 →最終 1080×1920目安
- Sampler：**DPM++ 2M Karras** ／ Steps：**30** ／ CFG：**6**
- Checkpoint：DreamShaper XL / Juggernaut XL / RealVisXL 等（**商用可**を確認）

## 4. 一貫性の出し方（SDの肝・ここが強み）
1. **固定するもの**：Checkpoint／STYLE_BASE／NEGATIVE／Sampler／Steps／CFG。**一つも途中で変えない**。
2. **同じ部屋の4方向**：まず北を良い1枚に。その **Seedを固定** し、SUBJECT の「focus」部分だけ東/南/西に差し替え→同じ部屋の4枚。
3. **部屋どうしを揃える**：
   - 一番強い＝**IP-Adapter**（基準画＝R1北を参照に入れる／weight 0.5〜0.7）または**スタイルLoRA**。
   - 併用推奨＝**ControlNet（depth or canny）**でラフな構図を固定（家具の位置ズレ防止）。
4. **ズーム（接写）は img2img が最適**：その壁の生成画を img2img に入れ、下のズームSUBJECTで **denoise 0.5〜0.65**。→ 壁の実ピクセルを保持したまま寄れる＝Geminiで苦労した「遠景と接写の食い違い」が起きない。

---

## 5. 各部屋 SUBJECT（Positive：STYLE_BASE の後ろに続ける）
> 記法：`北/N・東/E・南/S・西/W`。ファイル名 `r<n>_<dir>.png`。「focus on」を主役に。

### R1 白い部屋（精神科隔離室・白タイル）
- N: `focus on an old white porcelain washstand, a double-door cabinet below, a clouded cracked mirror above, damp pipes, grimy white subway tiles`
- E: `focus on a simple iron-frame bed, wrinkled sheets with dark dried blood spots, a stained pillow, a dark gap under the bed, white tiles`
- S: `focus on a cold sterile locked white door, a tiny peephole, a prominent keyhole, white tiled wall`
- W: `focus on a barred window, thick milky fog outside, cold backlight, white tiles`

### R2 準備室
- N: `focus on a wall-mounted glass-doored medicine cabinet, rows of old grimy bottles, a torn paper scrap wedged behind the bottles, peeling teal wall`
- E: `focus on a metal workbench with scattered papers and a half-open drawer, a stool, tiled lower wall, wood upper wall`
- S: `focus on a metal door with a frosted window and a small green card reader beside it, papers pinned on the wall`
- W: `focus on a flush even row of tall steel lockers side by side, one central locker has a small blank metal name-plate, wet mossy floor`

### R3 暗室（赤い安全灯）
- N: `red-safelight darkroom, focus on developing photo prints hung on strings against a dark wall`
- E: `red-safelight darkroom, focus on a wall clock with stopped hands, a faint dark spray-like trace beside it`
- S: `red-safelight darkroom, focus on a door fitted with a clockwork lock and a round dial face`
- W: `red-safelight darkroom, focus on an old electrical fuse box and a small blacklight switch, an illegible handwritten note pinned beside it`

### R4 書斎（暗い木・タイルではない）
- N: `dark wood-panelled study, focus on an ominous oil portrait in a heavy frame, an iron safe half-hidden behind the frame, parquet floor and rug`
- E: `dark wood-panelled study, focus on shelves packed with old medical books, fresh finger-grease gleaming on one spine, thick rug`
- S: `dark wood-panelled study, focus on a door with its knob removed, exposed mounting hardware`
- W: `dark wood-panelled study, focus on a medical chart pinned to the wall covered in scrawled illegible symbols, papers scattered on the floor`

### R5 診察室
- N: `focus on trembling scratch-like gouges in the plaster wall, medical charts pinned up messily`
- E: `focus on a leather examination table with an unnatural amount of dark blood, the shadow of restraint straps`
- S: `focus on a door with a four-dial alphabet combination lock`
- W: `focus on a locked medicine cabinet with a small control tag`

### R6 記録室
- N: `focus on a suspect investigation board covered with photos linked by red string, one blank slot in the centre`
- E: `focus on sheets of testimony and a gate lock log pinned in rows (illegible marks only)`
- S: `focus on a door with a numeric combination lock`
- W: `focus on a night-shift logbook, a page where the ink breaks off, faint traces of fresh tampering ink`

### R7 廊下（暗い廊下）
- N: `dark corridor, focus on pale footprints going away and returning with an uneven return stride, a faint weapon-shaped bleed on the wall`
- E: `dark corridor, focus on one-way bloody footprints and dark red smears on the wall`
- S: `dark corridor, focus on a door with a numeric lock, cold air drifting from beyond`
- W: `dark corridor, focus on muddy gardener's footprints with an even unnatural stride`

### R8 鏡の間（豪奢な木・タイルではない）
- N: `ornate hall of mirrors with dark wood and gilt frames, focus on a calm oil portrait and a small fogged mirror beside it`
- E: `ornate hall of mirrors with dark wood, focus on a large ornate standing mirror with an ordinary clear reflection`
- S: `ornate hall of mirrors with dark wood, focus on a heavy closed door`
- W: `ornate hall of mirrors with dark wood, focus on an old light switch on the wall`

### R9 標本室
- N: `focus on shelves of glass specimen jars (brains and organs in fluid), an empty syringe at the back`
- E: `focus on a workbench with amber fluid bottles and a drawer holding a needle`
- S: `focus on a door with a small hole shaped to insert a syringe`
- W: `focus on an old closed cupboard, a faint sense of something stirring inside`

### R10 監視室（隅に赤いデジタル崩壊ノイズ）
- N: `faint red digital corruption in the corners, focus on a powered-off recording terminal with a dark screen, a coffee-stained note`
- E: `faint red digital corruption in the corners, focus on banks of dark auxiliary monitors and a pile of unlabeled spare tapes`
- S: `faint red digital corruption in the corners, focus on a heavy closed door`
- W: `faint red digital corruption in the corners, focus on a large main-power lever and a dusty bundle of wiring`

### R11 手術室（赤い崩壊ノイズ）
- N: `faint red digital corruption in the corners, focus on a ceiling surgical lamp switched off and a sterilizer basin beside it`
- E: `faint red digital corruption in the corners, focus on a procedure chart and an old anesthesia machine`
- S: `faint red digital corruption in the corners, focus on a door with a control panel of ordered steps`
- W: `faint red digital corruption in the corners, focus on a tray of neatly lined surgical instruments (scalpel, needle-holder, a hemostat)`

### R12 証拠保管室（赤い崩壊ノイズ）
- N: `faint red digital corruption in the corners, focus on numbered evidence boxes on shelves, a single glove visible in one open box`
- E: `faint red digital corruption in the corners, focus on stacked case files, a night-shift logbook and autopsy memos`
- S: `faint red digital corruption in the corners, focus on a door with a timeline record panel`
- W: `faint red digital corruption in the corners, focus on a single stark crime-scene photograph pinned alone`

### R13 最後の扉（崩壊ノイズ最大）
- N: `heavy red digital corruption bleeding across the walls, focus on fragmentary carved glyph-like marks scattered on the wall (illegible, no real letters)`
- E: `heavy red digital corruption, focus on more fragmentary carved glyph-like marks across wall and beam (illegible)`
- S: `heavy red digital corruption, focus on a huge ominous final door with a large combination mechanism, light leaking from beyond`
- W: `heavy red digital corruption, focus on fragmentary carved glyph-like marks, the heaviest corruption in the corner`

---

## 6. ズーム（接写／subview背景）＝ img2img 推奨
その壁の生成画を **img2img** に入れ（denoise 0.5〜0.65）、下のSUBJECTで寄る。ファイル名は各room JSONの bg 名に合わせる。

- `r1_wash_zoom`（閉）: `extreme close-up of the same washstand, double-door cabinet CLOSED, clouded cracked mirror above`
- `r1_wash_zoom_open`（開）: `extreme close-up of the same washstand, double-door cabinet OPEN revealing a small rusty tin box inside, cracked mirror above`
- `r1_bed_zoom`: `extreme close-up looking down at the same iron bed, stained pillow, bloodstained wrinkled sheets, a dark gap under the bed with a rolled old newspaper`
- `r1_window_zoom`: `extreme close-up of the same barred window, worn sill with faint thin claw-scratch marks, thick fog beyond the bars`
- `r2_shelf_zoom`: `extreme close-up into the glass medicine cabinet, rows of old bottles, a torn paper scrap wedged behind the bottles`
- `r2_drawer_zoom`: `extreme close-up looking into an open metal workbench drawer, an old wooden-handled rubber reception stamp inside`
- `r2_locker_zoom`: `extreme close-up of a steel locker's small name-plate, a torn strip of an old medical chart hidden behind the blank plate`

> R3〜の他室もズームが要るものは同様に「その壁を img2img → 寄る」。room JSON の `subview.bg` 名で保存。

---

## 7. 状態差分（★）
その通常版を img2img/同seed に入れ、状態だけ変える。ファイル名 `<base>_<suffix>.png`。
- R3 `_lit`（4方向）: `+ blacklight ultraviolet on, everything bathed in eerie blue-violet UV glow instead of red, faint fluorescent hand-prints glowing on the north wall`
- R8 `_dark`（4方向）: `+ lights off, near-darkness lit by faint cold moonlight; on the east mirror a shadowy blood-spattered human silhouette appears (only inside the mirror)`
- R9 `_open`（4方向）: `+ the west cupboard door is open, revealing an empty dark interior`
- R10 `_on`（4方向）: `+ power on, the north recording terminal and east monitors glow cyan-blue with faint scanlines, cold monitor light filling the room`
- R1 北の棚 `r1_north_open`: 上の `r1_wash_zoom_open` と同じ（北=接写採用のため）

---

## 8. アイテム透過アイコン（15個）
**LayerDiffuse**（透過直出し）＋ 正方1024。STYLE_BASE は使わず、単体・暗い無地背景で：
```
a single <item>, centered, on a plain dark background, item icon, muted grimy texture, painterly
```
例：`a small brass key with a worn tag` / `a torn paper scrap` / `an old wooden-handled rubber stamp` / `an empty glass syringe` / `an amber medicine vial` / `a cold silver metal cylinder` 等。生成後 rembg で透過（LayerDiffuse不使用時）。

---

## 9. 今晩の進め方（最短）
1. R1北を1枚、STYLE_BASE＋§5(R1 N)＋§2NEG＋§3設定で**画風確定**。良ければ **Seed控える**。
2. Seed固定で R1 E/S/W → 4方向。**IP-Adapterに R1北を入れて**以降の全室のトーンを固定。
3. ズームは各壁を **img2img**（§6）。差分は §7。
4. `assets/images/rooms/<name>.png` に配置（SDは9:16直出しなのでスライス不要）。room JSONのbg名と一致させる。
5. まず**R1を通しで**（4壁＋ズーム＋北open）作って、SD運用を確立してから量産。

> 命名一覧：背景 `r1_north.png`…／R1ズーム `r1_wash_zoom(.._open) / r1_bed_zoom / r1_window_zoom`／R2ズーム `r2_shelf_zoom / r2_drawer_zoom / r2_locker_zoom`／差分 `r3_<dir>_lit`・`r8_<dir>_dark`・`r9_<dir>_open`・`r10_<dir>_on`。

---

## 10. 【Lv3 視点移動】R1のアート — "見渡し起点"で作る（重要）
視点移動モデル（[設計](ナビゲーション_Lv3視点移動_設計.md)・[r1.json](../data/deep_rooms/r1.json)）では、**まず見渡しを作り、そこから各接近ビューを派生**させる。順序を守らないと「遠くの洗面台と近くの洗面台が別物」になり没入が壊れる。

### ① 見渡し `r1_entrance`（最初に作る・1枚）
STYLE_BASE ＋ §1.5-B(フルパース) ＋：
```
first-person view standing in the centre of a small decaying 1950s psychiatric room looking across the room: an old white porcelain washstand with a cracked mirror on the left wall, a simple iron-frame bed with bloodstained sheets along the right wall, a barred foggy window, a cold white locked door; grimy white subway tiles, peeling walls, cracked floor, deep shadows, one bare hanging bulb, strong perspective depth
```
→ 保存 `r1_entrance.png`

### ② 各接近ビュー（①の見渡しから派生＝一致させる）
**やり方**：見渡し `r1_entrance` の**該当部分をトリミング → img2img（denoise 0.45〜0.6）**で寄る。または **IP-Adapterに r1_entrance を入れて**各接写を生成。プロンプトは各対象のclose-up：
| ノード | 保存名 | 対象のclose-up |
|---|---|---|
| at_washstand | `r1_washstand`（＋`r1_washstand_open`） | 洗面台正面・両開き棚（閉／開＋箱）・上に鏡 |
| at_bed | `r1_bed` | 鉄枠ベッド接写・枕・血のシーツ・下の隙間 |
| at_door | `r1_door` | 白い施錠扉・鍵穴 |
| at_window | `r1_window` | 鉄格子の窓・窓枠の爪痕・霧 |

- **一致が命**：見渡しに写った洗面台＝接近後の洗面台、が同じ形・同じ位置に見えること（img2img派生ならほぼ自動で一致）。
- `r1_washstand_open` は閉版から「両開きの扉が開き奥に錆びた小箱」で派生（棚を開ける演出用）。

### 配置
`assets/images/rooms/` に上記名で置く（9:16直出し・スライス不要）。置けば r1.json の各ノードが自動でその絵になる。**未配置のノードは暗転**するので、まず `r1_entrance` から。
> エントランスの4つの「進む」タップ位置(rect)は仮置き。`r1_entrance` が出たら実際の構図に合わせて私が調整します。

---

## 11. 【館の部屋ライブラリ】R2〜R13を一気に量産する
方針＝**豪華な館の一室をSDに作らせ→後で謎解き用に割り当て・調整**。下の**ベースは固定**、**末尾の一言だけ差し替え**て各部屋を出す。各部屋2〜3枚ずつQueue（seedはrandomize）→良いのを保存。

### ベース（Positiveの先頭・固定）
```
dark painterly semi-realistic illustration, interior of a decaying 1950s gothic mansion converted into a psychiatric institution, richly furnished and highly detailed, ornate crown moulding, wood wainscoting, faded damask wallpaper, aged period furniture, heavy drapes, a worn persian rug, brass fixtures, a bare hanging bulb, muted teal and sepia palette, near-black shadows, a single faint blood-red accent, dim cinematic lighting, heavy decay (peeling walls, black mold, water stains, dust, cobwebs), deep perspective view looking across the room, first-person, atmospheric depth, film grain, vertical 9:16
```
### Negative（固定）
```
text, letters, words, numbers, captions, label, watermark, signature, logo, ui, people, person, human, face, crowd, hands, deformed, bright, cheerful, high saturation, colorful, cartoon, anime, flat lighting, lowres, blurry, jpeg artifacts, modern objects, smartphone, clean, pristine, brand new
```
設定：832×1216 / dpmpp_2m + karras / steps 30 / cfg 6

### 部屋ごとの"末尾の一言"（ベースの後ろに付ける。`(...:数)`＝重み付け）
```
R2 準備室 : , a preparation room, (a tall glass-doored medicine cabinet full of old bottles:1.3), a metal workbench, a row of steel lockers
R3 暗室   : , a photographic darkroom, (developing photo prints hung on strings:1.3), an old wall clock, an electrical fuse box, EVERYTHING lit only by a deep red safelight glow   ← ※末尾のteal記述を「red safelight」に読み替え
R4 書斎   : , a study, (tall bookshelves packed with old medical books:1.3), a heavy desk, an ominous oil portrait in a gilt frame, a small iron safe
R5 診察室 : , an examination room, (a leather examination table with dark bloodstains and restraint straps:1.4), medical charts on the wall, a locked medicine cabinet
R6 記録室 : , a records office, (a wall covered with a suspect board of photos linked by red string:1.3), filing cabinets, stacks of papers and logbooks
R7 廊下   : , a long dark corridor with many closed doors, (pale and bloody footprints leading down the floor:1.3), faint dark smears on the wall
R8 鏡の間 : , a hall of mirrors, (several tall ornate gilt-framed mirrors on the walls:1.4), a lone chair
R9 標本室 : , a specimen room, (shelves of glass jars with preserved organs and brains in fluid:1.4), a workbench with medical vials and a syringe
R10 監視室: , a surveillance room, (a bank of old monitors and a recording terminal:1.4), a large electrical power lever, tangled wiring, faint red digital corruption in the corners
R11 手術室: , an operating room, (a surgical table under a large round surgical lamp:1.4), a tray of surgical instruments, an old anesthesia machine, faint red digital corruption
R12 証拠室: , an evidence storage room, (shelves of numbered evidence boxes:1.3), stacked case files, a single crime-scene photograph pinned to the wall, faint red digital corruption
R13 最後の扉: , a final chamber, (a huge ominous locked door with a large combination mechanism:1.5), carved glyph-like marks on the walls, heavy red digital corruption bleeding across the walls, faint light leaking from beyond the door
```
> R3暗室だけは「muted teal…」を消して赤い安全灯に。R10〜R13は末尾の red digital corruption が"崩壊の進行"。
> 各部屋、良い1枚が出たら保存 → `output/` から scp で回収 → 私に渡してくれれば **どの絵をどの部屋のどのノードに割り当て、謎をどう配置するか** をやります（R1と同じ要領で）。

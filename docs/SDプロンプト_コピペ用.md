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

### 11.1 部屋タイプ別の注意（無駄打ち防止・実地で判明）
「豪華な家具の館ベース」だと**設備部屋まで応接室**になってしまう。以下で使い分ける：
- **家具ベース(§11)でOK**：R2 / R4(本棚:1.5) / R6(相関板:1.4) / R7(廊下+扉) / R8(鏡:1.5) / R12(証拠箱:1.4)
- **"簡素な臨床室"ベースに差し替え**（家具の羅列を消す）：R5 / R9 / R11
  ```
  dark painterly semi-realistic illustration, a cold decaying clinical room inside an old 1950s psychiatric institution, grimy tiled and plaster walls, sparse and utilitarian, muted teal and sepia palette, near-black shadows, a single faint blood-red accent, dim cinematic lighting, heavy decay (peeling walls, black mold, rust, dust), deep perspective, first-person, atmospheric depth, film grain, vertical 9:16
  ```
  - R5: `, (a leather examination table with dark bloodstains and restraint straps:1.6), medical charts, a metal instrument cabinet`
  - R9: `, (tall shelves of glass jars with preserved organs and brains in fluid:1.6), a metal workbench with vials and a syringe`
  - R11: `, (a surgical table under a large round surgical lamp:1.6), surgical instruments, an old anesthesia machine, faint red digital corruption`
- **R3 暗室**：tealを消して赤安全灯 `:1.6`（§7/上記の修正版）。赤が弱ければNegativeの `high saturation` を削除。
- **R10 監視室**：簡素ベース＋`(banks of old dark monitors and a recording terminal:1.6), a large power lever, tangled wiring, faint red digital corruption` ＋ **Negativeから `modern objects` を削除**（消されるため）。
- **R13 最後の扉**：`(a huge ominous locked door with a combination mechanism:1.6), carved glyph-like marks, heavy red digital corruption, faint light from beyond`。
- 共通：主役が家具に埋もれたら重みを上げる（`:1.5→1.7`）。設備部屋は**家具の羅列語（period furniture, drapes, persian rug）を削る**と主役が立つ。

---

## 12. 【アニメ版・確定レシピ】全室Lv3視点・ノード別プロンプト（★現行の本命）
2026-07-09 方針転換：写真調 → **アニメ/マンガ調に全室統一**（[経緯メモ](../%E9%96%8B%E7%99%BA/)）。§1〜§11 の写真調は旧版。**以降はこの§12を使う**。
- モデル：**animagineXL31.safetensors**（Animagine XL 3.1）
- 設定：**euler_ancestral(euler a) / normal / steps 28 / cfg 6 / 832×1216 / batch 1**
- 生成後、`python tools/crop_916.py <入力> assets/images/rooms/<bg名>.png` で中央9:16化して配置（832→幅684）。
- **絵柄は全室共通で固定**（＝下の PREFIX / SUFFIX / NEGATIVE を一切変えない）。**変えるのは各室の「色調」と各ノードの「シーン」だけ**＝「同じ絵師の一つの館」に揃う。
- ナビ：全室が視点移動スイート。**R1を自宅実機で検証してからR2以降を1室ずつ視点化**（生成＝先行OK）。

### 最終プロンプトの組み立て
```
最終Positive = PREFIX + <各ノードのSCENE> + ", " + <各室のPALETTE> + SUFFIX
```

**PREFIX（固定・毎回先頭）** ※`first-person standing view`は人物召喚＋絵画調を招くので**入れない**（R1成功版に一致）
```
masterpiece, best quality, absurdres, (no humans:1.3), empty room, scenery, indoors, anime background art, illustration, manga style, bold ink lineart, cel shading, sharp clean lineart, high contrast,
```
**SUFFIX（固定・毎回末尾）**
```
, cracked walls, peeling paint, water stains, faint dark blood accents, eerie psychological horror mood, cinematic lighting, detailed background, vertical composition, sense of depth
```
**NEGATIVE（固定・全室共通）** ※人物・絵画調を強めに排除
```
photorealistic, photo, realistic, 3d, cgi, render, painterly, soft focus, watercolor, impressionist, sketch, motion blur, blurry, out of focus, lowres, (bad quality:1.2), text, letters, words, numbers, captions, label, watermark, signature, logo, ui, error, extra digits, jpeg artifacts, worst quality, low quality, people, person, 1girl, 1boy, human, character, silhouette, standing figure, shadow person, deformed
```
> **主役は必ず重み付け**：各SCENEの主対象を `(...:1.3)`（弱ければ1.5）で囲む。R2a棚が「無」になったのは主役が弱かったため。
> 錠前や刻印は**読める文字を焼かない**（`text/letters/numbers` はNegativeのまま）。ダイヤル・時計・刻印は「文字なしの機構/記号」で描かせ、数値・文字はアプリ側で重ねる。

### R1 白い部屋（cold）★見本・生成済
PALETTE: `muted teal and desaturated blue palette, cold moonlight, cracked white tiled walls`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_bed | `R1a/img` | `r1_bed` | `an old iron bed with wrinkled sheets and a single pillow, a small barred window` |
| at_washstand | `R1a_wash/img` | `r1_washstand` | `an old washstand with a white porcelain basin, an arched mirror above, a small cabinet under the basin, dark reddish water stains` |
| at_door | `R1a_door/img` | `r1_door` | `a heavy closed wooden door with a prominent keyhole, an old cracked clawfoot bathtub` |

### R2 準備室（cold steel）
PALETTE: `muted teal and cold steel-blue palette, dim overhead light`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_shelf | `R2a_shelf/img` | `r2_shelf` | `a tall glass-doored medicine cabinet full of old grimy bottles, a torn paper scrap wedged behind the bottles` |
| at_bench | `R2a_bench/img` | `r2_bench` | `a metal workbench with scattered papers and a half-open drawer, a stool` |
| at_locker | `R2a_locker/img` | `r2_locker` | `a row of tall steel lockers side by side, one locker with a small blank metal name-plate` |
| at_door | `R2a_door/img` | `r2_door` | `a metal door with a frosted window and a small card reader beside it` |

### R3 暗室（red safelight・teal禁止）
PALETTE: `near-black darkness lit only by a deep red safelight, ominous red glow, (red safelight:1.5)`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_devwall | `R3a_wall/img` | `r3_wall` | `developing photo prints hung on strings against a dark wall, trays of chemicals` |
| at_clock | `R3a_clock/img` | `r3_clock` | `a wall clock with stopped hands, a faint dark spray-like trace beside it` |
| at_door | `R3a_door/img` | `r3_door` | `a door fitted with a clockwork lock and a round blank dial face` |

### R4 書斎（warm wood）
PALETTE: `warm amber and sepia palette, candlelight, dark wood panelling, a worn persian rug`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_bookshelf | `R4a_shelf/img` | `r4_shelf` | `tall bookshelves packed with old medical books, fresh finger-grease gleaming on one spine` |
| at_desk | `R4a_desk/img` | `r4_desk` | `a heavy wooden writing desk with scattered papers and an oil lamp` |
| at_portrait | `R4a_portrait/img` | `r4_portrait` | `an ominous oil portrait in a heavy gilt frame on a wood-panelled wall` |
| at_safe | `R4a_safe/img` | `r4_safe` | `an iron safe half-hidden behind a portrait frame, a blank dial lock` |

### R5 診察室（clinical・簡素）
PALETTE: `cold clinical teal-green palette, sterile grimy tiled walls`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_couch | `R5a_couch/img` | `r5_couch` | `(a leather examination table with an unnatural amount of dark blood and shadowy restraint straps:1.4), medical charts on the wall` |
| at_cabinet | `R5a_cab/img` | `r5_cabinet` | `a locked metal medicine cabinet with a small control tag` |
| at_door | `R5a_door/img` | `r5_door` | `a clinical door with a four-dial combination lock (no readable characters)` |

### R6 記録室（grey + 赤い糸）
PALETTE: `dim desaturated grey palette, a single red-string accent, a dusty records office`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_board | `R6a_board/img` | `r6_board` | `(an investigation board covered with photos linked by red string:1.4), one blank slot in the centre` |
| at_files | `R6a_files/img` | `r6_files` | `a records desk with stacks of testimony papers and an open logbook` |
| at_door | `R6a_door/img` | `r6_door` | `a door with a numeric combination lock (blank dials, no readable numbers)` |

### R7 廊下（dark corridor）
PALETTE: `long dark corridor, cold moonlight, muted blue palette, strong one-point perspective`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_hall | `R7a_hall/img` | `r7_hall` | `a long corridor with many closed doors receding into shadow, pale footprints going away and returning on the floor, a faint weapon-shaped bleed on the wall` |
| at_door | `R7a_door/img` | `r7_door` | `a corridor door with a numeric lock, cold air drifting from beyond` |

### R8 鏡の間（ornate silver・暗転差分あり）
PALETTE: `ornate dark wood and gilt, cold silver palette, a hall of mirrors`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_mirror | `R8a_mirror/img` | `r8_mirror` | `(a large ornate gilt-framed standing mirror with an ordinary clear reflection:1.4)` |
| at_mirror(暗転) | `R8a_mirror_dark/img` | `r8_mirror_dark` | `SCENE同上 + lights off, near-darkness lit by cold moonlight, a shadowy blood-spattered human silhouette appears only inside the mirror` |
| at_switch | `R8a_switch/img` | `r8_switch` | `an old brass light switch on an ornate wood-panelled wall` |
| at_door | `R8a_door/img` | `r8_door` | `a heavy ornate closed door` |

### R9 標本室（formalin green・簡素）
PALETTE: `sickly formalin-green palette, cold glow through the jars, sparse clinical room`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_specimens | `R9a_jars/img` | `r9_specimens` | `(tall shelves of glass specimen jars with preserved brains and organs in fluid:1.5), an empty syringe at the back` |
| at_desk | `R9a_desk/img` | `r9_desk` | `a metal workbench with amber fluid bottles and a drawer holding a needle` |
| at_door | `R9a_door/img` | `r9_door` | `a door with a small hole shaped to insert a syringe` |

### R10 監視室（monitor glow・点灯差分あり）
PALETTE: `dark room, cold blue-green monitor glow, faint red digital corruption in the corners`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_monitors | `R10a_mon/img` | `r10_monitors` | `banks of old dark monitors and a recording terminal, a coffee-stained note` |
| at_monitors(点灯) | `R10a_mon_on/img` | `r10_monitors_on` | `SCENE同上 + power on, the monitors glow cyan-blue with faint scanlines, cold monitor light filling the room` |
| at_power | `R10a_power/img` | `r10_power` | `a large main-power lever and a dusty bundle of wiring` |
| at_door | `R10a_door/img` | `r10_door` | `a heavy closed door` |

### R11 手術室（surgical・簡素）
PALETTE: `cold sterile white and teal palette, surgical lamp glow, faint red digital corruption in the corners`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_table | `R11a_table/img` | `r11_table` | `(a surgical table under a large round surgical lamp:1.4), a sterilizer basin beside it` |
| at_tray | `R11a_tray/img` | `r11_tray` | `a tray of neatly lined surgical instruments, a scalpel and a hemostat` |
| at_door | `R11a_door/img` | `r11_door` | `a door with a control panel of ordered steps (blank, no readable text)` |

### R12 証拠室（cold grey）
PALETTE: `dim cold grey palette, a dusty evidence room, faint red digital corruption in the corners`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_evidence | `R12a_boxes/img` | `r12_evidence` | `shelves of numbered evidence boxes, a single glove visible in one open box` |
| at_photos | `R12a_photos/img` | `r12_photos` | `a desk with stacked case files and a single stark crime-scene photograph pinned alone` |
| at_door | `R12a_door/img` | `r12_door` | `a door with a timeline record panel` |

### R13 最後の扉（crumbling void・崩壊差分あり）
PALETTE: `crumbling desaturated void, heavy red digital corruption bleeding across the walls, faint light leaking from beyond`
| ノード | prefix | bg名 | SCENE |
|---|---|---|---|
| at_door | `R13a_door/img` | `r13_door` | `(a huge ominous final door with a large combination mechanism:1.5), fragmentary carved glyph-like marks around it (illegible), faint light from beyond` |
| at_door(崩壊) | `R13a_door_end/img` | `r13_door_end` | `SCENE同上 + the corruption at its most intense, walls dissolving into red noise` |

### 生成の運用
- **1室ずつ**：各ノード 25枚キュー（seedはrandomize）→ 良いのをローカルへscp → 私に渡す → 私が中央9:16化して `assets/images/rooms/<bg名>.png` に配置＋r*.jsonを視点スイート化。
- 主役が弱ければ `(...:1.4→1.7)` で重み上げ。臨床室(R5/R9/R11)は家具の羅列を足さない（簡素ベースのまま）。
- 差分bg（_dark/_on/_end）は**通常版をimg2img**（denoise 0.4〜0.5）で状態だけ変えると一致しやすい。

---

## 13. 【追加生成】1壁＝1ノード用の不足画像（2026-07-10 方針A）
R4以降は元の謎が**4壁ぶん**あり、生成済みの2〜3枚では足りないと判明。**元の4方向を「1壁＝1ノード」で忠実に視点化**するため、下の**不足壁・扉・状態差分だけ**を追加生成する。共通の **PREFIX / SUFFIX / NEGATIVE・設定は §12 と同じ**（`first-person standing view`は入れない）。各行は `PREFIX + <SCENE> + ", " + <PALETTE> + SUFFIX`。

> R1/R2/R3は変換済。R8はスイッチ画像待ち。既存で足りる壁は再生成不要。

### 13.1 不足「壁・扉」（最優先・各25枚）
| bg名(prefix) | SCENE（主役 `:1.4`） | PALETTE |
|---|---|---|
| `r4_door` | `(a heavy closed wooden study door with its brass knob removed, exposed mounting hardware:1.4)` | `warm amber and sepia palette, candlelight, dark wood panelling` |
| `r5_chart` | `(a cracked clinical wall covered with pinned medical charts and trembling scratch-like gouges carved into the plaster:1.4)` | `cold clinical teal-green palette, sterile grimy tiled walls` |
| `r6_log` | `(a records wall with a metal filing cabinet, pinned testimony papers and an open night-shift logbook on a desk:1.4)` | `dim desaturated grey palette, a dusty records office` |
| `r7_blood` | `(a long dark corridor floor with a trail of dark red bloody footprints and a weapon-shaped blood smear on the wall:1.4)` | `long dark corridor, cold moonlight, muted blue palette with dark red blood, strong one-point perspective` |
| `r7_mud` | `(a long dark corridor floor with a trail of muddy gardener's footprints:1.4)` | `long dark corridor, cold moonlight, muted blue palette, strong one-point perspective` |
| `r9_cabinet` | `(an old tall closed wooden cupboard against the wall, a faint long shadow stirring behind its doors:1.4)` | `sickly formalin-green palette, cold glow, sparse clinical room` |
| `r11_chart` | `(a wall with a pinned procedure chart and an old anesthesia machine beside it:1.4)` | `cold sterile white and teal palette, surgical lamp glow, faint red digital corruption in the corners` |
| `r12_files` | `(shelves and a desk stacked with case files, a night-shift logbook and an autopsy memo:1.4)` | `dim cold grey palette, a dusty evidence room, faint red digital corruption in the corners` |
| `r13_glyphs` | `(a crumbling wall and beam covered with fragmentary carved glyph-like marks, illegible:1.4)` | `crumbling desaturated void, heavy red digital corruption bleeding across the walls, faint light` |
| `r10_aux`（任意） | `(a bank of smaller auxiliary CRT monitors and a pile of unlabeled spare tapes:1.4)` | `dark room, cold blue-green monitor glow, faint red digital corruption in the corners`（※r10_monitors再利用でも可） |

### 13.2 R8（スイッチ＝§前掲の改善プロンプト・扉/鏡は採用済R8a#9・R8b#7）
| bg名(prefix) | SCENE | 備考 |
|---|---|---|
| `r8_switch` | `extreme close-up of (a single old toggle light switch on a rectangular wall plate:1.6), one small flip lever, mounted on a cracked plaster wall` | Negativeに `door, doorknob, door handle, lock, keyhole, ornate brass, gilt fittings, chandelier` を追加 |

### 13.3 状態差分（第2バッチ・**通常版をimg2img** denoise0.4〜0.5）
| bg名 | 元画像 | 加える語 |
|---|---|---|
| `r3_wall_lit` | r3_wall | `blacklight ultraviolet ON, everything bathed in eerie blue-violet UV glow, faint glowing handprints on the wall` |
| `r8_mirror_dark` | r8_mirror | `lights off, near-darkness lit by cold moonlight, a shadowy blood-spattered figure appears only inside the mirror reflection`（Negativeから人物語を外す＝§前掲） |
| `r9_cabinet_open` | r9_cabinet | `the cupboard doors are open, revealing an empty dark interior` |
| `r10_monitors_on` | r10_monitors | `powered ON, screens glowing cyan-blue with faint scanlines, cold monitor light filling the room` |

### 13.4 各室の「1壁＝1ノード」割り当て（変換時の対応表）
- **R4**: N=portrait(+safe subview r4_safe) / E=r4_shelf(books) / W=r4_desk(暗号パネル) / S=**r4_door**
- **R5**: N=**r5_chart**(刻み) / E=r5_couch(診察台) / W=r5_cabinet(薬棚) / S=r5_door
- **R6**: N=r6_board(相関板+尋問) / E=r6_files(証言) / W=**r6_log**(証言+日誌) / S=r6_door
- **R7**: N=r7_hall(白足跡) / E=**r7_blood** / W=**r7_mud** / S=r7_door
- **R9**: N=r9_specimens(標本棚) / E=r9_desk(作業台) / W=**r9_cabinet**(隠し戸棚・chase) / S=r9_door
- **R10**: W=r10_power / N=r10_monitors(scrub) / E=**r10_aux**(補助M) / S=r10_door
- **R11**: N=r11_table(無影灯+消毒槽) / E=**r11_chart**(カルテ+麻酔器) / W=r11_tray(器具) / S=r11_door
- **R12**: N=r12_evidence(箱+手帳) / E=**r12_files**(ファイル/日誌/検視) / W=r12_photos(現場写真) / S=r12_door
- **R13**: 刻印wall=**r13_glyphs**（6刻印を不可視ホットスポットで） / S=r13_door
> 太字＝今回追加生成する画像。それ以外は配置済みを流用。揃えば各室、元の各wallのオブジェクトをそのままノードに移すだけ＝**パズル完全保持**でクリーン変換できる。

---

## 14. 【アイテムアイコン】アニメ調・全16個（透過PNG）
インベントリ用の小アイコン。**単体・正方・プレーン背景で生成 → 背景除去(透過) → 縮小**。部屋と同じアニメ調（インク線＋セル塗り）で。**文字は焼かない**（Negativeで排除）。
- 設定：**1024×1024（正方）** / animagineXL31 / euler a / steps 28 / cfg 6
- 保存名：`assets/images/items/<id>.png`（透過）。※現状 `item_r1_wire` が欠品・他は仮画像→差し替え。

### PREFIX（先頭・固定）
```
masterpiece, best quality, anime, manga style, bold ink lineart, cel shading, a single game item icon of
```
### SUFFIX（末尾・固定）
```
, centered, isolated on a plain flat neutral grey background, soft rim light, muted grimy texture, slight wear, no text
```
### NEGATIVE（固定）
```
photorealistic, photo, 3d, cgi, render, text, letters, words, numbers, watermark, signature, logo, multiple objects, hand, fingers, person, cluttered background, scenery, room, blurry, lowres, (bad quality:1.2), deformed
```

### 各アイテム（PREFIX + 下記 + SUFFIX）
| id（保存名） | ラベル | SUBJECT |
|---|---|---|
| item_r1_wire | 折れた針金 | `an old bent rusty thin piece of wire` |
| item_r1_key | 小さな鍵 | `a small old brass key with a worn blank paper tag` |
| item_frag_a | 破れた紙片(左) | `the torn left half of an old paper scrap, ragged torn right edge` |
| item_frag_b | 破れた紙片(右) | `the torn right half of an old paper scrap, ragged torn left edge` |
| item_frag_c | カルテ担当医欄 | `a small torn scrap from a medical chart` |
| item_chart_half | 復元しかけのカルテ | `an old medical chart partly reassembled from taped torn pieces, one corner still missing` |
| item_pass | 復元カルテ(通行証) | `a restored old medical chart document used as a pass` |
| item_stamp | 受付印 | `an old wooden-handled round rubber stamp` |
| item_pass_valid | 受理印つき通行証 | `an old pass document with a single red circular ink stamp mark` |
| item_knob | ドアノブ | `a single ornate brass doorknob` |
| item_syringe_empty | 空のシリンジ | `a single empty glass syringe without a needle` |
| item_needle | 注射針 | `a single steel hypodermic needle` |
| item_vial | 薬液 | `a small glass vial of amber medicine fluid` |
| item_syringe_loaded | 針付きシリンジ | `a glass syringe with a needle attached, empty barrel` |
| item_syringe_full | 薬液入りシリンジ | `a glass syringe with a needle, barrel filled with amber fluid` |
| item_culprit_evidence | 金属製の筒 | `a small cold silver metal cylinder` |

### 透過にする（背景除去）
生成はプレーン背景の不透過PNG→**背景を抜いて透過PNG**にする：
- **推奨：ComfyUIの背景除去ノード**（`rembg` 系カスタムノード等）を生成の後段に足す → そのまま透過保存。
- または **Spark上で rembg**：`pip install rembg` → `rembg i in.png out.png`（Sparkはネット可）。
- 仕上げ：256px程度に縮小して `assets/images/items/<id>.png` へ（インベントリは18px表示だが元は大きめで可）。

> 補足：18px表示なので細密さより**シルエットの分かりやすさ**優先。合成中間物（chart_half/pass/syringe_loaded等）は元＋αで“途中感”を出すと親切。

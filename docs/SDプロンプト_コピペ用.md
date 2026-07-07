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

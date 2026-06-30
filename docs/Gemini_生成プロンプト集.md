# Gemini 画像生成プロンプト集 — アムネジィ・ケース

> **目的**：まず **Gemini（Gemini 2.5 Flash Image＝通称 Nano Banana）でテスト生成**するための、**画像1枚ごとにコピペして即使えるプロンプト**を全点まとめた一覧。
> 元になる被写体・画風は [アセット仕様書 §8](アセット仕様書.md#8-生成プロンプト集画像ごと) と同じ。本書はそれを **Gemini 流（散文・ネガティブ欄なし・会話で画風固定）** に作り替えたもの。
> ファイル名は **コードと一致**させること（保存先は §0 の対応表）。

---

## 0. Gemini で使うときの要点（先に読む）

Midjourney/SD と作法が違う。ここを押さえると失敗が激減する。

1. **散文で書く**：Geminiはキーワード羅列より「**情景を文章で描写**」した方が忠実。本書のプロンプトはそのまま貼ればよい文章にしてある。
2. **ネガティブ欄は無い**：「〜を入れない」は文中で言う（各プロンプト末尾に `No text, no people.` 等を内包済み）。
3. **縦横比**：
   - **背景は 9:16（縦長）**、**アイテム/結末/マーカーは指定どおり**。
   - **gemini.google.com（アプリ）** は比率指定が弱い → 文中の `vertical 9:16 composition` で誘導し、はみ出しは後でトリミング。
   - **Google AI Studio / API** なら **aspect ratio を 9:16 / 1:1 に明示設定**できる。厳密にやるならこちら。
4. **画風の統一はこれが命**（→ §1 の手順）：1枚目を「基準画」として作り、**2枚目以降はその画像を添付して「この画風そのままで」と指示**する。Gemini は会話・参照画像で画風を引き継ぐのが得意。
5. **検閲（流血・自傷）**：Gemini も `blood / gore / self-harm / corpse` 等は弾かれやすい。本書は **婉曲表現を最初から埋め込み**、赤や生々しさは「**後でPhotoshop等で加筆**」前提（→ 各所の ⚠️）。
6. **文字・数字は崩れる**：時計の `3:45`、暗号の `0415 / 6271` 等は **Geminiが正しく描けない**ことが多い。**重要な数字は後から手で入れる**のが安全（プロンプトでは「数字の存在」だけ示唆）。
7. **透過PNG**：Gemini は完全な透過を直接は出しにくい。アイテムは **無地背景で生成 → remove.bg / Photoshop「背景を削除」/ rembg** で透過化。

> ⚠️ **商用ライセンス確認**：広告収益＝商用。Gemini/Imagen 出力の商用可否は**利用中プランの最新規約を必ず確認**。

### 保存先パス（コードと一致）
| 種別 | 置き場所 | 例 |
|---|---|---|
| 部屋背景 | `assets/images/rooms/<roomId>_<dir>.png` | `r6_north.png`（dir＝north/east/south/west）|
| アイテム | `assets/images/items/<itemId>.png` | `item_r1_key.png` |
| ドア・マーカー・結末・その他 | 任意（§2/§5/§6の名前で） | `door_final.png` 等 |

---

## 1. 画風を統一する手順（テストでも最初にこれ）

1. **基準画を1枚作る**：おすすめは **R1 北（白い部屋・洗面台）**。§3 の `R1 / north` を貼って、納得いくまで再生成。これが「美術の聖典」。
2. **2枚目以降**：Gemini に**基準画を添付**して、こう前置きしてから各プロンプトを貼る：
   ```
   Use the exact same art style, color palette, lighting, brushwork and mood as this reference image.
   Keep it consistent — same vintage gothic-medical world, same teal-sepia tones, same blood-red accent.
   Now render this new scene:
   ```
3. **同じ部屋の4方向**：直前の方向の画像も添付し「same room, same furniture style, now looking at the [east] wall」と足すと、壁が繋がって見える。
4. 仕上げに **全画像へ同じ色調補正（ティール&セピア＋黒締め＋粒状＋ビネット）** をかけると一発で“同じ世界”になる（Photoshopのバッチ推奨）。

> 本書の各プロンプトには画風文を**毎回フル内包**してある（単体でも使える）が、**統一を取るなら必ず §1 の参照画像方式**を併用すること。

---

## 共通の画風文（STYLE — 各背景プロンプトに内包済み）

参考までに分離して掲示（各プロンプトには既に含まれている）：

```
A dark, painterly, semi-realistic illustration. Vintage 1950s gothic western-mansion
interior that is secretly a sterile medical facility — the two worlds bleed together.
Muted teal-and-sepia palette with a single accent of blood red. Dim cinematic lighting,
oppressive and uncanny, with a faint feeling that this place is a reconstructed false
memory. Vertical 9:16 composition. No text, no letters, no people.
```

---

## 2. ドア（4枚）

各プロンプトに `front view, no text, no people.` を内包。背景と同じ画風で。

### door_white_wood
```
A dark painterly semi-realistic illustration in a vintage 1950s gothic-medical style,
muted teal-and-sepia palette with a faint blood-red accent, dim cinematic uncanny lighting.
Subject: an old, worn white-painted wooden door seen from the front, slightly aged and grimy,
set into a dim mansion wall. Vertical composition. No text, no people.
```

### door_carved
```
A dark painterly semi-realistic illustration in a vintage 1950s gothic-medical style,
muted teal-and-sepia palette with a faint blood-red accent, dim cinematic uncanny lighting.
Subject: a heavy, ornately carved gothic wooden door seen from the front, imposing and old,
deep relief carvings, set into a dim mansion wall. Vertical composition. No text, no people.
```

### door_lock_pad
```
A dark painterly semi-realistic illustration in a vintage 1950s gothic-medical style,
muted teal-and-sepia palette with a faint blood-red accent, dim cinematic uncanny lighting.
Subject: an old door fitted with a metal numeric combination lock / dial mechanism, seen
from the front, worn brass and steel. Vertical composition. No legible text, no people.
```

### door_final（R13）
```
A dark painterly semi-realistic illustration in a vintage 1950s gothic-medical style,
muted teal-and-sepia palette with a strong blood-red accent, ominous dim lighting.
Subject: a massive final door of engraved iron and stone covered in cryptic carved
inscriptions, seen from the front, monumental and foreboding, faint red digital glitches
creeping at the edges. Vertical composition. No people.
```

---

## 3. 部屋背景（R1〜R13 × 東西南北 = 52枚）

各プロンプトは**単体で完結**（画風文を内包）。`{}` はズーム/拡大画像のヒント、★ は §4 の状態差分も別途必要な面。
**R10〜R13 は崩壊表現**として末尾に `Faint red digital glitches and data-corruption artifacts creep into the edges.` を内包。

### 第1章

#### R1 白い部屋 — `r1_north` / `r1_east` / `r1_south` / `r1_west`
**north（洗面台）**
```
A dark painterly semi-realistic illustration. Vintage 1950s gothic western-mansion interior
that is secretly a sterile medical facility; muted teal-and-sepia palette with a faint blood-red
accent; dim cinematic uncanny lighting; reconstructed-false-memory mood. Scene: a small bare
asylum-like white room, the north wall dominated by an old porcelain washstand with a small
cabinet underneath. Vertical 9:16 composition. No text, no people.
```
**east（ベッド・染み）** ⚠️染みは赤を後加筆
```
A dark painterly semi-realistic illustration. Vintage 1950s gothic mansion-meets-medical
white room; muted teal-and-sepia palette with a faint reddish accent; dim uncanny lighting.
Scene: the east side, a simple iron-framed bed with old wrinkled sheets bearing dark
irregular reddish-brown stains. Vertical 9:16 composition. No text, no people.
```
**south（施錠扉）**
```
A dark painterly semi-realistic illustration. Vintage 1950s gothic mansion-meets-medical
white room; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting.
Scene: the south wall, a plain locked white wooden door, the only way out, slightly menacing.
Vertical 9:16 composition. No text, no people.
```
**west（鉄格子の窓・霧）**
```
A dark painterly semi-realistic illustration. Vintage 1950s gothic mansion-meets-medical
white room; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting.
Scene: the west wall, a barred window with thick impenetrable fog pressing against the glass
outside, cold pale light. Vertical 9:16 composition. No text, no people.
```

#### R2 準備室 — `r2_north` / `r2_east` / `r2_south` / `r2_west`
**north（薬棚 `{引き出し奥：紙片左}`）**
```
A dark painterly semi-realistic illustration. Vintage 1950s gothic-medical preparation room;
muted teal-and-sepia palette with a faint blood-red accent; dim cinematic uncanny lighting.
Scene: the north wall, a tall old wooden medicine cabinet with many small drawers and rows
of glass vials behind glass. Vertical 9:16 composition. No text, no people.
```
**east（作業台・紙片右）**
```
A dark painterly semi-realistic illustration. Vintage 1950s gothic-medical preparation room;
muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene: the
east side, a cluttered wooden worktable with scattered torn paper scraps, ink and old tools.
Vertical 9:16 composition. No legible text, no people.
```
**south（通行証式の扉）**
```
A dark painterly semi-realistic illustration. Vintage 1950s gothic-medical preparation room;
muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene: the
south wall, a locked door with an old document slot / permit reader beside it. Vertical 9:16
composition. No legible text, no people.
```
**west（ロッカー）**
```
A dark painterly semi-realistic illustration. Vintage 1950s gothic-medical preparation room;
muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene: the
west wall, a row of old dented metal lockers, one slightly ajar. Vertical 9:16 composition.
No text, no people.
```

#### R3 暗室 — `r3_west` / `r3_north`★ / `r3_east` / `r3_south`
**west（配電盤・ブラックライト）★**
```
A dark painterly semi-realistic illustration. A 1950s photography darkroom inside a gothic-medical
mansion; deep teal-and-sepia shadows lit by a dim red safelight, faint blood-red accent, uncanny.
Scene: the west wall, an old electrical breaker panel with switches, a black-light fixture mounted
nearby. Vertical 9:16 composition. No text, no people.
```
**north（現像壁 `{要ライトON}`）★** ⚠️数字は後入れ
```
A dark painterly semi-realistic illustration. A 1950s photography darkroom inside a gothic-medical
mansion; deep teal-and-sepia shadows, dim red safelight, faint blood-red accent, uncanny. Scene:
the north wall, developing photographs pinned in rows, drying on lines, damp and curling.
Vertical 9:16 composition. No legible text, no people.
```
**east（止まった時計 03:45 ＋①記憶の断片）** ⚠️時計の針=3時45分を後で正確に
```
A dark painterly semi-realistic illustration. A 1950s photography darkroom inside a gothic-medical
mansion; deep teal-and-sepia shadows, dim red safelight, faint blood-red accent, uncanny and tense.
Scene: the east wall, a stopped antique wall clock, its hands frozen at roughly a quarter to four.
Vertical 9:16 composition. No people.
```
**south（数字錠の扉）**
```
A dark painterly semi-realistic illustration. A 1950s photography darkroom inside a gothic-medical
mansion; deep teal-and-sepia shadows, dim red safelight, faint blood-red accent, uncanny. Scene:
the south wall, a locked door with an old metal numeric combination lock. Vertical 9:16
composition. No legible text, no people.
```

#### R4 書斎（分岐①）— `r4_north` / `r4_west` / `r4_south` / `r4_east`
**north（氷室の肖像 `{裏に金庫→ドアノブ}`）**
```
A dark painterly semi-realistic illustration. A gothic study inside a mansion that is secretly a
medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim cinematic uncanny
lighting. Scene: the north wall, a large oil portrait of a stern cold old professor in a heavy frame.
Vertical 9:16 composition. No text, no people.
```
**west（暗号パネル・獣の並び）**
```
A dark painterly semi-realistic illustration. A gothic study inside a mansion-medical facility;
muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene: the west
wall, an antique puzzle panel engraved with a row of carved animal/beast figures in sequence.
Vertical 9:16 composition. No legible text, no people.
```
**south（取付部の扉・ノブ欠落）**
```
A dark painterly semi-realistic illustration. A gothic study inside a mansion-medical facility;
muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene: the south
wall, a heavy door whose doorknob is conspicuously missing, leaving a bare metal fitting.
Vertical 9:16 composition. No text, no people.
```
**east（本棚）**
```
A dark painterly semi-realistic illustration. A gothic study inside a mansion-medical facility;
muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene: the east
wall, towering old bookshelves crammed with worn leather volumes, dust motes in dim light.
Vertical 9:16 composition. No legible text, no people.
```

### 第2章

#### R5 診察室 — `r5_north` / `r5_east` / `r5_south` / `r5_west`
**north（カルテ・数字→文字）** ⚠️数字は後入れ
```
A dark painterly semi-realistic illustration. A 1950s psychiatric examination room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim clinical
uncanny lighting. Scene: the north wall, a large medical wall chart covered in grids of figures.
Vertical 9:16 composition. No legible text, no people.
```
**east（血の付いた診察台）** ⚠️血は後加筆
```
A dark painterly semi-realistic illustration. A 1950s psychiatric examination room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a reddish accent; dim clinical uncanny
lighting. Scene: the east side, an old leather examination couch with dark irregular reddish-brown
stains on it. Vertical 9:16 composition. No text, no people.
```
**south（文字錠の扉）**
```
A dark painterly semi-realistic illustration. A 1950s psychiatric examination room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the south wall, a locked door fitted with an old letter-dial combination lock.
Vertical 9:16 composition. No legible text, no people.
```
**west（薬棚）**
```
A dark painterly semi-realistic illustration. A 1950s psychiatric examination room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the west wall, a locked steel-and-glass drug cabinet full of bottles and vials.
Vertical 9:16 composition. No legible text, no people.
```

#### R6 記録室 — `r6_north` / `r6_east` / `r6_west` / `r6_south`
**north（容疑者表 ＋①記憶の断片）**
```
A dark painterly semi-realistic illustration. A dim 1950s archive/records room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the north wall, a large suspect investigation board with pinned portraits and
threads connecting them. Vertical 9:16 composition. No legible text, no people.
```
**east（証言A）**
```
A dark painterly semi-realistic illustration. A dim 1950s archive/records room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the east wall, a single aged testimony document pinned up, lit by a small lamp.
Vertical 9:16 composition. No legible text, no people.
```
**west（証言B）**
```
A dark painterly semi-realistic illustration. A dim 1950s archive/records room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the west wall, another aged testimony document pinned up, slightly different,
lit by a small lamp. Vertical 9:16 composition. No legible text, no people.
```
**south（数字錠の扉）**
```
A dark painterly semi-realistic illustration. A dim 1950s archive/records room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the south wall, a locked door with an old metal numeric combination lock,
flanked by old filing cabinets. Vertical 9:16 composition. No legible text, no people.
```

#### R7 廊下 — `r7_north` / `r7_east` / `r7_west` / `r7_south`
**north（白い足跡=本物 ＋①記憶の断片）**
```
A dark painterly semi-realistic illustration. A long dim mansion corridor that is secretly a
medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting.
Scene: looking north down the corridor, a clear trail of pale white chalky footprints leading away
into the gloom. Vertical 9:16 composition. No text, no people.
```
**east（血の足跡・ニセ）** ⚠️赤は後加筆
```
A dark painterly semi-realistic illustration. A long dim mansion corridor / medical facility;
muted teal-and-sepia palette with a reddish accent; dim uncanny lighting. Scene: the east branch,
a trail of dark reddish-brown footprints on the floor, ominous and misleading. Vertical 9:16
composition. No text, no people.
```
**west（泥の足跡・ニセ）**
```
A dark painterly semi-realistic illustration. A long dim mansion corridor / medical facility;
muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene: the west
branch, a trail of muddy brown footprints on the floor, ominous and misleading. Vertical 9:16
composition. No text, no people.
```
**south（数字錠の扉）**
```
A dark painterly semi-realistic illustration. A long dim mansion corridor / medical facility;
muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene: the south
end of the corridor, a locked door with an old metal numeric combination lock. Vertical 9:16
composition. No legible text, no people.
```

#### R8 鏡の間（分岐②）— `r8_west` / `r8_north` / `r8_east`★ / `r8_south`
**west（照明スイッチ）★**
```
A dark painterly semi-realistic illustration. A mirror chamber inside a gothic mansion-medical
facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene:
the west wall, an old wall-mounted light switch / brass toggle, alone on the wall. Vertical 9:16
composition. No text, no people.
```
**north（穏やかな肖像）**
```
A dark painterly semi-realistic illustration. A mirror chamber inside a gothic mansion-medical
facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene:
the north wall, a calm gentle oil portrait of the old professor, kindly expression, heavy frame.
Vertical 9:16 composition. No text, no people.
```
**east（鏡 `{暗転時：反転数字／返り血の自分}`）★** ⚠️数字は後入れ・赤は後加筆
```
A dark painterly semi-realistic illustration. A mirror chamber inside a gothic mansion-medical
facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene:
the east wall, a large antique mirror in an ornate frame, its reflection slightly wrong and
unsettling. Vertical 9:16 composition. No text, no people.
```
**south（数字錠の扉）**
```
A dark painterly semi-realistic illustration. A mirror chamber inside a gothic mansion-medical
facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene:
the south wall, a locked door with an old metal numeric combination lock. Vertical 9:16
composition. No legible text, no people.
```

#### R9 標本室 — `r9_north` / `r9_east` / `r9_west` / `r9_south`
**north（標本棚 `{奥：空シリンジ}`）**
```
A dark painterly semi-realistic illustration. A specimen room inside a gothic mansion-medical
facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene:
the north wall, tall shelves of old formalin specimen jars holding pale preserved organs, eerie.
Vertical 9:16 composition. No text, no people.
```
**east（薬液の瓶）**
```
A dark painterly semi-realistic illustration. A specimen room inside a gothic mansion-medical
facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene:
the east side, a workbench holding a small glass vial of pale liquid under a focused lamp.
Vertical 9:16 composition. No text, no people.
```
**west（隠し戸棚 `{奥：金属製の筒}`）**
```
A dark painterly semi-realistic illustration. A specimen room inside a gothic mansion-medical
facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene:
the west wall, a concealed cabinet hidden in the paneling, slightly ajar revealing darkness within.
Vertical 9:16 composition. No text, no people.
```
**south（注射器を挿す扉）**
```
A dark painterly semi-realistic illustration. A specimen room inside a gothic mansion-medical
facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny lighting. Scene:
the south wall, a locked door with a strange syringe-shaped slot mechanism beside it. Vertical
9:16 composition. No text, no people.
```

### 第3章（崩壊表現入り）

#### R10 監視室 — `r10_west` / `r10_north`★ / `r10_east`★ / `r10_south`
**west（主電源）★**
```
A dark painterly semi-realistic illustration. A 1950s surveillance room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the west wall, a large industrial main power switch / lever on the wall, off.
Faint red digital glitches and data-corruption artifacts creep into the edges. Vertical 9:16
composition. No text, no people.
```
**north（モニターA `{要通電}`）★**
```
A dark painterly semi-realistic illustration. A 1950s surveillance room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the north wall, a bank of old dark CRT security monitors, screens off and dead.
Faint red digital glitches creep into the edges. Vertical 9:16 composition. No text, no people.
```
**east（モニターB `{要通電}`）★** ⚠️数字は後入れ
```
A dark painterly semi-realistic illustration. A 1950s surveillance room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the east wall, another bank of old dark CRT security monitors, screens off.
Faint red digital glitches creep into the edges. Vertical 9:16 composition. No text, no people.
```
**south（数字錠の扉）**
```
A dark painterly semi-realistic illustration. A 1950s surveillance room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the south wall, a locked door with an old metal numeric combination lock. Faint
red digital glitches creep into the edges. Vertical 9:16 composition. No legible text, no people.
```

#### R11 手術室 — `r11_north` / `r11_east` / `r11_west` / `r11_south`
**north（無影灯）**
```
A dark painterly semi-realistic illustration. A cold sterile 1950s operating room inside a gothic
mansion; muted teal-and-sepia palette with a faint blood-red accent; dim clinical uncanny lighting.
Scene: the north side, a large shadowless surgical lamp hanging over an empty operating table.
Faint red digital glitches creep into the edges. Vertical 9:16 composition. No text, no people.
```
**east（カルテの束）**
```
A dark painterly semi-realistic illustration. A cold sterile 1950s operating room inside a gothic
mansion; muted teal-and-sepia palette with a faint blood-red accent; dim clinical uncanny lighting.
Scene: the east wall, stacks and bundles of old medical charts piled on a steel shelf. Faint red
digital glitches creep into the edges. Vertical 9:16 composition. No legible text, no people.
```
**west（トレイの器具 ＋壁の引っ掻き傷）**
```
A dark painterly semi-realistic illustration. A cold sterile 1950s operating room inside a gothic
mansion; muted teal-and-sepia palette with a faint blood-red accent; dim clinical uncanny lighting.
Scene: the west wall, a steel tray of old surgical instruments, and disturbing scratch gouges
clawed into the wall above it. Faint red digital glitches creep into the edges. Vertical 9:16
composition. No text, no people.
```
**south（数字錠の扉）**
```
A dark painterly semi-realistic illustration. A cold sterile 1950s operating room inside a gothic
mansion; muted teal-and-sepia palette with a faint blood-red accent; dim clinical uncanny lighting.
Scene: the south wall, a locked door with an old metal numeric combination lock. Faint red digital
glitches creep into the edges. Vertical 9:16 composition. No legible text, no people.
```

#### R12 証拠保管室（分岐③）— `r12_north` / `r12_east` / `r12_west` / `r12_south`
**north（証拠箱 `{中：甥の手袋}`）**
```
A dark painterly semi-realistic illustration. An evidence storage room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the north wall, an open cardboard evidence box on a table containing a single
leather glove. Faint red digital glitches creep into the edges. Vertical 9:16 composition.
No legible text, no people.
```
**east（事件ファイル）**
```
A dark painterly semi-realistic illustration. An evidence storage room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the east wall, a thick bulging case file folder bound with string on a shelf.
Faint red digital glitches creep into the edges. Vertical 9:16 composition. No legible text,
no people.
```
**west（現場写真）** ⚠️生々しさは抑える
```
A dark painterly semi-realistic illustration. An evidence storage room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the west wall, a grim crime-scene photograph pinned up (vague and shadowy, no
explicit content). Faint red digital glitches creep into the edges. Vertical 9:16 composition.
No legible text, no people.
```
**south（数字錠の扉）**
```
A dark painterly semi-realistic illustration. An evidence storage room inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a faint blood-red accent; dim uncanny
lighting. Scene: the south wall, a locked door with an old metal numeric combination lock. Faint
red digital glitches creep into the edges. Vertical 9:16 composition. No legible text, no people.
```

#### R13 最後の扉 — `r13_north` / `r13_east` / `r13_west` / `r13_south`
> 刻印 ME / MO / RY は **Geminiでは崩れがち**。文字は後から正確に入れる前提で「彫られた符号がある壁」として生成。
**north（刻印 ME）**
```
A dark painterly semi-realistic illustration. A final ominous antechamber inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a strong blood-red accent; ominous dim
lighting. Scene: the north wall, a carved stone inscription panel with cryptic gothic blackletter
symbols, faintly glowing red. Strong red digital glitches and data corruption creep across the
scene. Vertical 9:16 composition. No people.
```
**east（刻印 MO）**
```
A dark painterly semi-realistic illustration. A final ominous antechamber inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a strong blood-red accent; ominous dim
lighting. Scene: the east wall, a second carved stone inscription panel with cryptic gothic
blackletter symbols, faintly glowing red. Strong red digital glitches creep across the scene.
Vertical 9:16 composition. No people.
```
**west（刻印 RY）**
```
A dark painterly semi-realistic illustration. A final ominous antechamber inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a strong blood-red accent; ominous dim
lighting. Scene: the west wall, a third carved stone inscription panel with cryptic gothic
blackletter symbols, faintly glowing red. Strong red digital glitches creep across the scene.
Vertical 9:16 composition. No people.
```
**south（door_final・最後の扉）**
```
A dark painterly semi-realistic illustration. A final ominous antechamber inside a gothic
mansion-medical facility; muted teal-and-sepia palette with a strong blood-red accent; ominous dim
lighting. Scene: the south wall, a massive final door of engraved iron and stone covered in
cryptic carved inscriptions, monumental and foreboding. Strong red digital glitches creep across
the scene. Vertical 9:16 composition. No people.
```

---

## 4. 状態差分（★ の暗転/通電版・4枚）

通常版は §3。**同じ構図のまま光源だけ変える**ので、**§1 の参照画像（通常版）を添付**して生成すると整合する。

### r3_north_lit（現像壁・ブラックライト点灯）⚠️浮かぶ数字は後入れ
```
Same scene and composition as the reference darkroom north wall, but now lit by an ultraviolet
black-light: the developing photographs glow faintly, hidden pale marks fluoresce on the wet
photo paper. Dark painterly semi-realistic, teal-sepia with red safelight accent, uncanny.
Vertical 9:16 composition. No legible text, no people.
```

### r8_east_dark（鏡・照明OFF）⚠️反転数字は後入れ・返り血の赤は後加筆
```
Same antique mirror and composition as the reference, but now the lights are OFF: the chamber is
in near darkness, and the figure faintly reflected in the mirror appears wrong and disturbing,
smeared with dark red, an unsettling reversed reflection. Dark painterly semi-realistic, deep
teal-sepia with a blood-red accent, horror mood. Vertical 9:16 composition. No legible text,
no people.
```

### r10_north_on（モニターA 通電）
```
Same bank of CRT security monitors and composition as the reference, but now POWERED ON: the
screens glow with grainy flickering black-and-white CCTV footage of dim corridors. Dark painterly
semi-realistic, teal-sepia with a blood-red accent. Faint red digital glitches creep into the
edges. Vertical 9:16 composition. No legible text, no people.
```

### r10_east_on（モニターB 通電）⚠️画面の数字は後入れ
```
Same bank of CRT security monitors and composition as the reference, but now POWERED ON: the
screens glow with grainy flickering CCTV footage, faint numeric digits half-visible on one screen.
Dark painterly semi-realistic, teal-sepia with a blood-red accent. Faint red digital glitches
creep into the edges. Vertical 9:16 composition. No people.
```

---

## 5. アイテムアイコン（15種・正方→透過化）

**共通の作法**：`1:1`、**無地のニュートラル背景**で生成 → 後で **remove.bg / Photoshop背景削除 / rembg** で透過PNG化 → `assets/images/items/<id>.png` に保存。
各プロンプトに画風文を内包済み。`(label)` は対応する日本語名。

### item_r1_key（小さな鍵）
```
A single video-game item icon, centered and isolated on a plain neutral gray background for easy
cut-out. Subject: a small old brass-and-iron key. Soft rim lighting, dark vintage muted palette
with a subtle blood-red undertone, painterly, highly detailed. No text. Square 1:1.
```

### item_frag_a（破れた紙片・左）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: the
torn LEFT half of an aged paper document fragment, ragged torn right edge, yellowed and creased.
Soft rim lighting, dark vintage muted palette, painterly, detailed. No legible text. Square 1:1.
```

### item_frag_b（破れた紙片・右）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: the
torn RIGHT half of an aged paper document fragment, ragged torn left edge, yellowed and creased.
Soft rim lighting, dark vintage muted palette, painterly, detailed. No legible text. Square 1:1.
```

### item_frag_c（カルテの担当医欄）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: a
torn narrow strip cut from an old medical chart, the "attending physician" field area, yellowed
paper. Soft rim lighting, dark vintage muted palette, painterly, detailed. No legible text.
Square 1:1.
```

### item_chart_half（復元しかけのカルテ）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: a
partially reassembled old medical chart, several torn pieces taped back together, still incomplete.
Soft rim lighting, dark vintage muted palette, painterly, detailed. No legible text. Square 1:1.
```

### item_pass（復元カルテ＝通行証）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: a
fully reassembled old medical chart / paper entry permit, the torn pieces fused back into one
document. Soft rim lighting, dark vintage muted palette, painterly, detailed. No legible text.
Square 1:1.
```

### item_stamp（受付印）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: an
old wooden-handled rubber reception ink stamp, with a faint blood-red ink pad. Soft rim lighting,
dark vintage muted palette with a blood-red accent, painterly, detailed. No legible text. Square 1:1.
```

### item_pass_valid（受理印つき通行証）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: an
old paper entry permit document stamped with a single red circular approval mark. Soft rim lighting,
dark vintage muted palette with a blood-red accent, painterly, detailed. No legible text. Square 1:1.
```

### item_knob（ドアノブ）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: an
antique brass doorknob detached from a door, worn metal. Soft rim lighting, dark vintage muted
palette, painterly, highly detailed. No text. Square 1:1.
```

### item_vial（薬液）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: a
small glass vial filled with pale cloudy medicine liquid, cork stopper. Soft rim lighting, dark
vintage muted palette, painterly, highly detailed. No text. Square 1:1.
```

### item_syringe_empty（空のシリンジ）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: an
empty antique glass-and-brass syringe, no needle, no liquid. Soft rim lighting, dark vintage muted
palette, painterly, highly detailed. No text. Square 1:1.
```

### item_needle（注射針）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: a
single antique hypodermic needle, thin polished steel. Soft rim lighting, dark vintage muted
palette, painterly, highly detailed. No text. Square 1:1.
```

### item_syringe_loaded（針付きシリンジ）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: an
antique glass syringe fitted with a needle, still empty of liquid. Soft rim lighting, dark vintage
muted palette, painterly, highly detailed. No text. Square 1:1.
```

### item_syringe_full（薬液入りシリンジ）
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: an
antique glass syringe with a needle, filled with pale cloudy liquid. Soft rim lighting, dark
vintage muted palette, painterly, highly detailed. No text. Square 1:1.
```

### item_culprit_evidence（金属製の筒）⚠️Sルートの鍵・最重要
```
A single video-game item icon, centered, isolated on a plain neutral gray background. Subject: a
sinister sealed metal cylinder containing a hidden poison syringe, cold steel, ominous and
important-looking. Soft rim lighting, dark vintage muted palette with a faint blood-red accent,
painterly, highly detailed. No text. Square 1:1.
```

> 別の入口部屋「study」用に `item_key`（古い鍵）/ `item_evidence`（古い証拠書類）が要る場合は、上の鍵・書類プロンプトを流用。

---

## 6. ①記憶マーカー・結末・その他

### 6-1. ①記憶の断片マーカー（1枚を3箇所で流用：R3東/R6北/R7北）
**mem_fragment**（透過オーバーレイ推奨）
```
A glowing unstable fragment of a memory: a translucent shard of light with faint red corruption
and digital glitch flickering through it, eerie and dreamlike, painterly. Centered, isolated on a
plain dark/neutral background for easy cut-out. No text, no people. Square 1:1.
```
**mem_fragment_overwritten**（任意・書き換え後）
```
The same glowing memory shard, now overwritten and "painted over": fixed solid blood-red, opaque,
the glitch frozen and sealed, ominous. Centered, isolated on a plain dark background. No text,
no people. Square 1:1.
```

### 6-2. 結末キービジュアル（7種）
> いずれも縦長 or 16:9 自由。流血/自傷は **婉曲表現**にしてある（⚠️は後加筆推奨）。

**A＋ 完璧な偽物**
```
A dark painterly semi-realistic key visual. A clean white hospital room at dawn; a man lying
peacefully in bed with a serene blissful smile; soft golden morning light that feels subtly
artificial and staged; a relieved doctor and a detective standing quietly nearby; beautiful but
deeply, uncannily wrong. Muted palette with warm light. No text.
```
**A 作話の綻び** ⚠️幻の返り血は薄く後加筆
```
A dark painterly semi-realistic key visual. A 1950s psychiatrist's office; a man collapsed in a
panic attack, staring in terror at a single paper-knife on the desk; cold dread fills the room;
a faint ghostly reddish afterimage hangs in the air. Muted teal-sepia palette with a faint red
accent. No text.
```
**B 忘却の揺り籠** ⚠️乾いた赤は後加筆
```
A dark painterly semi-realistic key visual. The smooth featureless white door of the first room;
a hand stained with dried dark-red reaching for the knob; in the corner a flat-line monitor;
an eternal-loop, trapped feeling. Muted palette with a blood-red accent. No text, no face.
```
**C 断罪の重圧**
```
A dark painterly semi-realistic key visual. A padded isolation cell in a psychiatric ward; a man
in a restraint jacket screaming silently against thick observation glass; no one is listening;
cold institutional light. Muted teal-sepia palette. No text.
```
**D 精神の死**
```
A dark painterly semi-realistic key visual. Everything dissolving into a flat featureless gray
void fading to pure black; a single flat horizontal brainwave line; a cold typed diagnosis sheet
floating in the dark; total emptiness and silence. Muted grayscale palette. No legible text.
```
**S 深淵の白** ⚠️流血・自傷は描かず暗示のみ
```
A dark painterly semi-realistic psychological-horror key visual. A dense night forest drowned in
thick fog; the pale solemn ghost of an old professor standing among the trees; a lone man clutching
a metal cylinder/syringe; an abyssal blinding white glow swallowing the background; dread.
Muted palette dissolving into white. No explicit gore. No text.
```
**True 白慈の審判**
```
A dark painterly semi-realistic key visual. A solemn blinding white light; cold steel handcuffs
locked on a man's wrists; his expression calm and at peace; a faint red police-siren glow pulsing
through a window. Muted palette with white light and a red accent. No text.
```

### 6-3. その他
**bg_final_hall（30号室＝玄関ホール）**
```
A dark painterly semi-realistic illustration. The grand entrance hall of a gothic mansion at the
surface of consciousness, secretly a medical facility; muted teal-and-sepia palette with a faint
blood-red accent; a faint red police-siren glow seeping through the front door; oppressive stillness.
Vertical 9:16 composition. No text, no people.
```
**bg_void（D結末と共用の虚無）**
```
A featureless flat gray void slowly fading into pure black, cold absolute emptiness, no objects,
subtle grain. Vertical 9:16 composition. No text, no people.
```
**タイトル背景**
```
A dark painterly semi-realistic illustration. A single pale worn door standing in darkness, dim
cinematic light, muted teal-and-sepia palette with a faint blood-red accent, lots of empty dark
space above the door for a logo, minimal and ominous. Vertical 9:16 composition. No text, no people.
```

---

## 7. テスト生成のおすすめ順（クレジット節約）

1. **R1北** を作り込む（§3）→ これを基準画に固定（§1）。
2. R1の残り3方向 → 画風が引き継げるか確認（Geminiの一貫性テスト）。
3. アイテム数点（鍵・シリンジ・金属製の筒）→ 透過化まで一連で試す（§5）。
4. 結末1枚（例：True か A＋）→ 検閲に引っかからないか確認（§6-2）。
5. 問題なければ P0(R1〜R4)→P1(R5〜R9)→P2(R10〜R13＋結末) の順で量産（優先度は [アセット仕様書 §7](アセット仕様書.md#7-集計優先度)）。

> **チェック観点**：①4方向が“同じ部屋”に見えるか ②13部屋が“同じ館”に見えるか ③文字/数字の崩れ ④流血表現の検閲。テストで①②が弱ければ §1 の参照画像強度を上げる or 最後に色調補正で均す。

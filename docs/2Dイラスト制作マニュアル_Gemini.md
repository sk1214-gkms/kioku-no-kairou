# 2Dイラスト背景の作り方（Gemini／Nano Banana・初心者向け・見ながら作る）

**アート方針＝2Dイラスト（Gemini で生成）で確定**（3Dレンダリングから変更）。
一番の課題は **「52枚を"同じ館"に揃える一貫性」**（Fireflyで詰まった点）。Geminiは**会話で"同じ部屋のまま編集"できる**ので、これを解決できます。

- 各室に「何を描くか（情景・焦点）」→ [画像の理想像](画像イメージ_自然言語.md)
- 作る枚数の全リスト → [アセット完全チェックリスト](アセット完全チェックリスト.md)
- 英語プロンプトの雛形 → [Gemini_生成プロンプト集](Gemini_生成プロンプト集.md) / [コピペ用](Gemini_プロンプトだけ.md)
- 本書＝それらを「一貫性を保つ作業手順」に落とした主線。**まずこれを上から**。

> ⚠️ アプリ側は変更不要。背景は3Dでもイラストでも同じ `assets/images/rooms/<id>_<dir>.png` に置くPNG。エンジン・謎・コードは一切変わりません。

---

## 0. 全体像（作るもの・完成の定義）
| 種別 | 枚数 | 保存先 | 優先 |
|---|---|---|---|
| 背景（通常）13室×4方向 | **52枚** | `assets/images/rooms/r1_north.png` … | ★最優先 |
| 背景（状態差分）R3/R8/R10/R9 各4方向 | **16枚** | `..._lit/_dark/_on/_open.png` | ★必須 |
| アイテムアイコン（透過） | **15個** | `assets/images/items/xxx.png` | ★必須 |

**完成の定義（1枚）**：縦長9:16／調べる"焦点"が中央〜やや下にはっきり／暗くても焦点は視認できる／同じ館に見える／正しいファイル名で保存。

### 一貫性を保つ3原則（最重要・これが全て）
1. **スタイルDNAを毎回同じ英語文で指定**（下の固定文をコピペ）。
2. **"基準の1部屋"を先に完成**させ、以後は**その画像をGeminiに添付して「同じ部屋・同じ画風で」**と指示（＝ゼロから描かせない）。
3. **4方向・状態差分は"新規生成"でなく"編集"で出す**（「同じ部屋を右に向いた図」「同じ部屋で照明を点けた図」）。

---

## 1. スタイルDNA（毎回この英語をプロンプト冒頭に貼る）
```
A dark painterly semi-realistic illustration for a mobile escape-mystery game.
Vintage 1950s gothic mansion that is secretly a sterile medical facility. Unsettling but beautiful, unreliable-narrator mood.
Muted teal-and-sepia palette (base #202B2D and #2E2821), near-black shadows (#0E0C14), a single faint blood-red accent (#961A1A). Dim cinematic uncanny lighting, heavy vignette, subtle film grain.
Vertical 9:16 composition. First-person point of view (as if the player is standing in the room). No text, no numbers, no people/faces.
```
※**文字・数字は描かせない**（血文字・メモ・番号はアプリ側でテキスト重畳する＝多言語対応の恒久規則。[l10n土台](多言語対応_l10n土台.md)）。記号（○△□）もできれば避ける。

---

## 1.5 ★推奨：4方向を「1枚にまとめて」生成する（＝一室感の決定打）
> 「4方向を別々に作ると"別々の小箱"に見えて一室感が出ない」問題への最良の対処。
> **4壁を1枚のシートにまとめて生成**すれば、床・天井・光・色が**同一生成で必ず揃う**＝確実に「同じ部屋」になる。出た1枚を後述のツールで4枚に自動スライスするだけ。

### 手順（1室あたり3ステップ）
1. Gemini（Nano Banana）に、**§1のスタイルDNA＋下の"2×2グリッド"指示**を貼って生成。
2. 出てきた**1枚**をそのまま保存（例 `sheet_r1.png`）。
3. スライス：
   ```
   python tools/slice_room_sheet.py sheet_r1.png --room r1
   ```
   → `assets/images/rooms/r1_north.png / r1_east.png / r1_south.png / r1_west.png` が自動生成（各9:16に中央クロップ＝ホットスポットと完全一致）。
   - パネル間に黒い隙間があるなら `--gutter 8`。
   - 状態差分は `--suffix lit`（→ `r1_north_lit.png` …）。
   - 順番を変えたい時は `--order north,east,south,west`。

### コピペ用プロンプト（§1のDNAの後ろに続けて貼る／[焦点]は各室で差し替え）
```
Compose a SINGLE image as a 2x2 grid of four panels showing the FOUR WALLS of ONE AND THE SAME room, so they unmistakably belong to the same room.
Keep IDENTICAL across all four panels: floor material, ceiling, wall material/plaster, baseboard height, overall color grade, film grain, and one single consistent light source and its direction.
Each panel is a flat, head-on FIRST-PERSON view of one wall, as if standing in the center of the room and facing that wall directly. Minimal or no side walls; do not draw the room as a box.
- Top-left = NORTH wall: [北の焦点].
- Top-right = EAST wall: [東の焦点].
- Bottom-left = SOUTH wall: [南の焦点].
- Bottom-right = WEST wall: [西の焦点].
Each panel is vertical/portrait framed. Thin dark gutter between panels. No text, no numbers, no people, no faces.
```
例（R1 白い部屋）：北=古い洗面台／東=血の染みたシーツのベッド／南=施錠された白い扉と鍵穴／西=濃霧の見える鉄格子窓。各室の焦点は [画像の理想像](画像イメージ_自然言語.md)。

### さらに強い一室感が欲しいなら：パノラマ（アンロール）
4壁を**横一列に繋げて**描かせると、角（コーナー）まで連続して真に1部屋になる。
- プロンプトの「2x2 grid」を「one continuous horizontal panorama, the four walls unrolled left to right in order North, East, South, West, seamless corners」に置換。
- スライスは `--layout hstrip`：
  ```
  python tools/slice_room_sheet.py sheet_r1.png --room r1 --layout hstrip
  ```
- 短所：横長出力になり1壁あたりの解像度は下がりがち。まずは扱いやすい**2×2グリッド**を推奨。

> 以降の §2〜§4（基準1室→添付して4方向）は「1枚ずつ高解像度で作りたい」場合の従来法。**一室感重視なら本§1.5を優先**。

---

## 2. 基準の1部屋を作る（R1・ここが一番大事）
R1「白い部屋」の**北＝洗面台**を"館の基準画"にします。

1. Gemini（画像生成＝Nano Banana）を開く。
2. 下を送る（【スタイルDNA】＋被写体）：
   ```
   ＜ここに§1のスタイルDNAを貼る＞
   Subject: an old white psychiatric room. Front view of a grimy antique porcelain washstand against dim white tiles, the cabinet below slightly ajar, damp pipes. Cold foggy light from the side.
   ```
3. 出てきた1枚が"館の顔"。**気に入るまでここだけ粘る**（色の暗さ・タイルの質感・ティール寄りの陰影）。これが基準になるので妥協しない。
4. 良い1枚ができたら**保存**し、`assets/images/rooms/r1_north.png` に置く。**この画像は以後ずっと"参照用"に使う**（別名でも保管）。

---

## 3. 同じ部屋の"4方向"を出す（新規生成しない＝編集で）
基準画（R1北）を**Geminiに添付**して、向きだけ変える：
```
＜R1北の画像を添付＞
Keep the exact same room, same style, same palette and lighting as the attached image.
Now show the EAST wall of this same room: a simple iron-framed bed with sheets stained with faint dark spots. Same first-person view, vertical 9:16. No text, no people.
```
- 南＝扉（施錠された白い扉・鍵穴）／西＝鉄格子の窓（外は濃霧）も同様に「同じ部屋の◯の壁」で。
- 保存名：`r1_east.png` / `r1_south.png` / `r1_west.png`。
- ポイント：**毎回"同じ部屋・同じ画風（添付参照）"を明記**。ズレたら「もっと暗く」「ティール寄りに」で微修正。

---

## 4. 残り12室（基準画を"種"にして横展開）
各室も**まず北を1枚**作り、それを添付して4方向へ。さらに**"館全体の統一"のため、R1北も一緒に添付**して「この館の画風で」と足すと、部屋間のトーンが揃います。
- 各室の焦点は [画像の理想像](画像イメージ_自然言語.md)（例：R3暗室＝現像壁／止まった時計／時計錠の扉／配電盤）。
- 「館の共通要素」（同じ床材・同じ壁・同じ木の質感）を毎回一言添えると"同じ館"感が出る。

---

## 5. 状態差分16枚（"編集"で出す＝Geminiの得意技）
通常版の画像を添付して、状態だけ変える：
| 差分 | 指示（同じ部屋を添付して） | 保存名 |
|---|---|---|
| R3 `_lit` | 「同じ暗室。ブラックライトが点き、北の壁に蛍光の痕が浮かぶ。青白い光。」 | `r3_north_lit.png` ほか |
| R8 `_dark` | 「同じ鏡の間。照明を消し、東の姿見に赤い滴りと人影が浮かぶ。」 | `r8_east_dark.png` ほか |
| R10 `_on` | 「同じ監視室。通電し、北の記録端末と東のモニタがシアンに点灯。」 | `r10_north_on.png` `r10_east_on.png` ほか |
| R9 `_open` | 「同じ標本室。西の隠し戸棚が開き、中は空。」 | `r9_west_open.png` ほか |
- **通常版には"出現物"を描かない**（例：R10通常はモニタ消灯／`_on`だけ点灯）。編集なら同じ構図のまま切り替えられる。

---

## 6. アイテムアイコン15（透過）
- 各アイテムを**単体・正面・暗い無地背景**で生成（スタイルDNA＋「Subject: a small brass key on a plain dark background, centered, item icon」等）。
- 生成後に **remove.bg 等で背景透過** → `assets/images/items/item_r1_key.png` 等（命名は[チェックリストC](アセット完全チェックリスト.md#c-アイテムアイコン透過png-15種-必須)）。
- 面倒なら後回し可（プレースホルダ透過アイコンで動く）。

---

## 7. 色を全部そろえる（最後の仕上げ）
Geminiでもわずかにトーンがブレるので、最後に**Photoshop/GIMP/写真アプリで一括のカラー補正**（同じトーンカーブ／カラーバランス）を全PNGへ。これで52枚が完全に"同じ館"に。

---

## 8. つまずき集
- **部屋ごとにバラバラになる** → ゼロから生成している。**必ず基準画を添付**して「同じ部屋/同じ画風」と言う。
- **文字や数字が絵に入る** → プロンプトに `no text, no numbers` を明記。入っても後で消す（アプリ側でテキスト重畳するので絵に文字は不要）。
- **明るすぎ/ポップになる** → 「darker, muted teal, heavy vignette, cinematic」を足す。
- **人物・顔が出る** → `no people, no faces` を明記（主観視点）。
- **9:16にならない** → Geminiで比率指定できないときは、生成後に9:16でトリミング。
- **ゲームに反映されない** → 保存パス/名前を確認（`assets/images/rooms/r1_north.png` の形）。

---

## 9. ライセンス（商用配信のため必須）
- Geminiの画像出力の**商用利用可否・権利**を利用規約で必ず確認（本作は広告＋¥480＝商用）。
- 素材を混ぜる場合（テクスチャ等）はその素材のライセンスも確認。

---

## 付録：制作チェックリスト（3D版と共通）
枚数・ファイル名・焦点は [3D制作マニュアルの付録](3D制作マニュアル_初心者向け.md#付録全レンダリング-チェックリスト作った枚数を管理) と同じ（背景52＋差分16＋アイテム15）。**まず §2 の基準1室（R1北）→ §3 の4方向**を作って、ゲームに入れて確認するところから。

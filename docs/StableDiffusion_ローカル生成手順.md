# Stable Diffusion（ローカル）でアセットを作る手順 — Windows

『アムネジィ・ケース』の画像（背景13室×4方向／アイテム透過アイコン／結末キービジュアル）を、**自分のPCのStable Diffusionで生成する**ための手順書。プロンプトは [アセット仕様書.md §8](アセット仕様書.md#8-生成プロンプト集画像ごと) を使う。

> ⚠️ **どのPCでやるか**：モデル等で数〜数十GBのダウンロードが必要。**社内ネット（遮断あり）では不可**。ネットの通る**自宅PC**で行うこと。

---

## 0. 必要環境（まず確認）

| 項目 | 推奨 | 最低 | 備考 |
|---|---|---|---|
| GPU | **NVIDIA RTX系 VRAM 8GB+** | VRAM 6GB | SDXLは8GB+が快適。6GBは `medvram` で可 |
| VRAM 4GB / 非NVIDIA | — | SD1.5＋低VRAM設定 | AMD/IntelはDirectML等で手間。厳しければ**クラウド(Leonardo)推奨** |
| ストレージ | 30GB以上の空き | 15GB | モデル1個 2〜7GB |
| OS | Windows 10/11 | — | |

> **GPUが非力 or NVIDIAでない場合**：無理せず [アセット仕様書 §9](アセット仕様書.md#9-おすすめの生成ai) の **Leonardo.ai（クラウド・無料枠）** で同じプロンプトを使うのが早い。以下はNVIDIA GPU前提。

---

## 1. インストール（初心者は Stability Matrix が最速）

**おすすめ：[Stability Matrix](https://github.com/LykosAI/StabilityMatrix)**（各種SD UIをワンクリック導入・管理できるランチャー）

1. Stability Matrix を入手して起動。
2. 「Add Package」で **Forge**（`stable-diffusion-webui-forge`）を選んでインストール。
   - Forge＝定番A1111の高速・低VRAM版。UIはA1111とほぼ同じで、**透過生成(LayerDiffuse)も入れやすい**。
   - 代替：**A1111**（情報量最多）／**ComfyUI**（ノード式・上級者向け）。
3. インストール完了後、Stability Matrix から起動するとブラウザでWeb UIが開く。

> 手動派：A1111 / Forge の公式GitHubの「Windows 1-click installer」でも可。Python・gitは入れてくれる。

---

## 2. モデル（チェックポイント）を入れる

**入手先：[Civitai](https://civitai.com)**（最大手）または Hugging Face。

- **画質重視なら SDXL系**（VRAM 8GB+）。この陰鬱ゴシック×絵画調に合う汎用：
  - **DreamShaper XL** / **Juggernaut XL** / **RealVisXL** など（雰囲気・絵画調が得意なものを好みで）。
- **VRAMが少ない（6GB以下）なら SD1.5系**：**DreamShaper** / **Deliberate** など（軽い・実績多数）。
- ダウンロードした `.safetensors` を、Stability Matrix のモデルフォルダ（`Models/StableDiffusion`）に置く。

> ⚠️ **商用ライセンス必須確認**：広告収益＝商用。Civitaiの各モデルページ「**Permissions / Commercial use**」を必ず確認（商用OKのものを選ぶ）。LoRAを使う場合も同様。

---

## 3. 基本設定（このゲーム用の推奨値）

Web UI の **txt2img** タブで：

| 設定 | 推奨値 |
|---|---|
| 解像度（縦9:16） | SDXL: **832×1216**（または896×1152）／SD1.5: **512×768**→後でアップスケール |
| Sampling method | **DPM++ 2M Karras**（or Euler a） |
| Sampling steps | **28〜35** |
| CFG Scale | **5〜7**（高すぎると硬くなる） |
| Hires.fix（高解像度化） | ON、Upscaler=**4x-UltraSharp** 等、Denoise 0.3〜0.45、倍率1.5〜2倍 |
| VAE | モデル内蔵でOK。眠い色なら `sdxl_vae` を指定 |
| 低VRAM | 起動引数に `--medvram`（6GB）/ `--lowvram`（4GB） |

---

## 4. 背景の作り方（4方向の統一がキモ）

1. [アセット仕様書 §8-1](アセット仕様書.md#8-生成プロンプト集画像ごと) の **STYLE_BASE** を Prompt に、**NEGATIVE** を Negative prompt に貼る。
2. その後ろに [§8-2](アセット仕様書.md#8-生成プロンプト集画像ごと) の各部屋 **SUBJECT** を足す。
   例（R1北）：`STYLE_BASE, a small bare white room, focus on an old porcelain washstand, ...`
3. **4方向の連続性**：気に入った1枚が出たら**Seedを固定**（さいころ→数値コピー）し、SUBJECTの「focus on 〜」だけ東/南/西の家具に差し替える。→ 同じ部屋に見える4枚が揃う。
4. 後半部屋(R10〜R13)は末尾に `faint red digital glitch / data corruption` を追加。
5. 状態差分(★)：暗転版は `, room in darkness lit only by [blacklight/monitor glow], hidden detail glowing` を足して別生成。

---

## 5. アイテムアイコン＝透過PNG

**おすすめ：LayerDiffuse（透過を直接生成）**
- Forge/A1111 に拡張 **`sd-forge-layerdiffuse`（LayerDiffuse）** を導入 → 「Transparent」を有効化して生成すると、**背景透過のPNGがそのまま出る**。
- プロンプトは [§8-3](アセット仕様書.md#8-生成プロンプト集画像ごと) の **ITEM_BASE＋各アイテム**。解像度は正方（例 768×768 or 1024×1024）。

**代替：生成→背景除去**
- 普通に単色背景で生成 → **`rembg`**（`pip install rembg` → `rembg i in.png out.png`）／拡張「ABG Remover」／Photoshop／`remove.bg` で透過化。

---

## 6. 仕上げ（解像度・命名）

- **アップスケール**：背景は最終 **1080×1920**（@3x）目安。Hires.fix か「Extras」タブの Upscaler（4x-UltraSharp等）で拡大。
- **画風の統一・微修正**：**img2img** に既存画を入れ、STYLE_BASEで Denoise 0.3〜0.5 で回すと、素材サイト写真や別AI出力も同じ画風に寄せられる。
- **ファイル名はコードと一致**（[アセット仕様書 §2〜§6](アセット仕様書.md)）。例：`bg_stage`ではなく現行の各部屋背景／`item_r1_key.png`／`door_carved.png` 等。`assets/` 配下に置き pubspec の assets に追加。

---

## 7. このゲーム用・コピペ設定まとめ

```
[Prompt]
（§8-1 STYLE_BASE）, （§8-2 各部屋 SUBJECT）
[Negative]
text, letters, watermark, signature, modern objects, smartphone, bright cheerful
colors, cartoon, anime, lowres, blurry, deformed, extra limbs, people, crowd
[Size] 832x1216 (SDXL縦) / [Sampler] DPM++ 2M Karras / [Steps] 30 / [CFG] 6
[Hires.fix] 4x-UltraSharp, x1.5, denoise 0.4
[同一部屋4方向] Seed固定 + SUBJECTの focus 部分のみ変更
[アイテム] LayerDiffuse(透過) + §8-3 / 正方1024
```

---

## 8. つまずきポイント

- **VRAM不足エラー**：解像度を下げる／`--medvram`・`--lowvram`／SDXL→SD1.5に。
- **顔・手の崩れ**（結末の人物）：人物は小さく/後ろ向き/シルエットにする、または ADetailer 拡張で顔修復。本作は基本「人物なし情景」中心なので影響小。
- **4方向がバラバラ**：Seed固定＋同一モデル＋STYLE_BASE固定。img2imgで寄せる。
- **透過の縁が汚い**：LayerDiffuse推奨。rembg時は後で縁を消しゴム/マット処理。
- **商用ライセンス**：モデル・LoRAの規約を再確認（広告収益＝商用）。
- **生成は自宅PCで**（社内ネットはモデルDL不可）。

---

## 9. 進め方の目安

1. まず **R1（白い部屋）4方向** を §8-2＋§7設定で試作 → 画風とSeed運用を確立
2. P0（R1〜R4＋アイテム鍵/紙片/通行証/ドアノブ）を量産
3. P1（R5〜R9）→ P2（R10〜R13＋結末7種）→ 仕上げ
4. 並行して **黒文字体フォント**（[assets/fonts/](../assets/fonts/)）も配置

> 1枚目が決まれば後は流用で速い。まずは R1 を1部屋、最後まで（生成→透過/アップスケール→assets配置）通してみるのがおすすめ。

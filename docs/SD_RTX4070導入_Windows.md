# 自宅Windows（RTX 4070）で Stable Diffusion（ComfyUI）を動かす

自宅PC（**Windows ＋ GeForce RTX 4070／VRAM 12GB**）で、本作のアニメ調背景（SDXL）を生成する手順。
[DGX Spark版](SD_DGXSpark導入.md) と同じ **ComfyUI** を使うが、**Docker・SSH・tmuxは一切不要**でずっと簡単。プロンプトは [SDプロンプト集 §12（アニメ版・現行本命）](SDプロンプト_コピペ用.md)。

> ℹ 旧 [SD導入_やさしい手順](SD導入_やさしい手順.md)（Forge＋写真調）は旧方針。**いまはこのページ＋§12** が正。
> ⚠ モデルDLは自宅ネットで（社内ネットは不可）。RTX 4070（12GB）ならSDXLの832×1216は余裕で動く。

---

## なぜ ComfyUI か
- §12のレシピ（**filename_prefix・euler a・28steps** 等）が **ComfyUI前提**で書いてある → そのままコピペで使える。
- Windows向けに **ポータブル版**（zip解凍→バット起動だけ）があり、インストール作業がほぼ無い。
- Spark版と同じUIなので、手順・トラブル対処を共通化できる。

---

## STEP 0：前提確認（5分）
1. **NVIDIAドライバを最新に**：GeForce Experience／NVIDIAアプリで更新（古いとCUDAエラーの元）。
2. GPU確認：タスクマネージャー →「パフォーマンス」→ GPU に **RTX 4070／専用GPUメモリ 12GB** が出ればOK。
3. **空きディスク 30GB以上**（本体＋モデル6.9GB＋出力）。
4. あると良いもの：**7-Zip**（ポータブル版の解凍に使う）、**Python 3.x ＋ git**（STEP 6のクロップ・push用。[python.org](https://www.python.org/) のインストーラで「Add to PATH」にチェック）。

---

## STEP 1：ComfyUI を入れる（ポータブル版）
1. GitHub **comfyanonymous/ComfyUI** の README →「**Direct link to download**」（Windows portable, NVIDIA用）から **`ComfyUI_windows_portable_nvidia.7z`** をDL。
2. 7-Zipで **Cドライブ直下など浅い場所**に解凍（例：`C:\ComfyUI_windows_portable`。深い日本語パスは避ける）。
3. フォルダ内の **`run_nvidia_gpu.bat`** をダブルクリック → 黒い窓が開き、しばらくするとブラウザで **http://127.0.0.1:8188** が開く。これが本体。
   - 終了は黒い窓を閉じるだけ。次回も `run_nvidia_gpu.bat` を起動するだけ。

> 別解：公式の **ComfyUI Desktop**（Windowsインストーラ版）でも同じことができる。好みでOK（以降のフォルダパスは読み替え）。

## STEP 2：モデル（Animagine XL 3.1）を置く
1. **Civitai** か **Hugging Face（cagliostrolab/animagine-xl-3.1）** から **`animagine-xl-3.1.safetensors`**（約6.9GB）をDL。
   - ⚠ 配布ページの**ライセンス（Fair AI Public License 1.0-SD 等）を確認**。本作は配信＝商用なので、商用利用可であることを必ず見る。
   - ⚠ 拡張子は **`.safetensors` のみ**使う（`.ckpt`は避ける）。
2. `animagineXL31.safetensors` にリネーム（§12の表記と揃えるため。任意）。
3. 置き場所：**`C:\ComfyUI_windows_portable\ComfyUI\models\checkpoints\`**
4. ComfyUIの画面を開き直す（またはブラウザ更新）→ Load Checkpoint で選べるようになる。

## STEP 3：はじめての1枚（デフォルトワークフローで）
起動直後の **default workflow（txt2img）** をそのまま使う。ノードは6個：

| ノード | 設定 |
|---|---|
| **Load Checkpoint** | `animagineXL31.safetensors` |
| **CLIP Text Encode（上＝Positive）** | §12の **PREFIX ＋ SCENE ＋ ", " ＋ PALETTE ＋ SUFFIX** を連結して貼る |
| **CLIP Text Encode（下＝Negative）** | §12の **NEGATIVE**（全室共通・固定） |
| **Empty Latent Image** | **832 × 1216**／batch_size **1** |
| **KSampler** | sampler **euler_ancestral**（=euler a）／scheduler **normal**／steps **28**／cfg **6**／seed はまず random |
| **Save Image** | filename_prefix に §12 各表の **prefix**（例：`R2a_shelf/img`） |

**Queue Prompt** で実行。RTX 4070なら1枚 **20〜30秒**程度。
出力は `ComfyUI\output\` 配下（prefixに `/` を入れるとサブフォルダに整理される。例：`output\R2a_shelf\img_00001_.png`）。

> §12の鉄則：**PREFIX／SUFFIX／NEGATIVEは全室で一切変えない**。変えるのは各室の**PALETTE**と各ノードの**SCENE**だけ（＝「同じ絵師の一つの館」に揃う）。

## STEP 4：量産の回し方（1室＝ノード数枚）
1. [部屋アート割り当て](部屋アート割り当て.md) で次にやる部屋を確認（R1は生成済）。
2. §12 のその部屋の表を開き、ノードごとに **SCENE と filename_prefix を差し替え**て Queue Prompt。
   - PALETTEは**部屋内で共通**、SCENEだけノードごとに替える。
3. 気に入らなければそのまま再実行（seedがrandomなら毎回違う絵）。**数回引いて良いのを選ぶ**方式でOK。
4. 主役が家具に埋もれたら §12 の注意どおり **重み `:1.4→1.6` を上げる**／羅列語を削る。

## STEP 5：リポジトリを自宅PCに用意（初回だけ）
```powershell
git clone https://github.com/sk1214-gkms/kioku-no-kairou.git
cd kioku-no-kairou
pip install pillow   # クロップツール用
```

## STEP 6：9:16クロップ → ゲーム反映
SDXLの832×1216は**2:3寄り**なので、中央9:16に切ってから配置する（ツールあり）：
```powershell
# 例：R2 棚ノード。出力名は §12 の bg名 に合わせる
python tools/crop_916.py "C:\ComfyUI_windows_portable\ComfyUI\output\R2a_shelf\img_00001_.png" assets/images/rooms/r2_shelf.png
```
- 被写体が中央からズレている時は `--shift-x 40`（右へ）／`--shift-x -40`（左へ）。
- 全ノード分できたら push：
```powershell
git add assets/images/rooms && git commit -m "art: R2 SD" && git push
```
- もしくは生成PNGを `data/image/` に置いてpush →「置いた」と言ってくれれば、**トーン統一・配置・room JSONのタップ位置調整**はこちらで引き受けます。

---

## つまずき（Windows＋RTX 4070で起きやすい所）
- **遅い／GPUを使っていない** → `run_nvidia_gpu.bat` から起動しているか（CPU版のbatではないか）。ドライバ更新。黒い窓の先頭に `cuda` の文字が出ているか。
- **CUDA out of memory** → ゲーム・ブラウザ（ハードウェアアクセラレーション）など他のGPU使用アプリを閉じる。それでも出るなら一時的に 768×1120 で試す（12GBで832×1216は本来余裕）。
- **モデルが選択肢に出ない** → 置き場所が `ComfyUI\models\checkpoints\` か確認 → ブラウザ更新。
- **CivitaiのDLが失敗** → ログインが必要なことがある。Hugging Face 側から落とすのも手。
- **絵に文字が焼き込まれる** → NEGATIVEの `text, letters, words, numbers` が入っているか確認（ダイヤル・刻印は「文字なしの機構」で描かせ、数字はアプリ側で重ねる方針）。
- どれも、**黒い窓のエラー全文＋画面スクショ**を送ってくれればピンポイントで直します。

---

## 今晩のゴール
STEP 0〜3で **R2の1ノード（r2_shelf）を1枚** → 良ければ残り3ノード → crop_916で9:16化して `assets/images/rooms/` へ。**1部屋を最後まで通す**のが一番の近道。

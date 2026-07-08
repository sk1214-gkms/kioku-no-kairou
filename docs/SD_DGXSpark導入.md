# DGX Spark で Stable Diffusion（ComfyUI）を動かす

NVIDIA **DGX Spark**（GB10 Grace Blackwell・DGX OS＝Ubuntu系・**ARM64/aarch64**）で SDXL を動かす手順。**SSHでヘッドレス運用**（物理モニタは使わない）前提。
Windows版の [やさしい手順](SD導入_やさしい手順.md) は使えないので、こちらを使う。プロンプトは [SDプロンプト集](SDプロンプト_コピペ用.md)。

> ⚠ Sparkは新しいHW。**パッケージのバージョン相性で詰まる**ことがあるので、下記は「典型手順」。エラーは出力ごと私に送ってくれれば直します。

## ヘッドレス運用の要点（SSHで使う）
- ComfyUIは Spark 上で動かし、**Web UIだけ手元PCのブラウザに"ポート転送"で出す**（画面をSparkに繋がなくてよい）。
- 手元PCから：
  ```bash
  ssh -L 8188:localhost:8188 <ユーザー名>@<SparkのIP>
  ```
  これで手元の `http://localhost:8188` が Spark の 8188 に繋がる（安全・LANに晒さない）。
- **切断対策**：Spark側で **tmux** を使い、その中でコンテナ/ComfyUIを起動（SSHが切れても生き続ける）。
  ```bash
  tmux new -s sd        # 作業開始（再接続は tmux attach -t sd）
  ```

---

## なぜ ComfyUI ＋ NVIDIAコンテナか
- ComfyUIは **Linux/ARMで動かしやすい**（ノード式・SDXL/Flux/ControlNet/IP-Adapter対応）。
- Blackwell＋ARM向けの **PyTorch＋CUDA** は、**NVIDIA公式コンテナ(NGC)** が一番確実（自前pipはBlackwell対応wheelが遅れがち）。
- Sparkは元々コンテナ運用前提（Docker＋NVIDIA Container Toolkit同梱のはず）。

---

## STEP 0：前提確認（ターミナルで）
```bash
nvidia-smi            # GPUが見えるか（GB10 / CUDA版が出る）
docker --version      # Docker があるか
docker run --rm --gpus all nvcr.io/nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi  # コンテナからGPUが見えるか
```
- 3つ目でGPU情報が出れば、コンテナ→GPUの土台OK。
- まず **NVIDIA公式の DGX Spark プレイブック/NGC** に **ComfyUI や SD のすぐ使えるコンテナ**が無いか一度見てみると、もっと楽な可能性あり（あればそれが最速）。

---

## STEP 1：作業フォルダ＆コンテナ起動
```bash
mkdir -p ~/ai/comfy && cd ~/ai/comfy

# NVIDIA PyTorch コンテナ（ARM64向けが自動選択される）。タグは NGC で最新版を確認して置換。
docker run --gpus all -it \
  -p 8188:8188 \
  -v ~/ai/comfy:/workspace \
  --name comfy \
  nvcr.io/nvidia/pytorch:25.01-py3 bash
```
- `-v ~/ai/comfy:/workspace`＝ホストに保存（モデル・出力が消えない）。
- 2回目以降は `docker start -ai comfy` で入り直せる。

## STEP 2：コンテナ内で ComfyUI を入れる
```bash
cd /workspace
git clone https://github.com/comfyanonymous/ComfyUI
cd ComfyUI
# ★ torch はコンテナに入っている物を使う（再インストールしない）。まず素直に：
pip install -r requirements.txt
```
> もし `pip install` が **torch を入れ替えようとして壊れたら**：`requirements.txt` から `torch` 行を消して再実行（コンテナのtorchを温存）。ここは詰まりやすいので、**エラーを丸ごと送ってください**。

## STEP 3：モデル（SDXL・商用OK）を置く
- **Civitai** で SDXL の checkpoint（Juggernaut XL / DreamShaper XL 等）を、**Permissions＝Commercial use OK** を確認してDL。
- 置き場所：`/workspace/ComfyUI/models/checkpoints/`（ホストの `~/ai/comfy/ComfyUI/models/checkpoints/`）。
```bash
cd /workspace/ComfyUI/models/checkpoints
wget -O juggernautXL.safetensors "＜CivitaiのDLリンク＞"
```

## STEP 4：起動 → 手元PCのブラウザで開く（SSH転送）
Spark側（tmux内・コンテナ内）で：
```bash
cd /workspace/ComfyUI
python main.py --listen 0.0.0.0 --port 8188
```
手元PC側で、別ターミナルからSSHトンネルを張る（上の「ヘッドレス運用の要点」参照）：
```bash
ssh -L 8188:localhost:8188 <ユーザー名>@<SparkのIP>
```
→ 手元PCのブラウザで **http://localhost:8188**。初期の **default workflow（txt2img）** が出る。checkpoint選択 → Prompt/Negative → **Queue Prompt**。

> `--listen 0.0.0.0` はコンテナ内で外に出すため必要。SSH転送を使えばLANに直接晒さずに済む（安全）。

---

## STEP 5：このゲームの設定（ComfyUIのtxt2img）
- **Load Checkpoint**：入れたSDXL。
- **CLIP Text Encode（Positive）**：[SDプロンプト集](SDプロンプト_コピペ用.md) の **§1 STYLE_BASE ＋ §5 各部屋SUBJECT**。
- **CLIP Text Encode（Negative）**：**§2 NEGATIVE**。
- **Empty Latent**：**832×1216**（縦9:16）。
- **KSampler**：sampler **dpmpp_2m** ／ scheduler **karras** ／ steps **30** ／ cfg **6** ／ seed（まず random）。
- 実行＝**Queue Prompt**。良い**R1北**が出たら **seedを固定**（KSamplerのseedを控える）→ SUBJECTのfocusだけ東/南/西に替えて再実行＝4方向。

## STEP 6：一貫性・奥行き（あとで）
- **ControlNet / IP-Adapter** は ComfyUI-Manager から対応ノードを入れて追加（[SDプロンプト集 §4](SDプロンプト_コピペ用.md)）。
- 奥行き（森の洋館風）は [§1.5](SDプロンプト_コピペ用.md)。
- ズームは **img2img**（Load Image→VAE Encode→KSampler・denoise 0.5〜0.65）。
- Sparkはメモリ潤沢なので、余裕があれば**自前スタイルLoRAの学習**で一貫性を極めるのも◎（後日）。

## STEP 7：保存・ゲーム反映（ヘッドレス）
出力は Spark の `~/ai/comfy/ComfyUI/output/`（ホスト側にも残る）。ここから2通り：

**(a) Sparkでリポジトリを扱う（おすすめ・Sparkはネット可）**
```bash
# Spark上で一度だけ
git clone https://github.com/sk1214-gkms/kioku-no-kairou.git
# 生成物を配置（9:16直出しなのでスライス不要）
cp ~/ai/comfy/ComfyUI/output/＜出力＞.png kioku-no-kairou/assets/images/rooms/r1_north.png
cd kioku-no-kairou && git add -A && git commit -m "art: R1 SD" && git push
```
**(b) 手元PC/開発PCへ転送（scp/rsync）**
```bash
# 手元PCから
scp <ユーザー名>@<SparkのIP>:~/ai/comfy/ComfyUI/output/*.png ./
```
- ファイル名は `r1_north.png` 等に（[命名 §9](SDプロンプト_コピペ用.md)）。
- `data/image/` に置いて私に言ってくれれば、**トーン統一・配置・room JSONのタップ位置調整**を引き受けます（Web/CIも私が回します）。

---

## Flux も動く（余談）
Sparkのメモリなら **Flux.1（高画質）** も動く。ただし ControlNet/IP-Adapter/img2img の一貫性エコシステムは **SDXLの方が成熟**。本作は一貫性重視なので**まずSDXL**、余裕が出たらFluxを試す、が無難。

## つまずき（新HWで起きやすい所）
- **コンテナからGPUが見えない** → NVIDIA Container Toolkit の設定／`--gpus all`／ドライバ。STEP0の3つ目で切り分け。
- **pip が torch を壊す** → requirements から torch 行を外す（コンテナのを使う）。
- **sm_xxx not supported / CUDA error** → コンテナのタグを**より新しいNGC PyTorch**に上げる（Blackwell対応の版へ）。
- **モデルDLが遅い/失敗** → Civitaiはログイン要のことあり。`wget`のリンクは"Download"の実URLを。
- どれも、**コマンドとエラー全文をスクショ/コピペで送って**ください。ピンポイントで直します。

---

## 今晩のゴール
STEP0〜5で **R1北を1枚** → seed固定で **4方向** → `assets/images/rooms/` に配置。まず1部屋を通す。

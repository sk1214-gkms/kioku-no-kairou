# はじめての Stable Diffusion（迷わない導入・自宅Windows）

『アムネジィ・ケース』の背景をSDで作るための**最初の一歩**だけを、やさしく順番に。
プロンプトは [SDプロンプト_コピペ用.md](SDプロンプト_コピペ用.md)、詳しい設定は [SDローカル生成手順.md](StableDiffusion_ローカル生成手順.md) に。**まずは"1枚出す"までを目標**に。

> ⚠ 自宅PCで（社内ネットはモデルDL不可）。作業はネットの通る家で。

---

## STEP 0：自分のPCを確認（3分）
- **NVIDIA製グラボ**で、**VRAM 8GB以上**なら快適（6GBでも動く／4GBは重い）。
  - 確認：タスクマネージャー → 「パフォーマンス」→ GPU → 「専用GPUメモリ」。
- NVIDIAでない／VRAMが少ない → 無理せずクラウド（Leonardo.ai等）でも同じプロンプトが使えます。まずは手元GPUで試してOK。

---

## STEP 1：インストール（Stability Matrix が一番ラク）
1. ブラウザで **Stability Matrix** を検索 → GitHub（LykosAI/StabilityMatrix）から**Windows版をダウンロード**して起動。
2. 最初に保存先フォルダを聞かれるので、空きのある場所を指定（数十GB使う）。
3. 「**Add Package**」→ **Forge**（`Stable Diffusion WebUI Forge`）を選んで**Install**。
   - Forge＝定番UIの高速・省メモリ版。初心者向き。
4. 入ったら「**Launch**」。しばらくすると**ブラウザで操作画面**が開く（これがSDの本体）。

> インストール中はダウンロードが多いので気長に。完了後は次回から「Launch」だけ。

---

## STEP 2：モデル（絵柄の元）を1個入れる
1. ブラウザで **Civitai** を開く。
2. 上部で **「Checkpoint」＋「SDXL」** で絞り込み、**暗い絵画調が得意なもの**を選ぶ。おすすめ：
   - **Juggernaut XL** / **DreamShaper XL** / **RealVisXL** のどれか。
3. ⚠ **必ず確認**：モデルページの「**Permissions**」で **Commercial use（商用利用）**がOKか。→ 本作は配信＝商用なので**商用OKのものだけ**。
4. `.safetensors` を**ダウンロード** → Stability Matrix の **モデルフォルダ**（`Data/Models/StableDiffusion`）に置く。
5. Forgeの画面に戻り、左上の**モデル選択**の🔄で更新 → 入れたモデルを選ぶ。

---

## STEP 3：はじめての1枚（R1北で試す）
Forgeの **txt2img** タブで、画面の場所はこう：

- **① 上の大きな枠（Prompt）** に貼る＝ [SDプロンプト集](SDプロンプト_コピペ用.md) の **STYLE_BASE ＋ R1のN**：
  ```
  （§1 STYLE_BASE）, focus on an old white porcelain washstand, a double-door cabinet below, a clouded cracked mirror above, damp pipes, grimy white subway tiles
  ```
- **② その下の枠（Negative prompt）** に貼る＝ **§2 NEGATIVE** 一式。
- **③ 右側の設定**：
  - Sampling method：**DPM++ 2M Karras**
  - Sampling steps：**30**
  - Width **832** / Height **1216**（縦長）
  - CFG Scale：**6**
  - Seed：**-1**（毎回ランダム。まずはこのまま）
- **④ 右上のオレンジの「Generate」** を押す → 数十秒で右下に画像。

気に入らなければもう一度Generate（毎回違う絵）。**良いのが出るまで数回**。

---

## STEP 4：同じ部屋の"4方向"を揃える（Seed固定）
1. 良い**R1北**が出たら、画像の下に出る **Seed の数字**を覚える（コピー）。
2. **③のSeed欄にその数字を入れる**（-1 → 数字に）。
3. Promptの「focus on 〜」の部分だけ、**東/南/西の内容**に差し替えてGenerate。
   - 東：`focus on a simple iron-frame bed, wrinkled sheets with dark dried blood spots, a stained pillow, a dark gap under the bed, white tiles`
   - 南・西も同様（§5参照）。
4. → 同じ部屋に見える4枚が揃う。**これがSDの強み**（Geminiでできなかった所）。

---

## STEP 5：もっと揃えたく なったら（あとで／任意）
最初は STEP4 まででOK。さらに部屋どうしを揃えたくなったら拡張を足す：
- **ControlNet**：構図を線画/深度で固定。
- **IP-Adapter**：基準画（R1北）を"見本"として全生成に効かせる。
- 導入は Forge の「Extensions」から。詳細は [SDプロンプト集 §4](SDプロンプト_コピペ用.md) と[詳細手順](StableDiffusion_ローカル生成手順.md)。
- **奥行き（森の洋館風）**を出すなら [SDプロンプト集 §1.5](SDプロンプト_コピペ用.md)。

---

## STEP 6：保存とゲームへの反映
1. 出た画像を保存（右クリック保存、または `outputs` フォルダから）。
2. **正しい名前**にリネーム：`r1_north.png` / `r1_east.png` …（room JSONのbg名＝[命名一覧 §9](SDプロンプト_コピペ用.md)）。
3. `app/assets/images/rooms/` に置く。**SDは9:16直出しなのでスライス不要**。
4. GitHubにpush → CIでWeb反映（もしくは私に「data/imageに置いた」と言ってくれれば配置・調整します）。

---

## つまずいたら
- **VRAM不足のエラー** → 解像度を下げる（例 768×1152）／Forge起動引数に `--medvram`（6GB）`--lowvram`（4GB）。
- **絵が明るい/清潔すぎ** → NEGATIVEに `bright, clean` が入っているか確認、STYLE_BASEの `heavy decay` を強調。
- **顔・人物が出る** → NEGATIVEの `people, face` が効いているか。本作は基本"人物なし"。
- **商用ライセンス不安** → 使ったモデル/LoRAのCivitai「Permissions」を再確認。
- 詰まったら、**画面のスクショと状況**を送ってください。ピンポイントで直します。

---

## 今晩のゴール（欲張らない）
**R1北を1枚、気に入る絵で出す** → Seedを固定して**東/南/西で4方向** → `assets/images/rooms/` に置く。
ここまで来れば、あとは同じ流れで量産できます。1部屋を最後まで通すのが一番の近道です。

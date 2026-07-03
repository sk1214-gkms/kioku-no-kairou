# GitHub Pages で公開（Web版を配信）

> **用途＝開発・実機確認用の一時公開のみ。本番配信は Google Play ／ App Store。**
> Web版は「社内ネットでも実機で触れる」ための手段であり製品チャネルではない。
> **リリース前チェック**：① Pages公開を停止する or リポジトリをPrivate化（無料PagesはPublic必須＝公開のままだと全部屋JSONと[解答キー](解答とヒント_全室.md)が読める）。② 一度公開したものは検索キャッシュ/アーカイブに残り得る（＝完全な回収は不能）。攻略ネタを秘匿したいなら早めに非公開へ。

`main` へ push すると **GitHub 側（CI）でビルド → Pages 公開**される。
**ビルドは GitHub のサーバーで走るので、社内ネットの遮断（storage.googleapis.com）とは無関係。** スマホからも遊べる。

- 仕組み：[.github/workflows/deploy-pages.yml](../.github/workflows/deploy-pages.yml)
  - プレースホルダ画像をCIで生成（Pillow＋noto-cjk）→ `flutter build web --release --base-href "/kioku-no-kairou/"` → Pages へデプロイ。
- 公開URL（プロジェクトサイト）：**https://sk1214-gkms.github.io/kioku-no-kairou/**

## 初回だけ必要な設定（リポジトリ側）
1. **リポジトリを Public に**（GitHub 無料プランの Pages は公開リポジトリが条件。Private で使うには Pro 等が必要）。
   - ※公開するとソースcoード・物語のネタも見える点に注意。隠したい場合は「ビルド成果物だけ別の公開リポジトリへ出す／Proでprivate Pages」等を検討。
2. **Settings → Pages → Build and deployment → Source = “GitHub Actions”** を選択（ワークフローの `configure-pages` が自動有効化を試みるが、出ない場合は手動で）。
3. Actions タブでワークフローの成功を確認（数分）。緑になれば上記URLで表示。

## 更新のしかた
- 以後は **main に push するたびに自動で再ビルド＆再公開**。
- 手動実行：Actions タブ →「Deploy web to GitHub Pages」→ Run workflow。

## 注意・つまずき
- **base-href**：プロジェクトサイトは `/<repo名>/` 配下。リポジトリ名を変えたら yml の `--base-href "/kioku-no-kairou/"` も合わせる（ズレると真っ白/404）。
- 反映に数十秒〜数分のキャッシュ遅延あり。`Ctrl+Shift+R` で更新。
- 本番アート未配置でもプレースホルダで表示される。差し替えたい場合は `assets/images/...` に本画像を置いて push（その場合はそのPCで生成スクリプトを使わず本画像をコミット、または .gitignore を調整）。

# 音響仕様書（BGM・SE）— アムネジィ・ケース

ゲームに必要な **BGM／効果音(SE)** の一覧・ムード・**生成プロンプト**・おすすめツール・実装フック。画像の [アセット仕様書](アセット仕様書.md) と対になる音版。

## 0. 技術仕様

| 項目 | 指定 |
|---|---|
| 形式 | **BGM＝.mp3（or .ogg）／SE＝.mp3 or .wav**。Flutterの `audioplayers`/`just_audio` で再生 |
| BGM | ループ前提（**シームレスループ**に書き出し）。長さ 60〜120秒で十分（ループ） |
| SE | 0.2〜2秒の短尺。瞬発音は .wav、余韻ありは .mp3 |
| 音量 | BGMは控えめ（-18〜-14 LUFS目安）、SEはBGMより前に出す。コード側でも音量調整 |
| 命名 | 本書のファイル名と**コード参照を一致**させる（`assets/audio/` に配置→pubspec登録） |
| 実装 | **現状オーディオは未実装**。`audioplayers` 追加＋`AudioService`作成が必要（§4） |

---

## 1. BGM一覧（ムード／長さ／生成プロンプト）

> 共通方針：**ボーカル無しのインストゥルメンタル**。ゴシック洋館 × 無機質な医療 × 記憶の崩壊。章が進むほど“現実(医療)の滲み”と“崩壊ノイズ”を増やす。プロンプトはAI音楽ツール（Suno/Udio/Stable Audio）にそのまま貼る想定（英語）。

| file | 用途 | ムード | 生成プロンプト（英語） |
|---|---|---|---|
| `bgm_title.mp3` | タイトル | 不穏で美しい・喪失の予感 | `dark ambient main theme, melancholic music box and sustained strings, beautiful but unsettling, a sense of lost memory, slow, loopable, instrumental, no vocals` |
| `bgm_ch1.mp3` | 第1章(R1-R4) 混乱と違和感 | 低い不安 | `minimal dark ambient, deep low drone, faint slow heartbeat, distant detuned piano, gothic mansion unease, loopable instrumental, no vocals` |
| `bgm_ch2.mp3` | 第2章(R5-R9) 綻び・医療が滲む | 増す緊張 | `dark ambient with cold medical hum and monitor beeps, dissonant strings, subtle electronic glitch creeping in, rising tension, loopable instrumental, no vocals` |
| `bgm_ch3.mp3` | 第3章(R10-R13) メタ・崩壊 | 切迫・脳の崩壊 | `tense dark ambient, accelerating pulse, red-alert digital glitch and data corruption, neurons dying, dread and urgency, loopable instrumental, no vocals` |
| `bgm_finale.mp3` | 30号室 審判 | 厳粛・対決 | `solemn climactic dark ambient, deep choir pad, faint ticking clock, a moral reckoning, restrained and heavy, loopable instrumental, no vocals` |

### エンディング・テーマ（短尺・7結末で使い回し）
| file | 対象結末 | プロンプト |
|---|---|---|
| `bgm_end_serene.mp3` | A＋／A | `deceptively peaceful solo piano, warm but hollow and artificial, a beautiful lie with a hidden wrongness, instrumental` |
| `bgm_end_horror.mp3` | S／C／B | `abyssal horror drone, distorted strings, whispering noise, despair and madness, instrumental` |
| `bgm_end_true.mp3` | True | `solemn redemptive piano and cello, quiet acceptance of guilt, bittersweet humanity, instrumental` |
| `bgm_end_death.mp3` | D | `a single ECG tone fading into silence, cold emptiness, near-nothing, instrumental` |

---

## 2. SE（効果音）一覧

> 入手＝AI生成（ElevenLabs等）or 無料SFX素材（§3）。プロンプトは text-to-SFX 用（英語）。

| file | 鳴るイベント | 説明 / 生成プロンプト |
|---|---|---|
| `se_tap.wav` | 調査タップ・UI | `soft muted UI tap, subtle` |
| `se_lock_open.wav` | 数字/文字錠が外れる | `heavy old mechanical lock unlatching, satisfying metallic clunk` |
| `se_wrong.wav` | 暗証ミス | `low dull error buzz, short, discouraging` |
| `se_pickup.wav` | アイテム入手(gives) | `soft item pick-up, paper and metal rustle, gentle chime` |
| `se_combine.wav` | 合成成功 | `two objects fitting together, soft mechanical click, success` |
| `se_door.wav` | 扉が開く/部屋移動 | `old wooden door creaking open, echo` |
| `se_glyph_light.wav` | 符号(GEDÄCHTNIS)点灯 | `eerie shimmering tone as an arcane glyph ignites, cold glow` |
| `se_heartbeat.wav` | 脳死タイマー残少 | `slow ominous human heartbeat, single thump, loopable (再生間隔をコードで詰める)` |
| `se_overwrite.wav` | ①記憶を書き換える | `memory glitch and rewind, reversing tape with digital corruption, unsettling` |
| `se_face.wav` | ①直視する | `deep resonant tone of confronting a hard truth, heavy, somber` |
| `se_verdict.wav` | 推理を確定する | `weighty judgment confirm, low gavel-like impact` |
| `se_anagram.wav` | R13 アナグラム収束 | `slot-machine reels spinning and clicking into place, ending on a tense minor chord` |
| `se_verlust.wav` | VERLUST 割込 | `blood-red glitch slam, sudden dread sting, distorted` |
| `se_flatline.wav` | 結末D 脳死 | `ECG monitor flatline, continuous high beep, clinical` |

---

## 3. おすすめツール（生成・入手）

### AI音楽（BGM向け）
| ツール | 得意 | 商用 | 備考 |
|---|---|---|---|
| **Suno** | テキストから楽曲。手軽・高品質 | 有料プランで商用可 | 「instrumental」指定でボーカル無しに。ループ用に終端を整える |
| **Udio** | 同上・音質評価高い | 規約確認 | 雰囲気もの得意 |
| **Stable Audio** | **商用ライセンスが明確**・ループ/効果音も | 可（プラン） | 広告収益で権利を気にするなら有力。SFXもいける |

### SFX（効果音向け）
| ツール | 得意 | 商用 | 備考 |
|---|---|---|---|
| **ElevenLabs Sound Effects** | **テキストからSFX生成**（§2のプロンプトをそのまま） | プラン確認 | 短尺の作成に最適 |
| **Freesound.org** | 膨大な実録SFX | **CC0は自由／CC-BYは帰属表示必須** | ライセンス要確認 |
| **Pixabay / Mixkit** | 無料SFX・BGM | 商用可が多い | 手軽。規約は各素材で確認 |

> ⚠️ **商用ライセンス必須確認**（広告収益＝商用）。AI音楽は**有料プランでないと商用不可**なツールが多い。素材は CC0 か商用可＋帰属条件を確認。

---

## 4. 実装フック（コード側・今後の作業）

オーディオは**未実装**。導入時の指針：
1. `pubspec.yaml` に `audioplayers`（軽量）or `just_audio` を追加、`assets/audio/` を登録。
2. `lib/audio_service.dart`（仮）を作り、BGMループ1系統＋SE発火を集約（広告スタブと同様、最初はOFFでも可）。
3. 発火ポイント：
   - **BGM**：章替わり（R1/R5/R10）と30号室・各結末でクロスフェード切替（`DeepCampaignFlow` のフェーズ/部屋indexで判定）。
   - **se_glyph_light**：部屋クリア＝符号点灯時（`_clear`）。
   - **se_lock_open / se_wrong**：`_showLock` の正誤。
   - **se_pickup / se_combine**：`gives` / `_combine`。
   - **se_heartbeat**：`_remaining`（脳死タイマー）が閾値以下で再生、残り少で間隔短縮。
   - **se_overwrite / se_face**：①の `_overwriteMemory` / `_faceMemory`。
   - **se_anagram / se_verlust**：`VerlustRevealScreen` の各フェーズ。
   - **se_flatline**：Ending D（`_deathView`）。
   - **se_verdict**：`FinalJudgmentScreen` の「確定」。

---

## 5. 制作優先度
- **P0**：`bgm_ch1`／`bgm_title`／`se_lock_open`／`se_wrong`／`se_pickup`／`se_tap`（最小限で“鳴る”土台）
- **P1**：`bgm_ch2`/`bgm_ch3`/`bgm_finale`／`se_glyph_light`／`se_door`／`se_combine`／`se_heartbeat`
- **P2**：エンディング曲4種／`se_anagram`/`se_verlust`/`se_flatline`／`se_overwrite`/`se_face`/`se_verdict`

> まず P0 を数本そろえ、`audio_service` を仮実装して“音が出る”状態を作るのが近道。BGMは1章分でも雰囲気が激変します。

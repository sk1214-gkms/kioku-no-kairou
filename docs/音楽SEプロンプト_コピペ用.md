# BGM・SE プロンプト（コピペ用）

各プロンプトを**そのまま貼るだけ**で使えるようにした版。詳細・ムード解説・実装フックは [音響仕様書](音響仕様書_BGM_SE.md)。
出力ファイルは `assets/audio/<name>` に置く（例 `assets/audio/bgm_ch1.mp3`）。命名は音響仕様書と一致させる。

## 貼り付け先と設定（重要）
- **BGM → Suno / Udio / Stable Audio**：Custom（詳細）モードの **Style / Description** 欄に貼る。**Instrumental を ON**（歌詞なし）。長さ 60〜120秒でループ書き出し。
- **SE → ElevenLabs「Sound Effects」**：プロンプト欄に貼るだけ。0.2〜2秒の短尺。
- ⚠️ **商用ライセンス必須**（広告収益＝商用）。AI音楽は**有料プランで商用可**なツールが多い。必ず各ツールの規約を確認。

---

## BGM（章・タイトル）

### bgm_title.mp3 ── タイトル（不穏で美しい・喪失の予感）
```
Dark ambient main theme, melancholic music box and sustained strings, beautiful but deeply unsettling, a sense of lost memory, slow tempo, seamless loop, instrumental, no vocals
```

### bgm_ch1.mp3 ── 第1章 R1-R4（低い不安・混乱と違和感）
```
Minimal dark ambient, deep low drone, faint slow heartbeat, distant detuned piano, gothic mansion unease, seamless loop, instrumental, no vocals
```

### bgm_ch2.mp3 ── 第2章 R5-R9（増す緊張・医療が滲む）
```
Dark ambient with cold medical hum and monitor beeps, dissonant strings, subtle electronic glitches creeping in, rising tension, seamless loop, instrumental, no vocals
```

### bgm_ch3.mp3 ── 第3章 R10-R13（切迫・脳の崩壊）
```
Tense dark ambient, accelerating pulse, red-alert digital glitches and data corruption, the feeling of dying neurons, dread and urgency, seamless loop, instrumental, no vocals
```

### bgm_finale.mp3 ── 最終室 審判（厳粛・対決）
```
Solemn climactic dark ambient, deep choir pad, faint ticking clock, a moral reckoning, restrained and heavy, seamless loop, instrumental, no vocals
```

---

## BGM（エンディング・7結末で使い回し）

### bgm_end_serene.mp3 ── A＋／A（偽りの安らぎ）
```
Deceptively peaceful solo piano, warm but hollow and artificial, a beautiful lie with a hidden wrongness, slow, instrumental, no vocals
```

### bgm_end_horror.mp3 ── S／C／B（絶望・狂気）
```
Abyssal horror drone, distorted strings, whispering noise textures, despair and madness, instrumental, no vocals
```

### bgm_end_true.mp3 ── True（贖罪・受容）
```
Solemn redemptive piano and cello, quiet acceptance of guilt, bittersweet humanity, slow, instrumental, no vocals
```

### bgm_end_death.mp3 ── D（脳死・虚無）
```
A single ECG monitor tone fading into silence, cold emptiness, near-nothing, minimal, instrumental, no vocals
```

---

## SE（効果音・ElevenLabs Sound Effects 用）

### se_tap.wav ── 調査タップ・UI
```
Soft muted UI tap, subtle, short
```

### se_lock_open.wav ── 数字/文字錠が外れる
```
Heavy old mechanical lock unlatching, satisfying metallic clunk
```

### se_wrong.wav ── 暗証ミス
```
Low dull error buzz, short, discouraging
```

### se_pickup.wav ── アイテム入手
```
Soft item pick-up, paper and metal rustle, gentle chime
```

### se_combine.wav ── 合成成功
```
Two objects fitting together, soft mechanical click, success
```

### se_door.wav ── 扉が開く／部屋移動
```
Old wooden door creaking open, echo
```

### se_glyph_light.wav ── 符号（GEDÄCHTNIS）点灯
```
Eerie shimmering tone as an arcane glyph ignites, cold glow
```

### se_heartbeat.wav ── 脳死タイマー残少
```
Slow ominous human heartbeat, single deep thump
```

### se_overwrite.wav ── ①記憶を書き換える
```
Memory glitch and rewind, reversing tape with digital corruption, unsettling
```

### se_face.wav ── ①直視する
```
Deep resonant tone of confronting a hard truth, heavy, somber
```

### se_verdict.wav ── 推理を確定する
```
Weighty judgment confirm, low gavel-like impact
```

### se_anagram.wav ── R13 アナグラム収束
```
Slot-machine reels spinning and clicking into place, ending on a tense minor chord
```

### se_verlust.wav ── VERLUST 割込
```
Blood-red glitch slam, sudden dread sting, distorted
```

### se_flatline.wav ── 結末D 脳死
```
ECG monitor flatline, continuous high beep, clinical
```

---

## まず作る順（最小限で“鳴る”土台＝P0）
`bgm_ch1` ／ `bgm_title` ／ `se_lock_open` ／ `se_wrong` ／ `se_pickup` ／ `se_tap`
→ これだけで雰囲気が激変。次に P1（`bgm_ch2/ch3/finale`・`se_glyph_light/door/combine/heartbeat`）、P2（エンディング曲4・残りSE）。詳細な優先度は [音響仕様書 §5](音響仕様書_BGM_SE.md)。

/// 音響の発火点を集約するサービス。
/// 現状は **無音スタブ**（効果音/BGM音源と audioplayers 未導入。社内ネットDL不可のため）。
/// 自宅で `audioplayers` を pubspec に追加し、本クラス内部を実装＋ `enabled=true` にすれば
/// 既存の呼び出し（bgm/sfx）がそのまま鳴る。発火点は配線済み。
/// 音源名・対応イベントは docs/音響仕様書_BGM_SE.md を参照。
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  /// 音源を入れたら true に（pubspecへ audioplayers 追加＋下の 後日 実装）。
  static const bool enabled = false;

  /// ループBGM（key 例: 'ch1' 'ch2' 'ch3' 'finale' 'ending'）。
  void bgm(String key) {
    if (!enabled) return;
    // 後日: assets/audio/bgm_$key.mp3 をクロスフェードでループ再生
  }

  void stopBgm() {
    if (!enabled) return;
    // 後日
  }

  /// 単発SE（key 例: 'lock_open' 'wrong' 'pickup' 'glyph_light'
  /// 'overwrite' 'face' 'heartbeat' 'anagram' 'verlust' 'flatline' 'verdict'）。
  void sfx(String key) {
    if (!enabled) return;
    // 後日: assets/audio/se_$key.(wav|mp3) を再生
  }
}

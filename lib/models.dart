/// データモデル群。data/ 配下の JSON 構造（stage.schema.json）に対応する。
library;

double _toD(dynamic v) => (v as num).toDouble();

List<String>? _toStrList(dynamic v) =>
    v == null ? null : (v as List).map((e) => e.toString()).toList();

class Prerequisite {
  final String interactable;
  final String state;
  Prerequisite(this.interactable, this.state);

  factory Prerequisite.fromJson(Map<String, dynamic> m) =>
      Prerequisite(m['interactable'] as String, m['state'] as String);
}

/// branch タイプの選択肢。選ぶと story テキスト表示＋メーター/フラグを更新。
class BranchOption {
  final String id;
  final String label;
  final String text; // 表示するストーリーテキストID
  final String? meter; // 加算するメーター名（例: confront）
  final int delta; // メーターの増減
  final String? setFlag;

  BranchOption({
    required this.id,
    required this.label,
    required this.text,
    this.meter,
    this.delta = 0,
    this.setFlag,
  });

  factory BranchOption.fromJson(Map<String, dynamic> m) => BranchOption(
        id: m['id'] as String,
        label: m['label'] as String,
        text: m['text'] as String,
        meter: m['meter'] as String?,
        delta: (m['delta'] as num?)?.toInt() ?? 0,
        setFlag: m['set_flag'] as String?,
      );
}

class Gimmick {
  final String type; // number_pad | text_input | sequence_tap | state_toggle | condition | drag | branch
  final List<Prerequisite> prerequisites;
  final Map<String, dynamic> solutions; // normal/hard。値は String か List
  final String validate; // exact | case_insensitive | order
  final List<BranchOption>? branches; // branch タイプの選択肢

  Gimmick({
    required this.type,
    required this.prerequisites,
    required this.solutions,
    required this.validate,
    this.branches,
  });

  factory Gimmick.fromJson(Map<String, dynamic> m) => Gimmick(
        type: m['type'] as String,
        prerequisites: ((m['prerequisites'] as List?) ?? [])
            .map((e) => Prerequisite.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
        solutions: (m['solutions'] as Map?)?.cast<String, dynamic>() ?? {},
        validate: (m['validate'] as String?) ?? 'exact',
        branches: (m['branches'] as List?)
            ?.map((e) => BranchOption.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class Interactable {
  final String id;
  final List<double> rect; // [x, y, w, h]
  final String? zoomImage;
  final String? reveals;
  final List<String>? revealsGlyphs; // hard: 回廊文字の手がかり
  final List<String>? revealsGlyphsReflected; // hard: 鏡文字（反転）
  final String? labelGlyph; // hard: ボタン等のラベルが回廊文字
  final bool toggle;
  final List<String> states;
  final String? givesItem;
  final bool hidden;
  final bool decoy; // hard: 偽の手がかり（論理で除外させる）
  // --- アイテム使用（item_use）---
  final String? requiresItem; // この対象に「使う」のに必要なアイテムID
  final String? onUseState; // 使用後にこの interactable をこの状態にする（prerequisites 連動）
  final String? onUseGivesItem; // 使用後に入手するアイテム
  final String? onUseReveals; // 使用後に見える手がかり
  // --- ドラッグ（drag）---
  final bool draggable; // ドラッグできるピース
  final bool slot; // ピースの受け皿
  final List<Prerequisite>? requiresState; // この対象が反応する前提状態（例：照明=off）
  final String? altReveal; // altWhen が成立した時に見せる別の手がかり
  final List<Prerequisite>? altWhen; // altReveal を出す条件（例：照明=off）

  Interactable({
    required this.id,
    required this.rect,
    this.zoomImage,
    this.reveals,
    this.revealsGlyphs,
    this.revealsGlyphsReflected,
    this.labelGlyph,
    this.toggle = false,
    this.states = const [],
    this.givesItem,
    this.hidden = false,
    this.decoy = false,
    this.requiresItem,
    this.onUseState,
    this.onUseGivesItem,
    this.onUseReveals,
    this.draggable = false,
    this.slot = false,
    this.requiresState,
    this.altReveal,
    this.altWhen,
  });

  factory Interactable.fromJson(Map<String, dynamic> m) => Interactable(
        id: m['id'] as String,
        rect: (m['rect'] as List).map(_toD).toList(),
        zoomImage: m['zoom_image'] as String?,
        reveals: m['reveals'] as String?,
        revealsGlyphs: _toStrList(m['reveals_glyphs']),
        revealsGlyphsReflected: _toStrList(m['reveals_glyphs_reflected']),
        labelGlyph: m['label_glyph'] as String?,
        toggle: (m['toggle'] as bool?) ?? false,
        states: ((m['states'] as List?) ?? []).map((e) => e.toString()).toList(),
        givesItem: m['gives_item'] as String?,
        hidden: (m['hidden'] as bool?) ?? false,
        decoy: (m['decoy'] as bool?) ?? false,
        requiresItem: m['requires_item'] as String?,
        onUseState: m['on_use_state'] as String?,
        onUseGivesItem: m['on_use_gives_item'] as String?,
        onUseReveals: m['on_use_reveals'] as String?,
        draggable: (m['draggable'] as bool?) ?? false,
        slot: (m['slot'] as bool?) ?? false,
        requiresState: (m['requires_state'] as List?)
            ?.map((e) => Prerequisite.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        altReveal: m['reveals_alt'] as String?,
        altWhen: (m['alt_when'] as List?)
            ?.map((e) => Prerequisite.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

class Rewards {
  final String memoryId;
  final String textFull;
  final String textCorrupt;
  final String? item;

  Rewards({
    required this.memoryId,
    required this.textFull,
    required this.textCorrupt,
    this.item,
  });

  factory Rewards.fromJson(Map<String, dynamic> m) => Rewards(
        memoryId: m['memory_id'] as String,
        textFull: m['text_full'] as String,
        textCorrupt: m['text_corrupt'] as String,
        item: m['item'] as String?,
      );
}

/// ハードモードでの上書き（interactables / gimmick / hints）。
/// modifiers は難化レバーの宣言（cipher / decoy / hidden_clue / extra_step / scramble / indirection）。
class StageHard {
  final List<String>? modifiers;
  final List<Interactable>? interactables;
  final Gimmick? gimmick;
  final List<String>? hints;

  StageHard({this.modifiers, this.interactables, this.gimmick, this.hints});

  factory StageHard.fromJson(Map<String, dynamic> m) => StageHard(
        modifiers: _toStrList(m['modifiers']),
        interactables: (m['interactables'] as List?)
            ?.map((e) => Interactable.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        gimmick: m['gimmick'] != null
            ? Gimmick.fromJson((m['gimmick'] as Map).cast<String, dynamic>())
            : null,
        hints: _toStrList(m['hints']),
      );
}

class Stage {
  final int stageId;
  final String name;
  final Map<String, dynamic> assets;
  final List<Interactable> interactables;
  final Gimmick? gimmick;
  final List<String> hints;
  final Rewards? rewards;
  final StageHard? hard;

  // 最終室（final_room.json）専用フィールド
  final String? promptText;
  final Map<String, dynamic>? deduction;
  final List<Map<String, dynamic>>? choices;

  Stage({
    required this.stageId,
    required this.name,
    required this.assets,
    required this.interactables,
    this.gimmick,
    this.hints = const [],
    this.rewards,
    this.hard,
    this.promptText,
    this.deduction,
    this.choices,
  });

  factory Stage.fromJson(Map<String, dynamic> m) => Stage(
        stageId: m['stage_id'] as int,
        name: (m['name'] as String?) ?? '',
        assets: (m['assets'] as Map?)?.cast<String, dynamic>() ?? {},
        interactables: ((m['interactables'] as List?) ?? [])
            .map((e) => Interactable.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        gimmick: m['gimmick'] != null
            ? Gimmick.fromJson((m['gimmick'] as Map).cast<String, dynamic>())
            : null,
        hints: ((m['hints'] as List?) ?? []).map((e) => e.toString()).toList(),
        rewards: m['rewards'] != null
            ? Rewards.fromJson((m['rewards'] as Map).cast<String, dynamic>())
            : null,
        hard: m['hard'] != null
            ? StageHard.fromJson((m['hard'] as Map).cast<String, dynamic>())
            : null,
        promptText: m['prompt_text'] as String?,
        deduction: (m['deduction'] as Map?)?.cast<String, dynamic>(),
        choices: (m['choices'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList(),
      );
}

/// セーブ状態。結末を決める変数そのもの（save_template.json 相当）。
class GameState {
  String mode;
  final Map<String, String> memories; // memory_id -> unknown | corrupted | full
  final List<String> items;
  final Map<String, bool> flags; // has_culprit_evidence / deduction_correct
  final Map<String, int> meters; // 逃避⇄直面 等の軸（例: confront）

  GameState({
    required this.mode,
    required this.memories,
    required this.items,
    required this.flags,
    required this.meters,
  });

  factory GameState.initial(List<Stage> stages, {String mode = 'normal'}) {
    final mem = <String, String>{};
    for (final s in stages) {
      if (s.rewards != null) mem[s.rewards!.memoryId] = 'unknown';
    }
    return GameState(
      mode: mode,
      memories: mem,
      items: [],
      flags: {
        'has_culprit_evidence': false,
        'deduction_correct': false,
        'deduction_answered': false,
      },
      meters: {},
    );
  }

  /// full の記憶の割合（0〜100）
  int get memoryScore {
    if (memories.isEmpty) return 0;
    final full = memories.values.where((v) => v == 'full').length;
    return (full * 100 / memories.length).round();
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'memories': memories,
        'items': items,
        'flags': flags,
        'meters': meters,
      };

  factory GameState.fromJson(Map<String, dynamic> m) => GameState(
        mode: m['mode'] as String,
        memories: (m['memories'] as Map)
            .map((k, v) => MapEntry(k.toString(), v.toString())),
        items: (m['items'] as List).map((e) => e.toString()).toList(),
        flags: (m['flags'] as Map)
            .map((k, v) => MapEntry(k.toString(), v as bool)),
        meters: (m['meters'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
            <String, int>{},
      );
}

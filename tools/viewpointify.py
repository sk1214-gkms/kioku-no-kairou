#!/usr/bin/env python
"""4方向(views)の部屋JSONを、1壁=1ノードの視点(viewpoints)へ機械変換する。

- 各 views.<dir> を 1ノードへ移す（複数dirを同一node_idにマップすると objects を結合＝壁の集約）。
- オブジェクトは**一切改変せずそのままコピー**（lock/dialogue/editable_memory/chase/subview/record/flags等を完全保持）。
- 扉ノードをハブ(start_node)にし、他ノードへの goto を固定rectで付与。
- bg_variants は差分画像が未生成のため一旦除去（後で差分画像を作ったら手で戻す）。
- 既に viewpoints 化済み(views無し)の部屋はスキップ。

対応表(ROOMS)は §13.4（docs/SDプロンプト_コピペ用.md）に対応。
"""
import json
import os

ROOMS = {
    "r4":  {"door": "south", "map": {"north": ("at_portrait", "r4_portrait"), "east": ("at_shelf", "r4_shelf"), "west": ("at_desk", "r4_desk"), "south": ("at_door", "r4_door")}},
    "r5":  {"door": "south", "map": {"north": ("at_chart", "r5_chart"), "east": ("at_couch", "r5_couch"), "west": ("at_cabinet", "r5_cabinet"), "south": ("at_door", "r5_door")}},
    "r6":  {"door": "south", "map": {"north": ("at_board", "r6_board"), "east": ("at_files", "r6_files"), "west": ("at_log", "r6_log"), "south": ("at_door", "r6_door")}},
    "r7":  {"door": "south", "map": {"north": ("at_hall", "r7_hall"), "east": ("at_blood", "r7_blood"), "west": ("at_mud", "r7_mud"), "south": ("at_door", "r7_door")}},
    "r8":  {"door": "south", "map": {"west": ("at_switch", "r8_switch"), "north": ("at_mirror", "r8_mirror"), "east": ("at_mirror", "r8_mirror"), "south": ("at_door", "r8_door")}},
    "r9":  {"door": "south", "map": {"north": ("at_shelf", "r9_specimens"), "east": ("at_desk", "r9_desk"), "west": ("at_cabinet", "r9_cabinet"), "south": ("at_door", "r9_door")}},
    "r10": {"door": "south", "map": {"west": ("at_power", "r10_power"), "north": ("at_monitors", "r10_monitors"), "east": ("at_monitors", "r10_monitors"), "south": ("at_door", "r10_door")}},
    "r11": {"door": "south", "map": {"north": ("at_table", "r11_table"), "east": ("at_chart", "r11_chart"), "west": ("at_tray", "r11_tray"), "south": ("at_door", "r11_door")}},
    "r12": {"door": "south", "map": {"north": ("at_evidence", "r12_evidence"), "east": ("at_files", "r12_files"), "west": ("at_photos", "r12_photos"), "south": ("at_door", "r12_door")}},
    "r13": {"door": "south", "map": {"north": ("at_glyphs", "r13_glyphs"), "east": ("at_glyphs", "r13_glyphs"), "west": ("at_glyphs", "r13_glyphs"), "south": ("at_door", "r13_door")}},
}
GOTO_RECTS = [[0, 150, 52, 360], [308, 150, 52, 360], [120, 556, 120, 74]]
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def label_to_goto(lbl):
    # "北：肖像画" -> "肖像画の方へ"
    core = lbl.split("：")[-1] if "：" in lbl else lbl
    return f"{core}の方へ"


def convert(rid, cfg):
    path = os.path.join(BASE, "data", "deep_rooms", f"{rid}.json")
    d = json.load(open(path, encoding="utf-8"))
    if "views" not in d:
        print(f"{rid}: viewsなし→スキップ")
        return
    views = d.pop("views")
    d.pop("bg_variants", None)
    mp = cfg["map"]
    nodes = {}
    for dir_, view in views.items():
        if dir_ not in mp:
            print(f"{rid}: !! 未対応view {dir_}")
            continue
        nid, bg = mp[dir_]
        if nid not in nodes:
            nodes[nid] = {"label": view.get("label", nid), "bg": bg, "objects": []}
        nodes[nid]["objects"].extend(view["objects"])
    door_nid = mp[cfg["door"]][0]
    others = [nid for nid in nodes if nid != door_nid]
    for i, nid in enumerate(others):
        r = GOTO_RECTS[i] if i < len(GOTO_RECTS) else GOTO_RECTS[-1]
        nodes[door_nid]["objects"].append({
            "id": f"go_{nid}", "rect": r,
            "label": label_to_goto(nodes[nid]["label"]), "goto": nid,
        })
    # start_node と viewpoints を挿入（viewsがあった位置の代わりに末尾へ）
    d["start_node"] = door_nid
    d["viewpoints"] = nodes
    json.dump(d, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"{rid}: start={door_nid} nodes={list(nodes.keys())}")


if __name__ == "__main__":
    for rid, cfg in ROOMS.items():
        convert(rid, cfg)

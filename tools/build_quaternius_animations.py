"""Baut die Animations-Datei für alle Quaternius-Figuren.

Aufruf:
    python3 tools/build_quaternius_animations.py <UAL1_Standard.glb> <UAL2_Standard.glb> <Zielordner>

Nimmt die benötigten Animationen aus der "Universal Animation Library" 1 und 2 (ohne Root Motion)
und schreibt sie in EINE Datei: Animations.gltf (+ .bin) mit demselben Skelett wie Male.gltf/Female.gltf.
Im Spiel kopiert scenes/characters/modular_character.gd die Animationen in jede Figur.
Welche davon sich endlos wiederholen, steht in modular_character.gd (LOOPING).
(Bewusst ohne "_Loop" im Namen: Godot würde die Endung beim Import abschneiden.)
Weitere Animationen: Namen unten in ANIMATIONS eintragen und das Skript neu laufen lassen
(alle Namen zeigt https://quaternius.com/animviewer.html).
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from gltf_util import Gltf, Writer  # noqa: E402

# Name im Spiel -> (Bibliothek 1 oder 2, Name in der Bibliothek)
ANIMATIONS = {
    # Grundbewegung
    "Idle": (1, "Idle_Loop"),
    "Walk": (1, "Walk_Loop"),
    "Jog": (1, "Jog_Fwd_Loop"),
    "Sprint": (1, "Sprint_Loop"),
    "Roll": (1, "Roll"),
    # Kampf
    "Sword_Idle": (1, "Sword_Idle"),
    "Sword_Attack": (1, "Sword_Attack"),
    "Sword_Regular_A": (2, "Sword_Regular_A"),
    "Sword_Regular_B": (2, "Sword_Regular_B"),
    "Sword_Regular_C": (2, "Sword_Regular_C"),
    "Sword_Heavy_Combo": (2, "Sword_Heavy_Combo"),
    "Sword_Block": (2, "Sword_Block"),
    "Punch_Jab": (1, "Punch_Jab"),
    "Punch_Cross": (1, "Punch_Cross"),
    "Melee_Hook": (2, "Melee_Hook"),
    "Spell_Shoot": (1, "Spell_Simple_Shoot"),
    "Spell_Idle": (1, "Spell_Simple_Idle_Loop"),
    "Throw": (2, "OverhandThrow"),
    "Shield_Idle": (2, "Idle_Shield_Loop"),
    "Hit_Chest": (1, "Hit_Chest"),
    "Hit_Head": (1, "Hit_Head"),
    "Hit_Knockback": (2, "Hit_Knockback"),
    "Death": (1, "Death01"),
    "Revive": (2, "LayToIdle"),
    # Gesten
    "Interact": (1, "Interact"),
    "PickUp": (1, "PickUp_Table"),
    "Drink": (2, "Consume"),
    "Open_Chest": (2, "Chest_Open"),
    "Yes": (2, "Yes"),
    # Stadtbewohner
    "Talk": (1, "Idle_Talking_Loop"),
    "Torch_Idle": (1, "Idle_Torch_Loop"),
    "FoldArms": (2, "Idle_FoldArms_Loop"),
    "Lantern": (2, "Idle_Lantern_Loop"),
    "Sitting": (1, "Sitting_Idle_Loop"),
    "Chop": (2, "TreeChopping_Loop"),
    "Fixing_Kneeling": (1, "Fixing_Kneeling"),
    "Dance": (1, "Dance_Loop"),
    # Untote
    "Zombie_Idle": (2, "Zombie_Idle_Loop"),
    "Zombie_Walk": (2, "Zombie_Walk_Fwd_Loop"),
    "Zombie_Attack": (2, "Zombie_Scratch"),
    "Crouch_Walk": (1, "Crouch_Fwd_Loop"),
}


def qnorm(q):
    return q / np.linalg.norm(q, axis=-1, keepdims=True)


class Clip:
    def __init__(self, n):
        self.n = n
        self.times = None
        self.rot = {}  # Knochen -> (n, 4)
        self.pos = {}  # nur pelvis/root -> (n, 3); andere Verschiebungen würden die Körperform ändern


def read_clips(g):
    clips = {}
    for a in g.j["animations"]:
        times = g.acc(a["samplers"][0]["input"])
        c = Clip(len(times))
        c.times = times
        for ch in a["channels"]:
            name = g.j["nodes"][ch["target"]["node"]]["name"]
            out = g.acc(a["samplers"][ch["sampler"]]["output"]).astype(np.float32)
            if len(out) == 1:
                out = np.repeat(out, c.n, 0)
            if ch["target"]["path"] == "rotation":
                c.rot[name] = qnorm(out)
            elif ch["target"]["path"] == "translation" and name in ("pelvis", "root"):
                c.pos[name] = out
        clips[a["name"]] = c
    return clips


def main():
    ual1, ual2, out_dir = sys.argv[1:4]
    libs = {1: Gltf(ual1), 2: Gltf(ual2)}
    clips = {k: read_clips(g) for k, g in libs.items()}
    made = {}
    for name, (lib, src) in ANIMATIONS.items():
        if src not in clips[lib]:
            print(f"  fehlt: {src} in Bibliothek {lib}")
            continue
        made[name] = clips[lib][src]
    write(libs[1], made, os.path.join(out_dir, "Animations.gltf"))


def write(g, made, path):
    w = Writer()
    names = {}
    src_nodes = g.j["nodes"]
    skin = g.j["skins"][0]
    old_to_new = {}

    def copy_node(old):
        n = src_nodes[old]
        new = {k: n[k] for k in ("name", "translation", "rotation", "scale") if k in n}
        idx = w.add_node(new)
        old_to_new[old] = idx
        names[n["name"]] = idx
        kids = [copy_node(c) for c in n.get("children", []) if c in skin["joints"]]
        if kids:
            w.j["nodes"][idx]["children"] = kids
        return idx

    root = copy_node(g.node("root"))
    joints = [old_to_new[i] for i in skin["joints"]]
    # Winziges unsichtbares Dreieck, damit Godot das Skelett genauso wie bei den Figuren anlegt.
    ibm = g.acc(skin["inverseBindMatrices"])
    w.j["skins"].append({"name": "Armature", "joints": joints, "inverseBindMatrices": w.add(ibm.astype(np.float32))})
    tri = np.array([[0, 0, 0], [0.001, 0, 0], [0, 0.001, 0]], np.float32)
    prim = {"attributes": {"POSITION": w.add(tri, 34962, minmax=True),
                           "JOINTS_0": w.add(np.zeros((3, 4), np.uint16), 34962),
                           "WEIGHTS_0": w.add(np.tile(np.array([1, 0, 0, 0], np.float32), (3, 1)), 34962)}}
    w.j["meshes"].append({"name": "Dummy", "primitives": [prim]})
    dummy = w.add_node({"name": "Dummy", "mesh": 0, "skin": 0})
    w.add_node({"name": "Armature", "children": [root, dummy]}, root=True)

    for name in sorted(made):
        c = made[name]
        times = w.add(c.times.astype(np.float32), minmax=True)
        anim = {"name": name, "samplers": [], "channels": []}
        for bone, q in c.rot.items():
            if bone not in names:
                continue
            anim["samplers"].append({"input": times, "output": w.add(qnorm(q).astype(np.float32)), "interpolation": "LINEAR"})
            anim["channels"].append({"sampler": len(anim["samplers"]) - 1, "target": {"node": names[bone], "path": "rotation"}})
        for bone, p in c.pos.items():
            anim["samplers"].append({"input": times, "output": w.add(p.astype(np.float32)), "interpolation": "LINEAR"})
            anim["channels"].append({"sampler": len(anim["samplers"]) - 1, "target": {"node": names[bone], "path": "translation"}})
        w.j["animations"].append(anim)
    w.save(path)
    print(f"Animationen: {len(made)}, {len(w.blob) // 1024} KB")


if __name__ == "__main__":
    main()

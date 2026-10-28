"""Baut die Monster aus dem Quaternius-Pack "Bestiary - Dungeon Monsters Kit" für das Spiel um.

Aufruf:  python3 tools/build_quaternius_monsters.py <Exports/GLB (Godot-Unreal)> <Textures> <Zielordner>

Die Monster haben dasselbe Skelett wie die Menschen, also passen alle Animationen aus
Animations.gltf. Nur die Hüfthöhe ist anders: Die Animationen setzen die Hüfte auf
Menschenhöhe (0,95 m). Deshalb wird jedes Monster hier so vergrößert, dass seine Hüfte
genau so hoch ist. Im Spiel wird es dann mit `MONSTER_SCALE` wieder auf seine echte Größe
verkleinert (siehe scenes/characters/monster.gd).

Weggelassen werden Normal- und ORM-Maps und zusätzliche UV-/Farbkanäle, die Farbtexturen
werden auf 1024 px verkleinert (Leuchttextur 512 px).
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from gltf_util import Gltf, Writer  # noqa: E402

HUMAN_PELVIS = 0.949
TEX_SIZE = 1024
MONSTERS = ["Imp", "Puglin"]


def save_texture(src, dst, size):
    im = Image.open(src).convert("RGB")
    if im.width > size:
        im = im.resize((size, size), Image.LANCZOS)
    im.save(dst, optimize=True)


def build(name, glb_dir, tex_dir, out_dir):
    src = Gltf(os.path.join(glb_dir, name + ".glb"))
    j = src.j
    skin = j["skins"][0]
    joints = set(skin["joints"])
    w = Writer()

    # Hüfthöhe in der Grundhaltung (Weltkoordinaten) bestimmen.
    def world_y(target):
        def walk(i, parents):
            if i == target:
                return parents + [i]
            for c in j["nodes"][i].get("children", []):
                r = walk(c, parents + [i])
                if r:
                    return r
        chain = walk(j["scenes"][0]["nodes"][0], [])
        m = np.eye(4)
        for i in chain:
            n = j["nodes"][i]
            t = np.eye(4)
            t[:3, 3] = n.get("translation", [0, 0, 0])
            x, y, z, ww = n.get("rotation", [0, 0, 0, 1])
            r = np.eye(4)
            r[:3, :3] = [[1 - 2 * (y * y + z * z), 2 * (x * y - z * ww), 2 * (x * z + y * ww)],
                         [2 * (x * y + z * ww), 1 - 2 * (x * x + z * z), 2 * (y * z - x * ww)],
                         [2 * (x * z - y * ww), 2 * (y * z + x * ww), 1 - 2 * (x * x + y * y)]]
            s = np.diag(list(n.get("scale", [1, 1, 1])) + [1])
            m = m @ t @ r @ s
        return m[1, 3]

    factor = HUMAN_PELVIS / world_y(src.node("pelvis"))

    old_to_new = {}

    def copy(old):
        n = j["nodes"][old]
        node = {k: n[k] for k in ("name", "rotation", "scale") if k in n}
        if "translation" in n:
            node["translation"] = [v * factor for v in n["translation"]]
        idx = w.add_node(node)
        old_to_new[old] = idx
        kids = [copy(c) for c in n.get("children", []) if c in joints]
        if kids:
            w.j["nodes"][idx]["children"] = kids
        return idx

    root = copy(src.node("root"))
    ibm = src.acc(skin["inverseBindMatrices"]).copy()
    # Spaltenweise gespeichert: Verschiebung steht in [3, :3].
    ibm[:, 3, :3] *= factor
    w.j["skins"].append({"name": name, "joints": [old_to_new[i] for i in skin["joints"]],
                         "inverseBindMatrices": w.add(ibm.astype(np.float32))})

    textures = {}
    for variant in (1, 2, 3):
        textures[variant] = f"T_{name}_BaseColor_{variant}.png"
        save_texture(os.path.join(tex_dir, textures[variant]), os.path.join(out_dir, textures[variant]), TEX_SIZE)
    emissive = f"T_{name}_Emissive.png"
    save_texture(os.path.join(tex_dir, emissive), os.path.join(out_dir, emissive), 512)
    w.j["images"] = [{"uri": textures[1]}, {"uri": emissive}]
    w.j["textures"] = [{"sampler": 0, "source": 0}, {"sampler": 0, "source": 1}]
    w.j["materials"] = [{
        "name": name,
        "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0.0, "roughnessFactor": 0.8},
        "emissiveTexture": {"index": 1},
        "emissiveFactor": [1, 1, 1],
    }]

    mesh_nodes = []
    for n in j["nodes"]:
        if "mesh" not in n:
            continue
        prims = []
        for p in j["meshes"][n["mesh"]]["primitives"]:
            a = p["attributes"]
            wgt = src.acc(a["WEIGHTS_0"]).astype(np.float32)
            wgt /= np.maximum(wgt.sum(1, keepdims=True), 1e-6)
            pos = (src.acc(a["POSITION"]) * factor).astype(np.float32)
            idx = src.acc(p["indices"]).astype(np.uint32)
            prims.append({
                "attributes": {
                    "POSITION": w.add(pos, 34962, minmax=True),
                    "NORMAL": w.add(src.acc(a["NORMAL"]).astype(np.float32), 34962),
                    "TEXCOORD_0": w.add(src.acc(a["TEXCOORD_0"]).astype(np.float32), 34962),
                    "JOINTS_0": w.add(src.acc(a["JOINTS_0"]).astype(np.uint16), 34962),
                    "WEIGHTS_0": w.add(wgt, 34962),
                },
                "indices": w.add(idx.astype(np.uint16 if len(pos) < 65535 else np.uint32), 34963),
                "material": 0,
            })
        mesh_name = n["name"].replace("Teen_Male.004", name + "_Shorts")
        w.j["meshes"].append({"name": mesh_name, "primitives": prims})
        mesh_nodes.append(w.add_node({"name": mesh_name, "mesh": len(w.j["meshes"]) - 1, "skin": 0}))

    w.add_node({"name": "Armature", "children": [root] + mesh_nodes}, root=True)
    w.save(os.path.join(out_dir, name + ".gltf"))
    print(f"{name}: Faktor {factor:.3f} (im Spiel {1 / factor:.3f}), {len(mesh_nodes)} Teile, {len(w.blob) // 1024} KB")


def main():
    glb_dir, tex_dir, out_dir = sys.argv[1:4]
    os.makedirs(out_dir, exist_ok=True)
    for name in MONSTERS:
        build(name, glb_dir, tex_dir, out_dir)


if __name__ == "__main__":
    main()

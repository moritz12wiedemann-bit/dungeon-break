"""Wandelt die OBJ-Modelle aus dem Quaternius-Pack "Updated Modular Dungeon" (Mai 2019) in glTF um.

Aufruf:  python3 tools/build_quaternius_dungeon.py <Pack/OBJ> <Zielordner>

Das Pack gibt es nur als FBX/OBJ/Blend. Die Modelle haben keine Texturen, nur einfarbige
Materialien (Kd in der .mtl-Datei). Daraus wird pro Modell eine .gltf-Datei mit einem
Material pro Farbe. Gleiche Farben heißen in allen Dateien gleich, damit Godot sie teilen kann.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from gltf_util import Writer  # noqa: E402

# Doppelt vorhandene oder nicht gebrauchte Modelle.
SKIP = {"Arch_Door_bottompivot"}


def read_mtl(path):
    colors = {}
    name = None
    for line in open(path, encoding="utf-8", errors="ignore"):
        p = line.split()
        if not p:
            continue
        if p[0] == "newmtl":
            name = p[1]
        elif p[0] == "Kd" and name:
            colors[name] = [float(v) for v in p[1:4]]
    return colors


def read_obj(path):
    verts, normals = [], []
    groups = {}  # Material -> Liste von Dreiecken (je 3 x (v, vn))
    current = None
    for line in open(path, encoding="utf-8", errors="ignore"):
        p = line.split()
        if not p:
            continue
        if p[0] == "v":
            verts.append([float(v) for v in p[1:4]])
        elif p[0] == "vn":
            normals.append([float(v) for v in p[1:4]])
        elif p[0] == "usemtl":
            current = p[1]
        elif p[0] == "f":
            corners = []
            for c in p[1:]:
                parts = c.split("/")
                v = int(parts[0]) - 1
                n = int(parts[2]) - 1 if len(parts) > 2 and parts[2] else -1
                corners.append((v, n))
            tris = groups.setdefault(current, [])
            for k in range(1, len(corners) - 1):
                tris.append((corners[0], corners[k], corners[k + 1]))
    return np.array(verts, np.float32), np.array(normals, np.float32), groups


def convert(obj_path, out_dir, materials):
    name = os.path.splitext(os.path.basename(obj_path))[0]
    colors = read_mtl(os.path.splitext(obj_path)[0] + ".mtl")
    verts, normals, groups = read_obj(obj_path)
    w = Writer()
    prims = []
    for mat, tris in groups.items():
        corners = np.array(tris, np.int64).reshape(-1, 2)
        pos = verts[corners[:, 0]]
        if (corners[:, 1] >= 0).all():
            nrm = normals[corners[:, 1]]
        else:
            # Flächennormale, falls die Datei keine hat.
            t = pos.reshape(-1, 3, 3)
            fn = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
            fn /= np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-9)
            nrm = np.repeat(fn, 3, axis=0)
        # Gleiche Ecken zusammenfassen.
        key = np.concatenate([pos, nrm], 1).round(5)
        uniq, inverse = np.unique(key, axis=0, return_inverse=True)
        color = tuple(round(c, 4) for c in colors.get(mat, [0.6, 0.6, 0.6]))
        if color not in materials:
            materials[color] = "Dungeon_%02d" % len(materials)
        if materials[color] not in [m["name"] for m in w.j["materials"]]:
            w.j["materials"].append({"name": materials[color], "pbrMetallicRoughness": {
                "baseColorFactor": list(color) + [1.0], "metallicFactor": 0.0, "roughnessFactor": 0.9}})
        mat_index = [m["name"] for m in w.j["materials"]].index(materials[color])
        itype = np.uint16 if len(uniq) < 65535 else np.uint32
        prims.append({
            "attributes": {"POSITION": w.add(uniq[:, :3].astype(np.float32), 34962, minmax=True),
                           "NORMAL": w.add(uniq[:, 3:].astype(np.float32), 34962)},
            "indices": w.add(inverse.reshape(-1).astype(itype), 34963),
            "material": mat_index,
        })
    w.j["meshes"].append({"name": name, "primitives": prims})
    w.add_node({"name": name, "mesh": 0}, root=True)
    w.save(os.path.join(out_dir, name + ".gltf"))
    return len(w.blob)


def main():
    obj_dir, out_dir = sys.argv[1:3]
    os.makedirs(out_dir, exist_ok=True)
    materials = {}
    total = 0
    for f in sorted(os.listdir(obj_dir)):
        if f.endswith(".obj") and os.path.splitext(f)[0] not in SKIP:
            total += convert(os.path.join(obj_dir, f), out_dir, materials)
    print(f"{len(os.listdir(out_dir)) // 2} Modelle, {len(materials)} Farben, {total // 1024} KB")


if __name__ == "__main__":
    main()

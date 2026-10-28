"""Baut aus den Quaternius-Packs die Figuren-Dateien für Dungeon Break.

Aufruf:
    python3 tools/build_quaternius_characters.py <Outfits> <OutfitTextures> <BaseCharacters> <Hair> <Zielordner>

- <Outfits>: "Modular Character Outfits - Fantasy/Exports/glTF (Godot-Unreal)/Outfits"
- <OutfitTextures>: "Modular Character Outfits - Fantasy/Textures" (für die Farbvarianten)
- <BaseCharacters>: "Universal Base Characters/Base Characters/Godot - UE"
- <Hair>: "Universal Base Characters/Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)"

Ergebnis im Zielordner:
- Male.gltf / Female.gltf: ein Skelett mit ALLEN Teilen (Kleidung von Bauer + Waldläufer, Kopf,
  Augen, Frisuren, Bärte, Augenbrauen). Welche Teile sichtbar sind und welche Farben sie haben,
  entscheidet im Spiel scenes/characters/modular_character.gd anhand einer Vorlage.
- Texturen (auf 1024 px verkleinert, ohne Normal-/ORM-Maps, damit die Web-Version klein bleibt).
  Die Haare sind aufgehellt, damit man sie im Spiel beliebig einfärben kann.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
from gltf_util import Gltf, Writer  # noqa: E402

TEX_SIZE = 1024
# Standardfarben (im Spiel pro Figur änderbar). Haut und Haare werden damit multipliziert:
# Haut weiß = Originalfarbe der Textur, Haare sind aufgehellt und bekommen hier ihre Farbe.
SKIN_COLOR = (1.0, 1.0, 1.0)
HAIR_COLOR = (0.35, 0.22, 0.12)

# Kleidung: neuer Name im Spiel -> Name im Pack (ohne "Male_"/"Female_"). Mehrere = erster vorhandener.
OUTFIT_PARTS = {
    "Ranger_Hood": ["Ranger_Head_Hood"],
    "Ranger_Pauldrons": ["Ranger_Acc_Pauldron", "Ranger_Acc_Pauldrons"],
    "Ranger_Arms": ["Ranger_Arms"],
    "Ranger_Bracers": ["Ranger_Arms_Bracer"],
    "Ranger_Body": ["Ranger_Body"],
    "Ranger_Belt_1": ["Ranger_Body_Belt_1"],
    "Ranger_Belt_2": ["Ranger_Body_Belt_2", "Ranger_Body_Belt_1.001"],
    "Ranger_Legs": ["Ranger_Legs"],
    "Ranger_Boots": ["Ranger_Feet_Boots", "Ranger_Feet"],
    "Peasant_Arms": ["Peasant_Arms"],
    "Peasant_Body": ["Peasant_Body"],
    "Peasant_Legs": ["Peasant_Legs"],
    "Peasant_Feet": ["Peasant_Feet"],
}

# Frisuren usw.: neuer Name im Spiel -> Datei im Hair-Ordner
HAIR_PARTS = {
    "Hair_Buzzed": "Hair_Buzzed",
    "Hair_BuzzedFemale": "Hair_BuzzedFemale",
    "Hair_SimpleParted": "Hair_SimpleParted",
    "Hair_Long": "Hair_Long",
    "Hair_Buns": "Hair_Buns",
    "Beard": "Hair_Beard",
    "Eyebrows_Regular": "Eyebrows_Regular",
    "Eyebrows_Female": "Eyebrows_Female",
}

# Material im Pack -> (Material im Spiel, Textur-Datei, Grundfarbe)
MATERIALS = {
    "MI_Peasant": ("Peasant", "T_Peasant_BaseColor.png", None),
    "MI_Ranger": ("Ranger", "T_Ranger_BaseColor.png", None),
    "MI_Regular_Male": ("Skin", "T_Skin_Male.png", SKIN_COLOR),
    "MI_Regular_Female": ("Skin", "T_Skin_Female.png", SKIN_COLOR),
    "MI_Superhero_Male": ("Skin_Head", "T_Head_Male.png", SKIN_COLOR),
    "MI_Superhero_Female": ("Skin_Head", "T_Head_Female.png", SKIN_COLOR),
    "MI_Eyes": ("Eyes", "T_Eye_Brown.png", None),
    "MI_Hair_1": ("Hair", "T_Hair_1.png", HAIR_COLOR),
    "MI_Hair_2": ("Hair_Long", "T_Hair_2.png", HAIR_COLOR),
}


def save_texture(src, dst, size=TEX_SIZE):
    if os.path.exists(dst):
        return
    im = Image.open(src).convert("RGB")
    if im.width > size:
        im = im.resize((size, size), Image.LANCZOS)
    im.save(dst, optimize=True)


def neutral_texture(src, dst):
    """Textur durch ihre typische Farbe teilen: fast weiß, aber mit den feinen Unterschieden
    (Lippen, Falten, Haarsträhnen). Im Spiel wird sie mit der Haut-/Haarfarbe multipliziert."""
    if os.path.exists(dst):
        return
    im = Image.open(src).convert("RGB").resize((TEX_SIZE, TEX_SIZE), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32) / 255.0
    typical = np.median(a.reshape(-1, 3), 0)
    out = np.clip(a / typical * 0.85, 0, 1)
    Image.fromarray((out * 255).astype(np.uint8)).save(dst, optimize=True)


class Builder:
    def __init__(self, skeleton_src):
        self.w = Writer()
        self.src = skeleton_src
        skin = skeleton_src.j["skins"][0]
        self.joint_names = [skeleton_src.j["nodes"][i]["name"] for i in skin["joints"]]
        self.old_to_new = {}
        root_new = self._copy_node(skeleton_src.node("root"), set(skin["joints"]))
        self.joints = [self.old_to_new[i] for i in skin["joints"]]
        self.armature = self.w.add_node({"name": "Armature", "children": [root_new]}, root=True)
        self.mat_index = {}
        self.mesh_nodes = []

    def _copy_node(self, old, joints):
        n = self.src.j["nodes"][old]
        idx = self.w.add_node({k: n[k] for k in ("name", "translation", "rotation", "scale") if k in n})
        self.old_to_new[old] = idx
        kids = [self._copy_node(c, joints) for c in n.get("children", []) if c in joints]
        if kids:
            self.w.j["nodes"][idx]["children"] = kids
        return idx

    def material(self, src_name):
        name, tex, color = MATERIALS[src_name]
        if name in self.mat_index:
            return self.mat_index[name]
        w = self.w
        pbr = {"metallicFactor": 0.0, "roughnessFactor": 0.4 if name == "Eyes" else 0.85}
        w.j["images"].append({"uri": tex})
        w.j["textures"].append({"sampler": 0, "source": len(w.j["images"]) - 1})
        pbr["baseColorTexture"] = {"index": len(w.j["textures"]) - 1}
        if color:
            pbr["baseColorFactor"] = list(color) + [1.0]
        w.j["materials"].append({"name": name, "pbrMetallicRoughness": pbr, "doubleSided": True})
        self.mat_index[name] = len(w.j["materials"]) - 1
        return self.mat_index[name]

    def skin_from(self, src, name):
        """Eigene Bindung (inverse bind matrices) für Teile aus einer anderen Datei, aber dieselben Knochen."""
        s = src.j["skins"][0]
        names = [src.j["nodes"][i]["name"] for i in s["joints"]]
        ibm_src = src.acc(s["inverseBindMatrices"])
        ibm = np.tile(np.eye(4, dtype=np.float32), (len(self.joint_names), 1, 1))
        for k, nm in enumerate(names):
            ibm[self.joint_names.index(nm)] = ibm_src[k]
        self.w.j["skins"].append({"name": name, "joints": self.joints, "inverseBindMatrices": self.w.add(ibm)})
        remap = np.array([self.joint_names.index(nm) for nm in names], np.uint16)
        return len(self.w.j["skins"]) - 1, remap

    def prim(self, src, p, remap, tri_filter=None):
        w = self.w
        a = p["attributes"]
        pos = src.acc(a["POSITION"]).astype(np.float32)
        nrm = src.acc(a["NORMAL"]).astype(np.float32)
        uv = src.acc(a["TEXCOORD_0"]).astype(np.float32)
        jnt = remap[src.acc(a["JOINTS_0"]).astype(np.int64)]
        wgt = src.acc(a["WEIGHTS_0"]).astype(np.float32)
        idx = src.acc(p["indices"]).astype(np.uint32).reshape(-1, 3)
        if tri_filter is not None:
            idx = idx[tri_filter(idx, jnt, wgt)]
            used = np.unique(idx)
            lut = np.full(len(pos), -1, np.int64)
            lut[used] = np.arange(len(used))
            pos, nrm, uv, jnt, wgt = pos[used], nrm[used], uv[used], jnt[used], wgt[used]
            idx = lut[idx].astype(np.uint32)
        wgt = wgt / np.maximum(wgt.sum(1, keepdims=True), 1e-6)
        itype = np.uint16 if len(pos) < 65535 else np.uint32
        return {
            "attributes": {
                "POSITION": w.add(pos, 34962, minmax=True),
                "NORMAL": w.add(nrm, 34962),
                "TEXCOORD_0": w.add(uv, 34962),
                "JOINTS_0": w.add(jnt.astype(np.uint16), 34962),
                "WEIGHTS_0": w.add(wgt, 34962),
            },
            "indices": w.add(idx.reshape(-1).astype(itype), 34963),
            "material": self.material(src.j["materials"][p["material"]]["name"]),
        }

    def add_mesh(self, name, src, mesh, skin, remap, tri_filter=None):
        prims = [self.prim(src, p, remap, tri_filter) for p in mesh["primitives"]]
        self.w.j["meshes"].append({"name": name, "primitives": prims})
        self.mesh_nodes.append(self.w.add_node({"name": name, "mesh": len(self.w.j["meshes"]) - 1, "skin": skin}))

    def save(self, path):
        self.w.j["nodes"][self.armature]["children"] += self.mesh_nodes
        self.w.save(path)
        return len(self.mesh_nodes), len(self.w.blob) // 1024


def build(gender, outfits, base_dir, hair_dir, out_dir):
    ranger = Gltf(os.path.join(outfits, f"{gender}_Ranger.gltf"))
    peasant = Gltf(os.path.join(outfits, f"{gender}_Peasant.gltf"))
    body = Gltf(os.path.join(base_dir, f"Superhero_{gender}_FullBody.gltf"))
    b = Builder(ranger)

    for src, label in ((ranger, "Ranger"), (peasant, "Peasant")):
        skin, remap = b.skin_from(src, label)
        meshes = {m["name"].split("_", 1)[1]: m for m in src.j["meshes"]}
        for new_name, candidates in OUTFIT_PARTS.items():
            if not new_name.startswith(label):
                continue
            m = next((meshes[c] for c in candidates if c in meshes), None)
            if m is None:
                print(f"  {gender}: Teil {new_name} fehlt im Pack")
                continue
            b.add_mesh(new_name, src, m, skin, remap)

    # Kopf aus der Grundfigur herausschneiden: alles, was am Kopf- oder Halsknochen hängt.
    # (Laut Quaternius braucht man zu den Outfits nur den Kopf, der Rest würde durchscheinen.)
    skin, remap = b.skin_from(body, "Head")
    head_ids = [b.joint_names.index("Head"), b.joint_names.index("neck_01")]

    def head_filter(idx, jnt, wgt):
        on_head = (np.isin(jnt, head_ids) * wgt).sum(1) >= 0.5
        return on_head[idx].any(1)

    for m in body.j["meshes"]:
        mats = [body.j["materials"][p["material"]]["name"] for p in m["primitives"]]
        if mats[0].startswith("MI_Superhero"):
            b.add_mesh("Head", body, m, skin, remap, head_filter)
        elif mats[0] == "MI_Eyes":
            b.add_mesh("Eyes", body, m, skin, remap)

    for new_name, file in HAIR_PARTS.items():
        hair = Gltf(os.path.join(hair_dir, file + ".gltf"))
        skin, remap = b.skin_from(hair, new_name)
        b.add_mesh(new_name, hair, hair.j["meshes"][0], skin, remap)

    parts, kb = b.save(os.path.join(out_dir, f"{gender}.gltf"))
    print(f"{gender}: {parts} Teile, {kb} KB")


def main():
    outfits, outfit_tex, base_dir, hair_dir, out_dir = sys.argv[1:6]
    os.makedirs(out_dir, exist_ok=True)
    for f in ("T_Peasant_BaseColor.png", "T_Ranger_BaseColor.png"):
        save_texture(os.path.join(outfits, f), os.path.join(out_dir, f))
    # Farbvarianten der Kleidung
    save_texture(os.path.join(outfit_tex, "Peasant", "T_Peasant_2_BaseColor.png"), os.path.join(out_dir, "T_Peasant_2_BaseColor.png"))
    save_texture(os.path.join(outfit_tex, "Ranger", "T_Ranger_3_BaseColor.png"), os.path.join(out_dir, "T_Ranger_3_BaseColor.png"))
    save_texture(os.path.join(base_dir, "T_Eye_Brown.png"), os.path.join(out_dir, "T_Eye_Brown.png"))
    save_texture(os.path.join(outfits, "T_Regular_Male_Dark_BaseColor.png"), os.path.join(out_dir, "T_Skin_Male.png"))
    save_texture(os.path.join(outfits, "T_Regular_Female_Dark_BaseColor.png"), os.path.join(out_dir, "T_Skin_Female.png"))
    save_texture(os.path.join(base_dir, "T_Superhero_Male_Dark.png"), os.path.join(out_dir, "T_Head_Male.png"))
    save_texture(os.path.join(base_dir, "T_Superhero_Female_Dark_BaseColor.png"), os.path.join(out_dir, "T_Head_Female.png"))
    neutral_texture(os.path.join(hair_dir, "T_Hair_1_BaseColor.png"), os.path.join(out_dir, "T_Hair_1.png"))
    neutral_texture(os.path.join(hair_dir, "T_Hair_2_BaseColor.png"), os.path.join(out_dir, "T_Hair_2.png"))
    build("Male", outfits, base_dir, hair_dir, out_dir)
    build("Female", outfits, base_dir, hair_dir, out_dir)


if __name__ == "__main__":
    main()

"""Übernimmt glTF-Modelle aus einem Quaternius-Pack für Dungeon Break.

Aufruf:
    python3 tools/build_quaternius_props.py <glTF-Ordner des Packs> <Zielordner> [Modell1,Modell2,...] [Texturgröße]

Benutzt für:
    Fantasy Props MegaKit:   "<Pack>/Exports/glTF" assets/models/quaternius/props          (alle Modelle)
    Medieval Village MegaKit: "<Pack>/glTF" assets/models/quaternius/village <Liste> 512   (Liste: VILLAGE)
    Stylized Nature MegaKit:  "<Pack>/glTF" assets/models/quaternius/nature <Liste> 512    (Liste: NATURE)

Die Modelle selbst bleiben unverändert. Damit die Web-Version klein bleibt, werden nur die
Farb-Texturen (verkleinert) behalten; Normal- und ORM-Maps fallen weg.
"""
import glob
import json
import os
import shutil
import sys

from PIL import Image

TEX_SIZE = 1024

# Teile aus dem Medieval Village MegaKit, aus denen die Häuser gebaut werden (tools/build_town_houses.py),
# dazu Zaun und Pflaster für die Stadt.
VILLAGE = [
    "Wall_Plaster_Straight", "Wall_Plaster_Door_Round", "Wall_Plaster_Window_Wide_Round",
    "Wall_UnevenBrick_Straight", "Wall_UnevenBrick_Door_Round", "Wall_UnevenBrick_Window_Wide_Round",
    "Corner_Exterior_Wood", "Corner_Exterior_Brick", "Door_1_Round", "Window_Wide_Round1",
    "WindowShutters_Wide_Round_Open", "Roof_RoundTiles_4x4", "Roof_RoundTiles_6x6", "Roof_RoundTiles_6x8",
    "Roof_Front_Brick4", "Roof_Front_Brick6", "Prop_Chimney", "Prop_WoodenFence_Single",
    "Floor_UnevenBrick",
]
NATURE = [
    "CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5",
    "Pine_1", "Pine_2", "Pine_3", "Pine_5", "Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3",
    "Bush_Common", "Bush_Common_Flowers", "Fern_1", "Plant_1", "Plant_7", "Grass_Common_Short",
    "Grass_Common_Tall", "Grass_Wispy_Short", "Flower_3_Group", "Flower_4_Group", "Clover_1",
    "Mushroom_Common",
]
LISTS = {"VILLAGE": VILLAGE, "NATURE": NATURE}


def main():
    src_dir, out_dir = sys.argv[1:3]
    only = None
    if len(sys.argv) > 3:
        only = LISTS.get(sys.argv[3]) or sys.argv[3].split(",")
    tex_size = int(sys.argv[4]) if len(sys.argv) > 4 else TEX_SIZE
    os.makedirs(out_dir, exist_ok=True)
    textures = set()
    paths = sorted(glob.glob(os.path.join(src_dir, "*.gltf")))
    if only:
        paths = [os.path.join(src_dir, n + ".gltf") for n in only]
    for path in paths:
        j = json.load(open(path))
        images, tex_new = [], []

        def keep(tex_index):
            uri = j["images"][j["textures"][tex_index]["source"]]["uri"]
            if uri not in images:
                images.append(uri)
                tex_new.append({"sampler": 0, "source": len(images) - 1})
            return images.index(uri)

        for m in j["materials"]:
            pbr = m.get("pbrMetallicRoughness", {})
            m.pop("normalTexture", None)
            pbr.pop("metallicRoughnessTexture", None)
            if "baseColorTexture" in pbr:
                pbr["baseColorTexture"] = {"index": keep(pbr["baseColorTexture"]["index"])}
            metal = "Metal" in m["name"]
            pbr["metallicFactor"] = 0.4 if metal else 0.0
            pbr["roughnessFactor"] = 0.55 if metal else 0.85
            m["pbrMetallicRoughness"] = pbr
        j["images"] = [{"uri": u} for u in images]
        j["textures"] = tex_new
        j["samplers"] = [{"magFilter": 9729, "minFilter": 9987}]
        textures.update(images)
        name = os.path.basename(path)
        with open(os.path.join(out_dir, name), "w") as f:
            json.dump(j, f, separators=(",", ":"))
        for b in j["buffers"]:
            shutil.copy(os.path.join(src_dir, b["uri"]), os.path.join(out_dir, b["uri"]))
    for t in sorted(textures):
        im = Image.open(os.path.join(src_dir, t))
        # Durchsichtige Stellen (z. B. Blätter) behalten, sonst ohne Alphakanal.
        if im.mode != "RGBA" or im.getchannel("A").getextrema()[0] == 255:
            im = im.convert("RGB")
        size = tex_size if "Page" not in t else 256
        if im.width > size:
            im = im.resize((size, round(im.height * size / im.width)), Image.LANCZOS)
        im.save(os.path.join(out_dir, t), optimize=True)
    print(f"{len(glob.glob(os.path.join(out_dir, '*.gltf')))} Modelle, Texturen: {sorted(textures)}")


if __name__ == "__main__":
    main()

"""Übernimmt die Modelle aus dem "Fantasy Props MegaKit" (Quaternius) für Dungeon Break.

Aufruf:
    python3 tools/build_quaternius_props.py "<Fantasy Props MegaKit>/Exports/glTF" <Zielordner>

Die Modelle selbst bleiben unverändert. Damit die Web-Version klein bleibt, werden nur die
Farb-Texturen (auf 1024 px verkleinert) behalten; Normal- und ORM-Maps fallen weg.
"""
import glob
import json
import os
import shutil
import sys

from PIL import Image

TEX_SIZE = 1024


def main():
    src_dir, out_dir = sys.argv[1:3]
    os.makedirs(out_dir, exist_ok=True)
    textures = set()
    for path in sorted(glob.glob(os.path.join(src_dir, "*.gltf"))):
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
        im = Image.open(os.path.join(src_dir, t)).convert("RGB")
        size = TEX_SIZE if "Page" not in t else 256
        if im.width > size:
            im = im.resize((size, size), Image.LANCZOS)
        im.save(os.path.join(out_dir, t), optimize=True)
    print(f"{len(glob.glob(os.path.join(out_dir, '*.gltf')))} Modelle, Texturen: {sorted(textures)}")


if __name__ == "__main__":
    main()

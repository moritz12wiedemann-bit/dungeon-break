"""Baut die Häuser der Stadt aus den Teilen des Quaternius "Medieval Village MegaKit" zusammen.

Aufruf:  python3 tools/build_town_houses.py [vorschau.json]

Schreibt pro Haus eine Szene nach scenes/world/houses/<name>.tscn. Ein Haus ist ein Rechteck aus
2 m breiten Wandstücken mit Dach. Vorne (Richtung +Z) sind Giebel und Tür.
Die Szenen kann man danach ganz normal im Godot-Editor weiter bearbeiten (Teile verschieben,
austauschen ...). Wer das Skript noch mal laufen lässt, überschreibt diese Änderungen.

Mit einer Datei als Argument wird zusätzlich eine Szenen-Beschreibung für die Vorschau in
three.js geschrieben (nur zum Testen).
"""
import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KIT = "res://assets/models/quaternius/village/"
WALL_HEIGHT = 3.12
ROOFS = {(4, 4): "Roof_RoundTiles_4x4", (6, 6): "Roof_RoundTiles_6x6", (6, 8): "Roof_RoundTiles_6x8",
         (8, 8): "Roof_RoundTiles_8x8"}

# Name: Breite (X), Tiefe (Z), Stil, Schornstein
HOUSES = {
    "smithy": (6, 6, "UnevenBrick", True),
    "tavern": (6, 8, "Plaster", True),
    "house_small": (4, 4, "Plaster", False),
    "house_brick": (4, 4, "UnevenBrick", True),
    "house_large": (6, 6, "Plaster", False),
}


def house_parts(width, depth, style, chimney):
    """Liste von (Modell, Position, Drehung um Y in Grad)."""
    parts = []
    corner = "Corner_Exterior_Brick" if style == "UnevenBrick" else "Corner_Exterior_Wood"
    # Seiten: (Mitte der Wand, Drehung, Länge, Richtung entlang der Wand)
    sides = [
        ("front", (0, depth / 2), 0, width, (1, 0)),
        ("back", (0, -depth / 2), 180, width, (-1, 0)),
        ("right", (width / 2, 0), 90, depth, (0, -1)),
        ("left", (-width / 2, 0), -90, depth, (0, 1)),
    ]
    for side, (cx, cz), angle, length, (ax, az) in sides:
        count = length // 2
        for i in range(count):
            t = -length / 2 + 1 + 2 * i
            x, z = cx + ax * t, cz + az * t
            if side == "front" and i == count // 2:
                kind = "Door_Round"
            elif side in ("left", "right") and i % 2 == 1 or side == "front" and count > 2 and i != count // 2:
                kind = "Window_Wide_Round"
            elif side == "back" and i == 0:
                kind = "Window_Wide_Round"
            else:
                kind = "Straight"
            parts.append((f"Wall_{style}_{kind}", (x, 0, z), angle))
            # Tür und Fenster in die Öffnungen setzen (Position relativ zur Wandmitte, nach außen +Z).
            rad = math.radians(angle)
            if kind == "Door_Round":
                # Die Tür dreht sich um ihre linke Kante.
                dx = -0.56
                parts.append(("Door_1_Round", (x + dx * math.cos(rad), 0, z - dx * math.sin(rad)), angle))
            elif kind == "Window_Wide_Round":
                parts.append(("Window_Wide_Round1", (x, 0, z), angle))
                if style == "Plaster":
                    parts.append(("WindowShutters_Wide_Round_Open", (x, 0, z), angle))
    for sx in (-1, 1):
        for sz in (-1, 1):
            # Eckpfosten; das Modell zeigt mit seiner Außenecke nach (+X, +Z) bei Drehung 0 ...
            angle = {(1, 1): 0, (1, -1): 90, (-1, -1): 180, (-1, 1): -90}[(sx, sz)]
            parts.append((corner, (sx * width / 2, 0, sz * depth / 2), angle))
    parts.append((ROOFS[(width, depth)], (0, WALL_HEIGHT, 0), 0))
    gable = f"Roof_Front_Brick{width}"
    parts.append((gable, (0, WALL_HEIGHT, depth / 2), 0))
    parts.append((gable, (0, WALL_HEIGHT, -depth / 2), 180))
    if chimney:
        parts.append(("Prop_Chimney", (width / 2 - 1.0, WALL_HEIGHT - 0.5, -depth / 4), 0))
    return parts


def write_scene(name, parts):
    models = sorted({p[0] for p in parts})
    ids = {m: f"{i + 1}_{m[:12].lower()}" for i, m in enumerate(models)}
    lines = [f"[gd_scene load_steps={len(models) + 1} format=3]", ""]
    for m in models:
        lines.append(f'[ext_resource type="PackedScene" path="{KIT}{m}.gltf" id="{ids[m]}"]')
    lines += ["", f'[node name="{name.title().replace("_", "")}" type="Node3D"]', ""]
    counts = {}
    for model, (x, y, z), angle in parts:
        counts[model] = counts.get(model, 0) + 1
        node = model if counts[model] == 1 else f"{model}{counts[model]}"
        c, s = math.cos(math.radians(angle)), math.sin(math.radians(angle))
        lines.append(f'[node name="{node}" parent="." instance=ExtResource("{ids[model]}")]')
        # Godot schreibt die Basis zeilenweise.
        lines.append(f"transform = Transform3D({c:.4g}, 0, {s:.4g}, 0, 1, 0, {-s:.4g}, 0, {c:.4g}, {x:.4g}, {y:.4g}, {z:.4g})")
        lines.append("")
    out = os.path.join(ROOT, "scenes", "world", "houses", name + ".tscn")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        f.write("\n".join(lines))


def main():
    preview = []
    offset = 0
    for name, (width, depth, style, chimney) in HOUSES.items():
        parts = house_parts(width, depth, style, chimney)
        write_scene(name, parts)
        for model, (x, y, z), angle in parts:
            preview.append({"f": "../assets/models/quaternius/village/" + model + ".gltf",
                            "p": [x + offset, y, z], "ry": math.radians(angle)})
        offset += width + 4
        print(name, len(parts), "Teile")
    if len(sys.argv) > 1:
        json.dump({"grid": 40, "items": preview, "cams": [
            {"pos": [offset / 2, 14, 26], "at": [offset / 2 - 4, 2, 0]},
            {"pos": [offset / 2, 14, -26], "at": [offset / 2 - 4, 2, 0]}]}, open(sys.argv[1], "w"))


if __name__ == "__main__":
    main()

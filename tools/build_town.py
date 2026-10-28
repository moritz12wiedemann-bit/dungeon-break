"""Schreibt die Stadt (scenes/levels/town.tscn) neu: Häuser, Figuren, Altäre, Möbel, Zaun, Laternen.

Aufruf:  python3 tools/build_town.py

Die Szene kann man danach ganz normal im Godot-Editor weiter bearbeiten. Wer dieses Skript noch
einmal laufen lässt, überschreibt solche Änderungen. Boden und Wald baut town.gd beim Start
(Einstellungen dazu stehen beim obersten Knoten "Town" im Inspektor).

Aufbau (Norden = -Z, die Kamera schaut von Südosten):
- Süden: Ankunft des Spielers, Straße nach Norden.
- Mitte: gepflasterter Marktplatz. Westlich Haus und Platz des Magischen Ältesten,
  östlich die Marktstände mit dem Händler.
- Norden: Dungeon-Altar und Endlos-Altar nebeneinander, links davon die Schmiede mit dem
  Schmied (Beute zerlegen direkt vor dem Dungeon), rechts die Taverne mit der Mystikerin.
- Hohe Häuser stehen nur im Norden und Westen, damit sie der Kamera nicht die Sicht nehmen.
"""
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROPS = "res://assets/models/quaternius/props/"
VILLAGE = "res://assets/models/quaternius/village/"
HOUSES = "res://scenes/world/houses/"

HALF = 20.0  # Zaun bei ±20 m

# Gepflasterte Flächen: (x, z, Breite, Tiefe), auf dem 2-m-Raster.
# Moritz' Wunsch: die ganze Stadt innerhalb des Zauns ist gepflastert.
PAVED = [
    (-HALF, -HALF, 2 * HALF, 2 * HALF),
]

# Häuser: Name, Szene, Mitte (x, z), Blickrichtung der Tür in Grad (0 = Süden/+Z, 90 = Osten/+X),
# Größe (Breite, Tiefe) für die Kollision.
BUILDINGS = [
    ("Smithy", "smithy", (-13, -14), 0, (6, 6)),
    ("Tavern", "tavern", (13, -14), 0, (6, 8)),
    ("ElderHouse", "house_brick", (-16, -3), 90, (4, 4)),
    ("HouseWest", "house_small", (-16, 7), 90, (4, 4)),
]
# Häuser draußen im Wald (ohne Kollision, da kommt man nicht hin).
FAR_HOUSES = [
    ("FarHouse", "house_large", (-31, -6), 90),
    ("FarHouse2", "house_small", (30, -12), -90),
    ("FarHouse3", "house_brick", (-8, -31), 0),
]

# Figuren: Knoten, Fenster, Name, Farbe, Vorlage, Stelle, Blick zu diesem Punkt.
NPCS = [
    ("Smith", "smith", "Schmied", "1, 0.65, 0.35, 1", "smith", (-11.5, -9.0), (0, 2)),
    ("Mystic", "mystic", "Mystikerin", "0.8, 0.6, 1, 1", "mystic", (11.5, -8.5), (0, 2)),
    ("Elder", "elder", "Magischer Ältester", "0.55, 0.85, 1, 1", "elder", (-11.5, -1.5), (4, 6)),
    ("Merchant", "merchant", "Händler", "1, 0.85, 0.3, 1", "merchant", (8.8, 0.0), (0, 6)),
]

# Möbel: Modell (aus props/ oder village/), Stelle, Drehung (Grad), Größe.
PROPS_LIST = [
    # Schmiede
    ("Anvil", (-9.8, -10.2), 30, 1.2), ("Workbench", (-15.0, -9.0), 0, 1.0),
    ("WeaponStand", (-10.0, -7.8), 60, 1.0), ("Barrel", (-16.2, -10.6), 0, 1.1),
    ("Crate_Metal", (-15.3, -10.8), 20, 0.8),
    # Taverne
    ("Barrel", (9.6, -10.6), 0, 1.1), ("Barrel", (10.4, -10.9), 40, 1.1),
    ("Crate_Wooden", (16.0, -9.0), 10, 1.0), ("Bench", (14.0, -8.2), 0, 1.0),
    # Marktstände des Händlers (Vorderseite zum Platz)
    ("Stall_Empty", (11.0, -2.2), -90, 1.15), ("Stall_Empty", (11.0, 2.2), -90, 1.15),
    ("FarmCrate_Apple", (9.6, -3.4), 15, 1.3), ("FarmCrate_Carrot", (9.6, 3.4), -10, 1.3),
    ("Crate_Wooden", (12.6, 0.0), 0, 0.9), ("Bag", (10.2, 1.0), 0, 0.6),
    ("Stall_Cart_Empty", (12.5, 7.0), -90, 1.0), ("Barrel_Apples", (14.0, 9.0), 0, 1.0),
    # Ältester
    ("BookStand", (-12.2, -3.4), 90, 1.0), ("CandleStick_Stand", (-12.8, -0.2), 0, 1.0),
    # Platz
    ("Bench", (-5.0, 3.2), 0, 1.0), ("Bench", (5.0, 3.2), 0, 1.0),
    ("Bucket_Wooden_1", (6.6, 3.0), 0, 1.2), ("Bag", (-6.6, 3.1), 0, 0.6),
    # Kleines Haus im Westen
    ("Barrel", (-13.4, 9.6), 0, 1.0), ("Crate_Wooden", (-13.6, 4.6), 30, 0.9),
]

# Laternenpfähle an der Straße und am Platz.
LANTERNS = [(-2.8, 8.0), (2.8, 8.0), (-2.8, 15.0), (2.8, 15.0), (-9.6, 4.6), (9.6, 4.6)]

PLAYER_START = (0.0, 14.0)
ALTARS = [(-4.0, -14.5), (4.0, -14.5)]


def tf(angle_deg=0.0, pos=(0, 0, 0), scale=1.0):
    """Transform3D als Text. Godot schreibt die Basis zeilenweise. Drehung um Y."""
    a = math.radians(angle_deg)
    c, s = math.cos(a) * scale, math.sin(a) * scale
    x, y, z = pos
    return f"Transform3D({c:.5g}, 0, {s:.5g}, 0, {scale:.5g}, 0, {-s:.5g}, 0, {c:.5g}, {x:.5g}, {y:.5g}, {z:.5g})"


def look_angle(frm, to):
    return math.degrees(math.atan2(to[0] - frm[0], to[1] - frm[1]))


class Scene:
    def __init__(self):
        self.ext = {}
        self.subs = []
        self.nodes = []

    def res(self, path, typ="PackedScene"):
        if path not in self.ext:
            base = os.path.splitext(os.path.basename(path))[0]
            self.ext[path] = (typ, f"{len(self.ext) + 1}_{base[:14].lower()}")
        return f'ExtResource("{self.ext[path][1]}")'

    def sub(self, typ, sid, body):
        self.subs.append(f'[sub_resource type="{typ}" id="{sid}"]\n{body}\n')
        return f'SubResource("{sid}")'

    def node(self, header, *lines):
        self.nodes.append(header + "\n" + "".join(l + "\n" for l in lines))

    def text(self):
        out = ["[gd_scene format=3]\n"]
        for path, (typ, rid) in self.ext.items():
            out.append(f'[ext_resource type="{typ}" path="{path}" id="{rid}"]')
        out.append("")
        out += self.subs
        out += self.nodes
        return "\n".join(out)


def box_body(sc, parent, name, center, size, height):
    shape = sc.sub("BoxShape3D", f"Shape_{name}", f"size = Vector3({size[0]:.4g}, {height:.4g}, {size[1]:.4g})")
    sc.node(f'[node name="{name}" type="StaticBody3D" parent="{parent}"]',
            f"transform = {tf(0, (center[0], height / 2, center[1]))}", "collision_mask = 0")
    sc.node(f'[node name="Collision" type="CollisionShape3D" parent="{parent}/{name}"]', f"shape = {shape}")


def build():
    sc = Scene()
    town_script = sc.res("res://scenes/levels/town.gd", "Script")
    player = sc.res("res://scenes/player/player.tscn")
    camera = sc.res("res://scenes/camera/iso_camera.tscn")
    hud = sc.res("res://scenes/ui/hud.tscn")
    altar = sc.res("res://scenes/world/dungeon_altar.tscn")
    npc = sc.res("res://scenes/world/npc.gd", "Script")

    env = sc.sub("Environment", "Environment_tw001", "\n".join([
        "background_mode = 1", "background_color = Color(0.35, 0.45, 0.6, 1)", "ambient_light_source = 2",
        "ambient_light_color = Color(0.72, 0.72, 0.78, 1)", "ambient_light_energy = 0.5", "tonemap_mode = 2"]))
    nav = sc.sub("NavigationMesh", "NavigationMesh_tw001", "\n".join([
        "geometry_parsed_geometry_type = 1", "geometry_collision_mask = 1", "cell_height = 0.1",
        "agent_height = 1.8", "agent_max_climb = 0.3"]))
    ground = sc.sub("BoxShape3D", "Shape_ground", f"size = Vector3({HALF * 2}, 1, {HALF * 2})")
    fence_x = sc.sub("BoxShape3D", "Shape_fence_x", f"size = Vector3({HALF * 2}, 1.2, 0.5)")
    fence_z = sc.sub("BoxShape3D", "Shape_fence_z", f"size = Vector3(0.5, 1.2, {HALF * 2})")

    paved = ", ".join(f"Rect2({x}, {z}, {w}, {d})" for x, z, w, d in PAVED)
    clear = ", ".join(f"Rect2({c[0]}, {c[1]}, 6, 0)" for _, _, c, _ in FAR_HOUSES)
    sc.node('[node name="Town" type="Node3D"]', f"script = {town_script}",
            f"paved_areas = Array[Rect2]([{paved}])", f"clearings = Array[Rect2]([{clear}])")
    sc.node('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]', f"environment = {env}")
    sc.node('[node name="Sun" type="DirectionalLight3D" parent="."]',
            "transform = Transform3D(0.8660254, -0.40957603, 0.28678823, 0, 0.57357645, 0.81915206, -0.5, -0.7094065, 0.49673176, 0, 0, 0)",
            "light_color = Color(1, 0.88, 0.75, 1)", "light_energy = 1.0", "shadow_enabled = true")
    sc.node('[node name="NavigationRegion3D" type="NavigationRegion3D" parent="."]', f"navigation_mesh = {nav}")
    geo = "NavigationRegion3D/Geometry"
    sc.node('[node name="Geometry" type="Node3D" parent="NavigationRegion3D"]')
    sc.node(f'[node name="Ground" type="StaticBody3D" parent="{geo}"]', f"transform = {tf(0, (0, -0.5, 0))}",
            "collision_mask = 0")
    sc.node(f'[node name="Collision" type="CollisionShape3D" parent="{geo}/Ground"]', f"shape = {ground}")
    for name, pos, shape in (("FenceNorth", (0, 0.6, -HALF), fence_x), ("FenceSouth", (0, 0.6, HALF), fence_x),
                             ("FenceWest", (-HALF, 0.6, 0), fence_z), ("FenceEast", (HALF, 0.6, 0), fence_z)):
        sc.node(f'[node name="{name}" type="StaticBody3D" parent="{geo}"]', f"transform = {tf(0, pos)}",
                "collision_mask = 0")
        sc.node(f'[node name="Collision" type="CollisionShape3D" parent="{geo}/{name}"]', f"shape = {shape}")

    # Altäre
    sc.node(f'[node name="DungeonAltar" parent="{geo}" instance={altar}]',
            f"transform = {tf(0, (ALTARS[0][0], 0, ALTARS[0][1]))}")
    sc.node(f'[node name="EndlessAltar" parent="{geo}" instance={altar}]',
            f"transform = {tf(0, (ALTARS[1][0], 0, ALTARS[1][1]))}", 'window_name = "endless"',
            "crystal_color = Color(0.95, 0.12, 0.08, 1)", 'title_text = "Endlos-Altar\n(anklicken: Endlos-Modus)"')

    # Häuser: Kollision unter Geometry, Aussehen unter Decor
    for name, scene, (x, z), angle, (w, d) in BUILDINGS:
        size = (w + 0.4, d + 0.4) if angle % 180 == 0 else (d + 0.4, w + 0.4)
        box_body(sc, geo, name, (x, z), size, 6.0)
    # Marktstände: ein Kasten für beide Stände
    box_body(sc, geo, "MarketStalls", (11.0, 0.0), (1.4, 6.6), 2.6)
    box_body(sc, geo, "Cart", (12.5, 7.0), (1.2, 3.2), 2.0)

    for node, window, label, color, model, (x, z), target in NPCS:
        sc.node(f'[node name="{node}" type="StaticBody3D" parent="{geo}"]',
                f"transform = {tf(look_angle((x, z), target), (x, 0, z))}", f"script = {npc}",
                f'window_name = "{window}"', f'display_name = "{label}"', f"name_color = Color({color})",
                f'model = {sc.res(f"res://scenes/characters/{model}.tscn")}')

    sc.node('[node name="Decor" type="Node3D" parent="."]')
    for name, scene, (x, z), angle, _ in BUILDINGS:
        sc.node(f'[node name="{name}" parent="Decor" instance={sc.res(HOUSES + scene + ".tscn")}]',
                f"transform = {tf(angle, (x, 0, z))}")
    for name, scene, (x, z), angle in FAR_HOUSES:
        sc.node(f'[node name="{name}" parent="Decor" instance={sc.res(HOUSES + scene + ".tscn")}]',
                f"transform = {tf(angle, (x, 0, z))}")
    counts = {}
    for model, (x, z), angle, scale in PROPS_LIST:
        counts[model] = counts.get(model, 0) + 1
        name = model if counts[model] == 1 else f"{model}{counts[model]}"
        sc.node(f'[node name="{name}" parent="Decor" instance={sc.res(PROPS + model + ".gltf")}]',
                f"transform = {tf(angle, (x, 0, z), scale)}")

    # Zaun rundherum (2 m pro Stück), im Süden eine Lücke für die Straße.
    fence = sc.res(VILLAGE + "Prop_WoodenFence_Single.gltf")
    post = sc.res(VILLAGE + "Corner_Exterior_Wood.gltf")
    sc.node('[node name="Fence" type="Node3D" parent="Decor"]')
    k = 0
    for side, angle in (("N", 0), ("S", 0), ("W", 90), ("E", 90)):
        for i in range(int(HALF)):
            t = -HALF + 1 + 2 * i
            if side == "S" and abs(t) < 2.5:
                continue
            x, z = {"N": (t, -HALF), "S": (t, HALF), "W": (-HALF, t), "E": (HALF, t)}[side]
            k += 1
            sc.node(f'[node name="Fence{k}" parent="Decor/Fence" instance={fence}]',
                    f"transform = Transform3D({math.cos(math.radians(angle)):.5g}, 0, {math.sin(math.radians(angle)):.5g}, 0, 1.1, 0, "
                    f"{-math.sin(math.radians(angle)):.5g}, 0, {math.cos(math.radians(angle)):.5g}, {x}, 0, {z})")
    for i, x in enumerate((-2.6, 2.6)):
        sc.node(f'[node name="GatePost{i + 1}" parent="Decor/Fence" instance={post}]',
                f"transform = Transform3D(1.3, 0, 0, 0, 0.8, 0, 0, 0, 1.3, {x}, 0, {HALF})")

    # Laternen: Holzpfahl, Laterne daran, Licht
    lantern = sc.res(PROPS + "Lantern_Wall.gltf")
    sc.node('[node name="Lights" type="Node3D" parent="."]')
    for i, (x, z) in enumerate(LANTERNS):
        # Die Laterne hängt zur Straße hin.
        angle = 90 if x < 0 else -90
        name = f"Lantern{i + 1}"
        sc.node(f'[node name="{name}" type="Node3D" parent="Decor"]', f"transform = {tf(angle, (x, 0, z))}")
        sc.node(f'[node name="Post" parent="Decor/{name}" instance={post}]',
                "transform = Transform3D(0.8, 0, 0, 0, 0.8333, 0, 0, 0, 0.8, 0, 0, 0)")
        sc.node(f'[node name="Lantern" parent="Decor/{name}" instance={lantern}]',
                "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.2, 0.1)")
        lx = x + (0.6 if x < 0 else -0.6)
        sc.node(f'[node name="Lamp{i + 1}" type="OmniLight3D" parent="Lights"]',
                f"transform = {tf(0, (lx, 2.3, z))}", "light_color = Color(1, 0.75, 0.45, 1)",
                "light_energy = 1.3", "omni_range = 8.0")

    sc.node(f'[node name="Player" parent="." instance={player}]',
            f"transform = {tf(180, (PLAYER_START[0], 0, PLAYER_START[1]))}")
    sc.node(f'[node name="IsoCamera" parent="." node_paths=PackedStringArray("target") instance={camera}]',
            'target = NodePath("../Player")')
    sc.node(f'[node name="HUD" parent="." instance={hud}]')
    with open(os.path.join(ROOT, "scenes", "levels", "town.tscn"), "w") as f:
        f.write(sc.text())
    print("town.tscn geschrieben:", len(sc.nodes), "Knoten")


if __name__ == "__main__":
    build()

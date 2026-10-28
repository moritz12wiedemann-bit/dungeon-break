# Dungeon Break

Ein Action-RPG im Stil von Diablo 3, gebaut mit **Godot 4.7** (GDScript, Compatibility-Renderer, damit es im Browser läuft), 3D mit fester Iso-Kamera.

## Im Browser spielen

**https://moritz12wiedemann-bit.github.io/dungeon-break/**

Bei jedem Push auf `main` baut die GitHub Action `.github/workflows/web.yml` automatisch den Web-Export (Preset „Web“ in `export_presets.cfg`, Single-Thread) und veröffentlicht ihn dort. Nach ein paar Minuten einfach die Seite neu laden.

## Starten (in Godot)

1. Godot 4.7 öffnen, im Projekt-Manager auf **Importieren** klicken und die Datei `project.godot` in diesem Ordner auswählen.
2. Im Editor oben rechts auf **▶ (F5)** drücken. Du startest in der Stadt.
3. **Linke Maustaste auf den Boden** klicken oder gedrückt halten: die Figur läuft zum Mauszeiger und findet selbst den Weg um Wände herum.
4. **Linke Maustaste auf einen Gegner**: die Figur läuft hin und schlägt so lange zu, bis er tot ist.
5. **Taste 1** oder Klick auf den roten Kreis rechts neben dem Lebensbalken: Heiltrank trinken (heilt 40 %, danach 20 Sekunden Abklingzeit).
6. **Klick auf einen Gegenstand am Boden**: hinlaufen und aufheben. **Taste I**: Inventar öffnen/schließen.
7. **Klick auf den Dungeon-Altar** (Schrein mit schwebender lila Kugel am Nordende des Stadtplatzes): Monsterstufe wählen, neuer Dungeon. **Taste T**: aus dem Dungeon zurück in die Stadt.
8. **Escape** schließt das oberste offene Fenster.

Das alte Testlevel (`scenes/levels/test_level.tscn`) gibt es noch. Zum Starten die Szene im Editor öffnen und **F6** („Aktuelle Szene starten“) drücken.

## Stadt und Dungeons

- **Stadt** (`scenes/levels/town.tscn`): sicherer Ort ohne Gegner. Der **Dungeon-Altar** öffnet bei jedem Klick einen neuen Dungeon.
- **Dungeon „Kalksteintempel“** (`scenes/levels/dungeon.tscn`): wird jedes Mal **zufällig erzeugt** (18–22 große Räume, kurze Gänge, Säulen). Der Startraum ist leer, der Boss-Raum ist weit weg. In den Räumen dazwischen stehen Puglins, manchmal ein großer roter Imp („Brocken“).
- Die Gegner sind so stark wie deine Stufe beim Betreten (pro Stufe +25 % Leben, +15 % Schaden, mehr XP).
- Besiegst du den **Boss** (blauer Riesen-Imp mit Leuchten), erscheint ein blaues **Portal**. Anklicken bringt dich in die Stadt.
- **Taste T** bringt dich jederzeit aus dem Dungeon in die Stadt (der Dungeon ist dann verloren, der Altar macht einen neuen).
- Stufe, Erfahrung, Inventar und Leben bleiben beim Wechsel erhalten (`scenes/game/game_state.gd`, als Autoload „GameState“ eingetragen). Beim Beenden des Spiels wird noch nichts gespeichert.
- Wie die Karten erzeugt werden, steht in `scenes/levels/dungeon_generator.gd`. Anzahl Gegner pro Raum und Chance auf Brocken: Dungeon-Szene öffnen, oberen Knoten `Dungeon` anklicken, Inspektor.

## Stadt-Figuren, Gold, Orbs und Endlos-Modus

- **Altäre**: Der lila Dungeon-Altar und der rote Endlos-Altar öffnen ein Fenster, in dem man die **Monsterstufe 1–100** wählt (`scenes/ui/altar_window.gd`). Höhere Stufe = stärkere Monster, mehr XP, bessere Beute.
- **Endlos-Modus** (`scenes/levels/endless.gd`): offene Arena, Monster tauchen immer schneller um dich herum auf und jagen dich. Alle 8 Kills +1 Monsterstufe. Beute (Gold, Gegenstände, Orbs) fällt erst nach dem Tod neben dir zu Boden. Zahlen im Inspektor der Szene `endless.tscn`.
- **Gold** fällt von Gegnern und aus **Schatzkisten** (`scenes/world/chest.gd`) und wird beim Drüberlaufen automatisch aufgehoben, ebenso Orbs (`scenes/items/ground_pickup.gd`). Alle Beute-Zahlen und Preise: `scenes/items/loot.gd`.
- **Schmied** (neben dem Dungeon-Altar): Gegenstände zerlegen → Altmetall, bei guten Gegenständen manchmal ein Orb.
- **Händler** (am Markt): 3 Gegenstände zum Kaufen, neue Ware nach jedem Boss-Sieg. Verkaufen bringt 25 % des Kaufpreises.
- **Mystikerin**: Augment-Karten für Gold kaufen und mit **Arcana** ausrüsten (Start 3, für Gold erhöhbar). Die Karten sind Platzhalter (`scenes/game/augment_cards.gd`).
- **Magischer Ältester**: Fähigkeiten leveln (1 Punkt pro Stufe), pro Fähigkeit Grundform oder einen von zwei Skillbäumen wählen, bis zu 3 passive Fähigkeiten wählen (`scenes/ui/elder_window.gd`).
- **Klassen und Skill-Leiste**: erste Klasse Krieger. Skill-Leiste über dem Erfahrungsbalken mit 6 Plätzen (Q, W, E, R, Linksklick, Rechtsklick); Linksklick ist bei jeder Klasse der Standardangriff. Klassen, Fähigkeiten und Passive stehen in `scenes/game/player_classes.gd`, die Leiste in `scenes/ui/skill_bar.gd`.
- Die Fenster der Figuren erben von `scenes/ui/game_window.gd`, die Figuren selbst von `scenes/world/npc.gd`.

## Gegenstände und Orbs

- Jeder Wert hat einen **Bereich**, der in Klammern dahinter steht, z. B. „+7 Rüstung (5–10)“. Tabellen in `scenes/items/item_generator.gd`.
- Die **Seltenheit** hängt an der Zahl der Werte: 1 = Normal (weiß), 2 = Magisch (blau), 3 = Selten (gelb), 4 = Legendär (orange). **Set**-Gegenstände (grün) haben auch 4 Werte und sind eine Alternative zu Legendär.
- Im Inventar (Taste I) gibt es den aufklappbaren Reiter **Materialien**. Orbs dort rechtsklicken, dann einen Gegenstand anklicken:
  - **Orb der Erweiterung**: fügt einen zufälligen Wert hinzu, Seltenheit steigt (höchstens Legendär).
  - **Orb der Läuterung**: entfernt einen zufälligen Wert (nie den Grundwert), Seltenheit sinkt.
  - **Orb des Wandels**: würfelt alle Werte in ihren Bereichen neu.
  - Set-Gegenstände kann man nur neu würfeln. Jeder startet mit 5 von jedem Orb.

## Grafik

Alle 3D-Modelle und Animationen sind von **Quaternius**, fast alle **CC0** (frei nutzbar, auch kommerziell). Ausnahme: die Monster (Bestiary) stehen unter der Quaternius Asset License: im Spiel frei nutzbar, aber die Modell-Dateien selbst darf man nicht als Asset-Pack weitergeben. Woher was kommt: [CREDITS.md](CREDITS.md).
Was es in den Packs nicht gab (Brunnen, Kirche, Windmühle, Turm, Fahnen ...), ist vorerst einfach weggelassen.

- **Figuren sind ein Baukasten** (`scenes/characters/modular_character.gd`). Jede Figur ist eine kleine Szene in `scenes/characters/` (z. B. `hero.tscn`, `smith.tscn`). Szene öffnen, oberen Knoten anklicken, im Inspektor umstellen, die Figur ändert sich sofort:
  - *Körper*: Mann/Frau, Hautfarbe, Frisur (Glatze, Kurz, Kurz (fein), Gescheitelt, Lang, Dutt), Bart, Haarfarbe, Größe.
  - *Kleidung*: für Oberteil, Arme, Hose und Schuhe jeweils „Bauer“ oder „Waldläufer“, dazu Kapuze, Gürtel, Schulterpanzer, Armschienen, Farbvariante (Bauer: Braun/Oliv, Waldläufer: Grün/Leder) und eine Tönung über alles.
  - *In den Händen*: Schwert, Axt, Spitzhacke, Schild, Buch, Krug, Kerzenhalter, Trank.
- **Monster** (`scenes/characters/monster.gd`): Puglin und Imp aus dem Bestiary, je 3 Farbvarianten, Tönung, Leuchten, Größe. Vorlagen `puglin.tscn` (normale Gegner), `imp.tscn` (große Gegner), `imp_boss.tscn` (Boss). Sie haben dasselbe Skelett wie die Menschen und benutzen dieselben Animationen.
- **Animationen**: 41 Stück aus der Universal Animation Library 1 und 2 (Liste in `tools/build_quaternius_animations.py`). Welche wofür benutzt wird, steht beim Kind-Knoten `Animator` von Spieler und Gegnern im Inspektor (`scenes/components/character_animator.gd`).
- **Anderes Gegner-Aussehen**: Gegner-Szene öffnen, oberen Knoten anklicken, im Inspektor unter „Aussehen“ eine andere Szene aus `scenes/characters/` bei `Model Scene` hineinziehen.
- **Dungeon**: Boden, Wände und Säulen aus dem Modular Dungeon, Fackeln, Banner, Fässer, Kisten und Kleinkram aus Modular Dungeon und Fantasy Props MegaKit (`scenes/levels/dungeon.gd`, Listen `PROPS`, `CLUTTER`, `BANNERS`). Hinten (oben/links im Bild) sind die Wände hoch, vorn (unten/rechts) niedrig.
- **Stadt**: `town.tscn` wird von `tools/build_town.py` geschrieben (Häuser, Figuren, Altäre, Möbel, Zaun, Laternen). Aufbau: Eingang im Süden, die Straße führt auf den gepflasterten Marktplatz mit dem Händler; am Nordende stehen Dungeon- und Endlos-Altar, links davon die Schmiede (Schmied), rechts die Taverne (Mystikerin), am Westrand das Haus des Ältesten. Boden und Wald baut `scenes/levels/town.gd` beim Start: Pflaster (Medieval Village) überall innerhalb des Zauns (Flächen aus `paved_areas`), draußen Wiese mit Bäumen, Büschen, Farnen, Blumen und Pilzen (Stylized Nature). Zum Umbauen am besten `build_town.py` ändern und neu ausführen. Die Häuser sind eigene Szenen in `scenes/world/houses/` (`tools/build_town_houses.py`).
- **Neue Modelle aus den Packs einbauen**: Die Original-Packs werden mit den Skripten in `tools/` umgewandelt (Texturen verkleinert, Teile zusammengefasst). Alle 94 Möbel/Gegenstände aus dem Fantasy Props MegaKit und alle Teile des Modular Dungeon liegen schon im Projekt, aus Village und Nature nur die benutzten (Listen `VILLAGE` und `NATURE` in `tools/build_quaternius_props.py`).

## Gegner und Kampf

- **Gegner** stehen still, bis du ihnen näher als ihre *Aggro-Reichweite* kommst und keine Wand dazwischen ist. Dann verfolgen sie dich und schlagen zu. Wer getroffen wird, wehrt sich sofort.
- Läufst du weit genug weg (*Leine*), geben sie auf, gehen zurück an ihren Platz und heilen sich.
- Oben links stehen Ort und übrige Gegner. Unten in der Mitte ist dein Lebensbalken. Gegner zeigen ihren Balken, sobald sie verletzt sind.
- Stirbst du, erscheint „Du bist gestorben!“. Mit **Wiederbeleben** stehst du an derselben Stelle wieder auf, mit 25 % Leben und 3 Sekunden Schutz.
- Leben kommt von selbst zurück: 1 Lebenspunkt pro Sekunde.

## Erfahrung und Stufen

- Besiegte Gegner geben Erfahrung (XP): normale Gegner 20, Brocken 80, Boss 400, jeweils mal Dungeon-Stufe. Der lila Balken unten zeigt Stufe und XP.
- Höchste Stufe ist **100**. Jede Stufe braucht mehr XP als die vorige: `100 × Stufe^1,6` (Stufe 1 → 2: 100 XP, Stufe 10: ca. 4.000, Stufe 50: ca. 52.000, Stufe 99: ca. 156.000).
- Pro Stufe: +10 maximale Lebenspunkte, +1 Schaden, und du wirst voll geheilt.
- Die Werte stehen im Spieler (Inspektor, Gruppen „Stufenaufstieg“, „Heiltrank“, „Wiederbeleben“) und im Kind-Knoten `Experience`.

Werte wie Lebenspunkte, Schaden, Tempo und Reichweiten kannst du im Editor ändern: Gegner (oder Spieler) in der Szene anklicken und rechts im **Inspektor** die Werte anpassen. Die Lebenspunkte stehen im Kind-Knoten `Health`.

## Gegenstände und Inventar

- Besiegte Gegner lassen manchmal Gegenstände fallen. Der Name am Boden hat die Farbe der Seltenheit: **Weiß** normal, **Blau** magisch, **Gelb** selten, **Orange** legendär, **Grün** Set. Ab Gelb leuchtet ein Lichtstrahl.
- Normale Gegner lassen in etwa jedem dritten Fall etwas fallen, meistens Weißes. Brocken lassen meistens etwas fallen, der Boss immer 2–4 Gegenstände, viel öfter gelbe, orange und grüne. Die Gegenstandsstufe ist die Dungeon-Stufe. Alle Chancen stehen als Tabellen oben in `scenes/items/item_generator.gd`; die Beute-Stufe eines Gegners ist `loot_tier` im Inspektor (0 normal, 1 groß, 2 Boss).
- Plätze: Helm, Handschuhe, Rüstung, Hose, Schuhe, Waffe. Waffen geben Schaden, alles andere Rüstung. Je seltener, desto mehr Zusatzwerte (Schaden, Rüstung, Leben, Leben pro Sekunde, Laufgeschwindigkeit).
- Im Inventar: **Linksklick** in der Tasche zieht an (das Alte wandert in die Tasche), **Linksklick** auf Ausrüstung zieht aus, **Rechtsklick** wirft weg. Maus über einen Gegenstand halten zeigt seine Werte.
- Rüstung verringert Schaden: erlittener Schaden × 100 / (100 + Rüstung). Laufgeschwindigkeit aus Ausrüstung ist auf +25 % begrenzt.

## Ordnerstruktur

| Ordner | Was liegt dort? |
| --- | --- |
| `scenes/levels/` | Stadt, zufälliger Dungeon samt Kartengenerator, altes Testlevel |
| `scenes/player/` | Spielerfigur: Szene + Skript |
| `scenes/characters/` | Figuren-Vorlagen (Baukasten `modular_character.gd`) für Spieler, Gegner und Stadtbewohner |
| `scenes/enemies/` | Gegner: `enemy.tscn` (normal), `enemy_brute.tscn` (Brocken, „erbt“ vom normalen), `enemy_boss.tscn` (Boss, erbt vom Brocken) |
| `scenes/world/` | Benutzbare Objekte: Dungeon-Altar, Portal in die Stadt (`interactable.gd` ist die gemeinsame Grundlage) |
| `scenes/game/` | `game_state.gd`: Spielstand, der Szenenwechsel überlebt |
| `scenes/items/` | Gegenstände: Daten (`item_data.gd`), Zufallsgenerator (`item_generator.gd`), Gegenstand am Boden |
| `scenes/components/` | Bausteine, die an Figuren gehängt werden: `health.gd` (Lebenspunkte, Regeneration), `experience.gd` (XP und Stufe), `inventory.gd` (Tasche und Ausrüstung), `character_animator.gd` (Animationen) |
| `scenes/camera/` | Iso-Kamera, die dem Spieler folgt |
| `scenes/ui/` | Bildschirm-Anzeige (HUD), Inventar-Fenster, Lebensbalken über Gegnern, Schadenszahlen |
| `assets/models/quaternius/` | 3D-Modelle von Quaternius: `characters` (Figuren-Teile, Animationen), `monsters` (Bestiary), `props` (Möbel, Waffen, Kisten, Deko), `dungeon` (Modular Dungeon), `village` (Häuser-Teile, Zäune), `nature` (Bäume, Felsen, Wege) |
| `tools/` | Python-Skripte, die die Quaternius-Packs ins Projekt umwandeln; `tools/ci/` macht beim Test-Build Bildschirmfotos |
| `assets/textures/` | Texturen und Bilder |
| `assets/materials/` | Materialien |
| `assets/audio/` | Musik und Soundeffekte |

Skripte liegen direkt neben ihrer Szene (z. B. `player.tscn` + `player.gd`). So findet man zusammengehörige Dateien schnell.

## Physik-Ebenen

| Ebene | Name | Wofür |
| --- | --- | --- |
| 1 | Welt | Boden, Wände. Blockiert auch die Sicht der Gegner. |
| 2 | Spieler | Die Spielerfigur |
| 3 | Gegner | Alle Gegner. |
| 4 | Objekte | Gegenstände am Boden, Altar, Portal. Mausklicks treffen Welt, Gegner und Objekte. |

## Wichtig

- Der Ordner `.godot/` wird von Godot automatisch erzeugt und ist in `.gitignore` eingetragen. Er gehört nicht ins Repo.
- Die `.uid`-Dateien neben den Skripten **gehören** ins Repo. Godot braucht sie, um Dateien wiederzufinden.
- Das Navigations-Netz (wo man laufen kann) wird im Testlevel beim Start automatisch berechnet. Alles unter `NavigationRegion3D` mit einer Kollision auf Ebene 1 zählt als begehbar bzw. als Hindernis.

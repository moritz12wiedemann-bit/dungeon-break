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
7. **Klick auf den Dungeon-Altar** (Schrein mit lila Kristall vor dem Gittertor in der Stadt): Monsterstufe wählen, neuer Dungeon. **Taste T**: aus dem Dungeon zurück in die Stadt.
8. **Escape** schließt das oberste offene Fenster.

Das alte Testlevel (`scenes/levels/test_level.tscn`) gibt es noch. Zum Starten die Szene im Editor öffnen und **F6** („Aktuelle Szene starten“) drücken.

## Stadt und Dungeons

- **Stadt** (`scenes/levels/town.tscn`): sicherer Ort ohne Gegner. Der **Dungeon-Altar** öffnet bei jedem Klick einen neuen Dungeon.
- **Dungeon** (`scenes/levels/dungeon.tscn`): wird jedes Mal **zufällig erzeugt** (6–8 Räume, Gänge, Säulen). Der Startraum ist leer, der Boss-Raum ist am anderen Ende. In den Räumen dazwischen stehen Skelette, manchmal ein großer Skelett-Krieger („Brocken“).
- Die Gegner sind so stark wie deine Stufe beim Betreten (pro Stufe +25 % Leben, +15 % Schaden, mehr XP).
- Besiegst du den **Boss** (riesiger Skelett-Magier mit lila Leuchten), erscheint ein blaues **Portal**. Anklicken bringt dich in die Stadt.
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
- **Magischer Ältester**: Unterklasse wählen und Fähigkeiten leveln (1 Punkt pro Stufe). Alles noch Platzhalter ohne Wirkung (`scenes/ui/elder_window.gd`).
- Die Fenster der Figuren erben von `scenes/ui/game_window.gd`, die Figuren selbst von `scenes/world/npc.gd`.

## Gegenstände und Orbs

- Jeder Wert hat einen **Bereich**, der in Klammern dahinter steht, z. B. „+7 Rüstung (5–10)“. Tabellen in `scenes/items/item_generator.gd`.
- Die **Seltenheit** hängt an der Zahl der Werte: 1 = Normal (weiß), 2 = Magisch (blau), 3 = Selten (gelb), 4 = Legendär (orange). **Set**-Gegenstände (grün) haben auch 4 Werte und sind eine Alternative zu Legendär.
- Im Inventar (Taste I) gibt es den aufklappbaren Reiter **Materialien**. Orbs dort rechtsklicken, dann einen Gegenstand anklicken:
  - **Orb der Erweiterung**: fügt einen zufälligen Wert hinzu, Seltenheit steigt (höchstens Legendär).
  - **Orb der Läuterung**: entfernt einen zufälligen Wert (nie den Grundwert), Seltenheit sinkt.
  - **Orb des Wandels**: würfelt alle Werte in ihren Bereichen neu.
  - Set-Gegenstände kann man nur neu würfeln. Jeder startet mit 5 von jedem Orb.

## Grafik (Platzhalter-Modelle)

Alle 3D-Modelle sind **CC0** (frei nutzbar, auch kommerziell, keine Namensnennung nötig) von **Kay Lousberg (KayKit)**. Sie sind ein einheitlicher Platzhalter-Stil, bis die endgültige Optik feststeht. Woher was kommt: [CREDITS.md](CREDITS.md).

- **Figuren** (`scenes/characters/`): Spieler = Ritter, normale Gegner = Skelett-Diener mit Schwert, Brocken = Skelett-Krieger mit Axt und Schild, Boss = Skelett-Magier. Jede Figur ist eine kleine Szene, die das Modell lädt und Waffen an die Hand hängt (`HandRight`/`HandLeft`).
- **Animationen** spielt der Baustein `scenes/components/character_animator.gd` (Kind-Knoten `Animator` bei Spieler und Gegnern): Stehen, Laufen, Schlagen, Treffer, Tod, Aufstehen. Welche Animation wofür benutzt wird, steht im Inspektor. Alle verfügbaren Animationen siehst du, wenn du ein Modell (z. B. `assets/models/kaykit/adventurers/Knight.gltf`) im Editor öffnest und den `AnimationPlayer` anklickst.
- **Anderes Gegner-Modell**: Gegner-Szene öffnen, oberen Knoten anklicken, im Inspektor unter „Aussehen“ eine andere Szene aus `scenes/characters/` bei `Model Scene` hineinziehen. Das Modell erscheint erst beim Spielen, nicht im Editor.
- **Dungeon**: Boden, Wände, Säulen, Fackeln, Banner, Kisten und Fässer werden beim Start aus dem Baukasten `assets/models/kaykit/dungeon/` zusammengesetzt (`scenes/levels/dungeon.gd`). Hinten (oben/links im Bild) sind die Wände hoch, vorn (unten/rechts) niedrig, damit sie die Figur nicht verdecken. Höhen und Fackeln pro Raum: oberen Knoten `Dungeon` anklicken, Inspektor.
- **Stadt**: Häuser, Brunnen, Zaun, Bäume, Laternen und Deko stehen als normale Knoten in `town.tscn` (unter `Decor`, `Paths` und bei den Häusern unter `NavigationRegion3D/Geometry`). Du kannst sie im Editor frei verschieben. Wenn du ein Haus verschiebst, verschiebe den ganzen Haus-Knoten (er enthält Modell und Kollision).
- Ungenutzte Modelle für später: Barbar, Magier und Schurke in `assets/models/kaykit/adventurers/` (für Klassen) und der komplette Dungeon-Baukasten (über 200 Teile).

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
| `scenes/characters/` | 3D-Figuren (Modell + Waffen in der Hand) für Spieler und Gegner |
| `scenes/enemies/` | Gegner: `enemy.tscn` (normal), `enemy_brute.tscn` (Brocken, „erbt“ vom normalen), `enemy_boss.tscn` (Boss, erbt vom Brocken) |
| `scenes/world/` | Benutzbare Objekte: Dungeon-Altar, Portal in die Stadt (`interactable.gd` ist die gemeinsame Grundlage) |
| `scenes/game/` | `game_state.gd`: Spielstand, der Szenenwechsel überlebt |
| `scenes/items/` | Gegenstände: Daten (`item_data.gd`), Zufallsgenerator (`item_generator.gd`), Gegenstand am Boden |
| `scenes/components/` | Bausteine, die an Figuren gehängt werden: `health.gd` (Lebenspunkte, Regeneration), `experience.gd` (XP und Stufe), `inventory.gd` (Tasche und Ausrüstung), `character_animator.gd` (Animationen) |
| `scenes/camera/` | Iso-Kamera, die dem Spieler folgt |
| `scenes/ui/` | Bildschirm-Anzeige (HUD), Inventar-Fenster, Lebensbalken über Gegnern, Schadenszahlen |
| `assets/models/kaykit/` | 3D-Modelle von KayKit: `adventurers` (Helden, Waffen), `skeletons` (Gegner), `dungeon` (Dungeon-Baukasten), `town` (Häuser, Bäume, Deko), `halloween` (Altar-Tor, Portal-Bogen, Wege, Laternen) |
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

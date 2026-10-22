# Dungeon Break

Ein Action-RPG im Stil von Diablo 3, gebaut mit **Godot 4.7** (GDScript, Forward+), 3D mit fester Iso-Kamera.

## Starten

1. Godot 4.7 öffnen, im Projekt-Manager auf **Importieren** klicken und die Datei `project.godot` in diesem Ordner auswählen.
2. Im Editor oben rechts auf **▶ (F5)** drücken. Der Test-Dungeon startet.
3. **Linke Maustaste auf den Boden** klicken oder gedrückt halten: die Figur läuft zum Mauszeiger und findet selbst den Weg um Wände herum.
4. **Linke Maustaste auf einen Gegner**: die Figur läuft hin und schlägt so lange zu, bis er tot ist.
5. **Taste 1** oder Klick auf den roten Kreis rechts neben dem Lebensbalken: Heiltrank trinken (heilt 40 %, danach 20 Sekunden Abklingzeit).
6. **Klick auf einen Gegenstand am Boden**: hinlaufen und aufheben. **Taste I**: Inventar öffnen/schließen.

Das alte Testlevel (`scenes/levels/test_level.tscn`) gibt es noch. Zum Starten die Szene im Editor öffnen und **F6** („Aktuelle Szene starten“) drücken.

## Test-Dungeon

Vier Räume mit Gängen: Startraum (unten links), zwei Räume mit Gegnern und ein großer Raum mit einem lila „Brocken“ (stärkerer Gegner) und seinen Helfern.

- **Gegner** (rote Kapseln) stehen still, bis du ihnen näher als ihre *Aggro-Reichweite* kommst und keine Wand dazwischen ist. Dann verfolgen sie dich und schlagen zu. Wer getroffen wird, wehrt sich sofort.
- Läufst du weit genug weg (*Leine*), geben sie auf, gehen zurück an ihren Platz und heilen sich.
- Oben links steht, wie viele Gegner noch leben. Unten in der Mitte ist dein Lebensbalken. Gegner zeigen ihren Balken, sobald sie verletzt sind.
- Stirbst du, erscheint „Du bist gestorben!“. Mit **Wiederbeleben** stehst du an derselben Stelle wieder auf, mit 25 % Leben und 3 Sekunden Schutz.
- Leben kommt von selbst zurück: 1 Lebenspunkt pro Sekunde.

## Erfahrung und Stufen

- Besiegte Gegner geben Erfahrung (XP): normale Gegner 20, der Brocken 150. Der lila Balken unten zeigt Stufe und XP.
- Höchste Stufe ist **100**. Jede Stufe braucht mehr XP als die vorige: `100 × Stufe^1,6` (Stufe 1 → 2: 100 XP, Stufe 10: ca. 4.000, Stufe 50: ca. 52.000, Stufe 99: ca. 156.000).
- Pro Stufe: +10 maximale Lebenspunkte, +1 Schaden, und du wirst voll geheilt.
- Die Werte stehen im Spieler (Inspektor, Gruppen „Stufenaufstieg“, „Heiltrank“, „Wiederbeleben“) und im Kind-Knoten `Experience`.

Werte wie Lebenspunkte, Schaden, Tempo und Reichweiten kannst du im Editor ändern: Gegner (oder Spieler) in der Szene anklicken und rechts im **Inspektor** die Werte anpassen. Die Lebenspunkte stehen im Kind-Knoten `Health`.

## Gegenstände und Inventar

- Besiegte Gegner lassen manchmal Gegenstände fallen. Der Name am Boden hat die Farbe der Seltenheit: **Weiß** normal, **Blau** magisch, **Gelb** selten, **Orange** legendär, **Grün** Set. Ab Gelb leuchtet ein Lichtstrahl.
- Normale Gegner lassen in etwa jedem dritten Fall etwas fallen, meistens Weißes. Der Brocken (Boss) lässt immer 2–4 Gegenstände fallen, viel öfter gelbe, orange und grüne. Alle Chancen stehen als Tabellen oben in `scenes/items/item_generator.gd`; die Beute-Stufe eines Gegners ist `loot_tier` im Inspektor (0 normal, 1 groß, 2 Boss).
- Plätze: Helm, Handschuhe, Rüstung, Hose, Schuhe, Waffe. Waffen geben Schaden, alles andere Rüstung. Je seltener, desto mehr Zusatzwerte (Schaden, Rüstung, Leben, Leben pro Sekunde, Laufgeschwindigkeit).
- Im Inventar: **Linksklick** in der Tasche zieht an (das Alte wandert in die Tasche), **Linksklick** auf Ausrüstung zieht aus, **Rechtsklick** wirft weg. Maus über einen Gegenstand halten zeigt seine Werte.
- Rüstung verringert Schaden: erlittener Schaden × 100 / (100 + Rüstung). Laufgeschwindigkeit aus Ausrüstung ist auf +25 % begrenzt.

## Ordnerstruktur

| Ordner | Was liegt dort? |
| --- | --- |
| `scenes/levels/` | Levels (Testlevel, später Hub, Overworld, Dungeons) |
| `scenes/player/` | Spielerfigur: Szene + Skript |
| `scenes/enemies/` | Gegner: `enemy.tscn` (normaler Gegner) und `enemy_brute.tscn` (stärkere Variante, „erbt“ vom normalen Gegner) |
| `scenes/items/` | Gegenstände: Daten (`item_data.gd`), Zufallsgenerator (`item_generator.gd`), Gegenstand am Boden |
| `scenes/components/` | Bausteine, die an Figuren gehängt werden: `health.gd` (Lebenspunkte, Regeneration), `experience.gd` (XP und Stufe), `inventory.gd` (Tasche und Ausrüstung) |
| `scenes/camera/` | Iso-Kamera, die dem Spieler folgt |
| `scenes/ui/` | Bildschirm-Anzeige (HUD), Inventar-Fenster, Lebensbalken über Gegnern, Schadenszahlen |
| `assets/models/` | 3D-Modelle (z. B. KayKit, Kenney, Quaternius) |
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
| 4 | Gegenstände | Gegenstände am Boden. Mausklicks treffen Welt, Gegner und Gegenstände. |

## Wichtig

- Der Ordner `.godot/` wird von Godot automatisch erzeugt und ist in `.gitignore` eingetragen. Er gehört nicht ins Repo.
- Die `.uid`-Dateien neben den Skripten **gehören** ins Repo. Godot braucht sie, um Dateien wiederzufinden.
- Das Navigations-Netz (wo man laufen kann) wird im Testlevel beim Start automatisch berechnet. Alles unter `NavigationRegion3D` mit einer Kollision auf Ebene 1 zählt als begehbar bzw. als Hindernis.

# Dungeon Break

Ein Action-RPG im Stil von Diablo 3, gebaut mit **Godot 4.7** (GDScript, Forward+), 3D mit fester Iso-Kamera.

## Starten

1. Godot 4.7 öffnen, im Projekt-Manager auf **Importieren** klicken und die Datei `project.godot` in diesem Ordner auswählen.
2. Im Editor oben rechts auf **▶ (F5)** drücken. Der Test-Dungeon startet.
3. **Linke Maustaste auf den Boden** klicken oder gedrückt halten: die Figur läuft zum Mauszeiger und findet selbst den Weg um Wände herum.
4. **Linke Maustaste auf einen Gegner**: die Figur läuft hin und schlägt so lange zu, bis er tot ist.

Das alte Testlevel (`scenes/levels/test_level.tscn`) gibt es noch. Zum Starten die Szene im Editor öffnen und **F6** („Aktuelle Szene starten“) drücken.

## Test-Dungeon

Vier Räume mit Gängen: Startraum (unten links), zwei Räume mit Gegnern und ein großer Raum mit einem lila „Brocken“ (stärkerer Gegner) und seinen Helfern.

- **Gegner** (rote Kapseln) stehen still, bis du ihnen näher als ihre *Aggro-Reichweite* kommst und keine Wand dazwischen ist. Dann verfolgen sie dich und schlagen zu. Wer getroffen wird, wehrt sich sofort.
- Läufst du weit genug weg (*Leine*), geben sie auf, gehen zurück an ihren Platz und heilen sich.
- Oben links steht, wie viele Gegner noch leben. Unten in der Mitte ist dein Lebensbalken. Gegner zeigen ihren Balken, sobald sie verletzt sind.
- Stirbst du, erscheint „Du bist gestorben!“ mit einem Knopf zum Neustarten.

Werte wie Lebenspunkte, Schaden, Tempo und Reichweiten kannst du im Editor ändern: Gegner (oder Spieler) in der Szene anklicken und rechts im **Inspektor** die Werte anpassen. Die Lebenspunkte stehen im Kind-Knoten `Health`.

## Ordnerstruktur

| Ordner | Was liegt dort? |
| --- | --- |
| `scenes/levels/` | Levels (Testlevel, später Hub, Overworld, Dungeons) |
| `scenes/player/` | Spielerfigur: Szene + Skript |
| `scenes/enemies/` | Gegner: `enemy.tscn` (normaler Gegner) und `enemy_brute.tscn` (stärkere Variante, „erbt“ vom normalen Gegner) |
| `scenes/components/` | Bausteine, die an mehrere Figuren gehängt werden, z. B. `health.gd` (Lebenspunkte) |
| `scenes/camera/` | Iso-Kamera, die dem Spieler folgt |
| `scenes/ui/` | Bildschirm-Anzeige (HUD), Lebensbalken über Gegnern, Schadenszahlen |
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
| 3 | Gegner | Alle Gegner. Mausklicks treffen Welt und Gegner. |

## Wichtig

- Der Ordner `.godot/` wird von Godot automatisch erzeugt und ist in `.gitignore` eingetragen. Er gehört nicht ins Repo.
- Die `.uid`-Dateien neben den Skripten **gehören** ins Repo. Godot braucht sie, um Dateien wiederzufinden.
- Das Navigations-Netz (wo man laufen kann) wird im Testlevel beim Start automatisch berechnet. Alles unter `NavigationRegion3D` mit einer Kollision auf Ebene 1 zählt als begehbar bzw. als Hindernis.

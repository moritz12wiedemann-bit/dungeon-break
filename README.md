# Dungeon Break

Ein Action-RPG im Stil von Diablo 3, gebaut mit **Godot 4.7** (GDScript, Forward+), 3D mit fester Iso-Kamera.

## Starten

1. Godot 4.7 öffnen, im Projekt-Manager auf **Importieren** klicken und die Datei `project.godot` in diesem Ordner auswählen.
2. Im Editor oben rechts auf **▶ (F5)** drücken. Das Testlevel startet.
3. **Linke Maustaste** klicken oder gedrückt halten: die Figur läuft zum Mauszeiger und findet selbst den Weg um Wände herum.

## Ordnerstruktur

| Ordner | Was liegt dort? |
| --- | --- |
| `scenes/levels/` | Levels (Testlevel, später Hub, Overworld, Dungeons) |
| `scenes/player/` | Spielerfigur: Szene + Skript |
| `scenes/camera/` | Iso-Kamera, die dem Spieler folgt |
| `scenes/ui/` | Menüs, Inventar, Lebensanzeige usw. (noch leer) |
| `assets/models/` | 3D-Modelle (z. B. KayKit, Kenney, Quaternius) |
| `assets/textures/` | Texturen und Bilder |
| `assets/materials/` | Materialien |
| `assets/audio/` | Musik und Soundeffekte |

Skripte liegen direkt neben ihrer Szene (z. B. `player.tscn` + `player.gd`). So findet man zusammengehörige Dateien schnell.

## Physik-Ebenen

| Ebene | Name | Wofür |
| --- | --- | --- |
| 1 | Welt | Boden, Wände. Mausklicks treffen nur diese Ebene. |
| 2 | Spieler | Die Spielerfigur |
| 3 | Gegner | Für später |

## Wichtig

- Der Ordner `.godot/` wird von Godot automatisch erzeugt und ist in `.gitignore` eingetragen. Er gehört nicht ins Repo.
- Die `.uid`-Dateien neben den Skripten **gehören** ins Repo. Godot braucht sie, um Dateien wiederzufinden.
- Das Navigations-Netz (wo man laufen kann) wird im Testlevel beim Start automatisch berechnet. Alles unter `NavigationRegion3D` mit einer Kollision auf Ebene 1 zählt als begehbar bzw. als Hindernis.

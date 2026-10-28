# Credits

## 3D-Modelle und Animationen

Alle Modelle und Animationen stammen von **Quaternius** ([quaternius.com](https://quaternius.com), [Patreon](https://www.patreon.com/quaternius))
und stehen unter der Lizenz **CC0 1.0** ([Creative Commons Zero](https://creativecommons.org/publicdomain/zero/1.0/)):
frei nutzbar für private und kommerzielle Projekte, Namensnennung nicht nötig (aber nett).
Lizenztext: `assets/models/quaternius/LICENSE.txt`. Verwendet werden jeweils die kostenlosen „Standard“-Versionen.

| Pack | Was wir daraus nutzen | Ordner im Projekt |
| --- | --- | --- |
| Modular Character Outfits – Fantasy | Kleidung: Bauer (Oberteil, Arme, Hose, Schuhe) und Waldläufer (Kapuze, Schulterpanzer, Oberteil, 2 Gürtel, Arme, Armschienen, Hose, Stiefel), je für Mann und Frau, mit Farbvarianten | `assets/models/quaternius/characters/` |
| Universal Base Characters | Köpfe mit Gesicht, Augen, Augenbrauen, 5 Frisuren, Bart | `assets/models/quaternius/characters/` |
| Universal Animation Library | Stehen, Gehen, Joggen, Sprinten, Rolle, Schwertschlag, Faustschläge, Zauber, Treffer, Tod, Aufheben, Benutzen, Reden, Sitzen, Tanzen ... | `assets/models/quaternius/characters/Animations.gltf` |
| Universal Animation Library 2 | Schwert-Kombos, Blocken, Schild, Trinken, Truhe öffnen, Aufstehen, Arme verschränken, Laterne, Holzhacken, Zombie (Stehen, Gehen, Kratzen) | `assets/models/quaternius/characters/Animations.gltf` |
| Fantasy Props MegaKit | alle 94 Modelle: Fässer, Kisten, Truhe, Möbel, Fackel, Laterne, Banner, Kerzen, Waffen (Schwert, Axt, Spitzhacke, Schild), Münzen, Tränke, Bücher, Marktstand ... | `assets/models/quaternius/props/` |

Technische Änderungen (mit den Skripten in `tools/`): Die Kleidung beider Outfits und die Köpfe/Frisuren
wurden pro Körper in eine Datei mit einem gemeinsamen Skelett zusammengefasst, der Kopf wurde aus der
Grundfigur herausgeschnitten (laut Quaternius braucht man zu den Outfits nur den Kopf).
Texturen wurden auf 1024 px verkleinert, Normal- und ORM-Maps weggelassen, damit die Web-Version klein bleibt.
Die Modelle selbst sind unverändert.

## Was im Spiel woher kommt

| Im Spiel | Kommt aus |
| --- | --- |
| Spieler, Gegner, Stadtbewohner | Modular Character Outfits + Universal Base Characters (Vorlagen in `scenes/characters/`) |
| alle Bewegungen der Figuren | Universal Animation Library 1 + 2 |
| Waffen in der Hand und am Boden, Beutel, Münzen | Fantasy Props MegaKit |
| Schatztruhe (golden = eingefärbt) | Fantasy Props MegaKit (`Chest_Wood`) |
| Dungeon: Fackeln, Banner, Fässer, Kisten, Käfig, Kessel, Kleinkram | Fantasy Props MegaKit |
| Stadt: Fässer, Kisten, Bank, Eimer, Waffenständer, Marktstände, Laternen, Beutel | Fantasy Props MegaKit |
| Altar: Kerzenständer | Fantasy Props MegaKit |
| Kristall am Altar, Portal-Ring, Fackel-Flammen, Leuchtflecken der Beute | im Spiel selbst gebaut (einfache Formen) |

## Was noch fehlt (graue Platzhalter im Spiel)

| Fehlt | Wo | Passendes Quaternius-Pack (Idee) |
| --- | --- | --- |
| Dungeon-Wände, -Böden, Säulen | Dungeon | „Modular Dungeon“ / „Ultimate Modular Ruins“ |
| Häuser, Schmiede, Taverne, Kirche, Windmühle, Turm, Brunnen | Stadt | „Medieval Village MegaKit“ |
| Bäume, Felsen | Stadt | „Stylized Nature MegaKit“ / „Ultimate Nature“ |
| Wege, Zäune, Fahnen, Laternenpfähle, Holzstapel, Schubkarre | Stadt | „Medieval Village MegaKit“ |
| Altar-Sockel und Tor, Portalbogen | Stadt / Dungeon | „Ultimate Modular Ruins“ oder ein Fantasy-Pack mit Torbögen |
| Monster (echte Untote/Skelette, Bosse) | Dungeon | „Ultimate Monsters“ / „Universal Monster“-Packs (die Gegner sind jetzt eingefärbte Menschen) |
| Weitere Kleidung (Ritter, Magier ...) | Figuren | Source-Version der Modular Character Outfits oder weitere Outfit-Packs |

# Credits

## 3D-Modelle und Animationen

Alle Modelle und Animationen stammen von **Quaternius** ([quaternius.com](https://quaternius.com), [Patreon](https://www.patreon.com/quaternius)).
Verwendet werden jeweils die kostenlosen „Standard“-Versionen.

Fast alles steht unter **CC0 1.0** ([Creative Commons Zero](https://creativecommons.org/publicdomain/zero/1.0/)):
frei nutzbar für private und kommerzielle Projekte, Namensnennung nicht nötig (aber nett).
Lizenztext: `assets/models/quaternius/LICENSE.txt`.

**Ausnahme:** Das *Bestiary - Dungeon Monsters Kit* steht unter der **Quaternius Asset License (QAL) v1.0**
(`assets/models/quaternius/monsters/LICENSE.txt`): im Spiel frei nutzbar, auch kommerziell, ohne Namensnennung.
Nicht erlaubt ist, die Modelle selbst als Asset-Pack weiterzugeben oder zu verkaufen.

| Pack | Was wir daraus nutzen | Ordner im Projekt |
| --- | --- | --- |
| Modular Character Outfits – Fantasy | Kleidung: Bauer (Oberteil, Arme, Hose, Schuhe) und Waldläufer (Kapuze, Schulterpanzer, Oberteil, 2 Gürtel, Arme, Armschienen, Hose, Stiefel), je für Mann und Frau, mit Farbvarianten | `characters/` |
| Universal Base Characters | Köpfe mit Gesicht, Augen, Augenbrauen, 5 Frisuren, Bart | `characters/` |
| Universal Animation Library | Stehen, Gehen, Joggen, Sprinten, Rolle, Schwertschlag, Faustschläge, Zauber, Treffer, Tod, Aufheben, Benutzen, Reden, Sitzen, Tanzen ... | `characters/Animations.gltf` |
| Universal Animation Library 2 | Schwert-Kombos, Blocken, Schild, Trinken, Truhe öffnen, Aufstehen, Arme verschränken, Laterne, Holzhacken, Zombie | `characters/Animations.gltf` |
| Bestiary - Dungeon Monsters Kit (QAL) | Monster: Puglin und Imp, je 3 Farbvarianten | `monsters/` |
| Updated Modular Dungeon (Mai 2019) | Dungeon-Boden, -Wände, Säulen, Torbogen, Sockel, dazu Fässer, Kisten, Tische, Totenköpfe ... (alle 47 Modelle) | `dungeon/` |
| Medieval Village MegaKit | Teile für die Häuser (Wände mit Tür/Fenster, Ecken, Dächer, Giebel, Schornstein), Holzzaun | `village/` |
| Stylized Nature MegaKit | Laub- und Nadelbäume, Felsen, Steinweg-Platten | `nature/` |
| Fantasy Props MegaKit | alle 94 Modelle: Fässer, Kisten, Truhe, Möbel, Fackel, Laterne, Banner, Kerzen, Waffen (Schwert, Axt, Spitzhacke, Schild), Münzen, Tränke, Bücher, Marktstand ... | `props/` |

(Alle Ordner liegen unter `assets/models/quaternius/`.)

Das *Ultimate Modular Ruins Pack* wurde angeschaut, aber nicht eingebaut: Das Modular Dungeon passt
stilistisch besser und hat schon alles, was der Dungeon braucht.

Technische Änderungen (mit den Skripten in `tools/`): Die Kleidung beider Outfits und die Köpfe/Frisuren
wurden pro Körper in eine Datei mit einem gemeinsamen Skelett zusammengefasst, der Kopf wurde aus der
Grundfigur herausgeschnitten. Die Monster wurden so vergrößert, dass ihre Hüfte auf Menschenhöhe liegt
(dann passen die Animationen), und werden im Spiel wieder verkleinert. Das Modular Dungeon gab es nur als
OBJ und wurde nach glTF umgewandelt. Texturen wurden verkleinert (Figuren 1024 px, Dorf und Natur 512 px),
Normal- und ORM-Maps weggelassen, damit die Web-Version klein bleibt. Die Modelle selbst sind unverändert.

## Was im Spiel woher kommt

| Im Spiel | Kommt aus |
| --- | --- |
| Spieler, Stadtbewohner | Modular Character Outfits + Universal Base Characters (Vorlagen in `scenes/characters/`) |
| Gegner: Puglin (normal), roter Imp (groß), blauer Riesen-Imp (Boss) | Bestiary - Dungeon Monsters Kit |
| alle Bewegungen der Figuren und Monster | Universal Animation Library 1 + 2 |
| Waffen in der Hand und am Boden, Beutel, Münzen | Fantasy Props MegaKit |
| Schatztruhe (golden = eingefärbt) | Fantasy Props MegaKit (`Chest_Wood`) |
| Dungeon: Boden, Wände, Säulen | Modular Dungeon |
| Dungeon: Fackeln, Banner, Kessel, Käfig, Kleinkram | Fantasy Props MegaKit |
| Dungeon: Fässer, Kisten, Tische | Fantasy Props MegaKit + Modular Dungeon |
| Stadt: Häuser (Schmiede, Taverne, Wohnhäuser) | Medieval Village MegaKit (in `scenes/world/houses/` zusammengesetzt) |
| Stadt: Zäune, Laternenpfähle | Medieval Village MegaKit (Laterne aus dem Fantasy Props MegaKit) |
| Stadt: Bäume, Felsen, Steinweg | Stylized Nature MegaKit |
| Stadt: Fässer, Kisten, Bank, Eimer, Waffenständer, Marktstände, Handkarren, Beutel | Fantasy Props MegaKit |
| Altar: Sockel und Torbogen, Portalbogen | Modular Dungeon |
| Altar: Kerzenständer | Fantasy Props MegaKit |
| Kristall am Altar, Portal-Ring, Fackel-Flammen, Leuchtflecken der Beute, Wiese | im Spiel selbst gebaut (einfache Formen) |

## Was fehlt (vorerst weggelassen)

Es gibt keine grauen Platzhalter mehr. Was in keinem Pack vorkam, ist einfach nicht im Spiel:
Brunnen, Kirche, Windmühle, Turm, Fahnen und Holzstapel in der Stadt.
Weitere Kleidung (Ritter, Magier ...) und mehr Monster gibt es in den Source-Versionen der Packs.

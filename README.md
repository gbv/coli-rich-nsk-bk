# coli-conc scripts

Dieses Repository enthält Skripte zur Anreicherung der Sacherschließung im K10plus-Katalog auf Grundlage von Mappings und vorhandener Sacherschließung ([coli-rich](https://coli-conc.gbv.de/de/coli-rich/)).

## Inhalt

* [Ermittlung der Anreicherung](#ermittlung-der-anreicherung)
* [Eintragung in den K10plus-Katalog](#eintragung-in-den-k10plus-katalog)
* [Statistik und Korrekturen](#statistik-und-korrekturen)
* [Dokumentation der einzelnen Skripte](#dokumentation-der-einzelnen-skripte)

## Ermittlung der Anreicherung

...

## Eintragung im K10plus-Katalog

Die ermittelte Anreicherung werden mit Angabe der beteiligten Vokabulare und Mappings im PICA Änderungsformat in einem FTP-Hotfolder bereitgestellt. Ein anderer Dienst schaut dort regelmäßig nach ob Änderungen vorliegen und trägt diese in Paketen in den K10plus-Katalog ein. Die Eintragung wird bislang noch manuell angestoßen, in Zukunft sollen Anreicherungen einmal am Tag vorgenommen werden.

Die Anreicherung besteht aus den PICA-Feldern für das betreffende Zielvokabular (z.B. `045Q/01` für die Basisklassifikation) und einer Quellenangabe in `$A`. Das erste Vorkommen enthält die Angabe der beteiligten Vokabulare (z.B. `coli-conc RVK->BK` für Anreicherung von RVK zu BK) und as zweite Vorkommen die URI des zur Anreicherung verwendeten Mappings. Hier ein Beispiel:

      003@ $01756577099
    + 045Q/01 $9106409476$a44.72$Acoli-conc RVK->BK$Ahttps://coli-conc.gbv.de/api/mappings/d415aba4-14c2-4a9c-822a-1a589787545d

Bei Korrekturen und Löschungen wird dem Feld ein `-` vorangestellt.

## Statistik und Korrekturen

Zur Qualitätskontrolle lassen sich verschiedene Abfragen und Statistiken erstellen.

Werden nachträglich Fehler erkannt so lässt sich die Anreicherung automatisch korrigieren oder verbessern. Dabei müssen zwei Fälle unterschieden werden:

1. Korrektur der Anreicherung einzelner Titel

   Haben sich die vorhandenen Mappings oder die Sacherschließung eines Titels geändert so wird mit dem Skript [enrich](#enrich) die gesamte Anreicherung des Titels neu berechnet.

2. Korrektur einzelner Mappings

   Stellt sich heraus dass einzelne Mappings falsch oder nicht genau genug waren, so müssen alle mit diesem Mapping angereicherten Titel überprüft werden. Zur Abfrage dieser Titel dient das Skript [titles-with-mapping](#titles-with-mapping).

## Dokumentation der einzelnen Skripte

### enrich

Das Skript `./bin/enrich` berechnet für PICA-Datensätze Anreicherungen (**TODO**)

### titles-with-mapping

Das Skript `./bin/titles-with-mapping` fragt ab wie viele bzw. welche Titel im K10plus-Katalog auf Grundlage eines bestimmten Mappings oder einer Kombination von Vokabularen angerichert wurden.

### mapping-status

Das Skript `./bin/mapping-status` prüft ob und welche Mapping für eine Teilhierarchie eines Vokabulars vorhanden sind.

## stats

Das Skript `./bin/stats` zählt die im K10plus vorhandenen Titel mit Anreicherungen und erzeugt daraus eine aktuelle Statistik, aufgeschlüsselt nach vorkonfigurierten Vokabular-Paaren. Das Skript sollte täglich per cronjob aufgerufen werden.


# coli-conc scripts

Dieses Repository enthält Skripte zur Anreicherung der Sacherschließung im K10plus-Katalog auf Grundlage von Mappings und vorhandener Sacherschließung ([coli-rich](https://coli-conc.gbv.de/de/coli-rich/)).

## Inhalt

* [Ablauf der Anreicherung](#ablauf-der-anreicherung)
  * [Erstellung und Bewertung von Mappings](#erstellung-und-bewertung-von-mappings)
  * [Auswahl von Mappings](#auswahl-von-mappings)
  * [Auswahl von Titeldatensätzen](#auswahl-von-titeldatensätzen)
  * [Berechnung der Anreicherung](#berechnung-der-anreicherung)
  * [Eintragung in den Katalog](#eintragung-in-den-katalog)
  * [Statistik und Korrekturen](#statistik-und-korrekturen)
* [Technische Umsetzung](#technische-umsetzung)
  * [Installation](#installation)
  * [enrich](#enrich)
  * [mapping-status](#mapping-status)
  * [titles-with-mapping](#titles-with-mapping)
  * [stats](#stats)

## Ablauf der Anreicherung

Das gesamte Verfahren erfordert fünf Arbeitsschritte:

1. [Erstellung und Bewertung von Mappings](#erstellung-und-bewertung-von-mappings)
2. [Auswahl von Mappings](#auswahl-von-mappings)
3. [Auswahl von Titeldatensätzen](#auswahl-von-titeldatensätzen)
4. [Berechnung der Anreicherung](#berechnung-der-anreicherung)
5. [Eintragung in den Katalog](#eintragung-in-den-katalog)

Für den Produktivbetrieb sollen alle Schritte bis auf die Erstellung und Bewertung von Mappings dauerhaft und automatisch ablaufen. Zur Qualitätssicherung und strategischen Steuerung der Anreicherung gibt es zudem Verfahren für [Statistik und Korrekturen](#statistik-und-korrekturen).

~~~
+-------------+    .---------------.
| Vokabulare  |   | Konfiguration  |-----------------> 3: Auswahl von
+-----+-------+    '---------------'                   Titeldatensätzen
      |        \      | 2: Auswahl von             .----------------------.
      v         v     v Mappings                   v                       \
  .--------.     +-----------------+    .-----------------.                 +---------+
  | Cocoda |     | Mappingtabelle  |--->| 4: Anreicherung |---------------->| Katalog |             
  '---+----'     +-----------------+    '-----------------' 5: Eintragung   +---------+
      | 1: Erstellung    ^
      v und Bewertung   / 
 +----------+          /
 | Mappings |---------'
 +----------+
~~~

<!-- SVG via https://ivanceras.github.io/svgbob-editor/ -->

### Erstellung und Bewertung von Mappings

Zur Erstellung und Bewertung von Mappings dient die [Webanwendung Cocoda](https://coli-conc.gbv.de/cocoda/app/). Mappings können von allen Interessierten in eine zentrale Mappingdatenbank eingestellt und per Benutzerinterface und APIs abgefragt werden. Jedes Mapping ist einem Benutzeraccount zugeordnet. Einige Mappings sind zudem einer Konkordanz zugeordnet (*[bisher nur Eingeschränkt möglich](https://github.com/gbv/jskos-server/issues/98)*). Mappings können zudem durch Upvote/Downvote und von ausgewählten Benutzeraccounts und durch Bestätigung bewertet werden.

### Auswahl von Mappings

Das Skript [mapping-status](#mapping-status) wertet die (Teil)hierarchie eines Quellvokabulars und vorhandene Mappings auf ein Zielvokabular aus und berechnet daraus eine Mapping-Tabelle.

Die Auswahl wird gesteuert davon, unter welchen Bedingungen Mappings als für die Anreicherung nutzbar gelten. Standardmäßig gilt dies wenn:

* Ein Mapping vom Typ exact (=) oder narrower (<) ist und
* Ein Mapping bestätigt wurde, oder
* Ein Mapping von ausgewählten Accounts erstellt und nicht downgevoted wurde, oder
* Ein Mapping Teil von ausgewählten Konkordanzen ist und nicht downgevoted wurde

Diese Auswahl lässt sich in Zukunft pro Vokabular und Konkordanz konfigurieren.

### Auswahl von Titeldatensätzen

Die Anreicherung der Sacherschließung erfolgt immer für einzelne Titeldatensätze im K10plus-Katalog. Die Auswahl, welche Datensätze angereichert werden sollen ist also unabhängig von der Anreicherung. Es macht allerdings Sinn möglichst vollständige (Teil-)Konkordanzen zu erstellen und dann alle Titel anzureichern, die mit Normdaten aus dem gemappten Teilbereich des Quellvokabulars erschlossen sind. Die Auswahl von anzureichernden Titeln erfolgt per SRU-Abfrage oder per PPN-Liste. Für den Produktivbetrieb muss noch ein Verfahren entwickelt werden, dass ausgehend von Änderungen an Titeln und Mappings die vorhandene Anreicherung regelmäßig überprüft und ergänzt bzw. korrigiert.

### Berechung der Anreicherung

Die Anreicherung von Titeldatensätzen mit vorhandener Sacherschließung lässt sich relativ einfach aus den Mappingtabellen für die unterstützen Vokabulare ablesen. Die Anreicherungen und Korrekturen werden im PICA-Änderungsformat zur Eintragung im Katalog bereitgestellt.

Die Anreicherung besteht aus den PICA-Feldern für das betreffende Zielvokabular und einer Quellenangabe in `$A`. Das erste Vorkommen enthält die Angabe der beteiligten Vokabulare und as zweite Vorkommen die URI des zur Anreicherung verwendeten Mappings. Im Falle der Anreicherung von RVK zu BK wird beispielsweise ein PICA+ Feld `045Q/01` mit folgenden Unterfeldern angelegt:

* `$9` PPN des BK-Normdatensatzes
* `$a` BK-Notation
* `$A` Die Zeichenkette "`coli-conc RVK->BK`"
* `$A` Die URI des Mappings auf dessen Grundlage die Anreicherung ermittelt wurde

Hier ein Beispiel eines Änderungsdatensatzes:

      003@ $01756577099
    + 045Q/01 $9106409476$a44.72$Acoli-conc RVK->BK$Ahttps://coli-conc.gbv.de/api/mappings/d415aba4-14c2-4a9c-822a-1a589787545d

Bei Korrekturen und Löschungen wird dem Feld ein `-` vorangestellt.

[PICA Änderungsformat]: https://pro4bib.github.io/pica/#/formate?id=%c3%84nderungsformat

## Eintragung im K10plus-Katalog

Die ermittelte Anreicherung werden mit Angabe der beteiligten Vokabulare und Mappings im [PICA-Änderungsformat] in einem FTP-Hotfolder bereitgestellt. Ein anderer Dienst schaut dort regelmäßig nach ob Änderungen vorliegen und trägt diese in Paketen in den K10plus-Katalog ein. Die Eintragung wird bislang noch manuell angestoßen, in Zukunft sollen Anreicherungen täglich vorgenommen werden. Je nach Anzahl der Datensätze ist auch eine Eintragung innerhalb von Minuten denkbar.

### Statistik und Korrekturen

Zur Qualitätskontrolle lassen sich verschiedene Abfragen und Statistiken erstellen.

Werden nachträglich Fehler erkannt so lässt sich die Anreicherung automatisch korrigieren oder verbessern. Dabei müssen zwei Fälle unterschieden werden:

1. Korrektur der Anreicherung einzelner Titel

   Haben sich die vorhandenen Mappings oder die Sacherschließung eines Titels geändert so wird mit dem Skript [enrich](#enrich) die gesamte Anreicherung des Titels neu berechnet.

2. Korrektur einzelner Mappings

   Stellt sich heraus dass einzelne Mappings falsch oder nicht genau genug waren, so müssen alle mit diesem Mapping angereicherten Titel überprüft werden. Zur Abfrage dieser Titel dient das Skript [titles-with-mapping](#titles-with-mapping).

## Technische Umsetzung

### Installation

Benötigt wird Bash, jq und Perl mit Catmandu. Die Datei `cpanfile` enthält alle Perl-Dependencies (`cpanm --installdeps .`).

*TODO: Teile des Verfahren sollen auf JavaScript umgestellt werden, damit sie auch direkt in Cocoda eingesetzt werden können.*

### Konfiguration

Die Datei `catmandu.yaml` enthält die Konfiguration für Catmandu.

Darüber hinaus kann es je Unterverzeichnis eine Konfiguration zur Auswahl von Mappings geben.

*TODO: Die Konfiguration der Mapping-Auswahl muss noch genauer beschrieben werden*

### enrich

Das Skript `./bin/enrich` berechnet für PICA-Datensätze Anreicherungen.

*TODO: Das Skript wird derzeit überarbeitet!*

### mapping-status

Das Skript `./bin/mapping-status` durchläuft einen Teilbaum eines Vokabulars und ermittelt welcher Bereich durch Mappings abgedeckt ist. Somit kann die Vollständigkeit einer Konkordanz überprüft werden. Beispiel:

~~~
$ ./bin/mapping-status nsk-bk The -l en
The                                               = 11
 The A                                            Allgemeines, Kirchengeschichte, Systematische Theologie
  The A 100                                       ?
  The A 1100                                      < 11.50 ✓
  The A 1300                                      < 11.54 ∩ 11.50 ✓
  The A 1600                                      < 11.55 ✓
  The A 1700                                      < 11.55 ✓
  The A 200                                       < 11.51 ✓
  The A 2000                                      < 11.50 ✓
  The A 300                                       < 11.61 ✓
  The A 500                                       = 11.62 ✓
  The A 700                                       < 11.50 ✓
  The A 800                                       Papsttum, Kirchenstaat
  The A 900                                       < 11.69 ✓
 The B                                            = 11.70
  The B 100                                       ?
  The B 200                                       = 11.74 ✓
  The B 300                                       = 11.75 ✓
  The B 400                                       = 11.71 ✓
  The B 600                                       Katechetik
  The B 700                                       Mission
  The B 800                                       < 11.79 ✓
 The C                                            = 11.30
  The C 100                                       = 11.38 ✓
  The C 200                                       = 11.44 ✓
 The E                                            Einzelne christliche Konfessionen, Symbolik
  The E 100                                       Katholische Kirche
  The E 1900                                      < 11.55 ✓
  The E 200                                       < 11.54 ✓
  The E 2000                                      Protestantische Kirchen
  The E 2200                                      < 11.55 ✓
  The E 300                                       < 11.57 ✓
  The E 400                                       < 11.57 ✓
  The E 500                                       < 11.57 ✓
  The E 800                                       < 11.57 ✓
~~~

### titles-with-mapping

Das Skript `./bin/titles-with-mapping` fragt ab wie viele bzw. welche Titel im K10plus-Katalog auf Grundlage eines bestimmten Mappings oder einer Kombination von Vokabularen angerichert wurden.

## stats

Das Skript `./bin/stats` zählt die im K10plus vorhandenen Titel mit Anreicherungen und erzeugt daraus eine aktuelle Statistik, aufgeschlüsselt nach vorkonfigurierten Vokabular-Paaren. Das Skript sollte täglich per cronjob aufgerufen werden.


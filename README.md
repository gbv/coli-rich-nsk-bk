# coli-conc scripts

Dieses Repository enthält Skripte zur Anreicherung der Sacherschließung in Katalogen auf Grundlage von Mappings und vorhandener Sacherschließung ([coli-rich](https://coli-conc.gbv.de/de/coli-rich/)).

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
  * [mapping-table](#mapping-table)
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
| Vokabulare  |   | Konfiguration  |-----------------> Auswahl von
+-----+-------+    '---------------'                   "Titeldatensätzen (3)"
      |        \      | Auswahl von                .------------------------.
      v         v     v Mappings "(2)"             v                         \
  .--------.     +-----------------+    .-------------------.                 +---------+
  | Cocoda |     | Mappingtabelle  |--->| Anreicherung "(4)"|---------------->| Katalog |
  '---+----'     +-----------------+    '-------------------' Eintragung "(5)"+---------+
      | Erstellung und   ^
      v Bewertung "(1)" /
 +----------+          /
 | Mappings |---------'
 +----------+
~~~

<!-- SVG via https://ivanceras.github.io/svgbob-editor/ -->

### Erstellung und Bewertung von Mappings

Zur Erstellung und Bewertung von Mappings dient die [Webanwendung Cocoda](https://coli-conc.gbv.de/cocoda/app/). Mappings können von allen Interessierten in eine zentrale Mappingdatenbank eingestellt und per Benutzerinterface und APIs abgefragt werden. Jedes Mapping ist einem Benutzeraccount zugeordnet. Einige Mappings sind zudem einer Konkordanz zugeordnet (*[bisher nur Eingeschränkt möglich](https://github.com/gbv/jskos-server/issues/98)*). Mappings können zudem durch Upvote/Downvote und von ausgewählten Benutzeraccounts und durch Bestätigung bewertet werden.

### Auswahl von Mappings

Das Skript [mapping-table](#mapping-table) wertet die (Teil)hierarchie eines Quellvokabulars und vorhandene Mappings auf ein Zielvokabular aus und berechnet daraus eine Mapping-Tabelle.

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

### mapping-table

Das Skript `./bin/mapping-table` durchläuft einen Teilbaum eines Vokabulars und ermittelt welcher Bereich durch Mappings abgedeckt ist. Somit kann die Vollständigkeit einer Konkordanz überprüft werden und eine Mappingtabelle zur Anreicherung erstellt werden. Beispiel:

~~~
$ ./bin/mapping-table nsk-bk "The A" -l en
The A                                             Allgemeines, Kirchengeschichte, Systematische Theologie
 The A 100                                        ?
 The A 200                                        < 11.51 https://coli-conc.gbv.de/api/mappings/4858b9aa-f3fb-4f3c-a01d-94328cd199aa ✓
 The A 300                                        < 11.61 https://coli-conc.gbv.de/api/mappings/cae6e0dd-7a71-4e1b-9d27-ef9a52f82276 ✓
 The A 500                                        = 11.62 https://coli-conc.gbv.de/api/mappings/1e375fd9-204d-4fc3-a1a1-5200d7ae3362 ✓
 The A 700                                        < 11.50 https://coli-conc.gbv.de/api/mappings/0f09a960-f66a-47e5-8ae9-2df7e1d92ad9 ✓
 The A 800                                        Papsttum, Kirchenstaat
 The A 900                                        < 11.69 https://coli-conc.gbv.de/api/mappings/05b694e4-d621-4103-b28f-b72676b10b85 ✓
 The A 1100                                       < 11.50 https://coli-conc.gbv.de/api/mappings/7558e7fb-2f32-49ec-9a5b-d8828f317d51 ✓
 The A 1300                                       < 11.54 ∩ 11.50 https://coli-conc.gbv.de/api/mappings/db518852-1af6-46dd-8b71-bddb17d6fd32 ✓
 The A 1600                                       < 11.55 https://coli-conc.gbv.de/api/mappings/d7867a47-78cc-4a61-96bc-92b738d873e4 ✓
 The A 1700                                       < 11.55 https://coli-conc.gbv.de/api/mappings/9ac16525-2169-4294-be53-0b3d479669b7 ✓
 The A 2000                                       < 11.50 https://coli-conc.gbv.de/api/mappings/90d69b7a-ae1a-4c82-b2bc-61b7f9ca22d4 ✓
~~~

### enrich

Das Skript `./bin/enrich` berechnet für PICA-Datensätze Anreicherungen auf Grundlage einer vorhandenen Mapping-Tabelle.

*TODO: Das Skript wird derzeit überarbeitet!*


### titles-with-mapping

Das Skript `./bin/titles-with-mapping` fragt ab wie viele bzw. welche Titel im K10plus-Katalog auf Grundlage eines bestimmten Mappings oder einer Kombination von Vokabularen angerichert wurden.

## stats

Das Skript `./bin/stats` zählt die im K10plus vorhandenen Titel mit Anreicherungen und erzeugt daraus eine aktuelle Statistik, aufgeschlüsselt nach vorkonfigurierten Vokabular-Paaren. Das Skript sollte täglich per cronjob aufgerufen werden.


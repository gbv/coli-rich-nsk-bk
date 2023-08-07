# Anreicherung des K10plus mit BK-Notationen auf Grundlage von RVK-Notationen

Im Rahmen des Projekt [coli-conc](https://coli-conc.gbv.de/) werden Mappings zwischen Klassen der Regensburger Verbundklassifikation (RVK) und Klassen der Basisklassifikation (BK) gesammelt, erstellt und kontrolliert (siehe [RVK-BK-Mappings in der Konkordanzdatenbank](https://coli-conc.gbv.de/cocoda/app/?toScheme=http%3A%2F%2Furi.gbv.de%2Fterminology%2Fbk%2F&fromScheme=http%3A%2F%2Furi.gbv.de%2Fterminology%2Frvk%2F&search=%7B%22fromScheme%22%3A%22RVK%22%2C%22toScheme%22%3A%22BK%22%7D)). Auf Grundlage dieser Mappings können Titeldatensätze im K10plus-Katalog um fehlende BK-Notationen ergänzt werden. Diese Anreicherung läuft unter dem Projektnamen **coli-rich**.

**Siehe auch die [Allgemeine Beschreibung von coli-rich](../README.md)**

## Auswahl von Mappings

Die Auswahl der für das Mapping in Frage kommenden Mappings basiert auf zwei Kritierien:

* Formal: Nur Mappings vom Mappingtype exactMatch (=) und narrowMatch (<) können für die automatische Anreicherung berücksichtigt werden, weil nur in diesen Fällen sicher ist dass alle mit einer RVK-Klassen (oder ihren Unterklassen) erschlossenen Titel auch in die gemappte BK-Klasse passen.

* Inhaltlich: Die ausgewählten Mappings müssen vertrauenswürdig sein. Die Auswahl kann auf Grundlage folgender Informationen erfolgen:

  1. der Benutzeraccount unter dem ein Mapping erstellt wurde
  2. ob das Mapping bestätigt wurde (die Bestätigung von Mappings ist nur ausgewählten Benutzeraccounts möglich)
  3. ob und wie das Mapping bewertet wurde (alle Benutzeraccounts können Mappings mit +1 oder -1 bewerten)
  4. ob und zu welcher Konkordanz das Mapping gehört

  Momentan werden Mappings ausgewählt die zu einer Konkordanz gehören *und* nicht negativ bewertet wurden.

Geplant is noch eine zusätzliche Konsistenzprüfung, nach der die ausgewählten Mappings in sich widerspruchsfrei sein müssen. So sollte beispielsweise eine RVK-Unterklasse nicht auf eine umfassendere BK-Klasse gemappt sein als ihre Oberklasse.

## Auswahl von Titeldatensätzen

In der Pilotphase werden alle Titeldatensätze im K10plus ausgewählt, die mit RVK aber nicht mit BK erschlossen sind.

Im Produktivbetrieb soll das Verfahren erweitert werden um vorhandene BK-Notationen zu überprüfen und um angereicherte BK-Notationen anzupassen wenn die ausgewählten Mappings geändert haben.

## Ermittlung der Anreicherung

Nach Auswahl von Mappings und Titeldatensätzen können Datensätze mit einer RVK-Klasse α folgendermaßen um BK-Klassen angereichert werden:

* Gibt es ein Mapping α = β oder α < β passt die BK-Klasse β

* Gibt es stattdessen eine (ggf. transitive) Oberklasse γ von α mit einem Mapping γ = β oder γ < β dann passt ebenfalls die BK-Klasse β.
  Allerdings kann es sein, dass eine Unterklassen von β noch besser passen würde.

Diese Ermittlung der Anreicherung erfolgt über den [`infer` Endpunkt von JSKOS-Server](https://github.com/gbv/jskos-server#get-mappingsinfer).

## Skripte

- `bk2ppn.csv` enthält PPN für BK-Normdatensätze
- `bk2ppn.sh` ermittelt PPN für BK-Normdatensätze

- bk-from-rvk.js
- `rvk-no-bk.pl` erzeugt Anreicherungen im PICA-Patch-Format
- `ppshow.pl`

### Deprecated

* `rvk2bk.pl` sucht ausgehend von einer RVK-Notation nach passenden Mappings
  und geht die betreffende Download-Datei durch um BK-Anreicherung zu erzeugen. Beispiel:

  ~~~bash
  ./rvk2bk.pl "ET 500"  # TODO: Unterklassen einbeziehen
  ./rvk2bk.pl "XL"      # Ganze Oberklasse (weil auf BK-Blattknoten gemappt)
  ~~~

* `coli-rich` liest normalisierte PICA+ Datensätze von STDIN und gibt PICA Patch aus.

## Beispiele

Hauptklassen der RVK, die per exactMatch auf eine BK-Unterklasse der untersten Ebene gemappt sind:

* `XL` Rechtsmedizin
* `YG` Neurologie
* `YP` Zahnmedizin
* `YQ` Kinderheilkunde
* `WT` Verhaltensforschung und Tierpsychologie

Klassen der RVK, die per exactMatch auf eine beliebige BK-Klasse gemappt sind:

* `ET 500` Lexikologie
* ...


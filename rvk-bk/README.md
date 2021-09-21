# Anreicherung des K10plus mit BK-Notationen auf Grundlage von RVK-Notationen

Im Rahmen des Projekt [coli-conc](https://coli-conc.gbv.de/) werden Mappings zwischen Klassen der Regensburger Verbundklassifikation (RVK) und Klassen der Basisklassifikation (BK) gesammelt, erstellt und kontrolliert (siehe [RVK-BK-Mappings in der Konkordanzdatenbank](https://coli-conc.gbv.de/cocoda/app/?toScheme=http%3A%2F%2Furi.gbv.de%2Fterminology%2Fbk%2F&fromScheme=http%3A%2F%2Furi.gbv.de%2Fterminology%2Frvk%2F&search=%7B%22fromScheme%22%3A%22RVK%22%2C%22toScheme%22%3A%22BK%22%7D)). Auf Grundlage dieser Mappings können Titeldatensätze im K10plus-Katalog um fehlende BK-Notationen ergänzt werden. Diese Anreicherung läuft unter dem Projektnamen **coli-rich**.

**Siehe auch die [Allgemeine Beschreibung von coli-rich](../README.md)**

## Auswahl von Mappings

Die Auswahl der für das Mapping in Frage kommenden Mappings basiert auf zwei Kritierien:

* Formal: Nur Mappings vom Mappingtype exactMatch (=) und narrowMatch (<) können für die automatische Anreicherung berücksichtigt werden, weil nur in diesen Fällen sicher ist dass alle mit einer RVK-Klassen (oder ihren Unterklassen) erschlossenen Titel auch in die gemappte BK-Klasse passen.

* Inhaltlich: Die ausgewählten Mappings müssen vertrauenswürdig sein. Die Auswahl kann auf Grundlage folgender Informationen erfolgen:

  * der Benutzeraccount unter dem ein Mapping erstellt wurde
  * ob das Mapping bestätigt wurde (die Bestätigung von Mappings ist nur ausgewählten Benutzeraccounts möglich)
  * ob und wie das Mapping bewertet wurde (alle Benutzeraccounts können Mappings mit +1 oder -1 bewerten)
  * ob und zu welcher Konkordanz das Mapping gehört (noch nicht umgesetzt)

  Momentan werden Mappings ausgewählt die *entweder* bestätigt wurden *oder* von einem ausgewählten Benutzeraccount stammen und nicht negativ bewertet wurden. Die Liste der ausgewählten Benutzeraccounts lässt sich konfigurieren.

Geplant is noch eine zusätzliche Konsistenzprüfung, nach der die ausgewählten Mappings in sich widerspruchsfrei sein müssen. So sollte beispielsweise eine RVK-Unterklasse nicht auf eine umfassendere BK-Klasse gemappt sein als ihre Oberklasse.

## Auswahl von Titeldatensätzen

In der Pilotphase werden alle Titeldatensätze im K10plus ausgewählt, die mit RVK aber nicht mit BK erschlossen sind. Dabei gibt es zwei Möglichkeiten:

* Auswahl aller Titeldatensätze die mit einer RVK-Klasse oder mit in der Hierarchie darunter liegenden Klassen erschlossen sind (per SRU-Suchanfrage). Dies hat den Vorteil dass ausgehend von einem Mapping alle anzureichernden Titel ausgewählt werden können.

* Auswahl konkreter Titeldatensätze (per PPN oder PPN-Liste). Hierbei muss für jeden Titel einzeln geprüft werden ob und welche passenden Mappings zur Anreicherung vorhanden sind, was insgesamt langsamer ist.

Im Produktivbetrieb soll das Verfahren erweitert werden um vorhandene BK-Notationen zu überprüfen und um angereicherte BK-Notationen anzupassen wenn die ausgewählten Mappings geändert haben.

## Ermittlung der Anreicherung

Nach Auswahl von Mappings und Titeldatensätzen können Datensätze mit einer RVK-Klasse α folgendermaßen um BK-Klassen angereichert werden:

* Gibt es ein Mapping α = β oder α < β passt die BK-Klasse β

* Gibt es stattdessen eine (ggf. transitive) Oberklasse γ von α mit einem Mapping γ = β oder γ < β dann passt ebenfalls die BK-Klasse β.
  Allerdings kann es sein, dass eine Unterklassen von β noch besser passen würde.

## Skripte

* `./download-by-rvk.sh` läd Titeldatensätze beschränkt auf Normdatenfelder
  (BK und RVK) aus dem K10plus. Zur Vereinfachung der Suche nach RVK-Notationen
  werden nur Notationen aus zwei Buchstaben unterstützt, es werden jedoch alle
  mit diesen Buchstaben beginnenden Notationen gefunden.

  Das vollständige Herunterladen aller Datensätze mit RVK ist theoretisch so möglich (dauert fast einen
  Tag), es gibt aber einige Klassen deren Ergebnismengen zu groß sind:

  ~~~bash
  for X in {A..Z}; do for Y in {A..Z}; do ./download-by-rvk.sh $X$Y; done; done
  ~~~

* `rvkbk-mappings.sh` läd RVK-BK-Mappings vom Typ < oder = für eine gegebene RVK-Notation, mit Annotationen

* `trusted-mappings.jq`: filtern Mappings denen für die Anreicherung vertraut werden kann

* `rvk2bk.pl` sucht ausgehend von einer RVK-Notation nach passenden Mappings
  und geht die betreffende Download-Datei durch um BK-Anreicherung zu erzeugen. Beispiel:

  ~~~bash
  ./rvk2bk.pl "ET 500"  # TODO: Unterklassen einbeziehen
  ./rvk2bk.pl "XL"      # Ganze Oberklasse (weil auf BK-Blattknoten gemappt)
  ~~~

## Beispiele

Hauptklassen der RVK, die per exactMatch auf eine BK-Unterklasse der untersten Ebene gemappt sind:

* `XL` Rechtsmedizin
* `YG` Neurologie
* `YP` Zahnmedizin
* `YQ` Kinderheilkunde
* `WT` Verhaltensforschung und Tierpsychologie

Klassen der RVK, die per exactMatch auf eine beliebige BK-Klasse gemappt sind:

* `ET 500` Lexikologie
* `ST 240 - ST 250` Programmiersprachen (derzeit nicht unterstützt, da Unterklassen relevant)


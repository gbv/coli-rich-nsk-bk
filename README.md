# NSK-BK Anreicherung

Dieses git-Repository enthält Skripte und Daten zur Anreicherung des K10plus-Katalog um Notationen der Basisklassifikation (BK) auf Grundlage von Erschließungsdaten und Mappings mit der Systematik des neuen Sachkatalogs (NSK) der Staatsbibliothek zu Berlin.

## 1. Abfrage der NSK-Normdatensätze aus dem Bereich Theologie

    $ ./nsk-normdaten.sh The > nsk-the.tsv

## 2. Reduktion der NSK-Notationen auf Grundnotation (Fachgruppe, Buchstabe und Hundertergruppe)

...

## 3. Ermittlung verknüpfter Titeldatensätze

    $ ./sbb-rel.sh $PPN

## 4. Ermittlung und Ausgabe der Anreicherung

...

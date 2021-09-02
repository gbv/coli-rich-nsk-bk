# NSK-BK Anreicherung

Dieses git-Repository enthält Skripte und Daten zur Anreicherung des K10plus-Katalog um Notationen der [Basisklassifikation (BK)](http://bartoc.org/en/node/18785) auf Grundlage von Erschließungsdaten und Mappings mit der [Systematik des neuen Sachkatalogs (NSK)](http://bartoc.org/en/node/20298) der Staatsbibliothek zu Berlin.

## 1. Abfrage der NSK-Normdatensätze aus dem Bereich Theologie

    $ ./nsk-normdaten.sh The > nsk-the.tsv

 und Reduktion auf Grundnotation 

    $ ./nsk-grundnotation.pl < nsk-the.tsv

## 2. Abfrage aller Titeldatensätze mit verknüpftem NSK-Normdatensatz

    $ awk '{print $1}' nsk-the.tsv | xargs -L 1 ./sbb-rel.sh > nsk-title-records.pica

Nach einigen Stunden...

    $ picadata count nsk-title-records.pica | grep records
    39509 records

Anzahl unterschiedlicher Titeldatensätze:

    $ picadata -p 003@0 nsk-title-records.pica | sort | uniq | wc -l
    24624

    $ ./unique-pica-records.pl < nsk-title-records.pica > nsk-unique-titles.pica
 
## 3. Analyse der Titeldaten

    $ picadata 045Q nsk-unique-titles.pica | picadata count | grep records
    5801 records

## 4. Abfrage und Auswertung der Mappings

Es werden zur Anreicherung alle Mapping vom Typ =, <, und ≈ berücksichtigt.

...

## 5. Ermittlung und Ausgabe der Anreicherung

...

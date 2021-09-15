# NSK-BK Anreicherung

Dieses git-Repository enthält Skripte und Daten zur Anreicherung des K10plus-Katalog um Notationen der [Basisklassifikation (BK)](http://bartoc.org/en/node/18785) auf Grundlage von Erschließungsdaten und Mappings mit der [Systematik des neuen Sachkatalogs (NSK)](http://bartoc.org/en/node/20298) der Staatsbibliothek zu Berlin.

## 1. Abfrage der NSK-Normdatensätze aus dem Bereich Theologie

    $ ./nsk-normdaten.sh The > nsk-the.tsv
    $ wc -l nsk-the.tsv
    9273 nsk-the.tsv

 und Reduktion auf Grundnotation 

    $ ./nsk-grundnotation.pl < nsk-the.tsv > nsk-notationen-the.tsv
    $ awk -F'\t' '{print $2}' nsk-notationen-the.tsv | sort | uniq | wc -l
    36

## 2. Abfrage aller Titeldatensätze mit verknüpftem NSK-Normdatensatz

    $ awk '{print $1}' nsk-the.tsv | xargs -L 1 ./sbb-rel.sh > nsk-title-records.pica

Nach einigen Stunden...

    $ picadata count nsk-title-records.pica | grep records
    39509 records

Anzahl unterschiedlicher Titeldatensätze:

    $ picadata -p 003@0 nsk-title-records.pica | sort | uniq | wc -l
    24624

    $ ./unique-pica-records.pl < nsk-title-records.pica > nsk-unique-titles.pica
    24624 records
    24624 holdings
    101862 fields
 
## 3. Analyse der Titeldaten

    $ picadata 045Q nsk-unique-titles.pica | picadata count | grep records
    5801 records

## 4. Abfrage und Auswertung der Mappings sowie Ausgabe der Anreicherung

Es werden zur Anreicherung alle Mapping vom Typ =, <, und ≈ berücksichtigt. Da die Konkordanz für die Fachgruppe `The` vollständig bis zur tiefsten Ebene ist (alle Klassen sind direkt gemappt), vereinfacht sich der Mappingprozess.

    $ ./anreicherung.pl < nsk-unique-titles.pica  > nsk-the-anreicherung.pica
    Kein Mapping gefunden für NSK 'The B 900'
    Kein Mapping gefunden für NSK 'The B 100'
    Kein Mapping gefunden für NSK 'The E 1100'
    $ picadata count nsk-the-anreicherung.pica 
    22470 records
    54433 fields

Das heisst es können 25887 BK-Notationen an 18025 Datensätzen hinzugefügt werden. 

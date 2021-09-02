#!/bin/bash

# Liefert mit einem Normdatensatz verknüpften Titeln im SBB-Katalog (mit vorhandener BK/NSK-Sacherschließung)

# Beispiel:
# https://opac.k10plus.de/DB=2.299/REL?PPN=292581319
# https://sru.k10plus.de/opac-de-1?version=1.1&operation=searchRetrieve&query=pica.1049%3D292581319+and+pica.1045%3Drel-tt+and+pica.1001%3Db&maximumRecords=2&recordSchema=picaxml
# ./sbb-rel.sh 292581319

PPN=$1
MAX=10000

if [[ "$PPN" =~ ^[0-9]+[Xx]?$ ]]; then
    QUERY="pica.1049=$PPN and pica.1045=rel-tt and pica.1001=b"
    # SRU liefert trotz pica.1001=b Normdatensätze mit, deshalb der Filter
    catmandu convert sbb --query "$QUERY" --total $MAX \
        --fix 'select pica_match("002@$0","^[^T]")' \
        to pp | picadata -p '003@,045Q,145Z'
else
   echo "Usage: $0 PPN" >&2
   exit 1
fi



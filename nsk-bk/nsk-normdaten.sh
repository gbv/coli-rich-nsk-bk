#!/bin/bash

# Läd alle NSK-Normdatensätze einer Fachgruppe aus dem SBB-Katalog und gibt PPN und Notation aus

FACHGRUPPE=$1
MAX=20000

if [[ "$FACHGRUPPE" =~ ^[a-zA-Zäöü]+$ ]]; then
    echo "Ermittle NSK-Normdatensätze für die Fachgruppe '$FACHGRUPPE'" >&2
    catmandu convert sbb-normdaten --query "pica.xlsy=$FACHGRUPPE *" --total $MAX \
        --fix "pica_map(045A,record); select all_match(record,'^$FACHGRUPPE')" \
        to TSV --header 0
else
   echo "Usage: $0 FACHGRUPPE" >&2
   exit 1
fi

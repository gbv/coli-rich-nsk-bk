#!/usr/bin/env perl
use v5.14.1;

# Reduziert NSK-Notationen auf Grundnotation (Fachgruppe, Buchstabe und Hundertergruppe)

while (<>) {
    my ( $ppn, $notation ) = split "\t";

    # FIXME: Reduktion funktioniert nicht für
    # - Fachgruppe Geschichte (Ges)
    # - Fachgruppe Sprach- und Literaturwissenschaft (Spra)
    $notation =~ s/^([a-zäöü ]+)(\d{1,2})?(\d\d).*/ $2 ? "$1${2}00" : $1 /eis
      or next;

    say "$ppn\t$notation";
}

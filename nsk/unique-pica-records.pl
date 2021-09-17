#!/usr/bin/env perl
use v5.14.1;
use Catmandu ':all';

my $seen = sub {
    state %ppn;
    return !( $ppn{ $_[0]->{_id} }++ );
};
exporter('pp')->add_many( importer('pp')->select($seen) );

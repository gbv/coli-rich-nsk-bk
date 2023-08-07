#!/usr/bin/env perl
use v5.14.1;
use JSON::PP;

# Reichert PICA-Datensätze um BK an wenn RVK vorhanden aber keine BK

# usage : zcat kxp-subjects.tsv.gz | ./%

my %bk2ppn = do {
    local @ARGV = "bk2ppn.csv";
    map { chomp; split ','; } <>;
};
my %rvk2ppn = ();    # TODO

my ( $cur, @rvk );

#  003@ $0010015701
#+ 045Q/01 $910641593X$Acoli-conc RVK->BK$Ahttps://coli-conc.gbv.de/api/mappings/dabd3e00-b8f5-4521-9ede-1c5b7ba4bf9d

sub enrich {
    return unless $cur && @rvk;

    my $args = join " ", map { "\"$_\"" } @rvk;
    say STDERR $args;

    my @addrvk =
      map { decode_json($_) } split "\n", `./bk-from-rvk.js $args`;

    my %add;
    for (@addrvk) {
        my $bkppn = $bk2ppn{ $_->{bk} } or next;

        my $uri  = $_->{uri};
        my $pica = "+ 045Q/01 \$9$bkppn\$Acoli-conc RVK->BK\$A$uri";

        my $rvk = $_->{rvk};
        if ( my $rvkppn = $rvk2ppn{$rvk} ) {
            $pica = "  045R \$9$rvkppn\n$pica";
        }

        $add{ $_->{bk} } = $pica;
    }

    if ( keys %add ) {
        say "  003@ \$0$cur";
        say $_ for values %add;
        say "";
    }
}

while (<>) {
    chomp;
    my ( $ppn, $voc, $id ) = split "\t", $_;

    if ( $voc eq 'rvk' ) {
        push @rvk, $id;
    }
    elsif ( $voc eq 'bk' ) {
        @rvk = ();
    }

    if ( $cur && $ppn ne $cur ) {
        enrich;
        @rvk = ();
    }
    $cur = $ppn;
}

enrich;

#!/usr/bin/env perl
use v5.14.1;
use Catmandu ':all';
use PICA::Data ':all';
use List::Util qw(uniq);
use JSON::API;

# Lade PPNs für NSK-Normdatensätze
my %nsk;
importer( 'TSV', file => 'nsk-notationen-the.tsv', header => 0 )->each(
    sub {
        $nsk{ $_[0]{0} } = ( $_[0]{1} =~ s/\s+$//r );
    }
);

sub getNSKBKMapping {
    my $notation = shift;

    state %cache;
    state $api = JSON::API->new('http://coli-conc.gbv.de/api/mappings');

    $cache{$notation} //= $api->get(
        '',
        {
            from      => $notation,
            fromSchme => 'http://bartoc.org/en/node/20298',
            toScheme  => 'http://uri.gbv.de/terminology/bk/',
            type =>
'http://www.w3.org/2004/02/skos/core#exactMatch|http://www.w3.org/2004/02/skos/core#narrowMatch|http://www.w3.org/2004/02/skos/core#closeMatch',
            creator => 'https://orcid.org/0000-0001-5203-9976',
        }
    );
}

sub bkAncestors {
    my ($notation) = @_;

    state $api = JSON::API->new('http://api.dante.gbv.de/ancestors');
    state %ancestors;

    unless ( $ancestors{$notation} ) {
        my $uri = "http://uri.gbv.de/terminology/bk/$notation";
        my $param = { uri => $uri, properties => "notation" };
        my @ids =
          ( $notation, map { $_->{notation}[0] } @{ $api->get( '', $param ) } );

        # say STDERR "ancestors of $uri: " . join ' ', @ids;

        while (@ids) {
            my $id = shift @ids;
            $ancestors{$id} = [@ids];
        }
    }

    return $ancestors{$notation};
}

sub getBKPPN {
    my $notation = shift;

    state %cache;

    if ( !exists $cache{$notation} ) {
        my $importer =
          importer( 'kxp-normdaten', query => "pica.bkl=$notation" );
        my $pica = $importer->next;
        die "Failed to get unique PPN for BK record $notation\n"
          if !$pica || $importer->next;
        $cache{$notation} = $pica->{_id};
    }

    return $cache{$notation};
}

my $writer = pica_writer( 'plain', annotated => 1 );

importer('pp')->each(
    sub {
        my $record = shift;
        my $ppn    = $record->{_id};

        my @relppns = uniq( pica_values( $record, '145Z$9' ) );

        # warn "$ppn: Kein NSK-Satz für PPN $_\n"
        #  for grep { !$nsk{$_} } @relppns;
        my @notation = grep { $_ } map { $nsk{$_} } @relppns;

        my @mappings;
        for (@notation) {
            my $m = getNSKBKMapping($_);
            warn "Kein Mapping gefunden für NSK '$_'\n" unless @$m;
            push @mappings, @$m;
        }

        return unless @mappings;

        # Bereits vorhandene BK-Notationen
        my %bkseen = map { ( $_ => 1 ) } pica_values( $record, '045Q$a' );
        my @fields;

        # Alle BK-Notationen des Titels
        my %all = %bkseen;
        $all{$_} = 1 for map { $_->{to}{memberSet}[0]{notation}[0] } @mappings;

        for ( my ( $id, $status ) = each %all ) {
            for ( @{ bkAncestors($id) } ) {
                if ( $all{$_} ) {

                    # übergeordnete Klasse nicht ebenfalls vergeben
                    $bkseen{$_} = 1;
                }
            }
        }

        for my $m (@mappings) {
            my $bk = $m->{to}{memberSet}[0]{notation}[0];

            next if $bkseen{$bk}++;    # nicht mehrfach gleiche BK

            push @fields,
              [
                '045Q', '01',
                9 => getBKPPN($bk),
                a => $bk,
                A => 'coli-conc NSK->BK',
                A => $m->{uri},
                '+'
              ];
        }

        $writer->write( [ [ '003@', '', '0', $ppn, ' ' ], @fields ] )
          if @fields;
    }
);

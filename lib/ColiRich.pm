package ColiRich;
use v5.14.1;

use parent qw(Exporter);
our @EXPORT = qw(getConcept getScheme getMappings mappingTypeByUri coliRich);

use JSON::API;
use List::Util qw(any);
use MappingSource;    # TODO: relative to this directory

our %APIOPT = ( debug => 0, ssl_opts => { verify_hostname => 0 } );

sub getConcept {
    my ( $voc, %query ) = @_;

    die "missing notation" unless $query{notation} or $query{uri};

    my $hash = join ' ', map { ( $_, $query{$_} ) } sort keys %query;

    state %cache;
    unless ( exists $cache{$hash} ) {

        my $api = JSON::API->new( $voc->{API}, %APIOPT );
        my $res = $api->get( 'data', { voc => $voc->{uri}, %query } );
        if ( $api->was_success && ref $res ) {
            $cache{$hash} = $res->[0];
        }
        else {
            $cache{$hash} = undef;
            my $id = $query{notation} // $query{uri};
            warn "unknown " . $voc->{notation}[0] . ": $id\n";
        }
    }

    return $cache{$hash};
}

my %schemes = (
    NSK => {
        notation => ["NSK"],
        uri      => "http://bartoc.org/en/node/20298",
        API      => "https://coli-conc.gbv.de/api/",
    },
    BK => {
        notation => ["BK"],
        uri      => "http://bartoc.org/en/node/18785",
        API      => "http://api.dante.gbv.de/",
        PICAPATH => '045Q[01]$a',
    },
    RVK => {
        notation => ["RVK"],
        uri      => "http://uri.gbv.de/terminology/rvk/",
        API      => "https://coli-conc.gbv.de/rvk/api/",
        PICAPATH => '045R$a',
    },
    DDC => {
        notation => ["DDC"],
        uri      => "http://bartoc.org/en/node/241",
        API      => "https://coli-conc.gbv.de/api/"
    }
);

sub getScheme {
    my %query = @_;
    return $schemes{ $query{notation} };
}

sub getMappings {
    my ( $from, $to, $notation ) = @_;

    my $api = JSON::API->new( 'http://coli-conc.gbv.de/api/mappings', %APIOPT );
    my $mappings = $api->get(
        '',
        {
            from       => $notation,
            fromSchme  => $from->{uri},
            toScheme   => $to->{uri},
            properties => 'annotations,creator,partOf',
        }
    );

    return @$mappings;
}

my %mappingTypes = (
    'http://www.w3.org/2004/02/skos/core#closeMatch'   => { notation => ["≈"] },
    'http://www.w3.org/2004/02/skos/core#exactMatch'   => { notation => ["="] },
    'http://www.w3.org/2004/02/skos/core#narrowMatch'  => { notation => ["<"] },
    'http://www.w3.org/2004/02/skos/core#broadMatch'   => { notation => [">"] },
    'http://www.w3.org/2004/02/skos/core#relatedMatch' => { notation => ["~"] },
    'http://www.w3.org/2004/02/skos/core#mappingRelation' =>
      { notation => ['→'] },
);

sub mappingTypeByUri {
    return $mappingTypes{ $_[0] };
}

sub getBKEnrichment {
    my ( $from, $to, @fromNotations ) = @_;

    state $bkSource = MappingSource->new( from => $from, to => $to );

    return $bkSource->mapNotations(@fromNotations);
}

sub coliRich {
    my ( $record, $from, $to, $resolver ) = @_;
    my $pica = $record->fields('003@') or return;

    # FIXME: support other vocabularies as well
    return if $to->{uri} ne "http://bartoc.org/en/node/18785";

    my @fromNotations = $record->values( $from->{PICAPATH} ) or return;
    my @toNotations   = $record->values( $to->{PICAPATH} );

    my $source = "coli-conc $from->{notation}[0]\->$to->{notation}[0]";

    # TODO: bestehende Mappings kontrollieren und ggf. ändern ?

    my $enrich = getBKEnrichment( $from, $to, @fromNotations ) or return;

    # don't enrich existing notations
    delete $enrich->{$_} for @toNotations;

    while ( my ( $notation, $mappingUri ) = each %$enrich ) {
        my $conceptPPN = $resolver->($notation);

        push @$pica,
          [
            $to->{PICAPATH}->fields,
            $to->{PICAPATH}->occurrences,
            9 => $conceptPPN,
            a => $notation,
            A => $source,
            A => $mappingUri,
            '+'
          ];
    }

    return @$pica > 1 ? $pica : undef;
}

1;

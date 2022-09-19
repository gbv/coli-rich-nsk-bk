package MappingSource;
use v5.14.1;
use JSON::PP;
use URI::Escape;
use HTTP::Tiny;

sub new {
    my ( $class, %config ) = @_;
    bless {
        from  => $config{from},
        to    => $config{to},
        cache => {}
      },
      $class;
}

use Data::Dumper;

sub lookupMapping {
    my ( $self, $notation ) = @_;

    if ( !exists $self->{cache}->{$notation} ) {

        # TODO: other vocabularies too
        my %query = (
            fromScheme => $self->{from}{uri},
            toScheme   => $self->{to}{uri},
            from       => $notation,
            partOf     => "any",
            strict     => 1,
            type       =>
"http://www.w3.org/2004/02/skos/core#narrowMatch|http://www.w3.org/2004/02/skos/core#narrowMatch"
        );
        my $url = "https://coli-conc.gbv.de/api/mappings/infer?" . join '&',
          map { "$_=" . uri_escape( $query{$_} ) } sort keys %query;

        my $jskos = decode_json( HTTP::Tiny->new->get($url)->{content} );

        my $enrich = {};
        for my $mapping (@$jskos) {
            for ( @{ $mapping->{to}{memberSet}[0]{notation} } ) {
                $enrich->{$_} = $mapping->{uri};
            }
        }

        $self->{cache}->{$notation} = $enrich;
    }

    return $self->{cache}->{$notation};
}

sub mapNotations {
    my $self   = shift;
    my $result = {};

    for (@_) {
        my $map = $self->lookupMapping($_);
        for my $notation ( keys %$map ) {
            $result->{$notation} = $map->{$notation};
        }
    }

    return $result;
}

1;

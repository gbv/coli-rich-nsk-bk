package MappingFilter;
use v5.14.1;
use Catmandu qw(importer);
use List::Util qw(any);

sub new {
    my ( $class, $file ) = @_;
    bless Catmandu->importer( 'YAML', file => $file )->next, $class;
}

sub filter {
    my ( $self, $mapping ) = @_;

    # close, broad and related match can never be used for enrichment
    my $type = ( $mapping->{type} || [] )->[0]
      || 'http://www.w3.org/2004/02/skos/core#mappingRelation';
    return if $type && $type =~ /(close|broad|related)Match$/;

    my $annotations = $mapping->{annotations} || [];

    # confirmed mappings can be used
    return 1 if any { $_->{motivation} eq 'moderating' } @$annotations;

    # never use downvoted mappings
    # TODO: only if downvoted by known account?
    return
      if any { $_->{motivation} eq 'assessing' and $_->{bodyValue} eq "-1" }
    @$annotations;

    # useable concordances (independently of mapping type and creator)
    my %concordances = map { ( $_ => 1 ) } @{ $self->{concordances} || [] };
    return 1
      if any { $concordances{ $_->{uri} } } @{ $mapping->{partOf} || [] };

    # mappings of type exact or narrow by selected accounts
    return if $type !~ /exact|narrow/;

    # check creator
    my ($creator) = map { $_->{uri} } @{ $mapping->{creator} || [] };
    return unless $creator;

    my $fromScheme = $mapping->{fromScheme}{notation}[0] || '?';
    my $toScheme   = $mapping->{toScheme}{notation}[0]   || '?';

    for ( @{ $self->{creators} || [] } ) {
        if ( ref $_ ) {
            if (   $_->{fromScheme} eq $fromScheme
                or $toScheme eq $_->{toScheme} )
            {
                for ( @{ $_->{creators} } ) {
                    return 1 if $_ eq $creator;
                }
            }
        }
        else {
            return 1 if $_ eq $creator;
        }
    }

    return;
}

1;

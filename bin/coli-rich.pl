#!/usr/bin/env perl
use v5.14.1;

# libraries
use Cwd qw(abs_path);
use FindBin;
use lib abs_path("$FindBin::Bin/../lib");
use ColiRich qw(getScheme coliRich);
use PICA::Data qw(pica_path);

# parse command line options, get vocabularies: from and to
use Pod::Usage;
use Getopt::Long;

GetOptions( \my %opt, 'help|?', 'normalized|n' )
  or pod2usage(2);
pod2usage( -verbose => 99, -sections => [qw(SYNOPSIS OPTIONS EXAMPLES)] )
  if $opt{help} or !@ARGV;

pod2usage("missing schemes argument")   if @ARGV < 1;
pod2usage("malformed schemes argument") if $ARGV[0] !~ /^[^-]+-[^-]+$/;

my ( $from, $to ) =
  map { getScheme( notation => $_ ) or pod2usage("unknown scheme $_") }
  map { uc $_ } split /-/, shift @ARGV;

# TODO: support more target vocabularies
if ( $to->{uri} ne "http://bartoc.org/en/node/18785" ) {
    die "Sorry, only enrichment with BK supported by now!\n";
}

$_->{PICAPATH} = pica_path( $_->{PICAPATH}, position_as_occurrence => 1 )
  for ( $from, $to );

pod2usage("Choose either PPNs or CQL query!") if $opt{query} && @ARGV;

# initialize record source
use Catmandu qw(importer exporter);
my $reader;

if (@ARGV) {
    $opt{query} = join " or ", map {
        die "Invalid PPN: $_\n"
          if $_ !~ /^[0-9]+[0-9Xx]$/;
        "pica.ppn=$_"
    } @ARGV;
}

if ( $opt{query} ) {
    $reader = importer( 'kxp', query => $opt{query} );
}
else {
    $reader =
      importer( 'PICA', type => $opt{normalized} ? 'normalized' : 'plain' );
}

# Look up a BK class by its notation and return its PPN. Dies if not found.
my $getBKPPN = sub {
    state %cache;

    my $notation = shift;
    return $cache{$notation} if exists $cache{$notation};

    # get PPN of BK record
    my $importer =
      Catmandu->importer( 'kxp-normdaten', query => "pica.bkl=$notation" );
    my $pica = $importer->next;
    die "Failed to get unique PPN for BK record $notation\n"
      if !$pica || $importer->next;

    return $cache{$notation} = $pica->{_id};
};

# process records
my $writer = exporter( 'PICA', type => 'plain', annotate => 1 );
while ( my $record = $reader->next ) {
    bless $record, 'PICA::Data';
    my $pica = coliRich( $record, $from, $to, $getBKPPN );
    $writer->add($pica) if $pica;
}

=head1 SYNOPSIS

 enrich [options] <schemes> [ppn]+

 Enrich PICA Plain records from K10plus based on vocabulary mappings.

=head1 OPTIONS
 
 --help|-h        self help message
 --normalized|-n  expect input records PICA normalized syntax (from STDIN)
 --query|-q       get input records via SRU query (CQL)

=head1 EXAMPLES

 coli-rich < records.dat

=head1 DESCRIPTION

This script reads PICA+ records from STDIN or via SRU.

=cut

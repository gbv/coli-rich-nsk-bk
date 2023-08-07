#!/usr/bin/env perl
use v5.14;
use PICA::Data qw(1.18 :all);
use Catmandu   qw(importer);
use JSON::API;

my %ppn2bk = do {
    local @ARGV = "bk2ppn.csv";
    map { chomp; reverse split ','; } <>;
};

my $parser = pica_parser('plain');
my $writer = pica_writer('plain');
while ( my $record = $parser->next ) {
    my $ppn = $record->{_id};

    for my $f ( @{ $record->fields('045Q/01') } ) {
        my ($bkppn) = pica_values( [$f], '045Q/01$9' );
        my ($uri)   = grep { $_ =~ /^http/ } pica_values( [$f], '045Q/01$A' );

        system('kxp $ppn | grep -E "^045 [QR]"');
        say "BK $bkppn = $ppn2bk{$bkppn}";
        system(
"curl -s $uri | jq -r ' [.from,.to] | map(.memberSet[].notation[0]) | join( \" => \")'"
        );
    }

    #say $record;
    $writer->write($record),;
}


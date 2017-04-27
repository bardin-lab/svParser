#!/usr/bin/perl

use strict;
use warnings;

use 5.18.2;

use FindBin;
use FindBin '$Script';

use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'bin/');

use SV_parser;

use feature qw/ say /;
use Data::Dumper;
use Getopt::Long qw/ GetOptions /;

use File::Basename;

my $vcf_file; 
my $help;
my $id;
my $dump;
my $chromosome;
my $type = "guess";

my %filters;
			   
# Change to write to cwd by default (-o . is messy and confusing)
my $output_dir;

GetOptions( 'vcf=s'	        	=>		\$vcf_file,
			'type=s'			=>		\$type,
			'id=s'				=>		\$id,
			'dump'				=>		\$dump,
			'filter:s'			=>		\%filters,
            'output_dir=s'     	=>      \$output_dir,
			'chromosome=s'		=>		\$chromosome,
			'help'              =>      \$help
	  ) or die usage();

if ($help) { exit usage() } 



if (not $vcf_file) {
	 exit usage();
}


# temp
my $filter = 0;

if ( scalar keys %filters > 0 ){
	print "\n";
	if (exists $filters{'a'}){
		say "Running in filter mode, using all default filters:";
		say "o Read support > 4";
		say "o Read depth > 10";
		say "o Ratio of tumour:normal read support > 0.1";
		say "o SQ quality > 10";
		
		%filters = ("su" => 4,
					"dp" => 10,
					"tnr" => 0.1,
					"sq" => 10
					);
					
		$filter = 1;
	}
	elsif ( $filters{'su'} or $filters{'dp'} or $filters{'tnr'} or $filters{'sq'} ) {
		say "Running in filter mode, using custom filters:";
		say "o Read support > $filters{'su'}" if $filters{'su'};
		say "o Read depth > $filters{'dp'}" if $filters{'dp'};
		say "o Ratio of tumour:normal read support > $filters{'tnr'}" if $filters{'tnr'};
		say "o SQ quality > $filters{'sq'}" if $filters{'sq'};
		$filter = 1;
	}
	else { say "Illegal filter option used. Please specify filters to run with (or use '-f a' to run all defaults)"}
}

# Need to make sure this is stable
$output_dir =~ s!/*$!/! if $output_dir; # Add a trailing slash

my ($name, $extention) = split(/\.([^.]+)$/, basename($vcf_file), 2);

print "\n";

# Retun SV and info hashes 
my ( $SVs, $info, $filtered_vars ) = SV_parser::typer($vcf_file, $type, %filters);

# Print all info for specified id

SV_parser::summarise_variants( $SVs, $filter, $chromosome ) unless $id or $dump;

# Print all info for specified id

SV_parser::get_variant( $id, $SVs, $info, $filter ) if $id;

# Dump all variants to screen
SV_parser::dump_variants( $SVs, $info, $filter, $chromosome ) if $dump;

SV_parser::print_variants ( $SVs, $filtered_vars, $name, $output_dir ) if $output_dir;

sub usage {
	say "********** $Script ***********";
    say "Usage: $Script [options]";
	say "  --vcf = VCF file for parsing";
	say "  --type = specifiy input type [LUMPY = l; DELLY = d; novobreak = n] or let $Script guess";
	say "  --id = extract information for a given variant";
	say "  --dump = cycle through all variants (can be combined with both -f and -c)";
	say "  --filter = apply filters and mark filtered variants";
	say "  --output = write out variants that pass filters to specified dir";
	say "  --chromosome = used in conjunction with --dump will cycle though variants on chromosome speciified in -c";
	say "  --help\n";

	say "Examples: ";
	say "o Browse all variants that passed filter within a speicifc window on X chromosome:";

	say "->  perl script/sv_parse.1.0.pl -v data/HUM-7.tagged.SC.lumpy.gt_all.vcf -t l -f -d -c X:3000000-3500000";
	say "o Filter vars and write to file in cwd:";
	say "->  perl $0 -v data/HUM-7.tagged.SC.lumpy.gt_all.vcf -t l-f -o .\n";
	say "Nick Riddiford 2017";
}

# sub usage {
# 	print
# "
# usage: $Script [-h] [-v FILE] [-o PATH] [-t STR] [-i STR] [-d] [-f] [-c STR]
#
# svParser
# author: Nick Riddiford (nick.riddiford\@curie.fr)
# version: v1.0
# description: Browse vcf output from several SV callers LUMPY, DELLY and novobreak
#
# arguments:
#   -h, --help            show this help message and exit
#   -v FILE, --vcf FILE
#                         VCF input [required]
#   -o PATH, --output PATH
#                         path to write filtered file to
#   -t STRING, --type STRING
#                         specify input source (default: guess from input)
#                         -l = LUMPY
#                         -d = DELLY
#                         -n = novobreak
#   -i STRING, --id STRING
#                         breakpoint id to inspect
#   -d, --dump            cycle through breakpoints
#   -c STRING, --chromosome
#                         limit search to chromosome and/or region (e.g. X:10000-20000)
#                         can be used in conjunction with -d
#   -f SRING, --filter    number of reads to sample from BAM file for building insert size distribution [1000000]
#
# examples: ;
# o Browse all variants that passed filter within a speicifc window on X chromosome:
# ->  perl script/sv_parse.1.0.pl -v data/HUM-7.tagged.SC.lumpy.gt_all.vcf -t l -f -d -c X:3000000-3500000
# o Filter vars and write to file in cwd:
# ->  perl $0 -v data/HUM-7.tagged.SC.lumpy.gt_all.vcf -t l-f -o .
# "
# }
#! /usr/bin/perl -w

use strict;
use POSIX qw(strftime);


#die "perl $0 <input URL>\nOutput: <input.conditionFormat.bz2>\n" unless @ARGV;

my $CGDURL = 'http://research.nhgri.nih.gov/CGD/download/txt/CGD.txt.gz';

if (@ARGV > 0) {
	$CGDURL = $ARGV[0];
}


my $datestring = strftime "%m-%d-%y", localtime;



my $CGD_in = "CGD_$datestring.tsv";
my $CGD_ingz = "$CGD_in"."\.gz";

unless (-e $CGD_in) {
	system ("curl $CGDURL -o $CGD_ingz");
	system ("gunzip $CGD_ingz");
}

my $CGD_out = $CGD_in.".conditionFormat";
$CGD_out =~ s/\.gz//g;

print "output $CGD_out\n";


my %content = ();
my %output = ();


my %GENENAMEMAP = (
	"MT-ATP8"	=> "ATP8",
	"MT-TL1"	=> "TRNL1",
	"PRIMPOL"	=> "CCDC111",
	"KLHL41"	=> "KBTBD10",
	"C8ORF37"	=> "C8orf37",
	"MT-TS1"	=> "TRNS1",
	"MT-CO1"	=> "COX1",
	"MT-ND1"	=> "ND1",
	"MT-RNR1"	=> "RNR1",
	"MT-TE"		=> "TRNE",
	"BCO1"		=> "BCMO1",
	"C19ORF12"	=> "C19orf12",
	"POMK"		=> "SGK196",
	"C5ORF42"	=> "C5orf42",
	"KIF1BP"	=> "KIAA1279",
	"POMGNT2"	=> "GTDC2",
	#"TRAC"		=> "",
	"MT-TF"		=> "TRNF",
	"ADGRG1"	=> "GPR56",
	"UQCC3"		=> "C11orf83",
	"NSMF"		=> "NELF",
	"MT-ATP6"	=> "ATP6",
	"MT-CO3"	=> "COX3",
	"DNAAF5"	=> "HEATR2",
	"ANOS1"		=> "KAL1",
	"MT-ND5"	=> "ND5",
	"MT-ND6"	=> "ND6",
	"MT-TC"		=> "TRNC",
	"CEP83"		=> "CCDC41",
	"C12ORF65"	=> "C12orf65",
	"MT-RNR2"	=> "RNR2",
	#"FSHMD1A"	=> "",
	"P3H1"		=> "LEPRE1",
	"KLHL40"	=> "KBTBD5",
	"KIZ"		=> "PLK1S1",
	"SUGCT"		=> "C7orf10",
	"P3H2"		=> "LEPREL1",
	"SC5D"		=> "SC5DL",
	"ADGRV1"	=> "GPR98",
	#"PDZD7"		=> "",
	"ADGRG1"	=> "C2orf71",
	"CFAP57"	=> "WDR65",
	#"GRHL3"	=> "",
	"MT-CO2"	=> "COX2",
	"C21ORF59"	=> "C21orf59",
	"MT-ND2"	=> "ND2",
	"MT-ND4"	=> "ND4",
	"MT-ND4L"	=> "ND4L",
	"C12ORF65"	=> "C12orf65",
	"CFAP53"	=> "CCDC11",
	"PHYKPL"	=> "AGXT2L2",
	"MT-ND3"	=> "ND3",
	"KMT2A"		=> "MLL",
	"IFNL3"		=> "IL28B",
	#"IGHM"	=> "",
	"B3GLCT"	=> "B3GALTL",
	#"KCNJ18"	=> "",
	"HNRNPDL"	=> "HNRPDL",
	"NADK2"		=> "NADKD1",
	#"IGKC"	=> "",
	"AMER1"		=> "FAM123B",
	"NT5C3A"	=> "NT5C3",
	#"ATXN8"	=> "",
	"B4GAT1"	=> "B3GNT1",
	"KMT2D"		=> "MLL2",
	"ACKR1"		=> "DARC",
	"MGME1"		=> "C20orf72",
	"UQCC2"		=> "MNF1",
	"ERMARD"	=> "C6orf70",
	"ZBTB18"	=> "ZNF238",
	"LINS1"		=> "LINS"
	);

my %CATEGORIES = (
	'allergy-immunology-infectious'=>'1',
	'audiologic-otolaryngologic'=>'1',
	'biochemical'=>'1',
	'cardiovascular'=>'1',
	'craniofacial'=>'1',
	'dental'=>'1',
	'dermatologic'=>'1',
	'endocrine'=>'1',
	'gastrointestinal'=>'1',
	'general'=>'1',
	'genitourinary'=>'1',
	'hematologic'=>'1',
	'musculoskeletal'=>'1',
	'neurologic'=>'1',
	'obstetric'=>'1',
	'oncologic'=>'1',
	'ophthalmologic'=>'1',
	'pulmonary'=>'1',
	'renal'=>'1');

foreach my $key (keys %CATEGORIES) {
		print "all key $key\n";
}

& read_CGD ($CGD_in, \%content, \%output);

print "here abcd\n";

& output (\%output);

system ("bzip2	$CGD_out");
	
# Input
# Col 0 = GENE
# Col 1 = HGNC ID
# Col 2 = ENTREZ GENE ID
# Col 3 = CONDITION
# Col 4 = INHERITANCE
# Col 5 = AGE GROUP
# Col 6 = ALLELIC CONDITIONS
# Col 7 = MANIFESTATION CATEGORIES
# Col 8 = INTERVENTION CATEGORIES
# Col 9 = COMMENTS
# Col 10 = INTERVENTION/RATIONALE
# Col 11 = REFERENCES

# Output
# geneSymbols	
# name	
# inheritanceMode	
# categories	
# overview	
# interventions	
# abbreviation	
# additionalPhenotypicInformation	
# description	
# penetrance

sub output () {
	my ($output_r) = @_;

	print "here abcd $CGD_out\n";

	open (OUT, ">$CGD_out") || die "$!";

	my $HEADER = "geneSymbols	name	inheritanceMode	categories	overview	interventions	abbreviation	additionalPhenotypicInformation	description	penetrance";
	print OUT "$HEADER\n";

	foreach my $condition (keys %$output_r) {
		my $str = '';
		if (exists ($output_r->{"$condition"}->{"geneSymbols"})) {
			my $inheritanceMode = '';
			if (($output_r->{"$condition"}->{"inheritanceMode"} eq 'AR') ||
				($output_r->{"$condition"}->{"inheritanceMode"} eq 'AR|Digenic') || 
				($output_r->{"$condition"}->{"inheritanceMode"} eq 'AR|BG') ) {
				$inheritanceMode = 'autosomal-recessive';
			} elsif (($output_r->{"$condition"}->{"inheritanceMode"} eq 'AD') ||
				($output_r->{"$condition"}->{"inheritanceMode"} eq 'AD (with imprinting)') || 
				($output_r->{"$condition"}->{"inheritanceMode"} eq 'AD|BG') || 
				($output_r->{"$condition"}->{"inheritanceMode"} eq 'AD|Digenic') || 
				($output_r->{"$condition"}->{"inheritanceMode"} eq 'AD|Multigenic') || 
				($output_r->{"$condition"}->{"inheritanceMode"} eq 'AD|Metholation') ) {
				$inheritanceMode = 'autosomal-dominant';
			} elsif ($output_r->{"$condition"}->{"inheritanceMode"} =~ 'AD|AR') {
				$inheritanceMode = 'multiple';
			} elsif ($output_r->{"$condition"}->{"inheritanceMode"} =~ 'AR|AD') {
				$inheritanceMode = 'multiple';
			} elsif ($output_r->{"$condition"}->{"inheritanceMode"} eq 'Maternal') {
				$inheritanceMode = 'mitochondrial-inheritance';
			} elsif (($output_r->{"$condition"}->{"inheritanceMode"} eq 'XL') ||
					($output_r->{"$condition"}->{"inheritanceMode"} eq 'XL|Digenic') ){
				$inheritanceMode = 'x-linked';
			} elsif ($output_r->{"$condition"}->{"inheritanceMode"} eq 'YL') {
				$inheritanceMode = 'y-linked';
			} elsif ($output_r->{"$condition"}->{"inheritanceMode"} eq 'BG') {
				$inheritanceMode = 'blood-group';
			} elsif ($output_r->{"$condition"}->{"inheritanceMode"} eq 'BG') {
				$inheritanceMode = 'blood-group';
			} elsif ($output_r->{"$condition"}->{"inheritanceMode"} eq 'Digenic') {
				$inheritanceMode = 'multifactorial';
			} else {
				die "WTF  $condition\t".$output_r->{"$condition"}->{"inheritanceMode"}."\n";
			}

			#not add reference information in description
			#if ($output_r->{"$condition"}->{"description"} eq '') {
			#	$output_r->{"$condition"}->{"description"} = $output_r->{"$condition"}->{"References"};
			#} else {
			#	$output_r->{"$condition"}->{"description"} .= "\\n".$output_r->{"$condition"}->{"References"};
			#}

			$str .= $output_r->{"$condition"}->{"geneSymbols"}."\t".
					"$condition"."\t".
					"$inheritanceMode"."\t".
					$output_r->{"$condition"}->{"categories"}."\t".
					"$condition"."\t".										#overview
					$output_r->{"$condition"}->{"interventions"}."\t".
					"\t".													#abbreviation
					$output_r->{"$condition"}->{"AllelicConditions"}."\t".	#additionalPhenotypicInformation

#			                $output_r->{"$condition"}->{"HGNCIDs"}."  ".
#			                $output_r->{"$condition"}->{"ENTREZGeneID"}."  ".
#			                $output_r->{"$condition"}->{"AgeGroups"}."  ".
					#$output_r->{"$condition"}->{"description"}."\t".		#description
					''."\t".													#we don't output descript for now.
					"\n";													#penetrance
		} else {
			print "Error: $condition were not found.\n";
		}


		print OUT "$str";
	} 

	close (OUT);
}


sub read_CGD () {
	my ($CGD_in, $content_r, $output_r) = @_;

	my @Col = ();
	my %content = %$content_r;
	my %output = %$output_r;
	open (CGD, "<$CGD_in") || die "$! $CGD_in";
	while (<CGD>) {
		chomp;
		if (/^#GENE/) {
			my $line = $_;
			$line =~ s/^#//g;
			@Col = split(/\t/, $_);
			for (my $i = 0; $i <= $#Col; $i++) {
				print "Col $i = $Col[$i]\n";
			}
		} else {
			my @line = split(/\t/, $_);
			my $gene = $line[0];

			if (exists $GENENAMEMAP{$gene}) {
				$gene = $GENENAMEMAP{$gene};
			}

			$gene =~ s/ORF/orf/g;

			for (my $i = 1; $i <= $#Col; $i++) {
				$content{$gene}->{$Col[$i]} = $line[$i];

				print "gene $gene col $Col[$i] $line[$i] $content{$gene}->{$Col[$i]}\n" ;
			}

			my $d = ";";
			my @conditions = split (/$d/, $content{$gene}->{"CONDITION"});

			foreach my $condition (@conditions) {
				$condition =~ s/\"//g;
				$condition =~ s/^\s+//g;
				$condition =~ s/\s+$//g;
				$condition =~ s/;;/;/g;
				if ($condition eq "") { next;}

                           # output structure , condition key, content to bin, col in the output struture, prefix
				&binTerms ($output_r, $condition, $gene, "geneSymbols", "");
				&binTerms ($output_r, $condition, $content{$gene}->{"HGNC ID"}, "HGNCIDs", "");
				&binTerms ($output_r, $condition, $content{$gene}->{"ENTREZ GENE ID"}, "ENTREZGeneID", "");
				&binTerms ($output_r, $condition, $content{$gene}->{"AGE GROUP"}, "AgeGroups", "");
				&binTerms ($output_r, $condition, $content{$gene}->{"ALLELIC CONDITIONS"}, "AllelicConditions", "$gene: ");
				&binTerms ($output_r, $condition, $content{$gene}->{"MANIFESTATION CATEGORIES"}, "categories", "");
				&binTerms ($output_r, $condition, $content{$gene}->{"INTERVENTION CATEGORIES"}, "InterventionCategories", "");
				&binTerms ($output_r, $condition, $content{$gene}->{"INHERITANCE"}, "inheritanceMode", "");
				&binTerms ($output_r, $condition, $content{$gene}->{"REFERENCES"}, "References", "http://www.ncbi.nlm.nih.gov/pubmed/");
				&binTerms ($output_r, $condition, $content{$gene}->{"INTERVENTION/RATIONALE"}, "interventions", "");
				&binTerms ($output_r, $condition, $content{$gene}->{"COMMENTS"}, "description", "");
				

			}
		}
	}

	close (CGD);
}

sub binTerms (){
	my ($output_r, $condition, $termValue, $termInOutput, $prefix) = @_;

	$termValue =~ s/\"//g;
	$termValue =~ s/^\s+//g;
	$termValue =~ s/\s+$//g;

	print "$termInOutput $termValue\n";

	my $passflag = 0;
	#Adult (Colorectal cancer, hereditary nonpolyposis, type 5; Endometrial cancer)/Pediatric (Mismatch repair cancer syndrome)
	if ($termValue =~ /Adult\s+\((.+?)\)/) {

		if ($1 =~ /$condition/) {
			if (exists ($output_r->{$condition}->{$termInOutput})) {
				&insert (\$output_r->{$condition}->{$termInOutput}, $prefix."Adult");
			} else {
				$output_r->{$condition}->{$termInOutput} = $prefix."Adult";
			}			
			$passflag = 1;
		}
	}

	if ($termValue =~ /Pediatric\s+\((.+?)\)/) {
		if ($1 =~ /$condition/) {
			if (exists ($output_r->{$condition}->{$termInOutput})) {
				&insert (\$output_r->{$condition}->{$termInOutput}, $prefix."Pediatric");
			} else {
				$output_r->{$condition}->{$termInOutput} = $prefix."Pediatric";
			}
			$passflag = 1;
		} 
	}

	if ($passflag == 0) {

		if (($termValue =~ /Adult\s+\((.+?)\)/) && ($passflag == 0)){
			if (exists ($output_r->{$condition}->{$termInOutput})) {
				&insert (\$output_r->{$condition}->{$termInOutput}, $prefix."Adult");
			} else {
				$output_r->{$condition}->{$termInOutput} = $prefix."Adult";
			}			

			$passflag = 1;
		}

		if ($termValue =~ /Pediatric\s+\((.+?)\)/){
			if (exists ($output_r->{$condition}->{$termInOutput})) {
				&insert (\$output_r->{$condition}->{$termInOutput}, $prefix."Pediatric");
			} else {
				$output_r->{$condition}->{$termInOutput} = $prefix."Pediatric";
			}

			$passflag = 1;
		} 
	}	

	unless ($passflag == 1) {
		my @items_termValue = ();

		if (($termInOutput eq "AllelicConditions") || 
			($termInOutput eq "description"      ) || 
			($termInOutput eq "interventions"   )) {
			push (@items_termValue, $termValue)
		} elsif ($termInOutput eq "categories") { 
			@items_termValue = split (/[\;]/, $termValue);
		} else {
			@items_termValue = split (/[\;\/]/, $termValue);
		}
	
		foreach my $item (@items_termValue) {
			&cleanItem (\$item, $termInOutput);
			
			print "item $item\n";
			if ($item eq 'N/A') {
				$item = '';
			}

			if (exists ($output_r->{$condition}->{$termInOutput})) {
				if ($item ne '') {
					&insert(\$output_r->{$condition}->{$termInOutput}, $prefix.$item);
				}
			} else {
				if ($item ne '') {
					$output_r->{$condition}->{$termInOutput} = $prefix.$item;
				} else {
					$output_r->{$condition}->{$termInOutput} = $item;
				}
			}
		}
	}
	#print $output_r->{$condition}->{$termInOutput}."\n";
}

sub cleanItem () {
	my ($item_r, $termInOutput) = @_;

	$$item_r =~ s/^\s+//g;
	$$item_r =~ s/\s+$//g;

	if ($termInOutput =~ "categories") {
		$$item_r = lc ($$item_r);
		$$item_r =~ s/\//-/g;

		unless ($$item_r eq '') {
			unless (&validate($$item_r, \%CATEGORIES)) {
				die "die abc$$item_r abc"."\n";
			}
		}
	} else {	
		$$item_r =~ s/\"//g;
	}
	if (($$item_r =~ /^(\w\w)\s+\(.*\)/) ||
		($$item_r =~ /^(Digenic)\s+\(.*\)/)) {
		$$item_r = $1;
	}
}

sub insert () {
	my ($ori_r, $insertion) = @_;

	print "insertion $insertion\n";

	unless ($$ori_r =~ /$insertion/) {
		$$ori_r .= "|$insertion";
	}
}

sub validate () {
	my ($item, $hash_r) = @_;

	#foreach my $k (keys %$hash_r) {
	#	print "key $k\n";
	#}

	if (exists ($hash_r->{$item})) {
		print "here $item\n";
		return 1;
	} else {
		return 0;
	}
}

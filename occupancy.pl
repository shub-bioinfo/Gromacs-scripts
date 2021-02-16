#!/usr/bin/perl

#
# plot_hbmap.pl - plot the probability of finding a particular hydrogen bond
# based on several input files:
#   1. coordinate file (for atom naming) - MUST be a .pdb file with NO CHAIN IDENTIFIERS
#   2. hbmap.xpm 
#   3. hbond.ndx (modified to contain only the atom numbers in the [hbonds...] section, nothing else)
#

use strict;

unless(@ARGV) {
    die "Usage: perl $0 -s structure.pdb -map hbmap.xpm -index hbond.ndx\n";
}

# define input hash
my %args = @ARGV;

# input variables
my $map_in;
my $struct;
my $ndx;

if (exists($args{"-map"})) {
    $map_in = $args{"-map"};
} else {
    die "No -map specified!\n";
}

if (exists($args{"-s"})) {
    $struct = $args{"-s"};
} else {
    die "No -s specified!\n";
}

if (exists($args{"-index"})) {
    $ndx = $args{"-index"};
} else {
    die "No -index specified!\n";
}

# open the input
open(MAP, "<$map_in") || die "Cannot open input map file!\n";
my @map = <MAP>;
close(MAP);

open(STRUCT, "<$struct") || die "Cannot open input coordinate file!\n";
my @coord = <STRUCT>;
close(STRUCT);

open(NDX, "<$ndx") || die "Cannot open input index file!\n";
my @index = <NDX>;
close(NDX);

# determine number of HB indices and frames
my $nres = 0;
my $nframes = 0;
for (my $i=0; $i<scalar(@map); $i++) {
    if ($map[$i] =~ /static char/) {
        my $res_line = $map[$i+1];
        my @info = split(" ", $res_line);

        $nframes = $info[0];
        my @nframes = split('', $nframes);
        shift(@nframes);    # get rid of the "
        $nframes = join('', @nframes);

        $nres = $info[1];
    }
}

print "Processing the map file...\n";
print "There are $nres HB indices.\n";
print "There are $nframes frames.\n";

# initialize hashes for later output writing
# counter $a holds the HB index from hbond.ndx
my %hbonds;
for (my $a=0; $a<$nres; $a++) {
    $hbonds{$a+1} = 0;
}

# donor/acceptor hashes for bookkeeping purposes
my %donors;
for (my $b=1; $b<=$nres; $b++) {
    $donors{$b} = 0;
}

my %acceptors;
for (my $c=1; $c<=$nres; $c++) {
    $acceptors{$c} = 0;
}

# clean up the output - up to 18 lines of comments, etc.
splice(@map, 0, 18);

# remove any "x-axis" or "y-axis" lines
for (my $n=0; $n<scalar(@map); $n++) {
    if (($map[$n] =~ /x-axis/) || ($map[$n] =~ /y-axis/)) {
            shift(@map);
            $n--;
    }
}

# There should now be $nres lines left in the file
# The HB map for the last index is written first (top-down in .xpm file)
#   * Element 0 is index $nres, element 1 is $nres-1, etc.

for (my $i=$nres; $i>=1; $i--) {
    # There will be $nframes+2 elements in @line (extra two are " at beginning
    # and end of the line)
    # Establish a conversion factor and split the input lines  
    my $j = $nres - $i;
    my @line = split('', $map[$j]);

    # for each index, write to hash
    for (my $k=1; $k<=($nframes+1); $k++) {
        if ($line[$k] =~ /o/) {
            $hbonds{$i}++;
        }
    }
}

print "Processing the index file...\n";

# Open up the index file and work with it
for (my $n=0; $n<$nres; $n++) {
    my @line = split(" ", $index[$n]);
    $donors{$n+1} = $line[0];
    $acceptors{$n+1} = $line[2];
}


# some arrays for donor and acceptor atom names
my @donor_names;
my @donor_resn;
my @acceptor_names;
my @acceptor_resn;

# Open up the structure file and work with it
print "Processing coordinate file...\n";
foreach $_ (@coord) {
    my @line = split(" ", $_);
    my $natom = $line[1];
    my $name = $line[2];
    my $resn = $line[3];
    my $resnum = $line[4];

    if ($line[0] =~ /ATOM/) {
        for (my $z=1; $z<=$nres; $z++) {
            if ($donors{$z} == $natom) {
                $donor_names[$z] = $name;
                $donor_resn[$z] = join('', $resn, $resnum);
            } elsif ($acceptors{$z} == $natom) {
                $acceptor_names[$z] = $name;
                $acceptor_resn[$z] = join('', $resn, $resnum);
            }
        }
    }
}

# open a single output file for writing
open(OUT, ">>summary_HBmap.dat") || die "Cannot open output file!\n";
printf(OUT "%10s\t%10s\t%10s\t%10s\%10s\n", "#    Donor", " ", "Acceptor", " ", "   % Exist.");

for (my $o=1; $o<=$nres; $o++) {
    printf(OUT "%10s\t%10s\t%10s\t%10s\t%10.3f\n", $donor_resn[$o], $donor_names[$o], $acceptor_resn[$o], $acceptor_names[$o], (($hbonds{$o}/$nframes)*100));
}

close(OUT);

exit;


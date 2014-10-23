package Algorithm::BinPack;

our $VERSION = 0.3;

=head1 NAME

Algorithm::BinPack - efficiently pack items into bins

=head1 SYNOPSIS

C<Algorithm::BinPack> efficiently packs items into bins. The bins are 
given a maximum size, and the items are packed in with as little empty 
space as possible. An example use would be packing files onto CDs, and 
you want to use as few CDs as possible.

    my $bp = Algorithm::BinPack->new(binsize => 4);

    $bp->add_item(label => "one",   size => 1);
    $bp->add_item(label => "two",   size => 2);
    $bp->add_item(label => "three", size => 3);
    $bp->add_item(label => "four",  size => 4);

    for ($bp->pack_bins) {
        print "Bin size: ", $_->{size},  "\n";
        print "  Item: ",   $_->{label}, "\n" for @{ $_->{items} };
    }

=cut

use strict;
use warnings;
use Carp;

=head1 METHODS

=over 8

=item new

Creates a new C<Algorithm::BinPack> object. The maximum bin size is 
specified as a named argument 'binsize', and is required. A fudge 
factor may be specified as a named argument 'fudge'. If a fudge factor 
is specified, any items' sizes will be rounded up to a number divisible 
by the fudge factor. This can help keep items with similar sizes in 
order by their labels.

    my $bp = Algorithm::BinPack->new(binsize => 4);
    my $bp = Algorithm::BinPack->new(binsize => 100, fudge => 10);

=cut

sub new {
    my $name = shift;
    my $self = { @_ };

    checkargs($self, qw(binsize)) or return;

    bless $self, $name;
}

=item add_item

Adds an item to be packed into a bin. Required named arguments are 
'label' and 'size', but any others can be specified, and will be saved.

    $bp->add_item(label => 'one', size => 1);
    $bp->add_item(label => 'two', size => 2, desc => 'The second numeral');
    $bp->add_item(qw(label three size 3));
    $bp->add_item(qw(label four size 4 random key));

=cut

sub add_item {
    my $self = shift;
    my $item = { @_ };

    checkargs($item, qw(label size)) or return;

    if ($self->{fudge}) {
        require POSIX;

        my $fudge = $self->{fudge};
        my $size  = $item->{size};

        $item->{fudgesize} = POSIX::ceil($size/$fudge)*$fudge;
    }

    push @{ $self->{items} }, $item;
}

=item pack_bins

Packs the items into bins. This method tries to leave as little empty 
space in each bin as possible. It returns a list of hashrefs with the 
key 'size' containing the total bin size, and 'items' containing an 
arrayref holding the items in the bin. Each item is in turn a hashref 
containing the keys 'label', 'size', and any others added to the item. 
If a fudge factor was used, each item will contain a key 'fudgesize', 
which is the size this item was fudged to.

    for my $bin ($bp->pack_bins) {
        print "Bin size: ", $bin->{size}, "\n";
        
        for my $item (@{ $bin->{items} }) {
            printf "  %-6s %-20s\n", $_, $item->{$_} for keys %{ $item };
            print  "  ---\n";
        }
    }

=cut

sub pack_bins {
    my $self = shift;
    my $binsize = $self->{binsize};

    no warnings 'uninitialized';

    my @bins;

    for my $item (sort_items($self->{items})) {
        my ($size, $label) = @{$item}{qw(size label)};

        if ($size > $binsize) {
            carp "'$label' too big to fit in a bin\n";
            next;
        }

        my $i = 0;
        $i++ until $bins[$i]{size} + $size <= $binsize;

        push @{ $bins[$i]{items} }, $item;
        $bins[$i]{size} += $size;
    }

    return @bins;
}

sub checkargs {
    my ($href, @args) = @_;

    my $success = 1;

    for (@args) {
        unless (exists $href->{$_}) {
            carp "Missing argument '$_'";
            $success = 0;
        }
    }

    return $success;
}

sub sort_items {
    my $items = shift;

    sort {
             # use fudgesize if it's there, otherwise use actual
             my $asize = $a->{fudgesize} || $a->{size};
             my $bsize = $b->{fudgesize} || $b->{size};

                  $bsize <=> $asize
                         ||
             $a->{label} cmp $b->{label}

         } @{ $items };
}

1;

=head1 SEE ALSO

This module implements the bin packing algorithm described in 'The 
Algorithm Design Manual' by Steven S. Skiena.

This module is similar to L<Algorithm::Bucketizer>, but has a few key 
differences. The algorithms in Algorithm::Bucketizer are based on 
optimization by multiple iterations, so the module is set up 
differently. The algorithm used in Algorithm::BinPack is predictable, 
and does not require multiple iterations. I also figured it could use a 
name that's more well-known (searching for variations on "bin packing" 
finds more relevant results than variations on "bucketizer").

=head1 AUTHOR

Carey Tilden E<lt>revdiablo@wd39.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Carey Tilden

This code is dual licensed. You may choose from one of the following:
  - http://creativecommons.org/licenses/by/1.0/
  - http://d.revinc.org/pages/license

=cut

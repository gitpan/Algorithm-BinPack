#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 24;

BEGIN { use_ok('Algorithm::BinPack') };

my $bp = Algorithm::BinPack->new(binsize => 4);

isa_ok($bp, "Algorithm::BinPack");
is($bp->{binsize}, 4);

$bp->add_item(label => 'one',   size => 1);
$bp->add_item(label => 'two',   size => 2);
$bp->add_item(label => 'three', size => 3, misc => "This item is the best");
$bp->add_item(label => 'four',  size => 4, desc => "The fourth item");

my @bins = $bp->pack_bins;

# check pack order
is($bins[0]{items}[0]{label}, "four");
is($bins[1]{items}[0]{label}, "three");
is($bins[1]{items}[1]{label}, "one");
is($bins[2]{items}[0]{label}, "two");

# add an item manually
$bp->prefill_bin(bin => 2, size => 3, label => 'manual',
                 manual => 'Item was added manually');

@bins = $bp->pack_bins;

# check pack order
is($bins[0]{items}[0]{label}, "four");
is($bins[1]{items}[0]{label}, "three");
is($bins[1]{items}[1]{label}, "one");
is($bins[2]{items}[0]{label}, "manual");
is($bins[3]{items}[0]{label}, "two");

# check extra keys
is($bins[0]{items}[0]{desc},   "The fourth item");
is($bins[1]{items}[0]{misc},   "This item is the best");
is($bins[2]{items}[0]{manual}, "Item was added manually");

# check for missing params
$SIG{__WARN__} = sub { like( $_[0], qr/Missing argument/ ) };
$bp->add_item(label => 'five');
$bp->add_item(size  => 5);
$bp->prefill_bin(          label => "Manual", size => 4);
$bp->prefill_bin(bin => 0,                    size => 4);
$bp->prefill_bin(bin => 0, label => "Manual"           );

# check for too-big items
$SIG{__WARN__} = sub { like( $_[0], qr/too big/ ) };
$bp->prefill_bin(bin => 0, label => "Manual", size => 5);
$bp->prefill_bin(bin => 0, label => "Manual", size => 4); # fill the bin up
$bp->prefill_bin(bin => 0, label => "Manual", size => 1); # try to add an item to go past full
$bp->add_item(label => 'five', size  => 5);
$bp->pack_bins;

# check for non-numeric bin
$SIG{__WARN__} = sub { like( $_[0], qr/must be numeric/ ) };
$bp->prefill_bin(bin => 'a', label => "Manual", size => 4);

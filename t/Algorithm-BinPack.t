#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 12;

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

# check extra keys
is($bins[0]{items}[0]{desc}, "The fourth item");
is($bins[1]{items}[0]{misc}, "This item is the best");

# check for missing params
$SIG{__WARN__} = sub { like( $_[0], qr/Missing argument/ ) };
$bp->add_item(label => 'five');
$bp->add_item(size  => 5);

# check for too-big items
$SIG{__WARN__} = sub { like( $_[0], qr/too big/ ) };
$bp->pack_bins;

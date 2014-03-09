#!/usr/bin/perl

while (<>) {
    for my $match (m/\$\((\w+)/g) {
        print "$match\n";
    }
}

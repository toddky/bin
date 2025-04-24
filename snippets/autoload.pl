#!/usr/bin/env perl
hello("World");
sub AUTOLOAD {
    my $name = "hel" . "lo";
    if ($AUTOLOAD eq "main::$name") {
        print "Hello " . shift . "\n";
    }
}


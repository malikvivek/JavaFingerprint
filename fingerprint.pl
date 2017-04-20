#!/usr/bin/perl

# Fingerprint
# Version 2 Alpha
# IA Capstone
# Christopher Noyes
#
# Compares two java files
# Does basic comparison of java class structure to determine how close they are to each other
# usage: perl fingerprint.pl file1.java file2.java

use strict;
use warnings;
use Data::Dumper;

# given an array of information, determine where the lies in order to return a sub
# body of code back
sub find_nest {
    my @data = @_;
    my $start = 0;
    my $end = @data;
    my $depth = 0;
    my $i = $start;
    while ($i < $end) {
        if ($data[$i] =~ /\{/) {
            $depth++;
        }
        elsif ($data[$i] =~ /\}/) {
            $depth--;
            if ($depth == 0) {
                $end = $i;
                $i = $end + 1;
                last;
            }
        }
    $i++;
    }
    return @data[$start + 1 .. $end - 1];
}

# parse a class definition and return a hash of it
# takes in an array of code
sub parse_class {
    my @data = @_;
    my @body;
    my %hash = ();
    my $i = 0;
    $hash{"extends"} = "";
    
    # Loop until the end of the data
    while ($i < @data) {
        # Check for extends
        if ($data[$i] =~ /extends (\w+)/) {
            $hash{"extends"} = $1;
        }
        # Look for the body of the class
        elsif ($data[$i] =~ /\{/) {
            @body = find_nest(@data[$i .. $#data]);
            last;
        }
        $i++;
    }
    # process the body
    # store the line count of the body and the length
    $hash{"lines"} = @body;
    foreach (@body) { $hash{"size"} += length($_); }
        
    # set up the hashes
    $hash{"variables"} = {};
    $hash{"methods"} = {};
    $i = 0;
    # Loop through the body and parse it
    while ($i < @body) {
        # Store the variable definitions
        if ($body[$i] =~ /\s?((protected|public|private)\s+(static)?\s?(\w+)\s+(\w+))\;/)  {
            $hash{"variables"}->{"$4 $5"}->{"type"} = $4;
            $hash{"variables"}->{"$4 $5"}->{"name"} = $5;
            $hash{"variables"}->{"$4 $5"}->{"pre"} = $2;
            $hash{"variables"}->{"$4 $5"}->{"static"} = (($3 eq "static") ? 1 : 0);
            $hash{"variables"}->{"$4 $5"}->{"raw"} = $body[$i];
        }
        # Store the function definitions
        elsif ($body[$i] =~ /\s?(protected|public|private)\s+(static)?\s?(\w+)\s+(\w+)\((.*)\)/)  {
            # Find and store the body of the function
            my @func_body = find_nest(@body[$i + 1 .. $#body]);
            # increment i so the same code isn't read again
            $i = $i + @func_body;
            # store information about the function
            my $name = "$3 $4";
            my $static = ((defined $2) ? $2 : "");
            my @strings = ();
            $hash{"methods"}->{$name}->{"type"} = $3;
            $hash{"methods"}->{$name}->{"name"} = $4;
            $hash{"methods"}->{$name}->{"pre"} = $1;
            $hash{"methods"}->{$name}->{"static"} = (($static eq "static") ? 1 : 0);
            $hash{"methods"}->{$name}->{"lines"} = @func_body;
            foreach (@func_body) {
                $hash{"methods"}->{$name}->{"size"} += length($_);
                while (/\"(.*?)\"/g) {
                    push @strings, $1;
                }
            }
            $hash{"methods"}->{$name}->{"strings"} = \@strings;
            
            # Process the arguments
            my $args = $5;
            if ($args ne "") {
                if ($args =~ /, /) {
                    foreach my $arg (split /, /, $args) {
                        my ($atype, $aname) = split /\s+/, $arg;
                        $hash{"methods"}->{$name}->{"arguments"}->{$aname} = $atype;
                    }
                } else {
                    my ($atype, $aname) = split /\s+/, $args;
                    $hash{"methods"}->{$name}->{"arguments"}->{$aname} = $atype;
                }
            } else {
                $hash{"methods"}->{$name}->{"arguments"} = {};
            }
            
            # Store the body of the function as well for comparison if needed
            $hash{"methods"}->{$name}->{"body"} = \@func_body;
        }
        $i++;
    }
    
    return \%hash;
}

# parse a data array representing a java file
sub parse {
    my @data = @_;
    my @imports = ();
    my @extra = ();
    my %hash = ();
    my $i = 0;
    $hash{"classes"} = ();
    $hash{"package"} = "";
    
    # Loop through the data
    while ($i < @data) {
        
        # if its a class, parse the class
        if ($data[$i] =~ /((protected|public|private|abstract) class (\w+))/) {
            # grab the inside code
            my @inside = find_nest(@data[$i .. $#data]);
            # parse it
            $hash{"classes"}->{$3} = parse_class(@inside);
            $i += $#inside + 2;
        }
        # store the package information
        elsif ($data[$i] =~ /package (.*)\;/) {
            $hash{"package"} = $1;
        }
        # If the line is an import directive, store it
        elsif ($data[$i] =~ /import (.*)\;/) {
            push @imports, $1;
        }
        # push anything that cannot be accounted for
        else {
            push @extra, $data[$i];
        }
        $i++;
    }
    
    $hash{"imports"} = \@imports;
    $hash{"extra"} = \@extra;
    return \%hash;
}
    
# Process the arguments
my %hash = (); # hash holding parse data
my ($file1, $file2) = ($ARGV[0], $ARGV[1]); # two arguments representing two files
foreach (($file1, $file2)) {
    my $filename = $_;
    open my $handle, '<', $filename;
    chomp(my @lines = <$handle>);
    close $handle;
    print "[Import] Parsing $filename...\n";
    $hash{$filename} = parse(@lines);
}
    
# Comparison
# Testing potentially modified package against original
my $total = 0;
my $fails = 0;
print "Testing potentially modified package $file2 against original $file1...\n";

# Test the packages
print "Testing package... ";
$total++;
if ($hash{$file2}->{"package"} ne $hash{$file1}->{"package"}) {
    print "NOT OK\n\t[ ADDED ] ".$hash{$file2}->{"package"}."\n";
    print "\t[REMOVED] ".$hash{$file1}->{"package"}."\n";
    $fails++;
} else {
    print "OK\n";
}

# Test the imports
print "Testing imports... ";
my $same = 1;
foreach my $import (sort @{ $hash{$file2}->{"imports"} }) {
    $total++;
    if (! grep /^\Q$import\E$/, @{ $hash{$file1}->{"imports"} } ) {
        print "NOT OK\n" unless ($same == 0);
        print "\t[ ADDED ] $import\n";
        $same = 0;
        $fails++;
    }
}
foreach my $import (sort @{ $hash{$file1}->{"imports"} }) {
    $total++;
    if (! grep /^\Q$import\E$/, @{ $hash{$file2}->{"imports"} } ) {
        print "NOT OK\n" unless ($same == 0);
        print "\t[REMOVED] $import\n";
        $same = 0;
        $fails++;
    }
}
print "OK\n" unless ($same == 0);

# Test the classes
print "Testing classes... ";
my $f2_classes = keys $hash{$file2}->{"classes"};
my $f1_classes = keys $hash{$file1}->{"classes"};
$same = 1;

foreach my $class (sort keys $hash{$file2}->{"classes"}) {
    $total++;
    if (! exists $hash{$file1}->{"classes"}->{$class}) {
        print "NOT OK\n" unless ($same == 0);
        print "$file2 - $class - WARNING - Class mismatch\n";
        $same = 0;
        $fails++;
    }
}

foreach my $class (sort keys $hash{$file1}->{"classes"}) {
    $total++;
    if (! exists $hash{$file2}->{"classes"}->{$class}) {
        print "NOT OK\n" unless ($same == 0);
        print "$file1 - $class - WARNING - Class mismatch\n";
        $same = 0;
        $fails++;
    }
}
print "OK\n" unless ($same == 0);
    
# If the classes don't match, attempt to match them
if ($same == 0) {
    # If the length of both class arrays is the same, compare
    if ($f1_classes == $f2_classes) {
        print "Obfuscation may be in use, source files have same number of classes\n";
        print "Attempting to map classes for comparison...\n";
        my $mapped = 0;
        
        # Traverse the class and attempt to match up criteria
        foreach my $class2 (sort keys $hash{$file2}->{"classes"}) {
            my $match = 0;
            foreach my $class1 (sort keys $hash{$file1}->{"classes"}) {
                my $f2_class = \%{ $hash{$file2}->{"classes"}->{$class2} };
                my $f1_class = \%{ $hash{$file1}->{"classes"}->{$class1} };
                
                $match++ if (keys %{$f2_class->{"methods"}} == keys %{$f1_class->{"methods"}});
                $match++ if (keys %{$f2_class->{"variables"}} == keys %{$f1_class->{"variables"}});
                
                foreach ("size", "lines", "extends") {
                    if ($f2_class->{$_} eq $f1_class->{$_}) {
                        $match++;
                    }
                }
                
                # If enough matches were found, identify the match
                if ($match > 4) {
                    print "[Fingerprinting] class ($class2) of $file2 is likely ($class1) of $file1\n";
                    # For the purpose of this script, remap the hash for comparison
                    $hash{$file2}->{"classes"}->{$class1} = delete $hash{$file2}->{"classes"}->{$class2};
                    $mapped++;
                    last;
                }
            }
        }
        
        # If the number of classes remapped matches the total number of classes continue
        if ($mapped == keys $hash{$file2}->{"classes"}) {
            print "Mapping succeeded, continuing with the comparison process...\n";
            $same = 1;
        } else {
            print "Mapping did not succeed, exiting...\n";
            exit;
        }
    } else {
        # Bail if the number of classes between the two files differs
        print "The number of classes differs between files...\n";
        print "Out of the scope of this script... exiting\n";
        exit;
    }
}
    
# Compare the classes
# If there wasn't a naming mismatch, lets do this comparison first
my $f2_class = \%{ $hash{$file2}->{"classes"} };
my $f1_class = \%{ $hash{$file1}->{"classes"} };
my $f1_v;
my $f2_v;
    
if ($same == 1) {
    foreach my $class (sort keys %$f2_class) {
        print "Testing class $class:\n";
        
        $f2_class = \%{ $hash{$file2}->{"classes"}->{$class} };
        $f1_class = \%{ $hash{$file1}->{"classes"}->{$class} };
        
        foreach ("extends", "size", "lines") {
            $total++;
            print "\tTesting $_...";
            if ($f2_class->{$_} ne $f1_class->{$_}) {
                print "NOT OK\n";
                $fails++;
            } else {
                print "OK\n";
            }
        }
        
        print "\tTesting variables...\n";
        
        my $f2_keys = $f2_class->{"variables"};
        foreach my $variable (sort keys %$f2_keys) {
            $f2_v = \%{ $f2_class->{"variables"}->{$variable} };
            $total++;
            print "\t\t$variable...";
            if (exists ($f1_class->{"variables"}->{$variable})) {
                $f1_v = \%{ $f1_class->{"variables"}->{$variable} };
                print "OK\n";
                foreach (sort keys %{ $f2_v }) {
                    $total++;
                    print "\t\t\t$_...";
                    if ($f2_v->{$_} ne $f1_v->{$_}) {
                        print "NOT OK\n";
                        $fails++;
                    } else {
                        print "OK\n";
                    }
                }
            } else {
                print "NOT OK\n";
                $fails++;
            }
        }
        
        print "\tTesting methods...\n";
        
        my @f2_uk = ();
        my @f1_uk = ();
        my $f2_methods = $f2_class->{"methods"};
        foreach my $method (sort keys %$f2_methods) {
            $f2_v = \%{ $f2_class->{"methods"}->{$method} };
            $total++;
            print "\t\t$method... ";
            if (! (exists ($f1_class->{"methods"}->{$method}->{"name"})) ) {
                print " [ADDED]\n";
                push @f2_uk, $f2_class->{"methods"}->{$method};
                next;
            } else {
                print " OK\n";
            }
            
            $f1_v = \%{ $f1_class->{"methods"}->{$method} };
            foreach ("name", "type", "size", "lines", "pre", "static") {
                $total++;
                print "\t\t\t$_...";
                
                if ($f2_v->{$_} ne $f1_v->{$_}) {
                    print "NOT OK\n";
                    $fails++;
                } else {
                    print "OK\n";
                }
            }
            
            # Arguments
            my $args2 = \%{ $f2_class->{"methods"}->{$method}->{"arguments"} };
            my $args1 = \%{ $f1_class->{"methods"}->{$method}->{"arguments"} };
            my $s = 1;
            print "\t\t\tArguments... ";
            foreach my $arg (keys %{ $args2 }) {
                $total++;
                if (exists $args1->{$arg}) {
                    if ($args2->{$arg} ne $args1->{$arg}) {
                        print "NOT OK\n" unless ($s == 0);
                        print "\t\t\t\t[MODIFIED] $arg\n";
                        $s = 0;
                        $fails++;
                    }
                } else {
                    print "NOT OK\n" unless ($s == 0);
                    print "\t\t\t\t[ ADDED ] $arg\n";
                    $s = 0;
                    $fails++;
                }
            }
            
            foreach my $arg (keys %{ $args1 }) {
                $total++;
                if (! exists $args2->{$arg}) {
                    print "NOT OK\n" unless ($s == 0);
                    print "\t\t\t\t[ REMOVED ] $arg\n";
                    $s = 0;
                    $fails++;
                }
            }
            print "OK\n" unless ($s == 0);
            
            # Strings
            print "\t\t\tStrings... ";
            $s = 1;
            foreach my $string (@{ $f2_v->{"strings"} }) {
                $total++;
                if (! grep /^\Q$string\E$/, @{ $f1_v->{"strings"} } ) {
                    print "NOT OK\n" unless ($s == 0);
                    print "\t\t\t\t$string - [ADDED]\n";
                    $s = 0;
                    $fails++;
                }
            }
            foreach my $string (@{ $f1_v->{"strings"} }) {
                $total++;
                if (! grep /^\Q$string\E$/, @{ $f2_v->{"strings"} } ) {
                    print "NOT OK\n" unless ($s == 0);
                    print "\t\t\t\t$string - [REMOVED]\n";
                    $s = 0;
                    $fails++;
                }
            }
            
            print "OK\n" unless ($s == 0);
            
            # Body
            print "\t\t\tBody... ";
            $s = 1;
            foreach my $line (@{ $f2_v->{"body"} }) {
                $total++;
                if (! grep /^\Q$line\E$/, @{ $f1_v->{"body"} }) {
                    print "NOT OK\n" unless ($s == 0);
                    print "\t\t\t\t$line - [ADDED]\n";
                    $s = 0;
                    $fails++;
                }
            }
            foreach my $line (@{ $f1_v->{"body"} }) {
                $total++;
                if (! grep /^\Q$line\E$/, @{ $f2_v->{"body"} }) {
                    print "NOT OK\n" unless ($s == 0);
                    printf "\t\t\t\t$line - [REMOVED]\n";
                    $s = 0;
                    $fails++;
                }
            }
            
            print "OK\n" unless ($s == 0);
        }
        
        my $f1_methods = $f1_class->{"methods"};
        foreach my $method (sort keys %$f1_methods) {
            $total++;
            if (! (exists $f2_class->{"methods"}->{$method}->{"name"}) ) {
                print "\t\t$method... [REMOVED]\n";
                push @f1_uk, $f1_class->{"methods"}->{$method};
                $fails++;
            }
        }
        
        foreach my $f2uk (@f2_uk) {
            my $match = 0;
            my $f = -1;
            my $i = 0;
            foreach my $f1uk (@f1_uk) {
                $match = 0;
                foreach ("size", "lines", "pre", "static") {
                    if ($f2uk->{$_} eq $f1uk->{$_}) {
                        $match++;
                    }
                }
                $match++ if (keys %{$f2uk->{"arguments"}} == keys %{$f2uk->{"arguments"}});
                $match++ if (@{$f2uk->{"strings"}} == @{$f2uk->{"strings"}});
                if ($match > 5) {
                    print "\n\t\t[Fingerprinting] (".$f2uk->{"type"}." ".$f2uk->{"name"}.") of $file2 is likely (";
                    print $f1uk->{"type"}." ".$f1uk->{"name"}.") of $file1\n";
                    $f = $i;
                    last;
                }
                $i++;
            }
            $total++;
            if ($f == -1) {
                print "\n\t\t[Fingerprinting] Unmatched method (".$f2uk->{"type"}." ".$f2uk->{"name"}.") of $file2\n";
            } else {
                splice( @f1_uk, $f, 1 );
            }
        }
        
        foreach my $f1uk (@f1_uk) {
            print "\t\t[Fingerprinting] Unmatched method (".$f1uk->{"type"}." ".$f1uk->{"name"}.") of $file1\n";
        }
        
    }
}

printf("\n$fails failures in $total tests... %.1f percent confidence that files match.\n", (($total - $fails)/$total) * 100);

# Uncomment this line to show structures
#print Dumper %hash;

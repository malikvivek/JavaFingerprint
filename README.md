# JavaFingerprint
Proof of Concept Perl Code for Finger Printing Java - Capstone 2017

# Version 2 Alpha
# IA Capstone
# Christopher Noyes
#
# Compares two java files
# Does basic comparison of java class structure to determine how close they are to each other
# usage: perl fingerprint.pl file1.java file2.java
#
# This script comes with no warranty or guarantee.  While I wouldn't expect perl
# parsing and comparison to cause issues with your machine, I should not be held responsible
# if it does.
#
# This was written as a quick Proof of Concept to show possible ways to map and compare Java source files
# that have been normalized in a specific form.  In this case, I am expecting a java file in the output
# format that JD-GUI presents.  Using JD-GUI to generate both the source and comparison file also guarantees
# that the obfuscated names come out the same way.

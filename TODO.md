# Additional Things to Do

By no means is this script exhaustive.  As this was written in a limited amount of time I had to take some shortcuts.

1.  This will not cover all Java files, more work needs to be done to further parse class files using rarer Java Directives

2.  The comparison is limited in some places.  Hashing can be used to further compare classes.

3.  Once identifying a mapped method, it isn't re-checked.  This was due to time.  In order to properly scope those,
the method checking code should be moved to a function so it can be re-called after mapping methods.

4.  More logic needs to be done in determining a remapped class file completely.  While I have basic code determing if Class
A was obfuscated to Class B, I don't dive too deeply into the remapped class's methods to find all occurances of the remap.

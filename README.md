GEMiCal
=======

Simple GEM app to display a calendar from iCal (ics) files.
Originally written in Pure-Pascal it is now being migrated to Free Pascal.

It is not very functional at the moment, it is very much an MVP.

Current functions:

1. displays a month with simple month or year navigation.
2. loads all the .ics files in a folder.
3. shows any event that either starts in, ends in or straddles the
   current month.
4. the ICS folder can be changed.
5. gemical.cnf holds the lat-long and UTC offset so that the sunrise
   and sunset times can be calculated.

Contributions welcome.
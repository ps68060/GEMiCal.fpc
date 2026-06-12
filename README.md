GEMiCal
=======

Simple GEM app to display a calendar from iCal (ics) files.
Originally written in Pure-Pascal it is now being migrated to Free Pascal.

It is not very functional at the moment, it is very much an MVP.

**Contributions welcome**

Current functions:
1. displays a month with simple month or year navigation.
2. loads all the .ics files in a folder.
3. shows any event that either starts in, ends in or straddles the
   current month.
4. the ICS folder can be changed.
5. gemical.cnf holds the lat-long and UTC offset so that the sunrise
   and sunset times can be calculated.
6. added some rudimentary timezone calculations, mostly for Europe.

Future features:
* Improved Timezone handling.
* Repeating events.
* Event editing, adding and deleting.

Changes 2026-06
---------------
* Few functional changes, but a lot of code clean-up and refactoring to use FPC units.. The code is now much more modular and easier to read. 

* Timezone is now displayed with the time of day.
* Day of the week is now displayed with the date.
* Sunrise/sunset times are shown for the 1st of the currently displayed month and year.
* The grid rows are now the same number of weeks as the month being displayed.
* Control Up/Down keys now navigate the month.
July 24, 2001



AMERICAN SAMOA GRIDS FOR NADCON


First, in using the Samoa grids, it must be taken into account that NADCON is not set up to

read South latitudes.  Any *80* records used in batch mode must have the "S" found after the

latitude changed to "N".  This will make no difference to the mathematical computations.  The

shift values applied will be the same.


Second, the Samoan data was never on the NAD 27 datum, but was on its own datum, the "American

Samoa 1962 Datum".  These grids are only to be used in transformations involving that datum.


Third, unlike the HPGN grids created for various states in the continental U.S. and Hawaii, which

represent the shift between NAD 83 and the HARN readjustment of the state, these grids are based

on the shift from the old Samoan Datum directly to the HARN readjustment.  No grids were ever

created for the Samoa Datum to NAD 83 shift.


Fourth, the distance between islands required that the grids be split into east and west:

eshpgn and wshpgn.  Tutuila and Aunu'u Islands are included in the western grids.  Ofu, Olesega,

and Ta'u Islands are included in the eastern grids.


And finally, DO NOT USE THE MULTIPLE GRID SELECTION OPTION WITH THESE GRIDS.  Due to the way NADCON 
selects the grids to use and how the grids had to be created, an error of as much as 15 meters can be
introduced.


If you have any questions please contact:

Mr. David Doyle or Ms. Cindy Craig
N/GS4 N/NGS21
Telephone: (301) 713-3178 Telephone: (301) 713-3194
email: Dave.Doyle@noaa.govemail: Cindy.Craig@noaa.gov


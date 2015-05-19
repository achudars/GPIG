


                             NADCON
                          Version 2.10
                         August 5, 2004


Distribution Copy


PROGRAM DESCRIPTION

NADCON transforms latitude and longitude coordinate values between the North American Datum of
1927 (NAD 27) and the North American Datum of 1983 (NAD 83).  NADCON is the Federal
standard for NAD 27 to NAD 83 datum transformations (as was articulated in the Federal Register,
Volume 55, Number 155 dated August 10, 1990).  NADCON also transforms data originally
expressed in old island datums that exist in Alaska, Hawaii, Puerto Rico, American Samoa, and Virgin
Islands into data referenced to NAD 83.  However all datums, including these, are referred to within
the program as NAD 27.  NADCON automatically chooses the proper transformation; the user does
not need to know the specific name of the old island datum.

NADCON conversions between datums are approximate values based on models of real data.
NADCON should be used only when data does not exist in the data base (NGSIDB) for one of the
datums required.  The accuracy of the transformations should be viewed with some caution.  At the 67
percent confidence level, this method introduces approximately 0.15 meter uncertainty within the
conterminous United States, 0.50 meter uncertainty within Alaska, 0.20 meter uncertainty within
Hawaii, and 0.05 meter uncertainty within Puerto Rico and the Virgin Islands.  In areas of sparse
geodetic data coverage NADCON may yield less accurate results, but seldom in excess of 1.0 meter. 
Transformations between NAD 83 and States/Regions with High Accuracy Reference Networks
(HARNS) introduce approximately 0.05 meter uncertainty.  Transformations between old datums
(NAD 27, Old Hawaiian, Puerto Rico etc.) and HARN could combine uncertainties (e.g. NAD 27 to
HARN equals 0.15 meter + 0.05 meter = 0.20 meter).  In near offshore regions, results will be less
accurate but seldom in excess of 5.0 meters.  Farther offshore NAD 27 was undefined.  Therefore, the
NADCON computed transformations are extrapolations and no accuracy can be stated.

NADCON cannot improve the accuracy of data.  Stations that are originally third-order will not
become first-order stations.  NADCON is merely a tool for transforming coordinate values between
datums.  Remember, this program is based exclusively upon data within the official National Spatial
Reference System (NSRS).  Data originating from stations not part of this official reference may not be
compatible.Be sure that the data to be transformed is actually referenced to the NSRS.  While
NADCON will print out latitudes and longitudes to 0.00001 seconds of arc, the results in the fourth or
fifth place may change depending on the platform used.However, all results will be limited to, and
within, the accuracy stated above.This is true even though additional precision may be implied by the
results.

This additional precision is included for internal computation.  Users should not infer that the accuracy is
better than it really is.  The following areas are available for transformations between NAD 27 and
NAD 83:  (Each area consists of a pair of files, one ending in .LAS (Latitude Seconds), the other .LOS
(Longitude Seconds)).

Area				Name							Description File
==================================================================================

CONUS				Conterminous U S (lower 48 states)		CONUS

Alaska			Alaska, incl. Aleutian Islands		ALASKA

St. Lawrence Is., AK	Old Island Datum within Alaska		STLRNC

St. George Is., AK	Old Island Datum within Alaska		STGEORGE

St. Paul Is., AK		Old Island Datum within Alaska		STPAUL

Puerto Rico and V.I.	Puerto Rico and the Virgin Islands		PRVI

Hawaii			Hawaiian Islands					HAWAII


St. George I. and St. Paul I. are part of a region known as the Pribilof Islands.  There were two
separate datums, one for each island, before NAD 83.  The old island datums differ significantly from
NAD 27.  Data input into NADCON must be consistent with the identified transformation data sets. 
The transformation of misidentified data can result in very large errors (as much as hundreds of meters).

The CONUS grids cover an area from 20 to 50 degrees north latitude and from 63 to 131 degrees
west longitude.  The Alaskan grids cover an area from 46 to 77 degrees north latitude and from 128 to
194 degrees west longitude.  The CONUS and Alaskan grids overlap between 46 to 50 degrees north
latitude and 128 to 131 degrees west longitude.  In this area, the CONUS and Alaskan grids agree
within 2 centimeters.  For those cases requiring precision greater than this, the CONUS grids are to be
considered correct.  Remember, NADCON should be used only within the U.S. territorial limits.

HIGH ACCURACY REFERENCE NETWORK PROJECTS:

In 1992, NADCON capability was expanded to include transformations of latitude and longitude
coordinate values between NAD 83 (1986) (includes post NAD 83 adjustments) and state
readjustments to HARN projects. Latitude and longitude conversions from NAD 83 (1986) to HARN
and from HARN to NAD 83 (1986) are computed in the same manner as those conversions between
NAD 27 and NAD 83 (1986), but access HPGN (HARN) prepared files instead of the original
Conus, Alaska, etc. grid files.  Prior to 1992 HARNs were referred to as High Precision GPS
Networks (HPGN) and that acronym is used in NADCON.  Pairs of grid files are available for the
following states:

Area/State			File Name			Name For NADCON Execution
=========================================================================

Alabama			ALHPGN			AL

Arkansas			ARHPGN			AR

Arizona			AZHPGN			AZ

California			*CNHPGN			CN
 (Above 37 degrees latitude)

California			*CSHPGN			CS
 (Below 37 degrees latitude)

Colorado			COHPGN			CO

Florida			FLHPGN			FL

Georgia			GAHPGN			GA

Guam				GUHPGN			GU

Hawaii			HIHPGN			HI

Idaho-Montana		EMHPGN			EM
 (East of 113 degrees longitude)

Idaho-Montana		WMHPGN			WM
 (West of 113 degrees longitude)

Iowa				IAHPGN			IA

Illinois			ILHPGN			IL

Indiana			INHPGN			IN

Kansas			KSHPGN			KS

Kentucky			KYHPGN			KY

Louisiana			LAHPGN			LA

Maryland - Delaware	MDHPGN			MD

Maine				MEHPGN			ME

Michigan			**MIHPGN			MI

Minnesota			MNHPGN			MN

Mississippi			MSHPGN			MS

Missouri			MOHPGN			MO

Nebraska			NBHPGN			NB

Nevada			NVHPGN			NV

New England			NEHPGN			NE
 (CT,MA,NH,RI,VT)

New Jersey			NJHPGN			NJ

New Mexico			NMHPGN			NM

New York			NYHPGN			NY

North Carolina		NCHPGN			NC

North Dakota		NDHPGN			ND

Ohio				OHHPGN			OH

Oklahoma			OKHPGN			OK

Pennsylvania		PAHPGN			PA

Puerto Rico-Virgin Is	PVHPGN			PV

Samoa				***ESHPGN			ES
 (Eastern Islands)

Samoa				***WSHPGN			WS
 (Western Islands)

South Carolina		SCHPGN			SC

South Dakota		SDHPGN			SD

Tennessee			TNHPGN			TN

Texas				ETHPGN			ET
 (East of 100 degrees longitude)

Texas				WTHPGN			WT
 (West of 100 degrees longitude)

Utah				UTHPGN			UT

Virginia			VAHPGN			VA

Washington-Oregon		WOHPGN			WO

West Virginia		WVHPGN			WV

Wisconsin			WIHPGN			WI

Wyoming			WYHPGN			WY


* Prior to the development of the grids for Southern California (CSHPGN) in January 1998, these files
were labeled CAHPGN.

** During the analysis of the transformation grids for Michigan, a serious inconsistency was found in the
positional shifts for the control on Isle Royale when compared with the mainland portion of the
state.Investigation revealed that this was due to the fact that no HARN stations had been observed on
the island, and that the existing horizontal control had poor geometric ties to the networks in Michigan
and Minnesota.  The island is classified as a wilderness area by the National Park Service and will see
little if any development.  Therefore, the data for this area was omitted in the development of the
transformation grids.

*** The positional data for American Samoa is distributed over two clusters of islands separated by
many miles of ocean.  The lack of control on which to base grids which this separation represents
creates distortions unless the grids are split into two separate grid pairs.  WSHPGN covers the Islands
of Tutuila and Aunu'u.  ESHPGN covers Ofu, Olosega, and Ta'u Islands.

Guam and American Samoa never went through the intermediate step of island datum to NAD83. 
Those islands were adjusted directly from their old island datums (Guam 1963 and American Samoa
1962) to HPGN.  Consequently, positions computed on the island datums are considered to be
NAD83 for the input/output purposes.

INSTALLATION

The disks in the NADCON package contain the NADCON program executable file, pairs of grid files
ending in .LAS and .LOS, a README.210 file, other readme files for advanced use, four sample data
sets, a utility program, NADGRD, and, in a separate directory, program source codes.  The
NADCON executable on this disk is for an IBM compatible microcomputer with either a hard disk or
a 1.2 Mbyte floppy.  A floating point coprocessor (e.g. a 8087 or 80287) is not necessary.  You do
not need to store the data files for areas other than the ones of interest.For example, if you are only
concerned with data from Alaska, you do not need to obtain the data for Hawaii and the lower 48
States.  The data files for each region are labeled with ".LAS" and ".LOS" extensions.  Be sure to
include both files in the directory that contains the "NADCON.EXE" file.  Before using the program,
copy NDCON210.EXE file and any pairs of .LAS and .LOS files you will use.

Remember, all the files MUST be in the same directory as the .EXE file for the program to work
properly.

DATA INPUT/OUTPUT

As of 10/15/2001, NADCON has been modified to allow either east or west longitudes.  However,
NADCON still will only allow north latitudes.  In areas of south latitude where grids exist, the latitude
must be entered as positive.  This will not affect the shifts - they will still be correct.

Data may be entered either interactively or via a file.  The interactive use is preferable when only a few
points are desired.  Three file formats are available.  These are the standard NGS Horizontal Blue
Book and two very general (or free format) file structures.  In the two free format input file formats, the
exact column position of the latitude and longitude is not important as long as they fall within the
appropriate range (columns 41-80 for free format type 1 and columns 1-40 for free format type 2). 
The latitude and longitude in the two general file formats may be expressed as integer degrees, integer
minutes, and decimal seconds; as integer degrees and decimal minutes; or as decimal degrees.  The free
format files also differ in the structure of their output file.  Further information is available in the "help"
feature within the program.

Sample files, TYPE1.DAT and TYPE2.DAT, are provided to give you a start with the free format file
structures and with batch processing.  Please note that in these input files, various data formats have
been used for examples.  Most users will probably use a consistent data format within an input file.

Also included in the package is a sample file of NAD 27 position data for 221 stations, and the
corresponding file of NAD 83 positions output by NADCON-computed transformations.  Stations
were selected from each of the seven grid areas.  The input file, NAD 27.DAT, and the output file,
NADCON.OUT, are both in the format for *80* records described in "Input Formats and
Specifications of the National Geodetic Survey Data Base, Volume I. Horizontal Control Data".  The
station positions in these files are useful for tests of mathematical consistency when transporting
NADCON to other computers.

INPUT/OUTPUT WITH UTM OR STATE PLANE COORDINATES

Output printed to the screen and in the output file contain the latitude and longitude shifts in meters. 
This shift is a ground shift.It cannot be applied directly to projected coordinates such as the Universal
Transverse Mercator (UTM) coordinates or State Plane coordinates.  To transform UTM X-Y
coordinates from NAD 27 to NAD 83, for example, is a three step procedure.  First, the NAD 27
UTM coordinates must be converted to NAD 27 geographic (latitude and longitude) coordinates. 
Next, the NAD 27 geographic coordinates are transformed with NADCON to NAD 83 geographic
coordinates.  Last, the transformed geographic coordinates are converted to NAD 83 UTM
coordinates.  State Plane coordinate transformations are done similarly.  If the state/area has a HARN,
then a fourth step must be added to transform the NAD 83 geographic coordinates to "HPGN" prior to
their conversion into either UTM or State Plane Coordinates.  Questions concerning this procedure or
software needed to convert to and from geographic coordinates, please call the NGS Information
Services Branch (see below).



PROGRAM EXECUTION

Get into the directory containing NDCON210.EXE and the grid files.

Type NDCON210.

If transformation between NAD 27 and NAD 83 is selected, all grid files pertaining to NAD 27-NAD
83 shifts within the directory will be opened. If transformation between NAD 83 and HARN is
selected, the user will be prompted for the two-letter area/state code.  The state/area codes are listed in
the available state HARN areas above.  NDCON210 will permit three sets of HARN files to be open
at a time.  DO NOT USE THIS OPTION.  Complete all the conversions for one area (state) before
continuing to another area.  A menu at the beginning of the program permits the user to select only one
datum pair at a time for latitude, longitude conversions:  NAD 27-NAD 83 or NAD 83-HPGN.  If
both types of conversions are needed, compute all the transformations for one datum shift first. 
NDCON210 will then return to the menu and conversions for the second datum shift can then be
computed.


PROBLEMS

Most problems are concentrated on opening the grid files.

- Check that the file names have not been changed

- Are the grid files in the same directory as the executable?

- Do both the *.LAS and *.LOS files exist for the same area?

- Do you have NADCON, Version 2.10?

Some computers can not open all seven pairs of NAD 83-NAD 27 grid files at one time.  Version 2.10
has been compiled with an option to correct this.

- Are both the *.LAS and *.LOS grid files for an area from the same source?  NADCON will open a
pair of grid files only if their headings are the same.

UTILITY PROGRAM, NADGRD

Included with NADCON is a utility that allows users to manipulate the gridded data sets (as described
below).

This utility, NADGRD, allows users to:

(1)  reformat the binary data sets into ASCII for transfer to other computers;

(2)  reformat those data sets back into binary for use with NADCON; and

(3)  reformat data into an ASCII format compatible with SURFER, a product of Golden Software,
Inc., Golden, CO.

Files in this last format can be displayed as contour maps and 3-D wire-frame figures using SURFER. 
In addition, the NADGRD utility can extract data sets covering a smaller area from data sets covering
larger ones.  These smaller, gridded areas can be used either directly with NADCON or can be
reformatted themselves with NADGRD.  The extraction is based on user specified minimum and
maximum latitudes and longitudes for the rectangular area defining a region.

Transformations calculated with the extracted data sets will be identical to ones computed using the
larger grids; there is no loss of accuracy.  The README.GRD file provides additional information
about NADGRD.  Extracting a smaller area can be particularly important if you are only interested in a
specific region, such as a state, county, or municipality.  This will greatly reduce the amount of space
necessary on the hard or floppy disk.

This utility will also be important to those with computer limitations, especially field parties with lap-top
systems.

Note that this version is an official DISTRIBUTION version.

Comments, questions, and concerns can be addressed to:

Mr. David Doyle or Ms. Cindy Craig
Telephone: (301) 713-3178 Telephone: (301) 713-3194
email: Dave.Doyle@noaa.gov email: Cindy.Craig@noaa.gov

Additional copies of this program can be obtained from:

National Geodetic Survey
Information Services Branch
SSMC-3, #9202
1315 East-West Highway
Silver Spring, MD 20910
Telephone: (301) 713-3242

World Wide Web Home Page: http://www.ngs.noaa.gov


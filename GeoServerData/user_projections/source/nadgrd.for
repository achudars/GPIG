      PROGRAM NADGRD

***********************************************************************
*                                                                     *
* PURPOSES: 1) To extract NADCON subgrids from larger NADCON grids.   *
*                                                                     *
*           2) To translate NADCON grid files to binary from the      *
*              ASCII transfer format and visa versa.                  *
*                                                                     *
*           3) To translate NADCON grid files from binary or the      *
*              ASCII transfer format to the ASCII graphics format.    *
*                                                                     *
*           4) To print information about NADCON grids to a file.     *
*                                                                     *
*              The program NADCON reads binary grids of NAD 27 to     *
*              NAD 83 latitude and longitude shift information.       *
*              The first record in a grid file consists of header     *
*              information.  All the other records consist of REAL*4  *
*              grid numbers.  The grid files are unformatted and      *
*              direct access.                                         *
*                                                                     *
*              NADCON grids come in pairs and consist of the latitude *
*              and longitude shifts in seconds of arc between NAD 27  *
*              and NAD 83.  The names of the grids are consist of     *
*              the location of the grid (e.g. 'conus' or 'alaska')    *
*              plus an extension.  The extension for the grid of      *
*              shifts in latitude is '.las' and the extension for the *
*              grid of shifts in longitude is '.los'.                 *
*                                                                     *
*              The ASCII transfer files are used for porability.      *
*              The first two records in the ASCII file contain the    *
*              header information.  The rest of the records are       *
*              formatted as 6F12.6.                                   *
*                                                                     *
*              This program is intended to be used with NADCON        *
*              development.                                           *
*                                                                     *
*              Variables in this code that end in an 'A' are          *
*              associated with a latitude grid while variables that   *
*              end in an 'O' are associated with a longitude grid.    *
*                                                                     *
*              All grids start and finish at even degrees.            *
*              NOTE that there must be minimum number of degrees      *
*              between the minimum and maximum longitude.  This is    *
*              explained further in subroutine NLON.                  *
*                                                                     *
* VERSION CODE:  1.01                                                 *
*                                                                     *
* VERSION DATE:  APRIL 1, 1991                                        *
*                                                                     *
* AUTHOR:   ALICE R. DREW                                             *
*           SENIOR GEODESIST, HORIZONTAL NETWORK BRANCH               *
*           WARREN T. DEWHURST, PH.D.                                 *
*             LIEUTENANT COMMANDER, NOAA                              *
*           NATIONAL GEODETIC SURVEY, NOS, NOAA                       *
*           ROCKVILLE, MD   20852                                     *
***********************************************************************

***********************************************************************
*                                                                     *
*                  DISCLAIMER                                         *
*                                                                     *
*   THIS PROGRAM AND SUPPORTING INFORMATION IS FURNISHED BY THE       *
* GOVERNMENT OF THE UNITED STATES OF AMERICA, AND IS ACCEPTED AND     *
* USED BY THE RECIPIENT WITH THE UNDERSTANDING THAT THE UNITED STATES *
* GOVERNMENT MAKES NO WARRANTIES, EXPRESS OR IMPLIED, CONCERNING THE  *
* ACCURACY, COMPLETENESS, RELIABILITY, OR SUITABILITY OF THIS         *
* PROGRAM, OF ITS CONSTITUENT PARTS, OR OF ANY SUPPORTING DATA.       *
*                                                                     *
*   THE GOVERNMENT OF THE UNITED STATES OF AMERICA SHALL BE UNDER NO  *
* LIABILITY WHATSOEVER RESULTING FROM ANY USE OF THIS PROGRAM.  THIS  *
* PROGRAM SHOULD NOT BE RELIED UPON AS THE SOLE BASIS FOR SOLVING A   *
* PROBLEM WHOSE INCORRECT SOLUTION COULD RESULT IN INJURY TO PERSON   *
* OR PROPERTY.                                                        *
*                                                                     *
*   THIS PROGRAM IS PROPERTY OF THE GOVERNMENT OF THE UNITED STATES   *
* OF AMERICA.  THEREFORE, THE RECIPIENT FURTHER AGREES NOT TO ASSERT  *
* PROPRIETARY RIGHTS THEREIN AND NOT TO REPRESENT THIS PROGRAM TO     *
* ANYONE AS BEING OTHER THAN A GOVERNMENT PROGRAM.                    *
*                                                                     *
***********************************************************************

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

* NMAX is the maximum size of the buffer.  It is at least as large
* as the largest number of columns in the input grid

      INTEGER NMAX
      PARAMETER (NMAX = 1024)
      REAL VRSION
      PARAMETER (VRSION = 1.01E0)

      REAL XMIN, XMAX, YMIN, YMAX
      INTEGER NCFRST, NCLAST, NRFRST, NRLAST
      INTEGER KIN, KOUT, IMETR
      CHARACTER*56 RIDENT
      CHARACTER*32 FOUTA, FOUTO
      CHARACTER*28 BASEIN
      CHARACTER*8 PGM
      LOGICAL FLAG

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

* Initialize the input/output unit numbers

      LUIN = 5
      LUOUT = 6
      NINA = 11
      NINO = 12
      NOUTA = 21
      NOUTO = 22

* Header

      CALL HEADR (VRSION)

* Open the input and output files

      FLAG = .FALSE.
      CALL IFILES (KIN, FLAG, BASEIN, RIDENT, PGM)
      IF (FLAG) GOTO 9000

      CALL OFILES (KIN, KOUT, FOUTA, FOUTO, BASEIN, RIDENT, PGM, IMETR)

* Get the variables for the new grid files.

      CALL NPARMS (KOUT, XMIN, XMAX, YMIN, YMAX,
     +             NRFRST, NRLAST, NCFRST, NCLAST)

* Get maximum and minimum Z values in new grid area

      CALL ZEXTRM (KIN, KOUT, NCFRST, NCLAST, NRFRST, NRLAST)

*** Copy from input files to output files

      IF (KOUT .NE. 0) THEN
        CALL TONEW (KIN, KOUT, XMIN, XMAX, YMIN, YMAX,
     +              NCFRST, NCLAST, NRFRST, NRLAST, FOUTA, FOUTO, IMETR)
      ENDIF

* Close all files

 9000 CONTINUE
      CLOSE (NINA,STATUS='KEEP')
      CLOSE (NINO,STATUS='KEEP')
      IF (.NOT. FLAG) THEN
        CLOSE (NOUTA,STATUS='KEEP')
        IF (KOUT .NE. 0) CLOSE (NOUTO,STATUS='KEEP')
      ENDIF
      WRITE (LUOUT,9010)
 9010 FORMAT (' End of program NADGRD')
      STOP
      END
      SUBROUTINE HEADR (VRSION)

*** This subroutine prints the header information

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      REAL VRSION
      CHARACTER*1 ANS

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

      WRITE (LUOUT,920)
  920 FORMAT (12X,  '                      Welcome', /,
     +        12X,  '                      to  the', /,
     +        12X,  '             National Geodetic Survey', /,
     +        12X,  '  North American Datum Grid Manipulation program.',
     +    //, 12X,  '             For use when NADCON grids', /,
     +        12X,  '               need to be translated', /,
     +        12X,  '             between ASCII and binary', /,
     +        12X,  '                        or', /,
     +        12X,  '    when grids covering a smaller areal extent', /,
     +        12X,  '        need to be extracted from standard', /,
     +        12X,  '                   NADCON grids.', /,
     +        12X,  '                        or', /,
     +        12X,  '             for obtaining information', /,
     +        12X,  '              about the NADCON grids.')

      WRITE (LUOUT,930) VRSION
  930 FORMAT (/, 12X,  '                  (Version', F5.2, ')', /,
     +        12X,  '                   April 1, 1990', /,
     +        12X,  '             Warren T. Dewhurst, Ph.D.', /,
     +        12X,  '            Lieutenant Commander, NOAA', /,
     +        12X,  '                  Alice R. Drew', /,
     +        12X,  '    Senior Geodesist, Horizontal Network Branch',/)

      WRITE (LUOUT,931)
  931 FORMAT (12X,  '             (Hit RETURN to continue.)')

      READ (LUIN,'(A1)') ANS
      WRITE (LUOUT,2)
*   2 FORMAT ('1')
    2 FORMAT ('')

      WRITE (LUOUT,932)
  932 FORMAT ( /, 32X, 'DISCLAIMER' ,//,
     + ' This program and supporting information is furnished by',
     + ' the government of', /,
     + ' the United States of America, and is accepted/used by the',
     + ' recipient with', /,
     + ' the understanding that the U. S. government makes no',
     + ' warranties, express or', /,
     + ' implied, concerning the accuracy, completeness, reliability,',
     + ' or suitability', /,
     + ' of this program, of its constituent parts, or of any',
     + ' supporting data.', //,
     + ' The government of the United States of America shall be',
     + ' under no liability', /,
     + ' whatsoever resulting from any use of this program.',
     + '  This program should', /,
     + ' not be relied upon as the sole basis for solving a problem',
     + ' whose incorrect', /,
     + ' solution could result in injury to person or property.')
        WRITE (LUOUT,933)
  933   FORMAT ( /,
     + ' This program is the property of the government of the',
     + ' United States of', /,
     + ' America. Therefore, the recipient further agrees not to',
     + ' assert proprietary', /,
     + ' rights therein and not to represent this program to anyone as',
     + ' being other', /,
     + ' than a government program.', /)

      WRITE (LUOUT,931)
      READ (LUIN,'(A1)') ANS

      RETURN
      END
      SUBROUTINE IFILES (KIN, FLAG, BASEIN, RIDENT, PGM)

* Interactively get input file basenames.
* Open the input files

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      CHARACTER*32 B32
      PARAMETER (B32 = '                                ')

      REAL XMIN0A, YMIN0A, DXA, DYA
      REAL ANGLE, ANGLEA
      INTEGER NZ, LRECL, KIN
      INTEGER IFLAG2, N2
      INTEGER NCA, NRA, NZA
      CHARACTER*56 RIDENT
      CHARACTER*32 FINA, FINO
      CHARACTER*28 BASEIN
      CHARACTER*8 PGM
      CHARACTER*1 ANS
      LOGICAL FLAG

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

      REAL XMIN0, XMAX0, YMIN0, YMAX0, DX, DY
      INTEGER NC, NR
      COMMON /GRID0/ XMIN0, XMAX0, YMIN0, YMAX0, DX, DY, NR, NC

      DATA  IFLAG2 /2/

* Find out about the input files

      WRITE (LUOUT,2)
*   2 FORMAT ('1')
    2 FORMAT ('')
  220 WRITE (LUOUT,225)
  225 FORMAT (   ' For the input files enter:',
     +        /, '     ''A'' for ASCII transfer format.',
     +        /, '     ''B'' for binary - NADCON data file format).',
     +        /, ' (Default is B)')
      READ (LUIN,'(A1)') ANS
      IF (ANS .EQ. ' '  .OR.  ANS .EQ. 'B'  .OR.  ANS .EQ. 'b') THEN
        KIN = 1
      ELSEIF (ANS .EQ. 'A'  .OR.  ANS .EQ. 'a') THEN
        KIN = -1
      ELSE
        WRITE (LUOUT, 210) ANS
  210   FORMAT (/, ' ERROR - ''', A1, ''' is not a legal answer.')
        GOTO 220
      ENDIF

* Get basename

      IF (KIN .EQ. 1) THEN
        WRITE (LUOUT,110)
  110   FORMAT (   ' Enter the basename for the pair of input NADCON',
     +             ' grid files from which the',
     +          /, ' new grids will be extracted.  The ''.las''',
     +             ' and ''.los'' extensions will be',
     +          /, ' added to the basename by NADGRD.  The default',
     +             ' basename is ''conus''.')
      ELSEIF (KIN .EQ. -1) THEN
        WRITE (LUOUT,115)
  115   FORMAT (   ' Enter the basename for the pair of input NADCON',
     +             ' grid files from which the',
     +          /, ' new grids will be extracted.  The ''.laa''',
     +             ' and ''.loa'' extensions will be',
     +          /, ' added to the basename by NADGRD.  The default',
     +             ' basename is ''conus''.')
      ENDIF

      READ (LUIN,'(A28)') BASEIN
      CALL NBLANK (BASEIN, IFLAG2, N2)
      IF (N2 .EQ. 0) THEN
        BASEIN = 'conus'
        N2 = 5
      ENDIF

      FINA = B32
      FINA(1:N2) = BASEIN(1:N2)
      FINO = B32
      FINO(1:N2) = BASEIN(1:N2)

      IF (KIN .EQ. 1) THEN

* Open binary input files

        N2 = N2 + 4
        FINA(N2-3:N2) = '.las'
        FINO(N2-3:N2) = '.los'
        LRECL = 256
        OPEN (NINA,FILE=FINA,FORM='UNFORMATTED',ACCESS='DIRECT',
     +        RECL=LRECL,STATUS='OLD',ERR= 900)
        OPEN (NINO,FILE=FINO,FORM='UNFORMATTED',ACCESS='DIRECT',
     +        RECL=LRECL,STATUS='OLD',ERR= 900)
        READ (NINA,REC=1) RIDENT, PGM, NCA, NRA, NZA, XMIN0A, DXA,
     +                    YMIN0A, DYA, ANGLEA
        READ (NINO,REC=1) RIDENT, PGM, NC, NR, NZ, XMIN0, DX,
     +                    YMIN0, DY, ANGLE

      ELSEIF (KIN .EQ. -1) THEN

* Open ASCII input files

        N2 = N2 + 4
        FINA(N2-3:N2) = '.laa'
        FINO(N2-3:N2) = '.loa'
        OPEN (NINA,FILE=FINA,FORM='FORMATTED',ACCESS='SEQUENTIAL',
     +        STATUS='OLD',ERR=900)
        OPEN (NINO,FILE=FINO,FORM='FORMATTED',ACCESS='SEQUENTIAL',
     +        STATUS='OLD',ERR=900)
        READ (NINA,140) RIDENT, PGM
        READ (NINO,140) RIDENT, PGM
  140   FORMAT (A56, A8)
        READ (NINA, 150,ERR=900)  NCA, NRA, NZA, XMIN0A, DXA,
     +                            YMIN0A, DYA, ANGLEA
        READ (NINO, 150,ERR=900)  NC, NR, NZ, XMIN0, DX,
     +                            YMIN0, DY, ANGLE
  150   FORMAT (3I4, 5F12.5)
      ENDIF

* Check for corrupted files

      IF (NCA .NE. NC  .OR.  NRA .NE. NR  .OR.  NZA .NE.  NZ  .OR.
     +    XMIN0A .NE. XMIN0  .OR.  YMIN0A .NE. YMIN0  .OR.
     +    DXA .NE. DX  .OR.  DYA .NE. DY  .OR.  ANGLEA .NE. ANGLE)
     +  GOTO 960
      IF (NZ .NE. 1  .OR.  ANGLE .NE. 0.0) GOTO 960

* Reopen binary files with correct record length

      IF (KIN .EQ. 1) THEN
        CLOSE (NINA)
        CLOSE (NINO)
        LRECL = 4*(NC + 1)
        OPEN (NINA,FILE=FINA,FORM='UNFORMATTED',ACCESS='DIRECT',
     +        RECL=LRECL,STATUS='OLD')
        OPEN (NINO,FILE=FINO,FORM='UNFORMATTED',ACCESS='DIRECT',
     +        RECL=LRECL,STATUS='OLD')
      ENDIF

* Write the (user-significant) input file variables to the screen

      XMAX0 = DX * REAL( NC-1 )  +  XMIN0
      YMAX0 = DY * REAL( NR-1 )  +  YMIN0

      IF (KIN .EQ. 1) THEN
        WRITE (LUOUT,130) FINA(1:N2), FINO(1:N2)
  130   FORMAT (/, ' Binary files ''', A, ''' and ''', A, ''' have',
     +             ' been opened.')
      ELSEIF (KIN .EQ. -1) THEN
        WRITE (LUOUT,135) FINA(1:N2), FINO(1:N2)
  135   FORMAT (/, ' ASCII files ''', A, ''' and ''', A, ''' have',
     +             ' been opened.')
      ENDIF
      WRITE (LUOUT,180) YMIN0, YMAX0, -XMAX0, -XMIN0
  180 FORMAT (/, ' Their minimum and maximum latitudes  (+N) are: ',
     +           2F8.0,
     +        /, ' Their minimum and maximum longitudes (+W) are: ',
     +           2F8.0, /)
      WRITE (LUOUT,200)
  200 FORMAT (14X, '(Hit RETURN to continue.)')
      READ (LUIN,'(A1)') ANS
      WRITE (LUOUT,2)

  999 RETURN

* Error messages

  900 WRITE (LUOUT,910) FINA(1:N2), FINO(1:N2)
  910 FORMAT (/, ' *** ERROR *** ''', A, ''' and ''', A, ''' cannot',
     +           ' be opened!',
     +        /, ' Do you wish to try again (Y/N)?',
     +        /, ' (Default is Y)')
      READ (LUIN,'(A1)') ANS
      IF (ANS .NE. 'N'  .AND.  ANS .NE. 'n') GOTO 220
      FLAG = .TRUE.
      GOTO 999

* Corrupted input files

  960 WRITE (LUOUT, 965) FINA(1:N2), FINO(1:N2)
  965 FORMAT (/, 5X, ' *********** ERROR ***********', /,
     +           ' The header information in grid files', /,
     +           ' ''', A, ''' and ''', A, '''', /,
     +           ' is incorrect!  One or both of these files is',
     +                                ' corrupted or the wrong format.')
      FLAG = .TRUE.
      GOTO 999
      END
      SUBROUTINE METER2 (LAT, LON, DLAT, DLON, DLATM, DLONM)

* This subroutine computes a distance in meters at a position
* from a distance in seconds of arc.
*
* This method utilizes ellipsoidal rather than spherical
* parameters.  I believe that the original approach and code
* for this came from Ed McKay.
* The reference used by Ed McKay for this was:
*       'A Course in Higher Geodesy' by P.W. Zakatov, Israel Program
*       for Scientific Translations, Jerusalem, 1962
*
*       Warren T. Dewhurst
*       11/1/89
* Note that this subroutine is set up for +west longitude

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

* I think that these are GRS80 parameters

      DOUBLE PRECISION AXIS, E2, RHOSEC
      PARAMETER (AXIS = 6378137.0D0)
      PARAMETER (E2 = 0.0066943800229D0)
      PARAMETER (RHOSEC = 206264.806247D0)

      DOUBLE PRECISION LAT, LON, RLAT, RLON, DLAT, DLON, RDLAT, RDLON
      DOUBLE PRECISION W, LM, LP
      REAL DLATM, DLONM

* Change into radians and convert to +west longitude

      RLAT =  LAT*60.D0*60.D0/RHOSEC
      RLON = -LON*60.D0*60.D0/RHOSEC

      RDLAT = DLAT/RHOSEC
      RDLON = DLON/RHOSEC

      W  = DSQRT(1.0D0 - E2*DSIN(RLAT)**2)
      LM = AXIS*(1.0D0 - E2)/(W**3)
      LP = AXIS*DCOS(RLAT)/W

      DLATM = SNGL(LM*RDLAT)
      DLONM = SNGL(LP*RDLON)

      RETURN
      END
      SUBROUTINE NBLANK (A, IFLAG, NBLK)

*** Return position of last non-blank in string (IFLAG = 2)
*** or position of first non-blank in string (IFLAG = 1)

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER LENG, IFLAG, IBLK, NBLK
      CHARACTER*(*) A

      LENG = LEN(A)

      IF (IFLAG .EQ. 2) THEN
        DO 1 IBLK = LENG, 1, -1
          IF ( A(IBLK:IBLK) .NE. ' ' ) THEN
            NBLK = IBLK
            RETURN
          ENDIF
    1   CONTINUE
      ELSEIF (IFLAG .EQ. 1) THEN
        DO 2 IBLK = 1, LENG, +1
          IF ( A(IBLK:IBLK) .NE. ' ' ) THEN
            NBLK = IBLK
            RETURN
          ENDIF
    2   CONTINUE
      ENDIF

* String contains all blanks

      NBLK = 0

      RETURN
      END
      SUBROUTINE NLAT (KOUT, YMIN, YMAX)

* Get the new latitude variables

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

* SMALL is system dependent and should be a very small real number

      REAL SMALL
      PARAMETER (SMALL = 1.E-5)

      REAL RCARD
      REAL YMIN, YMAX
      INTEGER LENG, IERR, KOUT
      CHARACTER*10 ANS

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

      REAL XMIN0, XMAX0, YMIN0, YMAX0, DX, DY
      INTEGER NR, NC
      COMMON /GRID0/ XMIN0, XMAX0, YMIN0, YMAX0, DX, DY, NR, NC

  110 WRITE (LUOUT,115) YMIN0
  115 FORMAT (/, ' Enter the minimum latitude, north positive.',
     +        /, ' The default value is:', F8.0)
      READ (LUIN,'(A10)') ANS
      IF (ANS .EQ. '          ') THEN
        YMIN = YMIN0
      ELSE
        LENG = 10
        YMIN = RCARD (ANS, LENG, IERR)
      ENDIF

      WRITE (LUOUT,120) YMAX0
  120 FORMAT (/, ' Enter the maximum latitude, north positive.',
     +        /, ' The default value is:', F8.0)
      READ (LUIN,'(A10)') ANS
      IF (ANS .EQ. '          ') THEN
        YMAX = YMAX0
      ELSE
        LENG = 10
        YMAX = RCARD (ANS, LENG, IERR)
      ENDIF

* check values

      IF (YMIN .LT. YMIN0  .OR. YMIN .GT. YMAX0  .OR.
     +    YMAX .LT. YMIN0  .OR. YMAX .GT. YMAX0) THEN
        WRITE (LUOUT, 130) YMIN0, YMAX0
  130   FORMAT (/, ' *** ERROR *** ',
     +          /, ' One or both of the values that you gave for the',
     +             ' minimum and maximum',
     +          /, ' latitudes are out of bounds!  For the input',
     +             ' NADCON grids',
     +          /, ' the minimum and maximum latitudes (+N)  are: ',
     +             2F8.0)
        GOTO 110
      ELSEIF ( ( YMIN .GT. YMAX )  .OR.
     +         ( KOUT .EQ. -2  .AND.  YMIN .EQ. YMAX) ) THEN
        WRITE (LUOUT, 140) YMIN0, YMAX0
  140   FORMAT (/, ' *** ERROR *** ',
     +          /, ' The minimum value that you gave for the latitude',
     +             ' is less than the maximum!',
     +          /, ' For the input NADCON grids',
     +          /, ' the minimum and maximum latitudes (+N)  are: ',
     +             2F8.0)
        GOTO 110
      ENDIF

* The subgrid must be buffered by at least one whole degree of
* the original grid - BUT must be wholy within the original grid.

* For ASCII graphics format, buffer only to the nearest whole degree

      IF (KOUT .NE. -2) THEN
        YMIN = AINT(YMIN - 1.E0 + SMALL)
        YMAX = AINT(YMAX + 2.E0 - SMALL)
      ELSE
        YMIN = AINT(YMIN        + SMALL)
        YMAX = AINT(YMAX + 1.E0 - SMALL)
      ENDIF

      IF (YMIN .LT. YMIN0) YMIN = YMIN0
      IF (YMAX .GT. YMAX0) YMAX = YMAX0

      RETURN
      END
      SUBROUTINE NLON (KOUT, XMIN, XMAX)

* Get the new longitude variables.

* The variables LMIN is the minimum number of degrees between the
* minimum longitude and the maximum longitude.  The reason that
* there must be this minimum is that in order to be read by NADCON,
* the extracted grid must have a logical record length of at least 96.
* This is because the header record length is 96 bytes.
* This variables is not used for the graphics output (KOUT=-2)

* What happens is that the output file is opened with a record length
* of 4*(NC2+1) and the first record written.  The second record
* is then written into the file starting at character 4*(NC2+1)+1.
* where NC2 is the number of columns in the output file and is
* determined by the longitude difference and the longitude increment.
* Since the shifts are written as REAL*4 numbers, there must be at
* least 24 numbers in a row.

* For example, the conus files have .25=DX.  NADGRD requires that the
* grid boundarys be even degrees.  In order to have at least 24
* number in a row, the (maximum-minimum) longitude must be at least 6
* degrees.  However, given buffering, the inputted (maximum-minimum)
* longitude must be at least 4 degrees.

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

* SMALL is system dependent and should be a very small real number

      REAL SMALL
      PARAMETER (SMALL = 1.E-5)

      REAL RCARD
      REAL XMIN, XMAX
      INTEGER LENG, IERR, KOUT, LMIN
      CHARACTER*10 ANS

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

      REAL XMIN0, XMAX0, YMIN0, YMAX0, DX, DY
      INTEGER NR, NC
      COMMON /GRID0/ XMIN0, XMAX0, YMIN0, YMAX0, DX, DY, NR, NC

  160 WRITE (LUOUT,150) -XMAX0
  150 FORMAT (/, ' Enter the minimum longitude,',
     +           ' west longitude positive.',
     +        /, ' The default value is:', F8.0)
      READ (LUIN,'(A10)') ANS
      IF (ANS .EQ. '          ') THEN
        XMAX = XMAX0
      ELSE
        LENG = 10
        XMAX = RCARD (ANS, LENG, IERR)
        XMAX = -XMAX
      ENDIF
      IF (KOUT .NE. -2) THEN
        LMIN = INT(24.E0*DX + SMALL)
        IF (LMIN .LT. 1) LMIN = 1
        WRITE (LUOUT,155) LMIN, -XMIN0
  155   FORMAT (/, ' Enter the maximum longitude,',
     +             ' west longitude positive.',
     +          /, ' The (buffered) difference between the minimum and',
     +             ' maximum longitudes',
     +          /, ' must be at least', I3, ' degrees.  The default',
     +             ' value is:', F8.0)
      ELSE
        WRITE (LUOUT,165) -XMIN0
  165   FORMAT (/, ' Enter the maximum longitude,',
     +             ' west longitude positive.',
     +          /, ' The default value is:', F8.0)
      ENDIF
      READ (LUIN,'(A10)') ANS
      IF (ANS .EQ. '          ') THEN
        XMIN = XMIN0
      ELSE
        LENG = 10
        XMIN = RCARD (ANS, LENG, IERR)
        XMIN = -XMIN
      ENDIF

* check values

      IF (XMIN .LT. XMIN0  .OR. XMIN .GT. XMAX0  .OR.
     +    XMAX .LT. XMIN0  .OR. XMAX .GT. XMAX0) THEN
        WRITE (LUOUT, 170) -XMAX0, -XMIN0
  170   FORMAT (/, ' *** ERROR *** ',
     +          /, ' One or both of the values that you gave for the',
     +             ' minimum and maximum',
     +          /, ' longitudes are out of bounds!  For the input',
     +             ' NADCON grids',
     +          /, ' the minimum and maximum longitudes (+W)  are: ',
     +             2F8.0)
        GOTO 160
      ELSEIF ( ( XMIN .GT. XMAX )  .OR.
     +         ( KOUT .EQ. -2  .AND.  XMIN .EQ. XMAX) ) THEN
        WRITE (LUOUT, 180) -XMAX0, -XMIN0
  180   FORMAT (/, ' *** ERROR *** ',
     +          /, ' The minimum value that you gave for the longitude',
     +             ' is less than the maximum!',
     +          /, ' For the input NADCON grids',
     +          /, ' the minimum and maximum longitudes (+W)  are: ',
     +             2F8.0)
        GOTO 160
      ENDIF

* The subgrid must be buffered by at least one whole degree of
* the original grid - BUT must be wholy within the original grid.

* For ASCII graphics format, buffer only to the nearest whole degree

      IF (KOUT .NE. -2) THEN
        XMIN = AINT(XMIN - 2.E0 + SMALL)
        XMAX = AINT(XMAX + 1.E0 - SMALL)
      ELSE
        XMIN = AINT(XMIN - 1.E0 + SMALL)
        XMAX = AINT(XMAX        - SMALL)
      ENDIF

      IF (XMIN .LT. XMIN0) XMIN = XMIN0
      IF (XMAX .GT. XMAX0) XMAX = XMAX0

* check range

      IF ( KOUT .NE. -2  .AND.  (XMAX-XMIN) .LT. LMIN ) THEN
        WRITE (LUOUT, 190) LMIN, -XMAX0, -XMIN0
  190   FORMAT (/, ' *** ERROR *** ',
     +          /, ' The difference between the minimum and maximum',
     +             ' longitudes MUST be at',
     +          /, ' least', I3, ' degrees. ',
     +             ' For the input NADCON grids',
     +          /, ' the minimum and maximum longitudes (+W)  are: ',
     +             2F8.0)
        GOTO 160
      ENDIF

      RETURN
      END
      SUBROUTINE NPARMS (KOUT, XMIN, XMAX, YMIN, YMAX,
     +                   NRFRST, NRLAST, NCFRST, NCLAST)

* Get the variables for the new grid files.

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

* SMALL is system dependent and should be a very small real number

      REAL SMALL
      PARAMETER (SMALL = 1.E-5)

      REAL XMIN, XMAX, YMIN, YMAX
      INTEGER KOUT, NCFRST, NCLAST, NRFRST, NRLAST
      CHARACTER*1 ANS

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

      REAL XMIN0, XMAX0, YMIN0, YMAX0, DX, DY
      INTEGER NC, NR
      COMMON /GRID0/ XMIN0, XMAX0, YMIN0, YMAX0, DX, DY, NR, NC

* If only printing grid information then set defaults and return

      IF (KOUT .EQ. 0) THEN
        YMIN = YMIN0
        YMAX = YMAX0
        XMAX = XMAX0
        XMIN = XMIN0
        NRFRST = 1
        NRLAST = NR
        NCFRST = 1
        NCLAST = NC
        RETURN
      ENDIF

*** Get the area variables of the grid

      WRITE (LUOUT,2)
*   2 FORMAT ('1')
    2 FORMAT ('')
      IF (KOUT .NE. -2) THEN
        WRITE (LUOUT,100)
  100   FORMAT (   ' The extracted NADCON grids will be automatically',
     +             ' buffered to the next',
     +          /, ' whole degree plus one by NADGRD.  Please enter',
     +             ' the latitude and longitude',
     +          /, ' extremes for your area of interest.  Enter the',
     +             ' values in decimal degrees.',
     +          /, ' If you enter blanks, the extremes from the input',
     +             ' files will be used.')
      ELSE
        WRITE (LUOUT,105)
  105   FORMAT (   ' The extracted NADCON grids will be automatically',
     +             ' rounded to the next',
     +          /, ' whole degree by NADGRD.  Please enter the',
     +             ' latitude and longitude',
     +          /, ' extremes for your area of interest.  Enter the',
     +             ' values in decimal degrees.',
     +          /, ' If you enter blanks, the extremes from the input',
     +             ' files will be used.')
      ENDIF

* latitude

  200 CALL NLAT (KOUT, YMIN, YMAX)

* longitude, change to east positive

      CALL NLON (KOUT, XMIN, XMAX)

* Ask if the new maximums and minimums are OK

      WRITE (LUOUT,2)
      IF ( KOUT .NE. -2  .AND.
     +     ( XMIN .NE. XMIN0  .OR.  XMAX .NE. XMAX0  .OR.
     +       YMIN .NE. YMIN0  .OR.  YMAX .NE. YMAX0 )  ) THEN
        WRITE (LUOUT, 210) YMIN, YMAX, -XMAX, -XMIN
  210   FORMAT (   ' For the output grids;',
     +          /, ' the (buffered) minimum and maximum latitudes ',
     +             ' (+N) are: ', 2F8.0,
     +          /, ' the (buffered) minimum and maximum longitudes',
     +             ' (+W) are: ', 2F8.0)
      ELSE
        WRITE (LUOUT, 215) YMIN, YMAX, -XMAX, -XMIN
  215   FORMAT (   ' For the output grids;',
     +          /, ' the minimum and maximum latitudes ',
     +             ' (+N) are: ', 2F8.0,
     +          /, ' the minimum and maximum longitudes',
     +             ' (+W) are: ', 2F8.0)
      ENDIF

      WRITE (LUOUT,220)
  220 FORMAT (/, ' If these values are OK, hit RETURN to continue.',
     +           '  Enter any other character',
     +        /, ' to re-enter the minimum and maximum latitudes',
     +           ' and longitudes.')
      READ (LUIN,'(A1)') ANS
      IF (ANS .NE. ' ') GOTO 200

* Calculate the new origin for the subgrid area,
* calculate the number of columns and rows

      NRFRST = NINT( (YMIN - YMIN0)/DY ) + 1
      NRLAST = NINT( (YMAX - YMIN0)/DY ) + 1
      NCFRST = NINT( (XMIN - XMIN0)/DX ) + 1
      NCLAST = NINT( (XMAX - XMIN0)/DX ) + 1

      RETURN
      END
      SUBROUTINE OFILES (KIN, KOUT, FOUTA, FOUTO, BASEIN, RIDENT, PGM,
     +                   IMETR)

* Interactively get output file basenames.

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      CHARACTER*28 B28
      PARAMETER (B28 = '                            ')
      CHARACTER*32 B32
      PARAMETER (B32 = '                                ')

      INTEGER KIN, KOUT, IMETR
      INTEGER IFLAG2, N2
      CHARACTER*56 RIDENT
      CHARACTER*32 FOUTA, FOUTO
      CHARACTER*28 BASEIN, BASOUT, DBNAME
      CHARACTER*8 PGM
      CHARACTER*1 ANS

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

      REAL XMIN0, XMAX0, YMIN0, YMAX0, DX, DY
      INTEGER NC, NR
      COMMON /GRID0/ XMIN0, XMAX0, YMIN0, YMAX0, DX, DY, NR, NC

      DATA IFLAG2 /2/

* Find out about the output file(s)

  220 WRITE (LUOUT,115)
  115 FORMAT (   ' For the output files enter:',
     +        /, '     ''A'' for ASCII transfer format.',
     +        /, '     ''B'' for binary - NADCON data file format.',
     +        /, '     ''G'' for ASCII graphics format. ',
     +           ' There are five header information records,',
     +        /, '         and the record lengths',
     +           ' can be VERY large.'
     +        /, '     ''I'' for input file information written to a',
     +           ' single output file.',
     +        /, ' (Default is B)')
      READ (LUIN,'(A1)') ANS
      IF (ANS .EQ. ' '  .OR.  ANS .EQ. 'B'  .OR.  ANS .EQ. 'b') THEN
        KOUT = 1
      ELSEIF (ANS .EQ. 'A'  .OR.  ANS .EQ. 'a') THEN
        KOUT = -1
      ELSEIF (ANS .EQ. 'G'  .OR.  ANS .EQ. 'g') THEN
        KOUT = -2
      ELSEIF (ANS .EQ. 'I'  .OR.  ANS .EQ. 'i') THEN
        KOUT = 0
      ELSE
        WRITE (LUOUT, 210) ANS
  210   FORMAT (/, ' ERROR - ''', A1, ''' is not a legal answer.')
        GOTO 220
      ENDIF

* default basename is the input basename unless the same format

      IF (KOUT .NE. KIN) THEN
        DBNAME = BASEIN
        CALL NBLANK (DBNAME, IFLAG2, N2)
      ELSE
        DBNAME = 'nadgrd'
        N2 = 6
      ENDIF

  180 IF (KOUT .EQ. 1) THEN

* The extensions for the binary output files are .las and .los

        WRITE (LUOUT,160) DBNAME(1:N2)
  160   FORMAT (/, ' Enter the file name for the new pair of',
     +             ' NADCON grids.  Enter only the',
     +          /, ' basename.  The ''.las'' and ''.los'' extensions',
     +             ' will be added to the',
     +          /, ' basename by NADGRD.  The default base file name',
     +             ' is ''', A, '''.')
        READ (LUIN,'(A28)') BASOUT
        IF (BASOUT .EQ. B28) BASOUT = DBNAME
        IF (KIN .EQ. 1  .AND.  BASOUT .EQ. BASEIN) THEN
          WRITE (LUOUT,165) BASOUT
  165     FORMAT (/, ' ***** ERROR ****',
     +            /, ' File ''', A, ''' is the name of the input file!',
     +            /, ' You must choose another name.')
          GOTO 180
        ENDIF

        CALL NBLANK (BASOUT, IFLAG2, N2)
        FOUTA = B32
        FOUTA(1:N2) = BASOUT(1:N2)
        FOUTO = B32
        FOUTO(1:N2) = BASOUT(1:N2)
        FOUTA(N2+1:N2+4) = '.las'
        FOUTO(N2+1:N2+4) = '.los'

      ELSEIF (KOUT .EQ. -1) THEN

* The extensions for the ASCII output files are .laa and .loa

        WRITE (LUOUT,190) DBNAME(1:N2)
  190   FORMAT (/, ' Enter the file name for the new pair of',
     +             ' NADCON grids.  Enter only the',
     +          /, ' basename.  The ''.laa'' and ''.loa'' extensions',
     +             ' will be added to the',
     +          /, ' basename by NADGRD.  The default base file name',
     +             ' is ''', A, '''.')
        READ (LUIN,'(A28)') BASOUT
        IF (BASOUT .EQ. B28) BASOUT = DBNAME
        IF (KIN .EQ. -1  .AND.  BASOUT .EQ. BASEIN) THEN
          WRITE (LUOUT,185) BASOUT
  185     FORMAT (/, ' ***** ERROR ****',
     +            /, ' File ''', A, ''' is the name of the input file!',
     +            /, ' You must choose another name.')
          GOTO 180
        ENDIF

        CALL NBLANK (BASOUT, IFLAG2, N2)
        FOUTA = B32
        FOUTA(1:N2) = BASOUT(1:N2)
        FOUTO = B32
        FOUTO(1:N2) = BASOUT(1:N2)
        FOUTA(N2+1:N2+4) = '.laa'
        FOUTO(N2+1:N2+4) = '.loa'

      ELSEIF (KOUT .EQ. -2) THEN

* The extensions for the graphics output files are .lag and .log for
* seconds of arc or .lam and .lom for meters

        WRITE (LUOUT,310)
  310   FORMAT (/, ' Do you wish the ouput grids to have the shifts',
     +             ' in seconds of arc or in meters?',
     +          /, ' Enter ''S'' for seconds of arc or ''M'' for',
     +             ' meters.  The default is seconds of arc.')
        READ (LUIN,'(A1)') ANS
        IF (ANS .EQ. 'M'  .OR.  ANS .EQ. 'm') THEN
          IMETR = -1
        ELSE
          IMETR = 1
        ENDIF

        IF (IMETR .EQ. 1) THEN
          WRITE (LUOUT,170) DBNAME(1:N2)
  170     FORMAT (/, ' Enter the file name for the new pair of',
     +               ' NADCON grids.  Enter only the',
     +            /, ' basename.  The ''.lag'' and ''.log'' extensions',
     +               ' will be added to the',
     +            /, ' basename by NADGRD.  The default base file name',
     +               ' is ''', A, '''.')
        ELSE
          WRITE (LUOUT,175) DBNAME(1:N2)
  175     FORMAT (/, ' Enter the file name for the new pair of',
     +               ' NADCON grids.  Enter only the',
     +            /, ' basename.  The ''.lam'' and ''.lom'' extensions',
     +               ' will be added to the',
     +            /, ' basename by NADGRD.  The default base file name',
     +               ' is ''', A, '''.')
        ENDIF
        READ (LUIN,'(A28)') BASOUT
        IF (BASOUT .EQ. B28) BASOUT = DBNAME

        CALL NBLANK (BASOUT, IFLAG2, N2)
        FOUTA = B32
        FOUTA(1:N2) = BASOUT(1:N2)
        FOUTO = B32
        FOUTO(1:N2) = BASOUT(1:N2)
        IF (IMETR .EQ. 1) THEN
          FOUTA(N2+1:N2+4) = '.lag'
          FOUTO(N2+1:N2+4) = '.log'
        ELSE
          FOUTA(N2+1:N2+4) = '.lam'
          FOUTO(N2+1:N2+4) = '.lom'
        ENDIF

      ELSEIF (KOUT .EQ. 0) THEN

* The extension for the information file is .inf

        WRITE (LUOUT,195) DBNAME(1:N2)
  195   FORMAT (/, ' Enter the file name for the grid information',
     +             ' file.  Enter only the basename.',
     +          /, ' The ''.inf'' extension will be added to the',
     +             ' basename by NADGRD.  The default',
     +          /, ' base file name is ''', A, '''.')
        READ (LUIN,'(A28)') BASOUT
        IF (BASOUT .EQ. B28) BASOUT = DBNAME
        CALL NBLANK (BASOUT, IFLAG2, N2)
        FOUTA = B32
        FOUTA(1:N2) = BASOUT(1:N2)
        FOUTA(N2+1:N2+4) = '.inf'

* Write input header information to the information file

        OPEN (NOUTA,FILE=FOUTA,FORM='FORMATTED',ACCESS='SEQUENTIAL',
     +        STATUS='UNKNOWN')
        IF (KIN .EQ. 1) THEN
          CALL NBLANK (BASEIN, IFLAG2, N2)
          WRITE (NOUTA,230) BASEIN(1:N2)//'.las', BASEIN(1:N2)//'.los'
  230     FORMAT (/, ' Files ''', A, ''' and ''', A,
     +               ''' are binary.')
        ELSEIF (KIN .EQ. -1) THEN
          CALL NBLANK (BASEIN, IFLAG2, N2)
          WRITE (NOUTA,235) BASEIN(1:N2)//'.laa', BASEIN(1:N2)//'.loa'
  235     FORMAT (/, ' Files ''', A, ''' and ''', A, ''' are',
     +               ' ASCII.')
        ENDIF
        WRITE (NOUTA,250) RIDENT, PGM
  250   FORMAT (/, ' From the header record(s):',
     +          /, ' Data Identification =''', A56, '''',
     +          /, ' Originating software =''', A8, '''')
        WRITE (NOUTA,260) NC, NR
  260   FORMAT (/, ' Number of columns =', I5,
     +             '    Number of rows =', I5)
        WRITE (NOUTA,270) YMIN0, YMAX0, DY
  270   FORMAT (/, ' Latitude:   minimum =', F8.0,
     +             '   maximum =', F8.0,
     +             '  increment =', F9.5)
        WRITE (NOUTA,280) -XMAX0, -XMIN0, DX
  280   FORMAT (   ' Longitude:  minimum =', F8.0,
     +             '   maximum =', F8.0,
     +             '  increment =', F9.5)
      ENDIF

      RETURN
      END
      SUBROUTINE TONEW (KIN, KOUT, XMIN, XMAX, YMIN, YMAX,
     +                  NCFRST, NCLAST, NRFRST, NRLAST, FOUTA, FOUTO,
     +                  IMETR)

*** Copy from input files to output files

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

* NMAX is the maximum size of the buffer.  It is at least as large
* as the largest number of columns in the input grid

      INTEGER NMAX
      PARAMETER (NMAX = 1024)

* Variables ending in an 'A' are associated with the latitude grid
* files while variables ending in an 'O' are associated with the
* longitude grid files.

      DOUBLE PRECISION LAT, LON, DLAT, DLON
      REAL XMIN, XMAX, YMIN, YMAX
      REAL ANGLE, SCR
      REAL DLATM, DLONM
      REAL BUFA(NMAX), BUFO(NMAX)
      INTEGER NCFRST, NCLAST, NRFRST, NRLAST, IMETR
      INTEGER NZ, LRECL, KIN, KOUT, NRPR1, NRPR2
      INTEGER IFLAG2, N2
      INTEGER I, I2, IDUM, IREC1, IREC2, J, JJ, J1, J2, NR2, NC2
      CHARACTER*56 RIDENT
      CHARACTER*32 FOUTA, FOUTO
      CHARACTER*8 PGM
      CHARACTER*1 ASCR

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

      REAL XMIN0, XMAX0, YMIN0, YMAX0, DX, DY
      INTEGER NC, NR
      COMMON /GRID0/ XMIN0, XMAX0, YMIN0, YMAX0, DX, DY, NR, NC

      DOUBLE PRECISION ZSUMA, ZSUMO, ZSQRA, ZSQRO
      REAL ZMINA, ZMINO, ZMAXA, ZMAXO
      COMMON /ZSTATS/ ZMINA, ZMAXA, ZMINO, ZMAXO,
     +                ZSUMA, ZSQRA, ZSUMO, ZSQRO

      DOUBLE PRECISION ZMSUMA, ZMSUMO, ZMSQRA, ZMSQRO
      REAL ZMMINA, ZMMINO, ZMMAXA, ZMMAXO
      COMMON /ZMSTAT/ ZMMINA, ZMMAXA, ZMMINO, ZMMAXO,
     +                ZMSUMA, ZMSQRA, ZMSUMO, ZMSQRO

      DATA IFLAG2 /2/

* Open output file, write header information, reopen for grid size

      ANGLE = 0.0
      RIDENT = 'NADCON EXTRACTED REGION'
      PGM = 'NADGRD'
      NZ = 1
      NR2 = NRLAST - NRFRST + 1
      NC2 = NCLAST - NCFRST + 1

      IF (KOUT .EQ. 1) THEN

* Binary output files

        LRECL = 4*(NC2 + 1)
        OPEN (NOUTA,FILE=FOUTA,FORM='UNFORMATTED',ACCESS='DIRECT',
     +        RECL=LRECL,STATUS='UNKNOWN')
        OPEN (NOUTO,FILE=FOUTO,FORM='UNFORMATTED',ACCESS='DIRECT',
     +        RECL=LRECL,STATUS='UNKNOWN')
        WRITE (NOUTA,REC=1) RIDENT, PGM, NC2, NR2, NZ, XMIN, DX,
     +                      YMIN, DY, ANGLE
        WRITE (NOUTO,REC=1) RIDENT, PGM, NC2, NR2, NZ, XMIN, DX,
     +                      YMIN, DY, ANGLE

      ELSEIF (KOUT .EQ. -1) THEN

* ASCII transfer format output files

        OPEN (NOUTA,FILE=FOUTA,FORM='FORMATTED',ACCESS='SEQUENTIAL',
     +        STATUS='UNKNOWN')
        OPEN (NOUTO,FILE=FOUTO,FORM='FORMATTED',ACCESS='SEQUENTIAL',
     +        STATUS='UNKNOWN')
        WRITE (NOUTA,140) RIDENT, PGM
        WRITE (NOUTO,140) RIDENT, PGM
  140   FORMAT (A56, A8)
        WRITE (NOUTA,150) NC2, NR2, NZ, XMIN, DX,
     +                    YMIN, DY, ANGLE
        WRITE (NOUTO,150) NC2, NR2, NZ, XMIN, DX,
     +                    YMIN, DY, ANGLE
  150   FORMAT (3I4, 5F12.5)

      ELSEIF (KOUT .EQ. -2) THEN

* ASCII graphics format output files (SURFER header information)

        OPEN (NOUTA,FILE=FOUTA,FORM='FORMATTED',ACCESS='SEQUENTIAL',
     +        STATUS='UNKNOWN')
        OPEN (NOUTO,FILE=FOUTO,FORM='FORMATTED',ACCESS='SEQUENTIAL',
     +        STATUS='UNKNOWN')
        WRITE (NOUTA,160)
        WRITE (NOUTO,160)
  160   FORMAT ('DSAA')
        WRITE (NOUTA,165) NC2, NR2
        WRITE (NOUTO,165) NC2, NR2
  165   FORMAT (2I12)
        WRITE (NOUTA,170) XMIN, XMAX
        WRITE (NOUTO,170) XMIN, XMAX
  170   FORMAT (2F12.4)
        WRITE (NOUTA,170) YMIN, YMAX
        WRITE (NOUTO,170) YMIN, YMAX
        IF (IMETR .EQ. 1) THEN
          WRITE (NOUTA,170) ZMINA, ZMAXA
          WRITE (NOUTO,170) ZMINO, ZMAXO
        ELSE
          WRITE (NOUTA,170) ZMMINA, ZMMAXA
          WRITE (NOUTO,170) ZMMINO, ZMMAXO
        ENDIF
      ENDIF

      CALL NBLANK (FOUTA, IFLAG2, N2)
      WRITE (LUOUT,80) FOUTA(1:N2), FOUTO(1:N2)
   80 FORMAT (/, ' NADGRD is now creating the ''', A, ''' and ''', A,
     +           ''' files.',
     +        /, ' This process may take several minutes.')

* number of ASCII rows per binary row (note that there are always
* an odd number of grid columns)

        IF (KIN .EQ. -1) THEN
          NRPR1 = NC/6 + 1

* For ASCII input files, skip up to the NRFRST equivalent row

          REWIND NINA
          REWIND NINO
          READ (NINA, '(A1)') ASCR
          READ (NINO, '(A1)') ASCR
          READ (NINA, '(A1)') ASCR
          READ (NINO, '(A1)') ASCR
          IF (NRFRST .GT. 1) THEN
            I2 = (NRFRST - 1)*NRPR1
            DO 210 I = 1, I2
              READ (NINA, 200) SCR
              READ (NINO, 200) SCR
  200         FORMAT (F12.6)
  210       CONTINUE
          ENDIF

        ENDIF

        IF (KOUT .EQ. -1) THEN
          NRPR2 = (NCLAST - NCFRST + 1)/6 + 1
        ELSEIF (KOUT .EQ. 1) THEN
          IREC2 = 1
        ENDIF

* Copy input files to output files

      DO 300 I = NRFRST, NRLAST

* read input file

        IF (KIN .EQ. 1) THEN
          IREC1 = I + 1
          READ (NINA,REC=IREC1) IDUM, (BUFA(J), J = 1, NC)
          READ (NINO,REC=IREC1) IDUM, (BUFO(J), J = 1, NC)
        ELSE
          DO 320 JJ = 1, NRPR1-1
            J1 = (JJ-1)*6 + 1
            J2 = J1 + 5
            READ (NINA, 310) (BUFA(J), J = J1, J2)
            READ (NINO, 310) (BUFO(J), J = J1, J2)
  310       FORMAT (6F12.6)
  320     CONTINUE
          J1 = J2 + 1
          READ (NINA, 310) (BUFA(J), J = J1, NC)
          READ (NINO, 310) (BUFO(J), J = J1, NC)
        ENDIF

* write output file

        IF (KOUT .EQ. 1) THEN
          IDUM = 0
          IREC2 = IREC2 + 1
          WRITE (NOUTA,REC=IREC2) IDUM, (BUFA(J), J = NCFRST, NCLAST)
          WRITE (NOUTO,REC=IREC2) IDUM, (BUFO(J), J = NCFRST, NCLAST)
        ELSEIF (KOUT .EQ. -1) THEN
          DO 420 JJ = 1, NRPR2-1
            J1 = (JJ-1)*6 + NCFRST
            J2 = J1 + 5
            WRITE (NOUTA, 310) (BUFA(J), J = J1, J2)
            WRITE (NOUTO, 310) (BUFO(J), J = J1, J2)
  420     CONTINUE
          J1 = J2 + 1
          WRITE (NOUTA, 310) (BUFA(J), J = J1, NCLAST)
          WRITE (NOUTO, 310) (BUFO(J), J = J1, NCLAST)
        ELSEIF (KOUT .EQ. -2) THEN
          IF (IMETR .EQ. -1) THEN

*** If the output graphics grids are to be in meters, then
*** translate the buffer contents

            LAT = (DBLE( I) - 1.D0)*DBLE(DY) + DBLE(YMIN0)
            DO 430 JJ = NCFRST, NCLAST
              LON = (DBLE(JJ) - 1.D0)*DBLE(DX) + DBLE(XMIN0)
              DLON = DBLE( BUFO(JJ) )
              DLAT = DBLE( BUFA(JJ) )
              CALL METER2 (LAT, LON, DLAT, DLON, DLATM, DLONM)
              BUFO(JJ) = DLONM
              BUFA(JJ) = DLATM
  430       CONTINUE
          ENDIF
          WRITE (NOUTA,440) (BUFA(J), J = NCFRST, NCLAST)
          WRITE (NOUTO,440) (BUFO(J), J = NCFRST, NCLAST)
  440     FORMAT (1024F12.6)
        ENDIF

  300 CONTINUE

      IF (KOUT .EQ. 1) THEN
        CALL NBLANK (FOUTA, IFLAG2, N2)
        WRITE (LUOUT,130) FOUTA(1:N2), FOUTO(1:N2)
  130   FORMAT (/, ' Binary files ''', A, ''' and ''', A, '''',
     +             ' have been created.')
      ELSEIF (KOUT .EQ. -1  .OR.  KOUT .EQ. -2) THEN
        CALL NBLANK (FOUTA, IFLAG2, N2)
        WRITE (LUOUT,135) FOUTA(1:N2), FOUTO(1:N2)
  135   FORMAT (/, ' ASCII files ''', A, ''' and ''', A, '''',
     +             ' have been created.')
      ENDIF

      RETURN
      END
      SUBROUTINE ZEXTRM (KIN, KOUT, NCFRST, NCLAST, NRFRST, NRLAST)

* Read from the input file to obtain the minimum and maximum Z
* values for the new grids, and other statistical values

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

* NMAX is the maximum size of the buffer.  It is at least as large
* as the largest number of columns in the input grid

      INTEGER NMAX
      PARAMETER (NMAX = 1024)

* Variables ending in an 'A' are associated with the latitude grid
* files while variables ending in an 'O' are associated with the
* longitude grid files.

      DOUBLE PRECISION AVEA, AVEO, SIGA, SIGO
      DOUBLE PRECISION AVEAM, AVEOM, SIGAM, SIGOM
      REAL BUFA(NMAX), BUFO(NMAX)
      REAL SCR
      INTEGER I2, NRPR1, JJ, J1, J2, NTOT
      INTEGER IREC, I, J, IDUM, KIN, KOUT, ILAST
      INTEGER NCFRST, NCLAST, NRFRST, NRLAST
      CHARACTER*1 ASCR

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

      DOUBLE PRECISION ZSUMA, ZSUMO, ZSQRA, ZSQRO
      REAL ZMINA, ZMINO, ZMAXA, ZMAXO
      COMMON /ZSTATS/ ZMINA, ZMAXA, ZMINO, ZMAXO,
     +                ZSUMA, ZSQRA, ZSUMO, ZSQRO

      DOUBLE PRECISION ZMSUMA, ZMSUMO, ZMSQRA, ZMSQRO
      REAL ZMMINA, ZMMINO, ZMMAXA, ZMMAXO
      COMMON /ZMSTAT/ ZMMINA, ZMMAXA, ZMMINO, ZMMAXO,
     +                ZMSUMA, ZMSQRA, ZMSUMO, ZMSQRO

      REAL XMIN0, XMAX0, YMIN0, YMAX0, DX, DY
      INTEGER NC, NR
      COMMON /GRID0/ XMIN0, XMAX0, YMIN0, YMAX0, DX, DY, NR, NC

* Initialize

      ZMINA = 9.9E10
      ZMAXA = -9.9E10
      ZMINO = 9.9E10
      ZMAXO = -9.9E10
      ZSUMA = 0.D0
      ZSQRA = 0.D0
      ZSUMO = 0.D0
      ZSQRO = 0.D0

      ZMMINA = 9.9E10
      ZMMAXA = -9.9E10
      ZMMINO = 9.9E10
      ZMMAXO = -9.9E10
      ZMSUMA = 0.D0
      ZMSQRA = 0.D0
      ZMSUMO = 0.D0
      ZMSQRO = 0.D0

      NTOT = 0

      IF (KOUT .NE. 0) THEN
        WRITE (LUOUT,80)
   80   FORMAT (/, ' NADGRD is now finding the maximum and minimum',
     +             ' shift values in the new grids.',
     +          /, ' This process may take several minutes.')
      ELSE
        WRITE (LUOUT,85)
   85   FORMAT (/, ' NADGRD is now finding the maximum and minimum',
     +             ' shift values in the input grids.',
     +          /, ' This process may take several minutes.')
      ENDIF

      IF (KIN .EQ. 1) THEN
        DO 300 I = NRFRST, NRLAST
          IREC = I + 1

          READ (NINA,REC=IREC) IDUM, (BUFA(J), J = 1, NC)
          READ (NINO,REC=IREC) IDUM, (BUFO(J), J = 1, NC)

          CALL ZSUMS (I, NCFRST, NCLAST, BUFA, BUFO)
          NTOT = NTOT + NCLAST - NCFRST + 1

  300   CONTINUE

      ELSEIF (KIN .EQ. -1) THEN

        NRPR1 = NC/6 + 1

* For ASCII input files, skip up to the NRFRST equivalent row

        REWIND NINA
        REWIND NINO
        READ (NINA, '(A1)') ASCR
        READ (NINO, '(A1)') ASCR
        READ (NINA, '(A1)') ASCR
        READ (NINO, '(A1)') ASCR
        IF (NRFRST .GT. 1) THEN
          I2 = (NRFRST - 1)*NRPR1
          DO 210 I = 1, I2
            READ (NINA, 200) SCR
            READ (NINO, 200) SCR
  200       FORMAT (F12.6)
  210     CONTINUE
        ENDIF

        ILAST = NRLAST - NRFRST + 1
        DO 340 I = 1, ILAST
          DO 320 JJ = 1, NRPR1-1
            J1 = (JJ-1)*6 + 1
            J2 = J1 + 5
            READ (NINA, 310) (BUFA(J), J = J1, J2)
            READ (NINO, 310) (BUFO(J), J = J1, J2)
  310       FORMAT (6F12.6)
  320     CONTINUE
          J1 = J2 + 1
          READ (NINA, 310) (BUFA(J), J = J1, NC)
          READ (NINO, 310) (BUFO(J), J = J1, NC)
          CALL ZSUMS (I, NCFRST, NCLAST, BUFA, BUFO)
          NTOT = NTOT + NCLAST - NCFRST + 1
  340   CONTINUE

      ENDIF

      AVEA = ZSUMA / NTOT
      AVEO = ZSUMO / NTOT
      SIGA = DSQRT(  ( DBLE(NTOT)*ZSQRA - ZSUMA*ZSUMA )/
     +       ( DBLE(NTOT)*DBLE(NTOT-1) )  )
      SIGO = DSQRT(  ( DBLE(NTOT)*ZSQRO - ZSUMO*ZSUMO )/
     +       ( DBLE(NTOT)*DBLE(NTOT-1) )  )

      AVEAM = ZMSUMA / NTOT
      AVEOM = ZMSUMO / NTOT
      SIGAM = DSQRT(  ( DBLE(NTOT)*ZMSQRA - ZMSUMA*ZMSUMA )/
     +       ( DBLE(NTOT)*DBLE(NTOT-1) )  )
      SIGOM = DSQRT(  ( DBLE(NTOT)*ZMSQRO - ZMSUMO*ZMSUMO )/
     +       ( DBLE(NTOT)*DBLE(NTOT-1) )  )

      WRITE (LUOUT, 500)
  500 FORMAT (/, 32X, 'SHIFT STATISTICS',
     +        /, 1X, 71('-'),
     +        /, 18X, 2(5X, 'Latitude', 5X, 'Longitude'),
     +        /, 27X, '(seconds of arc)', 13X, '(meters)')
      WRITE (LUOUT, 510) ZMINA, ZMINO, ZMMINA, ZMMINO
  510 FORMAT (' Minimum', 14X, F9.3, 5X, F9.3, 4X, F9.3, 5X, F9.3)
      WRITE (LUOUT, 520) ZMAXA, ZMAXO, ZMMAXA, ZMMAXO
  520 FORMAT (' Maximum', 14X, F9.3, 5X, F9.3, 4X, F9.3, 5X, F9.3)
      WRITE (LUOUT, 530) AVEA, AVEO, AVEAM, AVEOM
  530 FORMAT (/, ' Average', 14X, F9.3, 5X, F9.3, 4X, F9.3, 5X, F9.3)
      WRITE (LUOUT, 540) SIGA, SIGO, SIGAM, SIGOM
  540 FORMAT (' Standard Deviation', 3X, F9.3, 5X, F9.3, 4X, F9.3, 5X,
     +                                                             F9.3)

      IF (KOUT .EQ. 0) THEN
        WRITE (NOUTA, 500)
        WRITE (NOUTA, 510) ZMINA, ZMINO, ZMMINA, ZMMINO
        WRITE (NOUTA, 520) ZMAXA, ZMAXO, ZMMAXA, ZMMAXO
        WRITE (NOUTA, 530) AVEA, AVEO, AVEAM, AVEOM
        WRITE (NOUTA, 540) SIGA, SIGO, SIGAM, SIGOM
        WRITE (LUOUT,*)
      ENDIF

      RETURN
      END
      SUBROUTINE ZSUMS (I, NCFRST, NCLAST, BUFA, BUFO)

* Do the summations for the subroutine ZEXTRM

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

* NMAX is the maximum size of the buffer.  It is at least as large
* as the largest number of columns in the input grid

      INTEGER NMAX
      PARAMETER (NMAX = 1024)

* Variables ending in an 'A' are associated with the latitude grid
* files while variables ending in an 'O' are associated with the
* longitude grid files.

      DOUBLE PRECISION LAT, LON, DLAT, DLON
      REAL BUFA(NMAX), BUFO(NMAX)
      REAL ZA, ZO, DLATM, DLONM
      INTEGER K, I, NCFRST, NCLAST

      INTEGER LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO
      COMMON /INOUT/ LUIN, LUOUT, NINA, NINO, NOUTA, NOUTO

      DOUBLE PRECISION ZSUMA, ZSUMO, ZSQRA, ZSQRO
      REAL ZMINA, ZMINO, ZMAXA, ZMAXO
      COMMON /ZSTATS/ ZMINA, ZMAXA, ZMINO, ZMAXO,
     +                ZSUMA, ZSQRA, ZSUMO, ZSQRO

      DOUBLE PRECISION ZMSUMA, ZMSUMO, ZMSQRA, ZMSQRO
      REAL ZMMINA, ZMMINO, ZMMAXA, ZMMAXO
      COMMON /ZMSTAT/ ZMMINA, ZMMAXA, ZMMINO, ZMMAXO,
     +                ZMSUMA, ZMSQRA, ZMSUMO, ZMSQRO

      REAL XMIN0, XMAX0, YMIN0, YMAX0, DX, DY
      INTEGER NC, NR
      COMMON /GRID0/ XMIN0, XMAX0, YMIN0, YMAX0, DX, DY, NR, NC

      DO 400 K = NCFRST, NCLAST

*** seconds of arc statistics

        ZA = BUFA(K)
        ZO = BUFO(K)
        ZMINA = MIN(ZMINA, ZA)
        ZMAXA = MAX(ZMAXA, ZA)
        ZMINO = MIN(ZMINO, ZO)
        ZMAXO = MAX(ZMAXO, ZO)
        ZSUMA = ZSUMA + DBLE(ZA)
        ZSQRA = ZSQRA + DBLE(ZA*ZA)
        ZSUMO = ZSUMO + DBLE(ZO)
        ZSQRO = ZSQRO + DBLE(ZO*ZO)

*** now meters

        LON = (DBLE(K) - 1.D0)*DBLE(DX) + DBLE(XMIN0)
        LAT = (DBLE(I) - 1.D0)*DBLE(DY) + DBLE(YMIN0)
        DLON = DBLE(ZO)
        DLAT = DBLE(ZA)
        CALL METER2 (LAT, LON, DLAT, DLON, DLATM, DLONM)
        ZMMINA = MIN(ZMMINA, DLATM)
        ZMMAXA = MAX(ZMMAXA, DLATM)
        ZMMINO = MIN(ZMMINO, DLONM)
        ZMMAXO = MAX(ZMMAXO, DLONM)
        ZMSUMA = ZMSUMA + DBLE(DLATM)
        ZMSQRA = ZMSQRA + DBLE(DLATM*DLATM)
        ZMSUMO = ZMSUMO + DBLE(DLONM)
        ZMSQRO = ZMSQRO + DBLE(DLONM*DLONM)

  400 CONTINUE

      RETURN
      END
      REAL FUNCTION RCARD (CHLINE, LENG, IERR)

*** Read a real number from a line of card image.
*** LENG is the length of the card
*** blanks are the delimiters of the REAL*4 variable

*     IMPLICIT REAL (A-H, O-Z)
*     IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER LENG, IERR, I, J, ILENG
      REAL VAR
      CHARACTER*80 CHLINE

      IERR = 0

* Find first non-blank character

* DO WHILE line character is blank, I is first non-blank character

      I = 1
   10 IF ( CHLINE(I:I) .EQ. ' '  .OR.  CHLINE(I:I) .EQ. ',' ) THEN
        I = I + 1

* Check for totally blank card

        IF ( I .GE. LENG) THEN
          RCARD = 0.0E0
          LENG = 0
          RETURN
        ENDIF

      GOTO 10
      ENDIF

* Find first blank character (or end of line)

* DO WHILE line character is not a blank

      J = I + 1
   20 IF ( CHLINE(J:J) .NE. ' '  .AND.  CHLINE(J:J) .NE. ',' ) THEN
        J = J + 1

* Check for totally filed card

        IF ( J .GT. LENG) THEN
          GOTO 40
        ENDIF

      GOTO 20
      ENDIF

* J is now 1 more than the position of the last non-blank character

   40 J = J - 1

* ILENG is the length of the real string, it cannot be greater
* than 15 characters

      ILENG = J - I + 1

      IF (ILENG .GT. 15) THEN
        STOP 'RCARD'
      ENDIF

* Read the real variable from the line, and set the return VAR to it

      READ (CHLINE(I:J), 55, ERR=9999) VAR
   55 FORMAT (F15.0)
      RCARD = VAR

* Now reset the values of LENG and CHLINE to the rest of the card

      CHLINE( 1 : LENG ) = CHLINE( (J+1) : LENG )
      LENG = LENG - J

      RETURN

* Read error

 9999 IERR = 1
      RETURN
      END

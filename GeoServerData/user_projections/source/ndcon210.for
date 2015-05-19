      PROGRAM NADCON

***********************************************************************
*                                                                     *
* PROGRAM :   NADCON                                                  *
*                                                                     *
* PURPOSE:    COMPUTATION PROGRAM TO CONVERT (OR TRANSFORM)           *
*             POSITIONAL DATA (E.G., LATITUDES AND LONGITUDES) FROM   *
*             THE NORTH AMERICAN DATUM OF 1927 (NAD 27) TO THE        *
*             NORTH AMERICAN DATUM OF 1983 (NAD 83).  THIS PROGRAM    *
*             CAN COMPUTE FROM FROM EITHER DATUM TO THE OTHER.        *
*                                                                     *
*             THE ACTUAL COMPUTATION IS PERFORMED AS AN INTERPOLATION *
*             FROM A REGULARLY-SPACED GRID OF POINTS OBTAINED FROM THE*
*             FITTING OF A MINIMUM-CURVATURE SURFACE TO THE ACTUAL    *
*             SHIFT DATA RESULTING FROM THE NAD 83 ADJUSTMENT.        *
*                                                                     *
*             THE INTERPOLATION IS ACCOMPLISHED BY LOCALLY FITTING    *
*             A CURVED POLYNOMIAL SURFACE TO THE FOUR DATA POINTS     *
*             DEFINING THE SQUARE WHICH SURROUND THE (X,Y) PAIR       *
*             WHERE THE INTERPOLATION IS TO TAKE PLACE.               *
*                                                                     *
*             THE POLYNOMIAL SURFACE IS DEFINED BY:                   *
*                                                                     *
*                         A+BX+CY+DXY=Z                               *
*                                                                     *
*             THE PROGRAM REQUIRES THAT THE USER SPECIFY:             *
*                                                                     *
*             1)  THE NAME OF AN OUTPUT FILE                          *
*                                                                     *
*             2)  THE NAME OF AN INPUT FILE (IF AVAILABLE).           *
*                                                                     *
*                                                                     *
*                                                                     *
*             ESTIMATES OF DATUM SHIFTS IN TERMS OF METERS ARE        *
*             COMPUTED FROM THE SHIFT ESTIMATES USING ELLIPSOIDAL     *
*             SCALING.                                                *
*                                                                     *
*             THIS PROGRAM ALLOWS FOR EITHER NGS STANDARD HORIZONTAL  *
*             DATA FORMATS AS SPECIFIED IN THE FGCC PUBLICATION,      *
*             COMMONLY KNOWN AS THE 'HORIZONTAL BLUE BOOK' (SEE       *
*             SUBROUTINE TYPE3), OR IN A GENERIC FILE FORMAT (SEE     *
*             SUBROUTINE TYPE1 OR SUBROUTINE TYPE2).                  *
*                                                                     *
*             THE CODE CAN BE EASILY MODIFIED TO ACCOMMODATE CUSTOM   *
*             FILE SPECIFICATIONS BY MODIFYING SUBROUTINES: ENDREP,   *
*             GETPT, IPARMS, WRTPT, AND (OPTIONALLY) FHELP.           *
*                                                                     *
*                                                                     *
* VERSION CODE:  1.03                                                 *
*                                                                     *
* VERSION DATE:  APRIL 1, 1991                                        *
*                                                                     *
*        AUTHOR:   WARREN T. DEWHURST, PH.D.                          *
*                    LIEUTENANT COMMANDER, NOAA                       *
*                  ALICE R. DREW                                      *
*                    SENIOR GEODESIST, HORIZONTAL NETWORK BRANCH      *
*                  NATIONAL GEODETIC SURVEY, NOS, NOAA                *
*                  ROCKVILLE, MD   20852                              *

c version 2.10 - 1/20/92
c      added option to select HPGN grids and compute NAD 83 - HPGN
c      conversions - jmb
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

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION VRSION
      INTEGER MXAREA
c     PARAMETER (VRSION = 1.03D0, MXAREA = 8)
      PARAMETER (VRSION = 2.10D0, MXAREA = 8)

      DOUBLE PRECISION ADLAM, VDLAM, ADLOM, VDLOM
      DOUBLE PRECISION ADLAS, VDLAS, ADLOS, VDLOS
      DOUBLE PRECISION SDLAM, SDLAM2, SDLOM, SDLOM2
      DOUBLE PRECISION SDLAS, SDLAS2, SDLOS, SDLOS2
      DOUBLE PRECISION XSMALL, XBIG, YSMALL, YBIG
      DOUBLE PRECISION DLAM, DLOM, DLAS, DLOS
      DOUBLE PRECISION SMDLAM, BGDLAM, SMDLOM, BGDLOM
      DOUBLE PRECISION SMDLAS, BGDLAS, SMDLOS, BGDLOS
      INTEGER KEY, NCONV, IPAGE, ITYPE, IFILE
      LOGICAL PAGE, NODATA, SCREEN,dsel

      DOUBLE PRECISION DX, DY, XMAX, XMIN, YMAX, YMIN
      INTEGER NC, NAREA
      COMMON /GDINFO/ DX(MXAREA), DY(MXAREA), XMAX(MXAREA),
     +                XMIN(MXAREA), YMAX(MXAREA), YMIN(MXAREA),
     +                NC(MXAREA), NAREA

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

**********************
* INITIALIZE VARIABLES
**********************
      CALL INITL (SCREEN, PAGE, IPAGE, ITYPE,
     +            SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +            SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +            ADLAM, VDLAM, SDLAM, SDLAM2,
     +            ADLOM, VDLOM, SDLOM, SDLOM2,
     +            ADLAS, VDLAS, SDLAS, SDLAS2,
     +            ADLOS, VDLOS, SDLOS, SDLOS2,
     +            XSMALL, XBIG, YSMALL, YBIG,dsel)

**************************
* PRINT HEADER INFORMATION
**************************

      CALL HEADR (VRSION)
c
c *********************************
c Print Main Menu; Get Datum Option
c *********************************

    1	CALL menu (dsel)

C *********************************

******************************************************** 
* OPEN NADCON DATA FILES (LATITUDE AND LONGITUDE GRIDS)
*******************************************************

       CALL NGRIDS (NODATA,dsel,VRSION)
       IF (NODATA) GOTO 1

******************************************************
* REQUEST FOR THE NEEDED VARIABLE VALUES FROM THE USER
******************************************************

      CALL IPARMS (KEY, ITYPE, SCREEN,dsel)
*********************************
* LOOP (ONCE FOR EACH CONVERSION)
*********************************

      CALL MLOOP (NCONV, IPAGE, ITYPE, KEY, VRSION,
     +            DLAM, DLOM, DLAS, DLOS,
     +            SDLAM, SDLAM2, SDLOM, SDLOM2,
     +            SDLAS, SDLAS2, SDLOS, SDLOS2,
     +            SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +            SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +            XSMALL, XBIG, YSMALL, YBIG,
     +            PAGE, SCREEN,dsel)

**********************************************
* FINISHED WITH ALL CONVERSIONS - WRITE REPORT
**********************************************

      CALL ENDREP (IPAGE, NCONV, KEY, ITYPE,
     +             DLAM, DLOM, DLAS, DLOS,
     +             ADLAM, ADLOM, VDLAM, VDLOM,
     +             ADLAS, ADLOS, VDLAS, VDLOS,
     +             SDLAM, SDLAM2, SDLOM, SDLOM2,
     +             SDLAS, SDLAS2, SDLOS, SDLOS2,
     +             SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +             SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +             XSMALL, XBIG, YSMALL, YBIG,dsel)

*****************
* CLOSE ALL FILES
*****************

      DO 1010 IFILE = 1, 2*NAREA
        CLOSE (LUAREA(IFILE), STATUS='KEEP')
 1010 CONTINUE
      CLOSE (NIN, STATUS='KEEP')
      CLOSE (NOUT, STATUS='KEEP')
      CLOSE (NAPAR, STATUS='KEEP')

      go to 1

 9999 STOP
      END
      SUBROUTINE HEADR (VRSION)

*** This subroutine prints the header information and the disclaimer

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)

      DOUBLE PRECISION VRSION
      CHARACTER*1 ANS

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      WRITE (LUOUT,920)
  920 FORMAT (10X,'                   Welcome', /,
     +    10X,    '                   to  the', /,
     +    10X,    '          National Geodetic Survey', /,
     +    10X,    '  North American Datum Conversion program.', //,
     +    10X,    ' For use when NAD 27 latitude and longitudes', /,
     +    10X,    '            need to be converted', /,
     +    10X,    '   to NAD 83 latitude and longitude values', /,
     +    10X,    '                     or', /,
     +    10X,    ' for use when NAD 83 latitude and longitudes', /,
     +    10X,    '            need to be converted', /,
     +    10X,    '  to NAD 27 latitude and longitude values.', /)

      WRITE (LUOUT,931)
      READ (LUIN,'(A1)') ANS
      WRITE (LUOUT,2)
      write(LUOUT,*) ' '
      write(LUOUT,921)
c...v....1....v....2....v....3....v....4....v....5....v....6....v....7....v....8....v....9....v....0....v....1....v....2
  921 format (10x,'              Additional Option',//,
     +        10x,' For use when NAD83 (1986) latitudes and longitudes',
     + /,
     +        10x,'             need to be converted',/,
     +        10x,'to applicable state HPGN latitude and longitude ',
     + 'values',/,
     +        10x,'                    or',/,
     +        10x,'    for use when HPGN latitudes and longitudes',/,
     +        10x,'             need to be converted',/,
     +        10x,'  to NAD 83 (1986) latitude and longitude values.',/)

      WRITE (LUOUT,931)
      READ (LUIN,'(A1)') ANS
      WRITE (LUOUT,2)

      WRITE (LUOUT,930) VRSION
  930 FORMAT (//,10X,'               (Version ', F5.2, ')', /,
c    +       10X,    '                April 1, 1991', /,
     +       10X,    '              January 15, 1992',/,
     +       10X,    '          Warren T. Dewhurst, Ph.D.', /,
     +       10X,    '         Lieutenant Commander, NOAA', /,
     +       10X,    '               Alice R. Drew', /,
     +       10X,   ' Senior Geodesist, Horizontal Network Branch', /,
     +       10X,    '             Janice M. Bengston',/,
     +       10x,    '        Geodesist, Horizontal Network Branch',/)

      WRITE (LUOUT,931)
  931 FORMAT (10X,    '          (Hit RETURN to continue.)')

      READ (LUIN,'(A1)') ANS
      WRITE (LUOUT,2)
*   2 FORMAT ('1')
    2 FORMAT ('')

      WRITE (LUOUT,932)
  932 FORMAT (/, '                           DISCLAIMER', //,
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
      WRITE (LUOUT,2)

      RETURN
      END
      SUBROUTINE INITL (SCREEN, PAGE, IPAGE, ITYPE,
     +                  SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +                  SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +                  ADLAM, VDLAM, SDLAM, SDLAM2,
     +                  ADLOM, VDLOM, SDLOM, SDLOM2,
     +                  ADLAS, VDLAS, SDLAS, SDLAS2,
     +                  ADLOS, VDLOS, SDLOS, SDLOS2,
     +                  XSMALL, XBIG, YSMALL, YBIG,dsel)

*** This subroutine initializes all the variables needed in NADCON

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)
      CHARACTER*20 B20
      CHARACTER*80 B80
      PARAMETER (B20 = '                   ', B80 = B20//B20//B20//B20)

      DOUBLE PRECISION ADLAM, VDLAM, ADLOM, VDLOM
      DOUBLE PRECISION ADLAS, VDLAS, ADLOS, VDLOS
      DOUBLE PRECISION SDLAM, SDLAM2, SDLOM, SDLOM2
      DOUBLE PRECISION SDLAS, SDLAS2, SDLOS, SDLOS2
      DOUBLE PRECISION XSMALL, XBIG, YSMALL, YBIG
      DOUBLE PRECISION SMDLAM, BGDLAM, SMDLOM, BGDLOM
      DOUBLE PRECISION SMDLAS, BGDLAS, SMDLOS, BGDLOS
      INTEGER IPAGE, ITYPE
      LOGICAL PAGE, SCREEN, dsel

      CHARACTER*80 CARD
      COMMON /CURNT/ CARD

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

* Initialize card variable in common CURNT to blank

      CARD = B80

* Set the logical units for input/output common INOUT
* Note that the unit numbers for the data grids (LUAREA) are defined
* in subroutine OPENFL as the numbers 11 through 2*MXAREA

      LUIN  = 5
      LUOUT = 6
      NOUT  = 101
      NIN   = 102
      NAPAR = 103

******************************************************************
*                             INITIALIZE
******************************************************************

* Defaults: SCREEN = .TRUE. => send results to screen
*           PAGE = .FALSE.  => don't start a new page in the output file
*           IPAGE = 0       => current output file page number is 0
*           ITYPE = 0       => interactive input of points
*           dsel  = .FALSE. => select NAD 83, HPGN datum conversion

      SCREEN = .TRUE.
      PAGE = .FALSE.
      IPAGE = 0
      ITYPE = 0
      dsel = .FALSE.

      SMDLAM =  1.0D10
      BGDLAM = -1.0D10
      SMDLOM =  1.0D10
      BGDLOM = -1.0D10
      SMDLAS =  1.0D10
      BGDLAS = -1.0D10
      SMDLOS =  1.0D10
      BGDLOS = -1.0D10

      ADLAM = 0.0D0
      VDLAM = 0.0D0
      SDLAM = 0.0D0
      SDLAM2 = 0.0D0
      ADLOM = 0.0D0
      VDLOM = 0.0D0
      SDLOM = 0.0D0
      SDLOM2 = 0.0D0

      ADLAS = 0.0D0
      VDLAS = 0.0D0
      SDLAS = 0.0D0
      SDLAS2 = 0.0D0
      ADLOS = 0.0D0
      VDLOS = 0.0D0
      SDLOS = 0.0D0
      SDLOS2 = 0.0D0

      XSMALL =  1.0D10
      XBIG   = -1.0D10
      YSMALL =  1.0D10
      YBIG   = -1.0D10

      RETURN
      END
      SUBROUTINE ASKPT (NCONV, KEY, NAME, IDLA, IMLA, SLA,
     +                  IDLO, IMLO, SLO, XPT, YPT, EOF, NOPT,dsel)

* Interactively ask for the name and location of a point

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)

      DOUBLE PRECISION XPT, YPT, RDLA, RDLO, DCARD
      DOUBLE PRECISION RMLA, RMLO, SLA, SLO
      INTEGER NCONV, KEY
      INTEGER IDLA, IMLA, IDLO, IMLO
      INTEGER IFLAG1, IFLAG2, N1, N2, IOS, LENG, IERR
      CHARACTER*80 NAME
      CHARACTER*40 ANS, B40, DUM
      LOGICAL EOF, NOPT,dsel

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      DATA IFLAG1 /1/, IFLAG2 /2/
      DATA B40 /'                                        '/
      NAME = '    '
      WRITE (LUOUT,*) ' What is the NAME for this station or',
     +                ' point?'
      READ (LUIN,'(A80)') NAME

**********
* LATITUDE
**********

      IF (NCONV .EQ. 0) THEN
        WRITE (LUOUT,110)
  110   FORMAT (/, ' Latitudes and Longitudes may be entered',
     +          ' in three formats:', /,
     +          '   (1) degrees, minutes, and decimal seconds, OR', /,
     +          '   (2) degrees, and decimal minutes OR', /,
     +          '   (3) decimal degrees.', /,
     +          ' Degrees, minutes and seconds may be separated',
     +          ' by blanks or commas.', /,
     +          ' A latitude or longitude of 0 will end data',
     +          ' entry.', /)
      ENDIF
      IF (KEY .EQ. 1) THEN
	IF(dsel) then
          WRITE (LUOUT,*) ' What is its NAD 27 latitude?'
	ELSE
	  WRITE (LUOUT,*) ' What is its NAD 83 latitude?'
	END IF
        WRITE (LUOUT,*) ' '
      ELSEIF (KEY .EQ. -1) THEN
        IF (NCONV .EQ. 1) THEN
          WRITE (LUOUT,110)
        ENDIF
	IF(dsel) then
	   
           WRITE (LUOUT,*) ' What is its NAD 83 latitude?'
	ELSE
	   WRITE (LUOUT,*) ' What is its HPGN latitude?'
	END IF
           WRITE (LUOUT,*) ' '
      ENDIF
      READ (LUIN,170,ERR=9930,IOSTAT=IOS) ANS
  170 FORMAT (A40)
      IF (ANS .EQ. B40) GOTO 9999

      DUM = ANS
      CALL NBLANK (DUM, IFLAG2, N2)
      LENG = N2
      RDLA = DCARD( DUM(1:N2), LENG, IERR )
      IF (IERR .NE. 0) GOTO 9950
      IF (LENG .GT. 0) THEN

        RMLA = DCARD( DUM, LENG, IERR )
        IF (IERR .NE. 0) GOTO 9950

        IF (LENG .GT. 0) THEN
          SLA  = DCARD( DUM, LENG, IERR )
          IF (IERR .NE. 0) GOTO 9950
        ELSE
          SLA = 0.D0
        ENDIF

      ELSE
        RMLA = 0.D0
        SLA = 0.D0
      ENDIF

      IF ( (RDLA .EQ. 0.D0)  .AND.  (RMLA .EQ. 0.D0)  .AND.
     +     (SLA .EQ. 0.D0) ) GOTO 9999

* Check for illogical values

      IF (RDLA .LT.   0.D0) GOTO 9940
      IF (RDLA .GT.  90.D0) GOTO 9950
      IF (RMLA .LT. 0.D0  .OR.  RMLA .GT. 60.D0) GOTO 9950
      IF ( SLA .LT. 0.D0  .OR.   SLA .GT. 60.D0) GOTO 9950

***********
* LONGITUDE
***********

      IF (KEY .EQ. 1) THEN
        WRITE (LUOUT,*) ' '
       IF(dsel) then
        WRITE (LUOUT,*) ' What is its NAD 27 longitude?',
     +                  '  (Longitude is positive west.)'
       ELSE
        WRITE (LUOUT,*) ' What is its NAD 83 longitude?',
     +                  '  (Longitude is positive west.)'
       END IF
        WRITE (LUOUT,*) ' '
      ELSEIF (KEY .EQ. -1) THEN
        WRITE (LUOUT,*) ' '
       IF(dsel) then
        WRITE (LUOUT,*) ' What is its NAD 83 longitude?',
     +                  '  (Longitude is positive west.)'
       ELSE
        WRITE (LUOUT,*) ' What is its HPGN longitude?',
     +                  '  (Longitude is positive west.)'
       END IF
      ENDIF

      READ (LUIN,170,ERR=9930,IOSTAT=IOS) ANS
      IF (ANS .EQ. B40) GOTO 9999

      DUM = ANS
      CALL NBLANK (DUM, IFLAG2, N2)
      LENG = N2
      RDLO = DCARD( DUM(1:N2), LENG, IERR )
      IF (IERR .NE. 0) GOTO 9960
      IF (LENG .GT. 0) THEN

        RMLO = DCARD( DUM, LENG, IERR )
        IF (IERR .NE. 0) GOTO 9960

        IF (LENG .GT. 0) THEN
          SLO  = DCARD( DUM, LENG, IERR )
          IF (IERR .NE. 0) GOTO 9960
        ELSE
          SLO = 0.D0
        ENDIF

      ELSE
        RMLO = 0.D0
        SLO = 0.D0
      ENDIF

      IF ( (RDLO .EQ. 0.D0)  .AND.  (RMLO .EQ. 0.D0)  .AND.
     +     (SLO .EQ. 0.D0) ) GOTO 9999

* Check for illogical values

      IF (RDLO .LT.   0.D0) GOTO 9940
      IF (RDLO .GT. 360.D0) GOTO 9960
      IF (RMLO .LT. 0.D0  .OR.  RMLO .GT. 60.D0) GOTO 9960
      IF ( SLO .LT. 0.D0  .OR.   SLO .GT. 60.D0) GOTO 9960

* Calculate decimal degrees

      YPT = RDLA + RMLA/60.D0 + SLA/3600.D0
      XPT = RDLO + RMLO/60.D0 + SLO/3600.D0

* Get degrees, minutes, seconds

      CALL HMS (YPT, IDLA, IMLA, SLA)
      CALL HMS (XPT, IDLO, IMLO, SLO)

 9000 RETURN

* Error messages

 9930 CONTINUE
      CALL NBLANK (ANS, IFLAG1, N1)
      CALL NBLANK (ANS, IFLAG2, N2)
      WRITE (LUOUT,9935) ANS(N1:N2)
 9935 FORMAT (' ERROR - in the answer:', /,
     +        9X, '''', A, '''', /,
     +        '         Must enter number in prescribed format!', /)
      NOPT = .TRUE.
      GOTO 9000

 9940 CONTINUE
      CALL NBLANK (ANS, IFLAG1, N1)
      CALL NBLANK (ANS, IFLAG2, N2)
      WRITE (LUOUT,9945) ANS(N1:N2)
 9945 FORMAT (' ERROR - in the answer:', /,
     +        9X, '''', A, '''', /,
     +        '         Latitude and Longitudes must be positive!', /,
     +        '         Longitude is positive west.', /)
      NOPT = .TRUE.
      GOTO 9000

 9950 CONTINUE
      CALL NBLANK (ANS, IFLAG1, N1)
      CALL NBLANK (ANS, IFLAG2, N2)
      WRITE (LUOUT,9955) ANS(N1:N2)
 9955 FORMAT (' ERROR - Illogical value for latitude in the answer:', /,
     +        '         ''', A, '''', /,
     +        '         Latitude must be between 0 and 90 degrees.', /,
     +        '         Minutes and seconds must be between 0',
     +                                                    ' and 60.', /)
      NOPT = .TRUE.
      GOTO 9000

 9960 CONTINUE
      CALL NBLANK (ANS, IFLAG1, N1)
      CALL NBLANK (ANS, IFLAG2, N2)
      WRITE (LUOUT,9965) ANS(N1:N2)
 9965 FORMAT (' ERROR - Illogical value for longitude in the answer:',/,
     +        '         ''', A, '''', /,
     +        '         Longitude must be between 0 and 360 degrees.',/,
     +        '         Minutes and seconds must be between 0',
     +                                                    ' and 60.', /)
      NOPT = .TRUE.
      GOTO 9000

 9999 CONTINUE
      EOF = .TRUE.
      GOTO 9000
      END
      CHARACTER*(*) FUNCTION CCARD (CHLINE, LENG, IERR)

*** Read a character variable from a line of card image.
*** LENG is the length of the card
*** blanks are the delimiters of the character variable

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER LENG, IERR, I, J, ILENG
      CHARACTER*80 CHLINE

      IERR = 0

* Find first non-blank character

* DO WHILE line character is blank, I is first non-blank character

      I = 1
   10 IF ( CHLINE(I:I) .EQ. ' '  .OR.  CHLINE(I:I) .EQ. ',' ) THEN
        I = I + 1

* Check for totally blank card (assume length of 2)

        IF ( I .GE. LENG) THEN

         CCARD = '  '
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

* ILENG is the length of the character string, it can be any length
* up to the length of the line

      ILENG = J - I + 1

      IF (ILENG .GT. LENG) THEN
        STOP 'CCARD'
      ENDIF

* Read the char variable from the line, and set the return VAR to it

c     READ (CHLINE(I:J), 55, ERR=9999) CCARD
c  55 FORMAT (A80)

* Now reset the values of LENG and CHLINE to the rest of the card

c     CHLINE( 1 : LENG ) = CHLINE( (J+1) : LENG )
c     LENG = LENG - J
c set ccard = to the non blank portion of chline
	CCARD = ' '
	CCARD(1:ILENG) = CHLINE(I:J)
	RETURN

* Read error

 9999 IERR = 1
      RETURN
      END
      SUBROUTINE COEFF (TEE1, TEE2, TEE3, TEE4, AY, BEE, CEE, DEE)

**********************************************************************
** SUBROUTINE COEFF: GENERATES COEFFICIENTS FOR SURFACE FUNCTION     *
**********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION AY, BEE, CEE, DEE
      DOUBLE PRECISION TEE1, TEE2, TEE3, TEE4

      AY = TEE1
      BEE = TEE3 - TEE1
      CEE = TEE2 - TEE1
      DEE = TEE4 - TEE3 - TEE2 + TEE1

      RETURN
      END
      DOUBLE PRECISION FUNCTION DCARD (CHLINE, LENG, IERR)

*** Read a double precision number from a line of card image.
*** LENG is the length of the card
*** blanks are the delimiters of the REAL*8 variable

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION VAR
      INTEGER LENG, IERR, I, J, ILENG
      CHARACTER*80 CHLINE

      IERR = 0

* Find first non-blank character

* DO WHILE line character is blank, I is first non-blank character

      I = 1
   10 IF ( CHLINE(I:I) .EQ. ' '  .OR.  CHLINE(I:I) .EQ. ',' ) THEN
        I = I + 1

* Check for totally blank card

        IF ( I .GE. LENG) THEN
          DCARD = 0.0D0
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

* ILENG is the length of the real*8 string, it cannot be greater
* than 15 characters

      ILENG = J - I + 1

      IF (ILENG .GT. 20) THEN
        STOP 'DCARD'
      ENDIF

* Read the real*8 variable from the line, and set the return VAR to it

      READ (CHLINE(I:J), 55, ERR=9999) VAR
   55 FORMAT (F20.0)
      DCARD = VAR

* Now reset the values of LENG and CHLINE to the rest of the card

      CHLINE( 1 : LENG ) = CHLINE( (J+1) : LENG )
      LENG = LENG - J

      RETURN

* Read error

 9999 IERR = 1
      RETURN
      END
      SUBROUTINE DGRIDS

* This subroutine opens the NADCON grids using the default grid
* names and locations.  The default names of the grid areas are
* given in DAREAS and the default base file locations are in DFILES

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA, MXDEF
      PARAMETER (MXAREA = 8, MXDEF = MXAREA)
      CHARACTER*80 B80
      CHARACTER*65 B65
      CHARACTER*20 B20
      PARAMETER (B20 = '                   ', B80 = B20//B20//B20//B20)
      PARAMETER (B65 = B20//B20//B20//'     ')

      DOUBLE PRECISION XMAX1, XMIN1, YMAX1, YMIN1
      DOUBLE PRECISION DX1, DY1
      INTEGER IDEF, ITEMP, NC1
      CHARACTER*80 DUM
      CHARACTER*65 AFILE, DFILES(MXAREA)
      CHARACTER*15 DAREAS(MXDEF)
      LOGICAL NOGO, GFLAG

      CHARACTER*15 AREAS
      COMMON /AREAS/ AREAS(MXAREA)

      DOUBLE PRECISION DX, DY, XMAX, XMIN, YMAX, YMIN
      INTEGER NC, NAREA
      COMMON /GDINFO/ DX(MXAREA), DY(MXAREA), XMAX(MXAREA),
     +                XMIN(MXAREA), YMAX(MXAREA), YMIN(MXAREA),
     +                NC(MXAREA), NAREA

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      DATA DUM / B80 /

* DFILES contains the default locations (pathname) of the grid files
* without the .las and .los extensions. (For example 'conus' would
* indicate that the conus.las and conus.los grid files are in the
* current working directory.)  The length of each entry in DFILES may
* be up to 65 characters.  DAREAS contains the default names of these
* areas.  The names are used internally in the program and in the
* program output.  They may be no longer than 15 characters.  They
* must correspond on a one-to-one basis with the file locations in
* the DFILES array.  That is, the first area name in DAREAS must
* be the name that you wish for the first data file set in the
* DFILES array.  You may, of course, have the arrays the same if
* the location of the data file is no longer than 15 characters.
* The locations of the grid files may be differ for each
* installation.  If the pathnames are not correct DFILES (and, possibly,
* DAREAS) may be changed and the program recompiled.

      DATA DFILES /'conus', 'hawaii', 'prvi',
     +             'stlrnc', 'stgeorge', 'stpaul', 'alaska', ' '/
      DATA DAREAS /'Conus', 'Hawaii', 'P.R. and V.I.',
     +             'St. Laurence I.', 'St. George I.', 'St. Paul I.',
     +             'Alaska', ' '/

      GFLAG = .FALSE.
      WRITE (LUOUT, 80)
   80 FORMAT (/, '      Default Data Grids', /,
     +           '   #  AREA NAME', /, 1X, 79('=') )

      DO 140 IDEF = 1, MXDEF
        AFILE = DFILES(IDEF)
        IF (AFILE .EQ. B65) GOTO 999

* Try to open a set of default files.
* Do not print error messages for non-existing files.

        ITEMP = NAREA + 1
        CALL OPENFL (AFILE, ITEMP, GFLAG, NOGO, DX1, DY1,
     +               XMAX1, XMIN1, YMAX1, YMIN1, NC1, DUM)

        IF (.NOT. NOGO) THEN

* Set of files opened OK and variables read

          NAREA = ITEMP
          AREAS(NAREA) = DAREAS(IDEF)
          DX(NAREA) = DX1
          DY(NAREA) = DY1
          XMAX(NAREA) = XMAX1
          XMIN(NAREA) = XMIN1
          YMAX(NAREA) = YMAX1
          YMIN(NAREA) = YMIN1
          NC(NAREA) = NC1

          WRITE (LUOUT,120) NAREA, AREAS(NAREA)
  120     FORMAT (2X, I2, 2X, A15)

        ENDIF

  140 CONTINUE

  999 RETURN
      END
      SUBROUTINE DIAGRM (LU, NCONV, XSMALL, XBIG, YSMALL, YBIG,
     +   KEY,dsel)

* This subroutine prints out a small diagram showing the area
* that was transformed.

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION XTEMP, XSMALL, XBIG, YSMALL, YBIG
      DOUBLE PRECISION SLOMIN, SLOMAX, SLAMIN, SLAMAX
      INTEGER LODMIN, LOMMIN, LODMAX, LOMMAX
      INTEGER LADMIN, LAMMIN, LADMAX, LAMMAX
      INTEGER LU, NCONV, KEY
      LOGICAL dsel


      IF (KEY .EQ. -1) THEN
        XTEMP = XSMALL
        XSMALL = XBIG
        XBIG = XTEMP
        CALL HMS (XBIG,   LODMIN, LOMMIN, SLOMIN)
        CALL HMS (XSMALL, LODMAX, LOMMAX, SLOMAX)
      ELSE
        CALL HMS (-XBIG,   LODMIN, LOMMIN, SLOMIN)
        CALL HMS (-XSMALL, LODMAX, LOMMAX, SLOMAX)
      ENDIF
      CALL HMS (YSMALL, LADMIN, LAMMIN, SLAMIN)
      CALL HMS (YBIG,   LADMAX, LAMMAX, SLAMAX)

      WRITE (LU,90) NCONV
   90 FORMAT (//, ' The total number of conversions: ', I8)
      WRITE (LU,100)
  100 FORMAT (//, 30X, 'Region of Conversions')
      if(dsel) then
      WRITE (LU,1000) LODMAX, LOMMAX, SLOMAX, LODMIN, LOMMIN, SLOMIN,
     +                LADMAX, LAMMAX, SLAMAX, LADMAX, LAMMAX, SLAMAX,
     +                LADMIN, LAMMIN, SLAMIN, LADMIN, LAMMIN, SLAMIN,
     +                LODMAX, LOMMAX, SLOMAX, LODMIN, LOMMIN, SLOMIN
      else
      WRITE (LU,1001) LODMAX, LOMMAX, SLOMAX, LODMIN, LOMMIN, SLOMIN,
     +                LADMAX, LAMMAX, SLAMAX, LADMAX, LAMMAX, SLAMAX,
     +                LADMIN, LAMMIN, SLAMIN, LADMIN, LAMMIN, SLAMIN,
     +                LODMAX, LOMMAX, SLOMAX, LODMIN, LOMMIN, SLOMIN
      end if

 1000 FORMAT (5(/), T4, 'NAD 27', /,
     +       T4, 'Longitude:', 8X, I4, 1X, I2.2, 1X, F6.3, 13X, I4, 1X,
     +       I2.2, 1X, F6.3, /,
     +       T4, 'Latitude:', 9X, I4, 1X, I2.2, 1X, F6.3,
     +       ' ************', I4, 1X, I2.2, 1X, F6.3, /,
     +       5(T27, 3X, '*', T57, '*', /),
     +       T27, 3X, '*', 9X, ' NAD 27', T57, '*', /,
     +       T27, 3X, '*', 9X, '  data ', T57, '*', /,
     +       T27, 3X, '*', 9X, ' points', T57, '*', /,
     +       5(T27, 3X, '*', T57, '*', /),
     +       T4, 'Latitude:', 9X, I4, 1X, I2.2, 1X, F6.3,
     +       ' ************', I4, 1X, I2.2, 1X, F6.3, /,
     +       T4, 'Longitude:', 8X, I4, 1X, I2.2, 1X, F6.3, 13X, I4, 1X,
     +       I2.2, 1X, F6.3, //)

 1001 FORMAT (5(/), T4, 'NAD 83', /,
     +       T4, 'Longitude:', 8X, I4, 1X, I2.2, 1X, F6.3, 13X, I4, 1X,
     +       I2.2, 1X, F6.3, /,
     +       T4, 'Latitude:', 9X, I4, 1X, I2.2, 1X, F6.3,
     +       ' ************', I4, 1X, I2.2, 1X, F6.3, /,
     +       5(T27, 3X, '*', T57, '*', /),
     +       T27, 3X, '*', 9X, ' NAD 83', T57, '*', /,
     +       T27, 3X, '*', 9X, '  data ', T57, '*', /,
     +       T27, 3X, '*', 9X, ' points', T57, '*', /,
     +       5(T27, 3X, '*', T57, '*', /),
     +       T4, 'Latitude:', 9X, I4, 1X, I2.2, 1X, F6.3,
     +       ' ************', I4, 1X, I2.2, 1X, F6.3, /,
     +       T4, 'Longitude:', 8X, I4, 1X, I2.2, 1X, F6.3, 13X, I4, 1X,
     +       I2.2, 1X, F6.3, //)
      RETURN
      END
      SUBROUTINE ENDREP (IPAGE, NCONV, KEY, ITYPE,
     +                   DLAM, DLOM, DLAS, DLOS,
     +                   ADLAM, ADLOM, VDLAM, VDLOM,
     +                   ADLAS, ADLOS, VDLAS, VDLOS,
     +                   SDLAM, SDLAM2, SDLOM, SDLOM2,
     +                   SDLAS, SDLAS2, SDLOS, SDLOS2,
     +                   SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +                   SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +                   XSMALL, XBIG, YSMALL, YBIG,dsel)

*** Gather statistics and write the end-of-program report

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)

      DOUBLE PRECISION ADLAM, VDLAM, ADLOM, VDLOM
      DOUBLE PRECISION ADLAS, VDLAS, ADLOS, VDLOS
      DOUBLE PRECISION SDLAM, SDLAM2, SDLOM, SDLOM2
      DOUBLE PRECISION SDLAS, SDLAS2, SDLOS, SDLOS2
      DOUBLE PRECISION XSMALL, XBIG, YSMALL, YBIG
      DOUBLE PRECISION DLAM, DLOM, DLAS, DLOS
      DOUBLE PRECISION SMDLAM, BGDLAM, SMDLOM, BGDLOM
      DOUBLE PRECISION SMDLAS, BGDLAS, SMDLOS, BGDLOS
      INTEGER IPAGE, NCONV, KEY, ITYPE, LU, I
      LOGICAL PAGE,dsel

      DOUBLE PRECISION DX, DY, XMAX, XMIN, YMAX, YMIN
      INTEGER NC, NAREA
      COMMON /GDINFO/ DX(MXAREA), DY(MXAREA), XMAX(MXAREA),
     +                XMIN(MXAREA), YMAX(MXAREA), YMIN(MXAREA),
     +                NC(MXAREA), NAREA

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      PAGE = .TRUE.
      IPAGE = IPAGE + 1

*******************
* DO THE STATISTICS
*******************

      IF (NCONV .GE. 2) THEN

* calculate mean, variance, standard deviation for both latitude and
* longitude in both meters and seconds of arc.

**********
* LATITUDE
**********

        ADLAM = SDLAM/DBLE(NCONV)
        VDLAM = SDLAM2/DBLE(NCONV-1) - SDLAM**2/DBLE( NCONV*(NCONV-1) )
        ADLAS = SDLAS/DBLE(NCONV)
        VDLAS = SDLAS2/DBLE(NCONV-1) - SDLAS**2/DBLE( NCONV*(NCONV-1) )

        IF (VDLAM .GT. 1.0D-6) THEN
          SDLAM = DSQRT(VDLAM)
        ELSE
          VDLAM = 0.0D0
          SDLAM = 0.0D0
        ENDIF

        IF (VDLAS .GT. 1.0D-6) THEN
          SDLAS = DSQRT(VDLAS)
        ELSE
          VDLAS = 0.0D0
          SDLAS = 0.0D0
        ENDIF

***********
* LONGITUDE
***********

        ADLOM = SDLOM/DBLE(NCONV)
        VDLOM = SDLOM2/DBLE(NCONV-1) - SDLOM**2/DBLE( NCONV*(NCONV-1 ))

        ADLOS = SDLOS/DBLE(NCONV)
        VDLOS = SDLOS2/DBLE(NCONV-1) - SDLOS**2/DBLE( NCONV*(NCONV-1 ))

        IF (VDLOM .GT. 1.0D-6) THEN
          SDLOM = DSQRT(VDLOM)
        ELSE
          VDLOM = 0.0D0
          SDLOM = 0.0
        ENDIF

        IF (VDLOS .GT. 1.0D-6) THEN
          SDLOS = DSQRT(VDLOS)
        ELSE
          VDLOS = 0.0D0
          SDLOS = 0.0
        ENDIF

      ELSEIF (NCONV .LT. 2) THEN
        ADLAM = DLAM
        ADLOM = DLOM
        VDLOM = 0.0D0
        SDLOM = 0.0D0
        VDLAM = 0.0D0
        SDLAM = 0.0D0
        ADLAS = DLAS
        ADLOS = DLOS
        VDLOS = 0.0D0
        SDLOS = 0.0D0
        VDLAS = 0.0D0
        SDLAS = 0.0D0
      ENDIF

***************************************
* PRINT OUT THE STATISTICS FOR THIS JOB
***************************************

      LU = LUOUT
      IF (NCONV .GT. 0) THEN

*************************************************
* FIRST REPORT THE FINAL STATISTICS TO THE SCREEN
*************************************************

        CALL REPORT (LU, SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +               SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +               ADLAM, VDLAM, SDLAM, ADLOM, VDLOM, SDLOM,
     +               ADLAS, VDLAS, SDLAS, ADLOS, VDLOS, SDLOS,
     +               IPAGE, PAGE, KEY,dsel)
        CALL DIAGRM (LU, NCONV, XSMALL, XBIG, YSMALL, YBIG, KEY,
     +  dsel)

****************************************************
* NOW REPORT THE FINAL STATISTICS TO THE OUTPUT FILE
****************************************************

        IF (ITYPE .EQ. 0) THEN

**************************************
* INTERACTIVE USE ONLY - NO INPUT FILE
**************************************

          LU = NOUT
          CALL REPORT (LU, SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +                 SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +                 ADLAM, VDLAM, SDLAM, ADLOM, VDLOM, SDLOM,
     +                 ADLAS, VDLAS, SDLAS, ADLOS, VDLOS, SDLOS,
     +                 IPAGE, PAGE, KEY,dsel)

          CALL DIAGRM (LU, NCONV, XSMALL, XBIG, YSMALL, YBIG, KEY,
     +    dsel)
          IF (NCONV .EQ. 0) THEN
            DO 1007 I = 1, 2
	     if(dsel) then
              WRITE (LU,*) ' All of your NAD 27 stations are out of',
     +                     ' bounds.'
	     else
	      WRITE(LU,*) ' All of your NAD 83 stations are out of',
     +                    ' bounds.'
	     end if
 1007       CONTINUE
          ENDIF
        ELSEIF (ITYPE .EQ. 1) THEN

* For file format type 1

          LU = NOUT
          CALL REPORT (LU, SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +                 SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +                 ADLAM, VDLAM, SDLAM, ADLOM, VDLOM, SDLOM,
     +                 ADLAS, VDLAS, SDLAS, ADLOS, VDLOS, SDLOS,
     +                 IPAGE, PAGE, KEY,dsel)

          CALL DIAGRM (LU, NCONV, XSMALL, XBIG, YSMALL, YBIG, KEY,
     +    dsel)

        ELSEIF (ITYPE .EQ. 2) THEN
       
* ITYPE = 2, (free format input, free format output) does not have a
* report written to the output file

        ELSEIF (ITYPE .EQ. 3) THEN
       
* ITYPE = 3, NGS Horizontal Blue Book file format does not have a
* report written to the output file

        ENDIF

      ENDIF

      RETURN
      END
      SUBROUTINE FGRID (XPT, YPT, DX, DY, XMAX, XMIN,
     +                  YMAX, YMIN, XGRID, YGRID, IROW, JCOL, NOGO)

**********************************************************************
** SUBROUTINE FGRID: IDENTIFIES THE LOCAL GRID SQUARE FOR INTRP.     *
**********************************************************************

* This subroutine is designed to identify the grid square in which a
* particular point is located and get the corner coordinates
* converted into the index coordinate system.

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION XPT, YPT, XGRID, YGRID
      DOUBLE PRECISION XMAX, XMIN, YMAX, YMIN
      DOUBLE PRECISION DX, DY
      INTEGER IROW, JCOL
      LOGICAL NOGO

      NOGO = .FALSE.

* Check to see it the point is outside the area of the gridded data

      IF (XPT .GE. XMAX  .OR.  XPT .LE. XMIN   .OR.
     +    YPT .GE. YMAX  .OR.  YPT .LE. YMIN ) THEN
        NOGO = .TRUE.
*       WRITE (*,*) '***THE POINT IS OUT OF BOUNDS***'
        GOTO 200
      ENDIF

* Calculate the coordinate values for the point to be interpolated
* in terms of grid indices

      XGRID = ( XPT - XMIN )/DX + 1.D0
      YGRID = ( YPT - YMIN )/DY + 1.D0

* Find the I,J values for the SW corner of the local square

      IROW = IDINT(YGRID)
      JCOL = IDINT(XGRID)

  200 RETURN
      END
      SUBROUTINE FHELP

*** Print information about the formats of the input data
*** file types used by NADCON.

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)

      INTEGER ITYPE, IOS
      CHARACTER*1 ANS

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

*****************************
* CHOSE THE INPUT FILE FORMAT
*****************************

 9001 WRITE (LUOUT,*) ' '
      WRITE (LUOUT,*) ' What format do you want information about?'
      WRITE (LUOUT,*) '  1) Free Format Type 1'
      WRITE (LUOUT,*) '  2) Free Format Type 2'
      WRITE (LUOUT,*) '  3) NGS Blue Book format (default)'

      READ (LUIN,'(A1)') ANS
      IF (ANS .EQ. ' ') THEN

        ITYPE = 3

      ELSE
        READ (ANS,347,ERR=9940,IOSTAT=IOS) ITYPE
  347   FORMAT (I1)

        IF (ITYPE .GT. 3  .OR.  ITYPE .LT. 1) THEN

* Not a good answer - Try again.

          WRITE (LUOUT,*) ' Gotta pick one of these -',
     +                    ' sorry try again.'
          GOTO 9001
        ENDIF
      ENDIF

* Print information

      IF (ITYPE .EQ. 1) THEN

*******************************
* FOR FILE FORMAT ITYPE = 1
* FREE FORMAT TYPE1 INPUT FILE
* PRETTY OUTPUT FORMAT
*******************************

        WRITE (LUOUT,2)
*   2   FORMAT ('1')
    2   FORMAT ('')
        WRITE (LUOUT, 110)
  110   FORMAT (' Free Format Type 1 - The first 40 characters of',
     +                                  ' the input data record may', /,
     +          ' contain the station name or be blank.  The rest of',
     +                                 ' the record (columns 41-80)', /,
     +          ' must contain the latitude and longitude.  They may',
     +                                    ' be given in (1) decimal', /,
     +          ' degrees; (2) integer degrees and decimal minutes,',
     +                                    ' or (3) integer degrees,', /,
     +          ' integer minutes, and decimal seconds.  The decimal',
     +                                    ' portion of the latitude', /,
     +          ' MUST contain a decimal point as it is used to',
     +                                ' determine which is the last', /,
     +          ' number forming part of the latitude.  The output',
     +                                ' will be in "pretty" format.', /)

        WRITE (LUOUT, 120)
  120   FORMAT (' The following three records are examples of valid',
     +                                            ' input records:', //,
     +          ' <------------ Columns 1-40 ------------>',
     +                     '<------------ Columns 41-80----------->', /,
     +          ' AAA                                     34.',
     +                                     '4444444      98.8888888', /,
     +          ' BBB                                     25',
     +                                   ' 55.55555     76 56.66666', /,
     +          ' CCC                                     45 45',
     +                                     ' 45.555   111 11 11.111', /)

        WRITE (LUOUT,931)
  931   FORMAT (12X,  '             (Hit RETURN to continue.)')
        READ (LUIN,'(A1)') ANS
        WRITE (LUOUT,2)

        WRITE (LUOUT, 130)
  130   FORMAT (' The following is an example of the output.  Note',
     +                               ' that with Free Format Type 1', /,
     +          ' data, both the input and transformed latitude and',
     +                                 ' longitude are expressed in', /,
     +          ' degrees, minutes, and seconds regardless of the',
     +                                           ' method of input.', /)
        WRITE (LUOUT, 140)
  140   FORMAT ('                           Transformation #:',
     +                                 '    1        Region: Conus', //,
     +                                        ' Station name:  AAA', //,
     +          '                                    Latitude',
     +                                  '                 Longitude', /,
     +          '  NAD 27 datum values:           34 26 39.99984',
     +                                   '           98 53 19.99968', /,
     +          '  NAD 83 datum values:           34 26 40.28857',
     +                                   '           98 53 21.25886', /,
     +          '  NAD 83 - NAD 27 shift values:         0.28873',
     +                            '                  1.25918(secs.)', /,
     +          '                                        8.897',
     +                         '                   32.144  (meters)', /,
     +          '  Magnitude of total shift:',
     +                        '                      33.353(meters)', /)

      ELSEIF (ITYPE .EQ. 2) THEN

*******************************
* FOR FILE FORMAT ITYPE = 2
* FREE FORMAT TYPE2 INPUT FILE
* FREE FORMAT OUTPUT
*******************************

        WRITE (LUOUT,2)
        WRITE (LUOUT, 210)
  210   FORMAT (' Free Format Type 2 - The first 40 characters of',
     +                                 ' the input data record must', /,
     +          ' contain the latitude and longitude.  They may be',
     +                              ' given in (1) decimal degrees;', /,
     +          ' (2) integer degrees and decimal minutes, or (3)',
     +                                   ' integer degrees, integer', /,
     +          ' minutes, and decimal seconds.  The decimal portion',
     +                               ' of the latitude MUST contain', /,
     +          ' a decimal point as it is used to determine which',
     +                                 ' is the last number forming', /,
     +          ' part of the latitude.  The rest of the input record',
     +                                ' (columns 41-80) may contain', /,
     +          ' the station name or be blank.  The output will be',
     +                                  ' in the same format as the', /,
     +          ' input but will contain the transformed latitude and',
     +                                                 ' longitude.', /)

        WRITE (LUOUT,931)
        READ (LUIN,'(A1)') ANS
        WRITE (LUOUT,2)

        WRITE (LUOUT, 220)
  220   FORMAT (' The following three records are examples of',
     +                                      ' valid input records:', //,
     +          ' <------------ Columns 1-40 ------------>',
     +                     '<------------ Columns 41-80----------->', /,
     +          ' 45 45 45.55555 111 11 11.11111          ',
     +                                                         'one', /,
     +          ' 25 55.5555555   76 56.6666666           ',
     +                                                         'two', /,
     +          ' 34.444444444    98.888888888            ',
     +                                                          'three')

        WRITE (LUOUT, 230)
  230   FORMAT (/, ' The following is an example of the output.', //,
     +          ' NADCON Version 1.02 - NAD 83 datum values converted',
     +                                   ' from NAD 27 datum values', /,
     +          '   45 45 45.30043 111 11 13.94256        ',
     +                                                         'one', /,
     +          '   25 55.5778817   76 56.6404343         ',
     +                                                         'two', /,
     +          '   34.444524645    98.889238661          ',
     +                                                       'three', /)

      ELSEIF (ITYPE .EQ. 3) THEN

****************************************
* FOR INPUT FILE ITYPE = 3
* THE HORIZONTAL BLUE BOOK SPECIFICATION
****************************************

        WRITE (LUOUT,2)
        WRITE (LUOUT, 310)
  310   FORMAT (' NGS Horizontal Blue Book format - *80* (Control',
     +                              ' Point) Record.  Only the *80*', /,
     +          ' records in a Blue Book file are used by NADCON, the',
     +                                   ' other records are passed', /,
     +          ' through without change to the output.  On the *80*',
     +                                 ' records, only the latitude', /,
     +          ' and longitude are modified - the rest of the record',
     +                                  ' is unchanged.  Thus, this', /,
     +          ' format can be used with either ''old'' Blue Book',
     +                          ' files or ''new'' Blue Book files.', /,
     +          ' On the *80* records, the direction of the latitude',
     +                             ' must be north positive (''N'')', /,
     +          ' and the direction of the longitude must be west',
     +                           ' positive (''W'').  The precision', /,
     +          ' of the output will be the same as the precision of',
     +                                   ' the input latitude.')

        WRITE (LUOUT, 320)
  320   FORMAT (/, ' For more information on this format,',
     +                                           ' please refer to:', /,
     +          '   ''Input Formats and Specifications of the',
     +                       ' National Geodetic Survey Data Base''', /,
     +          '   ''Volume 1. Horizontal Control Data''.', /,
     +          ' Published by the Federal Geodetic Control Committee',
     +                                       ' in January, 1989 and', /,
     +          ' available from: the National Geodetic Survey, NOAA,',
     +                                       ' Rockville, MD 20852.', /)

        WRITE (LUOUT,931)
        READ (LUIN,'(A1)') ANS
        WRITE (LUOUT,2)

        WRITE (LUOUT, 330)
  330   FORMAT (' The following input example is a *80* record from a',
     +                                 ' Blue Book file with NAD 27', /,
     +          ' coordinates:', //,

     +          ' 004560*80*096 KNOXVILLE CT HSE',
     +                    '              411906578  N0930548534  W 277')

        WRITE (LUOUT, 340)
  340   FORMAT (/, ' The following example is of the output *80*',
     +                                ' record with the transformed', /,
     +          ' NAD 83 latitude and longitude.', //,
     +          ' 004560*80*096 KNOXVILLE CT HSE',
     +                 '              411906566  N0930549268  W 277', /)

      ENDIF

      WRITE (LUOUT,*) ' Do you want more information (Y/N)?'
      WRITE (LUOUT,*) ' (Default is Y)'
      READ (LUIN,'(A1)') ANS
      IF (ANS .NE. 'N'  .AND.  ANS .NE. 'n') GOTO 9001

      RETURN

* Error message

 9940 WRITE (LUOUT,*) ' Gotta pick ''1'' or ''2'' or ''3'' -',
     +                ' sorry try again.'
      GOTO 9001
      END
      SUBROUTINE GETPT (NCONV, ITYPE, KEY, NAME, IDLA, IMLA, SLA,
     +                  IDLO, IMLO, SLO, XPT, YPT,
     +                  EOF, NOPT, FIRST, LAST, IPREC, IFMT,dsel)

* Get the name, latitude, and longitude of a point either interactively
* or from an input data file

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)

      DOUBLE PRECISION XPT, YPT
      DOUBLE PRECISION SLA, SLO
      INTEGER NCONV, ITYPE, KEY, IPREC, IFMT
      INTEGER IDLA, IMLA, IDLO, IMLO
      CHARACTER*80 NAME
      CHARACTER*44 FIRST
      CHARACTER*30 LAST
      CHARACTER*1 ANS
      LOGICAL EOF, NOPT,dsel

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      EOF = .FALSE.
      NOPT = .FALSE.

      IF (ITYPE .EQ. 0) THEN

*************************************
* FOR INTERACTIVE USE - NO INPUT FILE
*************************************

        IF (NCONV .GE. 1) THEN
          WRITE (LUOUT,*) ' Do you want to do another datum',
     +                    ' transformation (Y/N)?'
          WRITE (LUOUT,*) ' (Default is Y)'
          READ (LUIN,'(A1)') ANS
          IF (ANS .EQ. 'n'  .OR.  ANS .EQ. 'N') GOTO 9999
        ENDIF

* Get a point (X,Y) to compute
        CALL ASKPT (NCONV, KEY, NAME, IDLA, IMLA, SLA,
     +              IDLO, IMLO, SLO, XPT, YPT, EOF, NOPT,dsel)
        IF (NOPT) GOTO 9000

      ELSEIF (ITYPE .EQ. 1) THEN

* Free format type 1

        CALL TYPE1 (NAME, IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +              XPT, YPT, EOF, NOPT)

      ELSEIF (ITYPE .EQ. 2) THEN

* Free format type 2

        CALL TYPE2 (NAME, IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +              XPT, YPT, EOF, NOPT, IFMT)

      ELSEIF (ITYPE .EQ. 3) THEN

* NGS Horizontal Blue Book

        CALL TYPE3 (IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +              XPT, YPT, EOF, NOPT, FIRST, LAST, IPREC)

      ENDIF

*********************************************************
* CHANGE THE LONGITUDE TO POSITIVE EAST FOR INTERPOLATION
*********************************************************

      XPT = -XPT

 9000 RETURN

* End of file

 9999 CONTINUE
      EOF = .TRUE.
      GOTO 9000
      END
      SUBROUTINE GRIDS(dsel)

* This subroutine opens the NADCON grids that are requested in
* a file named 'AREA.PAR' (if it exists) or in a file named 'area.par'
* (if it exists).  AREA.PAR (or area.par) will be read for the names
* and locations of the gridded latitude and longitude data set files.

* The data in the AREA.PAR file has the following format:
* Columns 1-15 contain the name of the area.  This name may
*   contain blanks or any other characters.
* Columns 16-80 (the rest of the record) contain the base name of the
*   grid files.  That is the '.las' and '.lon' extensions are not
*   included - They are added by this subroutine before each file is
*   opened.

* Comments are indicated by an '*' in column 1, blank records are
* also treated as comments.  Comment records are printed to the
* output file but otherwise ignored.

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)
      CHARACTER*20 B20
      CHARACTER*80 B80
      PARAMETER (B20 = '                   ', B80 = B20//B20//B20//B20)

      DOUBLE PRECISION DX1, DY1, XMAX1, XMIN1, YMAX1, YMIN1
      INTEGER IOS, I, IFLAG1, IFLAG2, NC1, N1, N2, LENG, IERR, ITEMP
      INTEGER N3
      CHARACTER*15 AAREA
      CHARACTER*65 AFILE, GFILE
      CHARACTER*80 CARD, CCARD, DUM
      LOGICAL NOGO, GFLAG,dsel

      CHARACTER*15 AREAS
      COMMON /AREAS/ AREAS(MXAREA)

      DOUBLE PRECISION DX, DY, XMAX, XMIN, YMAX, YMIN
      INTEGER NC, NAREA
      COMMON /GDINFO/ DX(MXAREA), DY(MXAREA), XMAX(MXAREA),
     +                XMIN(MXAREA), YMAX(MXAREA), YMIN(MXAREA),
     +                NC(MXAREA), NAREA

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      DATA DUM / B80 /
      DATA IFLAG1 /1/, IFLAG2 /2/

***********************************************************************
* TRY AND OPEN THE 'AREA.PAR' FILE, IF NOT THEN TRY AND OPEN 'area.par'
***********************************************************************

      GFILE = 'AREA.PAR'
      OPEN (NAPAR,FILE=GFILE,FORM='FORMATTED',STATUS='OLD',
     +      ACCESS='SEQUENTIAL',ERR=9100,IOSTAT=IOS)

* File containing grid names exits

   10 GFLAG = .TRUE.
      WRITE (LUOUT, 80)
   80 FORMAT (/, '      Data Grids named in the AREA.PAR file', /,
     +           '   #  AREA NAME      LOCATION', /, 1X, 79('=') )

      DO 120 I = 1, MXAREA
  100   READ (NAPAR,110,ERR=9000,END=9000,IOSTAT=IOS) CARD
  110   FORMAT (A80)

* Check for comment records and blank records

        IF ( CARD(1:1) .EQ. '*' ) THEN
          CALL NBLANK (CARD, IFLAG2, N2)
          WRITE (LUOUT,'(5X, A)') CARD(1:N2)
          GOTO 100
        ELSEIF ( CARD .EQ. B80 ) THEN
          WRITE (LUOUT,*) ' '
          GOTO 100
        ENDIF

* Get area name and basename of file (i.e. location without extensions)

        DUM = CARD
        AAREA = DUM(1:15)
        CALL NBLANK (CARD(16:80), IFLAG1, N1)
        DUM(1:65) = CARD(15+N1:80)
        LENG = 65
        AFILE = CCARD(DUM, LENG, IERR)
        IF (IERR .NE. 0) STOP 'Coding error in GRIDS -- AFILE'
        IF (AFILE .EQ. '        ') GOTO 9000
c now find last non-blank in afile to check for hpgn at end of name
	CALL NBLANK (AFILE(1:65),IFLAG2,N3)

c check for state hpgn file; only 1 file can be open, must end
c in 'hpgn'
	if(.not.dsel) then
	   if(NAREA.ge.1) go to 9000
	   if(AFILE(N3-3:N3).ne.'hpgn') go to 120
	else
c nad27,nad83 datum; cannot access hpgn files
	   if(AFILE(N3-3:N3).eq.'hpgn') GO TO 120
	end if

        ITEMP = NAREA + 1
        CALL OPENFL (AFILE, ITEMP, GFLAG, NOGO, DX1, DY1,
     +               XMAX1, XMIN1, YMAX1, YMIN1, NC1, CARD)

        IF (.NOT. NOGO) THEN

* Files opened OK and variables read

          NAREA = ITEMP
          AREAS(NAREA) = AAREA
          DX(NAREA) = DX1
          DY(NAREA) = DY1
          XMAX(NAREA) = XMAX1
          XMIN(NAREA) = XMIN1
          YMAX(NAREA) = YMAX1
          YMIN(NAREA) = YMIN1
          NC(NAREA) = NC1

          CALL NBLANK (CARD, IFLAG2, N2)
          WRITE (LUOUT,140) NAREA, CARD(1:N2)
  140     FORMAT (2X, I2, 2X, A)
        ENDIF

  120 CONTINUE

 9000 RETURN

* 'AREA.PAR' does not exist, try the name 'area.par'
* If it exists, open it and continue, if it does not exist, return.

 9100 CONTINUE
      GFILE = 'area.par'
      OPEN (NAPAR,FILE=GFILE,FORM='FORMATTED',STATUS='OLD',
     +      ACCESS='SEQUENTIAL',ERR=9000,IOSTAT=IOS)
      GOTO 10
      END
      SUBROUTINE HMS (DD, ID, IM, S)

* Use this to change from decimal degrees (double precision)
* to integer degrees, integer minutes, and decimal seconds (double prec)
* Seconds are assumed to have no more than 5 decimal places

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION SMALL
      PARAMETER (SMALL = 1.D-5)

      DOUBLE PRECISION DD, TEMP
      DOUBLE PRECISION S
      INTEGER ID, IM

      ID = IDINT(DD)
      TEMP = ( DD - DBLE(ID) )*60.0D0
      IM = IDINT(TEMP)
      S = ( TEMP - DBLE(IM) )*60.0D0

      IF (IM .EQ. 60) THEN
        IM = 0
        ID = ID + 1
      ENDIF

      IF (S .LT. SMALL) S = 0.D0

      IF (S .GT. (60.D0-SMALL)  ) THEN
        S = 0.D0
        IM = IM + 1
      ENDIF

      RETURN
      END
      INTEGER FUNCTION ICARD (CHLINE, LENG, IERR)

*** Read an integer from a line of card image.
*** LENG is the length of the card
*** blanks are the delimiters of the integer

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER LENG, IERR, I, J, ILENG
      INTEGER IVAR
      CHARACTER*80 CHLINE

      IERR = 0

* Find first non-blank character

* DO WHILE line character is bland, I is first non-blank character

      I = 1
   10 IF ( CHLINE(I:I) .EQ. ' '  .OR.  CHLINE(I:I) .EQ. ',' ) THEN
        I = I + 1

* Check for totally blank card

        IF ( I .GE. LENG) THEN
          ICARD = 0
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

* ILENG is the length of the integer string, it cannot be greater
* than 13 characters

      ILENG = J - I + 1

      IF (ILENG .GT. 13) THEN
        STOP 'ICARD'
      ENDIF

* Read the integer variable from the line, and set the return VAR to it

      READ (CHLINE(I:J), 55, ERR=9999) IVAR
   55 FORMAT (I13)
      ICARD = IVAR

* Now reset the values for LENG and CHLINE to the rest of the card

      CHLINE( 1 : LENG ) = CHLINE( (J+1) : LENG )
      LENG = LENG - J

      RETURN

* Read error

 9999 IERR = 1
      RETURN
      END
      SUBROUTINE INTRP (IAREA, IROW, NC, JCOL, XGRID, YGRID,
     +                  XPT, YPT, XPT2, YPT2, DLOS, DLAS, DLAM, DLOM)

**********************************************************************
** DETERMINE SURFACE FUNCTION FOR THIS GRID SQUARE                   *
** AND INTERPOLATE A VALUE, ZEE, FOR XPT, YPT                        *
**********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA, MAXCOL
      PARAMETER (MAXCOL = 600, MXAREA = 8)

      DOUBLE PRECISION XPT, YPT, XPT2, YPT2, XGRID, YGRID
      DOUBLE PRECISION DLOS, DLAS, DLAM, DLOM
      DOUBLE PRECISION TEE1, TEE2, TEE3, TEE4, ZEE
      INTEGER IROW, JCOL, NC, IAREA, IFILE, IDUM, J
      REAL BUF(MAXCOL)

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      DOUBLE PRECISION AY1, BEE1, CEE1, DEE1, AY2, BEE2, CEE2, DEE2
      SAVE AY1, BEE1, CEE1, DEE1, AY2, BEE2, CEE2, DEE2
      INTEGER IROWL, JCOLL, IAREAL
      SAVE IROWL, JCOLL, IAREAL

      DATA IROWL / 0 /, JCOLL / 0 /, IAREAL / 0 /

**********
* LATITUDE
**********

      IF ( IROW .NE. IROWL  .OR.  JCOL .NE. JCOLL  .OR.
     +    IAREA .NE. IAREAL ) THEN

* Lower boundary

        IFILE = LUAREA( 2*IAREA - 1 )
        READ (IFILE,REC=IROW+1) IDUM, (BUF(J), J=1,NC)
        TEE1 = DBLE( BUF(JCOL) )
*       TEE4 = DBLE( BUF(JCOL+1) )
        TEE3 = DBLE( BUF(JCOL+1) )

* Upper boundary

        READ (IFILE,REC=IROW+2) IDUM, (BUF(J), J=1,NC)
        TEE2 = DBLE( BUF(JCOL) )
*       TEE3 = DBLE( BUF(JCOL+1) )
        TEE4 = DBLE( BUF(JCOL+1) )

        CALL COEFF (TEE1, TEE2, TEE3, TEE4, AY1, BEE1, CEE1, DEE1)

      ENDIF

      CALL SURF (XGRID, YGRID, ZEE, AY1, BEE1, CEE1, DEE1, IROW, JCOL)
      DLAS = ZEE

***********
* LONGITUDE
***********

      IF ( IROW .NE. IROWL  .OR.  JCOL .NE. JCOLL  .OR.
     +    IAREA .NE. IAREAL ) THEN


* Lower boundary

        IFILE = LUAREA( 2*IAREA )
        READ (IFILE,REC=IROW+1) IDUM, (BUF(J), J=1,NC)
        TEE1 = DBLE( BUF(JCOL) )
*       TEE4 = DBLE( BUF(JCOL+1) )
        TEE3 = DBLE( BUF(JCOL+1) )

* Upper boundary

        READ (IFILE,REC=IROW+2) IDUM, (BUF(J), J=1,NC)
        TEE2 = DBLE( BUF(JCOL) )
*       TEE3 = DBLE( BUF(JCOL+1) )
        TEE4 = DBLE( BUF(JCOL+1) )

        CALL COEFF (TEE1, TEE2, TEE3, TEE4, AY2, BEE2, CEE2, DEE2)

      ENDIF

      CALL SURF (XGRID, YGRID, ZEE, AY2, BEE2, CEE2, DEE2, IROW, JCOL)
      DLOS = ZEE

**************************
* COMPUTE THE NAD 83 VALUES
**************************

      YPT2 = YPT + DLAS/3600.D0

* Longitude is positive west in this subroutine

      XPT2 = XPT - DLOS/3600.D0

*********************************************************************
* USE THE NEW ELLIPSOIDAL VARIABLES TO COMPUTE THE SHIFTS IN METERS
*********************************************************************

      CALL METERS (YPT, XPT, YPT2, XPT2, DLAM, DLOM)

* Update the last-value variables

      IROWL = IROW
      JCOLL = JCOL
      IAREAL = IAREA

      RETURN
      END
      SUBROUTINE IPARMS (KEY, ITYPE, SCREEN,dsel)

*** This subroutine interactively requests for information
*** needed by NADCON.
c
c 1/92 - added print for hpgn, nad83 conversion

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)
      CHARACTER*20 B20
      CHARACTER*80 B80
      PARAMETER (B20 = '                   ', B80 = B20//B20//B20//B20)

      INTEGER KEY, ITYPE, IFLAG1, IFLAG2, N1, N2, IOS
      CHARACTER*80 INFILE, OFILE
      CHARACTER*1 ANS
      LOGICAL SCREEN, EFLAG,dsel

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      DATA IFLAG1 /1/, IFLAG2 /2/

c  option for hpgn file
      IF(dsel) THEN
c nad27,nad83 selected
*****************************************************************
* CHECK TO SEE IF USER WANTS NAD 27 TO NAD 83 OR NAD 83 TO NAD 27
*****************************************************************

      WRITE (LUOUT,*) ' Do you want to convert from NAD 27 to NAD 83?'
      WRITE (LUOUT,*) ' Enter:'
      WRITE (LUOUT,*) '     ''Y'' to convert from NAD 27 to NAD 83'
      WRITE (LUOUT,*) '     ''N'' to convert from NAD 83 to NAD 27'
      WRITE (LUOUT,*) ' (Default is Y)'

        READ (LUIN, '(A1)') ANS
        IF (ANS .EQ. 'n'  .OR.  ANS .EQ. 'N') THEN
          KEY = -1
        ELSE
          KEY = 1
        ENDIF

      ELSE
C NAD83, HPGN

      WRITE(LUOUT,*) ' Do you want to convert from NAD 83 to HPGN?'
      WRITE(LUOUT,*) ' Enter:'
      WRITE(LUOUT,*) '     ''Y'' to convert from NAD 83 to HPGN'
      WRITE(LUOUT,*) '     ''N'' to convert from HPGN  to NAD 83'
      WRITE(LUOUT,*) ' (Default is Y)'

        READ (LUIN, '(A1)') ANS
        IF (ANS .EQ. 'n'  .OR.  ANS .EQ. 'N') THEN
          KEY = -1
        ELSE
          KEY = 1
        ENDIF
      END IF


**********************************
* GET THE NAME FOR THE OUTPUT FILE
**********************************

   14 WRITE (LUOUT,*) ' What is the name of the file which will',
     +                ' contain the program results?'
      WRITE (LUOUT,*) ' The default name is ''nadcon.out''.'
      READ (LUIN,'(A80)') OFILE
      IF (OFILE .EQ. B80) OFILE = 'nadcon.out'
      INQUIRE (FILE=OFILE, EXIST=EFLAG)
      IF (EFLAG) THEN
        CALL NBLANK (OFILE, IFLAG1, N1)
        CALL NBLANK (OFILE, IFLAG2, N2)
        WRITE (LUOUT,*) ' The file ''', OFILE(N1:N2), ''''
        WRITE (LUOUT,*) ' already exists.  Do you want to overwrite',
     +                                 ' it (Y/N)?'
        WRITE (LUOUT,*) ' (Default is Y)'
        READ (LUIN, '(A1)') ANS
        IF (ANS .EQ. 'n'  .OR.  ANS .EQ. 'N') GOTO 14
      ENDIF
      OPEN (NOUT,FILE=OFILE,FORM='FORMATTED',STATUS='UNKNOWN',
     +      ACCESS='SEQUENTIAL',ERR=9910,IOSTAT=IOS)

**********************************
* GET THE NAME FOR THE INPUT FILE
**********************************

      WRITE (LUOUT,*) ' '
   13 WRITE (LUOUT,*) ' Do you have an input data file (Y/N)?'
      WRITE (LUOUT,*) ' (Default is N)'

      READ (LUIN,'(A1)') ANS
      IF (ANS .EQ. 'Y'  .OR.  ANS .EQ. 'y') THEN
        WRITE (LUOUT,*) ' '
        WRITE (LUOUT,*) ' What is the name of the input data file?'
        WRITE (LUOUT,*) ' The default name is ''BBOOK''.'
        READ (LUIN,'(A80)') INFILE
        IF (INFILE .EQ. B80) INFILE = 'BBOOK'
        OPEN (NIN,FILE=INFILE,FORM='FORMATTED',STATUS='OLD',
     +        ACCESS='SEQUENTIAL',ERR=9920,IOSTAT=IOS)

*****************************
* CHOSE THE INPUT FILE FORMAT
*****************************

 9001   CONTINUE
        WRITE (LUOUT,*) ' '
        WRITE (LUOUT,*) ' What is your file format?'
        WRITE (LUOUT,*) '  0) Help - File format information'
        WRITE (LUOUT,*) '  1) Free Format Type 1'
        WRITE (LUOUT,*) '  2) Free Format Type 2'
        WRITE (LUOUT,*) '  3) NGS Blue Book format (default)'

        READ (LUIN,'(A1)') ANS
        IF (ANS .EQ. ' ') THEN

* NGS Horizontal Blue Book format

          ITYPE = 3

        ELSE
          READ (ANS,347,ERR=9940,IOSTAT=IOS) ITYPE
  347     FORMAT (I1)

          IF (ITYPE .GT. 3  .OR.  ITYPE .LT. 0) THEN

* Not a good answer - Try again.

            WRITE (LUOUT,*) ' Gotta pick one of these -',
     +                      ' sorry try again.'
            GOTO 9001
          ENDIF
        ENDIF

* Get help information

        IF (ITYPE .EQ. 0) THEN
          CALL FHELP
          GOTO 9001
        ENDIF

********************************
* CHECK FOR A SCREEN OUTPUT ALSO
********************************

        WRITE (LUOUT,*) ' '
        WRITE (LUOUT,*) ' Do you want the results written to the',
     +                  ' terminal screen as well as to'
        WRITE (LUOUT,*) ' the output file (Y/N)?'
        WRITE (LUOUT,*) ' (Default is N)'
        READ (LUIN,'(A1)') ANS
        IF (ANS .NE. 'y'  .AND.  ANS .NE. 'Y') SCREEN = .FALSE.

        GOTO 9002

* Error message

 9940   WRITE (LUOUT,*) ' Gotta pick ''1'' or ''2'' or ''3'' -',
     +                  ' sorry try again.'
        GOTO 9001

 9002 ENDIF

      RETURN

* Error message

 9910 CONTINUE
      CALL NBLANK (OFILE, IFLAG1, N1)
      CALL NBLANK (OFILE, IFLAG2, N2)
      WRITE (LUOUT,9915) IOS, OFILE(N1:N2)
 9915 FORMAT (' ERROR (', I5, ') - The operating system could not',
     +        ' open the file ', /,
     +        ' ''', A, '''', /,
     +        ' Try again.', /)
      GOTO 14

 9920 CONTINUE
      CALL NBLANK (INFILE, IFLAG1, N1)
      CALL NBLANK (INFILE, IFLAG2, N2)
      WRITE (LUOUT,9915) IOS, INFILE(N1:N2)
      GOTO 13

      END
	subroutine menu(dsel)

c subroutine prints menu and gets datum option
c ********************************************
c  
	INTEGER LUIN,LUOUT,NOUT,NIN,NAPAR,LUAREA
	INTEGER MXAREA
	CHARACTER*1  ans2
	LOGICAL dsel

	PARAMETER(MXAREA=8)
	COMMON /INOUT/ LUIN,LUOUT,NOUT,NIN,NAPAR,LUAREA(2*MXAREA)

	write(LUOUT,900)
  900	FORMAT(10X,'        AVAILABLE DATUM CONVERSIONS',//,
     +         10x,'              NAD 27, NAD 83       ',/,
     +         10X,'              NAD 83, HPGN         ',//,
     + ' Hit RETURN for NAD 27, NAD 83',/
     + ' Press any other key (except ''Q'') then RETURN for NAD 83,HPGN',
     +    /,
     + ' Press ''Q'' then RETURN to quit',//)
	
	read(LUIN,'(a1)') ans2

	if(ans2.eq.' ') then
	   dsel = .TRUE.
	   return
	else if (ans2.eq.'Q'.or.ans2.eq.'q') then
 9999	  write(LUOUT,*) 'End of Nadcon conversions'
	  STOP
	else
	  dsel = .FALSE.
	end if

	end

      SUBROUTINE METERS (LAT1, LONG1, LAT2, LONG2, LATMTR, LONMTR)

* This subroutine computes the difference in two positions in meters.
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

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

* I think that these are GRS80 parameters

      DOUBLE PRECISION AXIS, E2, RHOSEC
      PARAMETER (AXIS = 6378137.0D0)
      PARAMETER (E2 = 0.0066943800229D0)
      PARAMETER (RHOSEC = 206264.806247D0)

      DOUBLE PRECISION W, LM, LP, AVLAT
      DOUBLE PRECISION LAT1S, LAT2S, LONG1S, LONG2S, LAT1, LAT2
      DOUBLE PRECISION LONG1, LONG2, DLAT, DLONG
      DOUBLE PRECISION LATMTR, LONMTR


*     LAT1  = (LATSEC + 60.D0*( LATMIN + 60.D0*LATDEG) )/RHOSEC
*     LONG1 = (LONSEC + 60.D0*( LONMIN + 60.D0*LONDEG) )/RHOSEC
*     LAT2  = (LATSEC + 60.D0*( LATMIN + 60.D0*LATDEG) )/RHOSEC
*     LONG2 = (LONSEC + 60.D0*( LONMIN + 60.D0*LONDEG) )/RHOSEC

* Change into sec.ddd and convert to +west longitude

      LAT1S =    LAT1*60.D0*60.D0/RHOSEC
      LONG1S = -LONG1*60.D0*60.D0/RHOSEC
      LAT2S =    LAT2*60.D0*60.D0/RHOSEC
      LONG2S = -LONG2*60.D0*60.D0/RHOSEC

      DLAT  = ( LAT2S -  LAT1S)*RHOSEC
      DLONG = (LONG2S - LONG1S)*RHOSEC

      AVLAT = (LAT1S + LAT2S)/2.0D0

      W  = DSQRT(1.0D0 - E2*DSIN(AVLAT)**2)
      LM = AXIS*(1.0D0 - E2)/(W**3*RHOSEC)
      LP = AXIS*DCOS(AVLAT)/(W*RHOSEC)

      LATMTR = LM*DLAT
      LONMTR = LP*DLONG

      RETURN
      END
      SUBROUTINE MLOOP (NCONV, IPAGE, ITYPE, KEY, VRSION,
     +                  DLAM, DLOM, DLAS, DLOS,
     +                  SDLAM, SDLAM2, SDLOM, SDLOM2,
     +                  SDLAS, SDLAS2, SDLOS, SDLOS2,
     +                  SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +                  SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +                  XSMALL, XBIG, YSMALL, YBIG,
     +                  PAGE, SCREEN,dsel)

**********************************************************************
* THIS SUBROUTINE LOOPS THROUGH THE INPUT DATA (EITHER AN INPUT DATA *
* FILE OR INTERACTIVELY), CALCULATES THE TRANSFORMATION VALUES,      *
* UPDATES THE MINIMUM, MAXIMUM, AND STATISTICAL SUMMATIONS, AND THEN *
* PRINTS THE RESULTS TO THE OUTPUT FILE AND/OR THE SCREEN.           *
**********************************************************************

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)

      DOUBLE PRECISION DLAM2, DLOM2, DLAS2, DLOS2
      DOUBLE PRECISION SDLAM, SDLAM2, SDLOM, SDLOM2
      DOUBLE PRECISION SDLAS, SDLAS2, SDLOS, SDLOS2
      DOUBLE PRECISION XSMALL, XBIG, YSMALL, YBIG, XPT, XPT2, YPT, YPT2
      DOUBLE PRECISION VRSION
      DOUBLE PRECISION SLA, SLO, SLA2, SLO2
      DOUBLE PRECISION DLAM, DLOM, DLAS, DLOS
      DOUBLE PRECISION SMDLAM, BGDLAM, SMDLOM, BGDLOM
      DOUBLE PRECISION SMDLAS, BGDLAS, SMDLOS, BGDLOS
      INTEGER NCONV, IPAGE, ITYPE, KEY, IFMT, IPREC
      INTEGER IDLA, IMLA, IDLO, IMLO
      INTEGER IDLA2, IMLA2, IDLO2, IMLO2
      CHARACTER*80 NAME
      CHARACTER*44 FIRST
      CHARACTER*30 LAST
      CHARACTER*15 RESP
      LOGICAL PAGE, NOGO, SCREEN, NOPT, EOF,dsel

      DOUBLE PRECISION DX, DY, XMAX, XMIN, YMAX, YMIN
      INTEGER NC, NAREA
      COMMON /GDINFO/ DX(MXAREA), DY(MXAREA), XMAX(MXAREA),
     +                XMIN(MXAREA), YMAX(MXAREA), YMIN(MXAREA),
     +                NC(MXAREA), NAREA

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

* set defaults for those variables not used by every format type

      DATA NAME /' '/, FIRST /' '/, LAST /' '/, IFMT /0/

*******************************************************************
* BEGIN THE COMPUTATION LOOP FOR EACH CONVERSION
* DO UNTIL END OF FILE OR NO MORE CONVERSIONS REQUESTED
*******************************************************************

      NCONV = 0
  160 CONTINUE

        PAGE = .FALSE.

********************************************
* GET THE NAME AND LOCATION OF ANOTHER POINT
********************************************

        CALL GETPT (NCONV, ITYPE, KEY, NAME, IDLA, IMLA, SLA,
     +              IDLO, IMLO, SLO, XPT, YPT,
     +              EOF, NOPT, FIRST, LAST, IPREC, IFMT,dsel)
        IF (NOPT) GOTO 155
        IF (EOF) GOTO 9999

************************
* DO THE TRANSFORMATION
************************
        NOGO = .FALSE.
        CALL TRANSF (NOGO, RESP, XPT, YPT, XPT2, YPT2,
     +               DLAM, DLOM, DLAS, DLOS, KEY, ITYPE)

****************************************************
* CHECK TO SEE IF THIS POINT CAN BE TRANSFORMED
* IF NOGO IS TRUE THEN GET ANOTHER POINT AND DON'T
* DO THE COMPUTATION - POINT IS OUT OF BOUNDS
* IF NOGO IS NOT TRUE THEN PROCEED - ESTIMATE MADE
****************************************************

        IF (NOGO) GOTO 155
        NCONV = NCONV + 1

********************************************
* CHANGE THE LONGITUDE BACK TO POSITIVE WEST
* AND CHANGE BACK TO D.M.S FORMAT
********************************************

        XPT2 = -XPT2

        IF (KEY .EQ. 1) THEN

**********************
* FOR NAD 27 TO NAD 83
**********************

          CALL HMS (YPT2, IDLA2, IMLA2, SLA2)
          CALL HMS (XPT2, IDLO2, IMLO2, SLO2)
        ELSEIF (KEY .EQ. -1) THEN

**********************
* FOR NAD 83 TO NAD 27
**********************

          XPT = -XPT
          IDLA2 = IDLA
          IMLA2 = IMLA
          SLA2 = SLA
          IDLO2 = IDLO
          IMLO2 = IMLO
          SLO2 = SLO
          CALL HMS (YPT, IDLA, IMLA, SLA)
          CALL HMS (XPT, IDLO, IMLO, SLO)
        ENDIF

**************************
* DO THE LITTLE STATISTICS
**************************

* First, the basics
* meters....

        DLAM2  = DLAM**2
        SDLAM2 = SDLAM2 + DLAM2
        SDLAM  = SDLAM  + DLAM

        DLOM2  = DLOM**2
        SDLOM2 = SDLOM2 + DLOM2
        SDLOM  = SDLOM  + DLOM

* seconds....

        DLAS2  = DLAS**2
        SDLAS2 = SDLAS2 + DLAS2
        SDLAS  = SDLAS  + DLAS

        DLOS2  = DLOS**2
        SDLOS2 = SDLOS2 + DLOS2
        SDLOS  = SDLOS  + DLOS

* then the ranges

        XSMALL = DMIN1( XSMALL, XPT)
        XBIG   = DMAX1( XBIG  , XPT)
        YSMALL = DMIN1( YSMALL, YPT)
        YBIG   = DMAX1( YBIG  , YPT)

        SMDLAM = DMIN1( SMDLAM, DLAM)
        BGDLAM = DMAX1( BGDLAM, DLAM)

        SMDLOM = DMIN1( SMDLOM, DLOM)
        BGDLOM = DMAX1( BGDLOM, DLOM)

        SMDLAS = DMIN1( SMDLAS, DLAS)
        BGDLAS = DMAX1( BGDLAS, DLAS)

        SMDLOS = DMIN1( SMDLOS, DLOS)
        BGDLOS = DMAX1( BGDLOS, DLOS)

**********************************
** WRITE TO OUTPUT FILE AND SCREEN
**********************************
        CALL WRTPT (ITYPE, KEY, NCONV, VRSION, NAME,
     +              IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +              IDLA2, IMLA2, SLA2, IDLO2, IMLO2, SLO2,
     +              DLAM, DLOM, DLAS, DLOS, IFMT,
     +              FIRST, LAST, IPREC, RESP, IPAGE, PAGE, SCREEN,
     +              dsel)

**********************
* START THE LOOP AGAIN
**********************

  155 GOTO 160

 9999 RETURN
      END
      SUBROUTINE NBLANK (A, IFLAG, NBLK)

*** Return position of last non-blank in string (IFLAG = 2)
*** or position of first non-blank in string (IFLAG = 1)

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER IFLAG, NBLK, LENG, IBLK
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
      SUBROUTINE NGRIDS (NODATA,dsel,VRSION)

* This subroutine opens the NADCON grids which contain datum shifts.
* A total of two files are necessary for each area; 1 for each latitude
* and longitude shift table (gridded data set) expressed in arc seconds.

* If a file named AREA.PAR exists it will be read for the names and
* locations of the gridded data.  The format of the data in
* the AREA.PAR file is given in the GRIDS subroutine.

* If the AREA.PAR file does not exist, or there is still room in the
* arrays in the GDINFO common then the default area names used.

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)
      
      CHARACTER*1 ANS
      LOGICAL NODATA,dsel

      DOUBLE PRECISION DX, DY, XMAX, XMIN, YMAX, YMIN
      DOUBLE PRECISION VRSION
      INTEGER NC, NAREA
      COMMON /GDINFO/ DX(MXAREA), DY(MXAREA), XMAX(MXAREA),
     +                XMIN(MXAREA), YMAX(MXAREA), YMIN(MXAREA),
     +                NC(MXAREA), NAREA

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

* Initialize

      NODATA = .FALSE.
      NAREA = 0
      WRITE (LUOUT,100)
  100 FORMAT (' NADCON is now opening the files containing the',
     +        ' gridded data.', /,
     +        ' The areas listed below may be used for datum',
     +        ' conversions.')

* Try to open the 'AREA.PAR' file in the subroutine GRIDS

      CALL GRIDS(dsel)

* If NAREA>=MXAREA, then skip the section that opens the default files.
* If NAREA<MXAREA or no 'AREA.PAR' file exists, then open default names
* in the subroutine DGRIDS.

c if state hpgn chosen(dsel=false) then only 1 file can be open at 
c a time.  If an hpgn file is not in area.par, then the user can 
c choose a state in SGRIDS.
       if(dsel) then
c default grids chosen
          IF (NAREA .LT. MXAREA) THEN

              CALL DGRIDS

          ENDIF
       else
c state hpgn grids chosen
	  if(NAREA.eq.0) then

	      CALL SGRIDS(VRSION)
	  end if
       end if

      WRITE (LUOUT,975)
  975 FORMAT (/, '  (Hit RETURN to continue.)')
      READ (LUIN,'(A1)') ANS
      WRITE (LUOUT,2)
*   2 FORMAT ('1')
    2 FORMAT ('')

      IF (NAREA .EQ. 0) THEN
        NODATA = .TRUE.
        WRITE (LUOUT, 970)
  970   FORMAT (/, ' ******* ERROR *********', /,
     +          ' No grid files were opened -- program ending!')
      ENDIF

      RETURN
      END
      SUBROUTINE OPENFL (AFILE, ITEMP, GFLAG, NOGO, DX, DY,
     +                   XMAX1, XMIN1, YMAX1, YMIN1, NC1, CARD)

*** Given base name of gridded data files, open the two data files

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)
      CHARACTER*23 B23
      PARAMETER (B23 = '                       ')
      CHARACTER*69 B69
      PARAMETER (B69 = B23//B23//B23)

      DOUBLE PRECISION XMAX1, XMIN1, YMAX1, YMIN1, DX, DY
      REAL DX1, DY1, DX2, DY2
      REAL X01, Y01, ANGLE1, X02, Y02, ANGLE2
      INTEGER IFLAG1, IFLAG2, N1, N2, N3, N4
      INTEGER ITEMP, LRECL, ILA, ILO, IFILE, IOS
      INTEGER NC1, NR1, NZ1, NC2, NR2, NZ2
      CHARACTER*80 CARD
      CHARACTER*69 ALAS, ALOS
      CHARACTER*65 AFILE
      CHARACTER*56 RIDENT
      CHARACTER*8 PGM
      LOGICAL GFLAG, NOGO, OFLAG, EFLAG1, EFLAG2

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      DATA IFLAG1 /1/, IFLAG2 /2/
      DATA OFLAG /.FALSE./, EFLAG1 /.FALSE./, EFLAG2 /.FALSE./


* Initialize

      NOGO = .FALSE.

* Form complete names of grid files

      CALL NBLANK (AFILE, IFLAG2, N2)
      IF (N2 .EQ. 0) STOP 'Logical Coding Error in OPENF'

      ALAS = B69
      ALAS(1:N2) = AFILE

      ALAS(N2+1:N2+4) = '.las'
      ALOS = B69
      ALOS(1:N2) = AFILE
      ALOS(N2+1:N2+4) = '.los'

*******************************************************
* DIRECT ACCESS GRID FILES
* Each file is opened once to get the grid variables.
* The file is then closed and reopened to ensure that
* the record length is correct
*******************************************************

* Seconds of latitude grid file

      LRECL = 256
      ILA = 2*ITEMP - 1
      IFILE = ILA + 10
      LUAREA(ILA) = IFILE
      INQUIRE (FILE=ALAS, EXIST=EFLAG1, OPENED=OFLAG)
      IF (.NOT. EFLAG1) GOTO 100
      IF (OFLAG) GOTO 980
      OPEN (IFILE,FILE=ALAS,FORM='UNFORMATTED',STATUS='OLD',
     +       ACCESS='DIRECT',RECL=LRECL,ERR=940,IOSTAT=IOS)
      READ (IFILE,REC=1) RIDENT, PGM, NC1, NR1, NZ1, X01, DX1,
     +                   Y01, DY1, ANGLE1
      CLOSE (IFILE)

      LRECL = 4*(NC1+1)
      OPEN (IFILE,FILE=ALAS,FORM='UNFORMATTED',STATUS='OLD',
     +       ACCESS='DIRECT',RECL=LRECL,ERR=940,IOSTAT=IOS)

* Seconds of longitude grid file

  100 LRECL = 256
      ILO = 2*ITEMP
      IFILE = ILO + 10
      LUAREA(ILO) = IFILE
      INQUIRE (FILE=ALOS, EXIST=EFLAG2, OPENED=OFLAG)
      IF (.NOT. EFLAG1) GOTO 910
      IF (.NOT. EFLAG2) GOTO 920
      IF (OFLAG) GOTO 980
      OPEN (IFILE,FILE=ALOS,FORM='UNFORMATTED',STATUS='OLD',
     +       ACCESS='DIRECT',RECL=LRECL,ERR=940,IOSTAT=IOS)
      READ (IFILE,REC=1) RIDENT, PGM, NC2, NR2, NZ2, X02, DX2,
     +                   Y02, DY2, ANGLE2
      CLOSE (IFILE)

      LRECL = 4*(NC2+1)
      OPEN (IFILE,FILE=ALOS,FORM='UNFORMATTED',STATUS='OLD',
     +       ACCESS='DIRECT',RECL=LRECL,ERR=940,IOSTAT=IOS)

* Check to see if the two files have the same variables

      IF ( (NC2 .NE. NC1)  .OR.  (NR2 .NE. NR1)  .OR.
     +     (NZ2 .NE. NZ1)  .OR.
     +     (X02 .NE. X01)  .OR.  (DX2 .NE. DX1)  .OR.
     +     (Y02 .NE. Y01)  .OR.  (DY2 .NE. DY1)  .OR.
     +     (ANGLE2 .NE. ANGLE1) ) GOTO 960

* Calculate values used in this program

      XMIN1 = DBLE(X01)
      YMIN1 = DBLE(Y01)
      XMAX1 = DBLE(X01) + (NC1-1)*DBLE(DX1)
      YMAX1 = DBLE(Y01) + (NR1-1)*DBLE(DY1)
      DX = DBLE( ABS(DX1) )
      DY = DBLE( ABS(DY1) )

*****************************************
* REPORT SOMETHING ABOUT THE GRIDDED DATA
*****************************************
*     WRITE (LUOUT,4050) RIDENT, PGM, NC1, NR
*4050 FORMAT (1X, A56, /, 1X, A8, /, I5, I5)
*     WRITE (LUOUT,*) 'DX,DY,NR,NC', DX1, DY1, NR1, NC1
*     WRITE (LUOUT,4055) -XMAX1, -XMIN1, YMIN1, YMAX1
*4055 FORMAT (' MIN Longitude = ', F10.4, ' MAX Longitude = ', F10.4, /,
*    +        ' MIN Latitude  = ', F10.4, ' MAX Latitude  = ', F10.4, /)
*****************************************

 9999 RETURN

****************************
* WARNING AND ERROR MESSAGES
****************************

* Grid files do not exist

  910 CONTINUE
      NOGO = .TRUE.
      IF (GFLAG) THEN
        CALL NBLANK (ALAS, IFLAG1, N1)
        CALL NBLANK (ALAS, IFLAG2, N2)
        CALL NBLANK (CARD, IFLAG1, N3)
        CALL NBLANK (CARD, IFLAG2, N4)
        IF (EFLAG2) THEN

* .los exists, .las does not exist

          WRITE (LUOUT, 925) ALAS(N1:N2), CARD(N3:N4), ALOS(N1:N2)
        ELSE

* neither .los nor .las exist

          WRITE (LUOUT, 915) ALAS(N1:N2), ALOS(N1:N2), CARD(N3:N4)
  915     FORMAT (/, 5X, ' *********** WARNING ***********', /,
     +            5X, ' The grid files', /,
     +            6X, '''', A, '''', /,
     +            6X, '''', A, '''', /,
     +            5X, ' from record:', /, 
     +            6X, '''', A, '''', /,
     +            5X, ' do not exist!', /,
     +            5X, ' *******************************', /)
        ENDIF
      ENDIF
      CLOSE ( LUAREA(ILA) )
      CLOSE ( LUAREA(ILO) )
      GOTO 9999

  920 CONTINUE
      NOGO = .TRUE.
      IF (GFLAG) THEN

* .las exists, .los does not exist

        CALL NBLANK (ALAS, IFLAG1, N1)
        CALL NBLANK (ALAS, IFLAG2, N2)
        CALL NBLANK (CARD, IFLAG1, N3)
        CALL NBLANK (CARD, IFLAG2, N4)
        WRITE (LUOUT, 925) ALOS(N1:N2), CARD(N3:N4), ALAS(N1:N2)
  925   FORMAT (/, 5X, ' *********** WARNING ***********', /,
     +          5X, ' The grid file', /,
     +          6X, '''', A, '''', /,
     +          5X, ' from record:', /,
     +          6X, '''', A, '''', /,
     +          5X, ' does not exist!  However, the grid file', /,
     +          6X, '''', A, '''', /,
     +          5X, ' does exist!', /,
     +          5X, ' *******************************', /)
      ENDIF
      CLOSE ( LUAREA(ILA) )
      CLOSE ( LUAREA(ILO) )
      GOTO 9999

* Grid file(s) already open

  940 CONTINUE
      NOGO = .TRUE.
      IF (GFLAG) THEN
        CALL NBLANK (ALAS, IFLAG1, N1)
        CALL NBLANK (ALAS, IFLAG2, N2)
        CALL NBLANK (CARD, IFLAG1, N3)
        CALL NBLANK (CARD, IFLAG2, N4)
        WRITE (LUOUT, 945) ALAS(N1:N2), ALOS(N1:N2), CARD(N3:N4), IOS
  945   FORMAT (/, 5X, ' *********** WARNING ***********', /,
     +          5X, ' The grid file', /,
     +          6X, '''', A, '''', /,
     +          5X, ' and/or grid file', /,
     +          6X, '''', A, '''', /,
     +          5X, ' from record:', /,
     +          6X, '''', A, '''', /,
     +          5X, ' cannot be opened!',
     +                      '  These files will be ignored.', 5X, I5, /,
     +          5X, ' *******************************', /)
      ENDIF
      CLOSE ( LUAREA(ILA) )
      CLOSE ( LUAREA(ILO) )
      GOTO 9999

* Grid files do not agree

  960 CONTINUE
      NOGO = .TRUE.
      CALL NBLANK (ALAS, IFLAG1, N1)
      CALL NBLANK (ALAS, IFLAG2, N2)
      WRITE (LUOUT, 965) ALAS(N1:N2), ALOS(N1:N2)
  965 FORMAT (/, 5X, ' *********** ERROR ***********', /,
     +        5X, ' The header information in grid files', /,
     +        6X, '''', A, '''', /,
     +        5X, ' and', /,
     +        6X, '''', A, '''', /,
     +        5X, ' do not agree!  One or both of these files must',
     +                                             ' be corrupted.', /,
     +        5X, ' These files will be ignored.', /,
     +        5X, ' *****************************', /)
      CLOSE ( LUAREA(ILA) )
      CLOSE ( LUAREA(ILO) )
      GOTO 9999

* Grid files already open

  980 CONTINUE
      NOGO = .TRUE.
      IF (GFLAG) THEN
        CALL NBLANK (ALAS, IFLAG1, N1)
        CALL NBLANK (ALAS, IFLAG2, N2)
        WRITE (LUOUT, 985) ALAS(N1:N2), ALOS(N1:N2)
  985   FORMAT (/, 5X, ' *********** ERROR ***********', /,
     +          5X, ' The grid file', /,
     +          6X, '''', A, '''', /,
     +          5X, ' and the grid file', /,
     +          6X, '''', A, '''', /,
     +          5X, ' have already been opened!  These files',
     +                                      ' will not be reopened.', /,
     +          5X, ' *****************************', /)
      ENDIF
      GOTO 9999
      END
      SUBROUTINE PRINT1 (LU, NCONV, NAME, VRSION, IDLA, IMLA, SLA,
     +                   IDLO, IMLO, SLO, IDLA2, IMLA2, SLA2,
     +                   IDLO2, IMLO2, SLO2, DLAM, DLOM, DLAS, DLOS,
     +                   RESP, IPAGE, PAGE, KEY,dsel)

* This subroutine prints out the actual transformation results using
* a pretty format - not the same as the input file format (if there
* is one).  This subroutine is used by type-1 format input and
* interactive input

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION VRSION, AMAG
      DOUBLE PRECISION SLA, SLO, SLA2, SLO2
      DOUBLE PRECISION DLAM, DLOM, DLAS, DLOS
      INTEGER LU, NCONV, IPAGE, KEY
      INTEGER IDLA, IMLA, IDLO, IMLO
      INTEGER IDLA2, IMLA2, IDLO2, IMLO2
      CHARACTER*15 RESP
      CHARACTER*80 NAME
      LOGICAL PAGE,dsel


      IF (NCONV .EQ. 1) THEN

********************
* FIRST PAGE HEADING
********************

        WRITE (LU,10) IPAGE
        WRITE (LU,5)
	IF(dsel) then
c nad 27, nad83
          IF (KEY .EQ. 1) THEN
            WRITE (LU,6)
          ELSE
            WRITE (LU,26)
          ENDIF
	ELSE
c nad 83, hpgn
	  IF(KEY.EQ.1) THEN
	    WRITE(LU,36)
	  ELSE
	    WRITE(LU,46)
	  END IF
	END IF

        WRITE (LU,7) VRSION
        WRITE (LU,8)
      ENDIF

      IF (PAGE) THEN
        IF (IPAGE .GT. 1) THEN
          WRITE (LU,2)
          WRITE (LU,10) IPAGE
        ENDIF
      ENDIF

   10 FORMAT (70(' '), 'Page ', I4, /)
    5 FORMAT (20X, '  North American Datum Conversion')
   36 FORMAT (20X, '         NAD 83 to HPGN'       )
   46 FORMAT (20X, '         HPGN   to NAD 83'     ) 
    6 FORMAT (20X, '         NAD 27 to NAD 83'     )
   26 FORMAT (20X, '         NAD 83 to NAD 27'     )
    7 FORMAT (20X, '    NADCON Program Version ', F4.2 )
    8 FORMAT (20X, '                          ', /, 1X, 79('=') )

*   2 FORMAT ('1')
    2 FORMAT ('')

      WRITE (LU,921) NCONV, RESP
      IF (NAME .NE. '    ') WRITE (LU,922) NAME
      WRITE (LU,900)
      IF(dsel) then
       WRITE (LU,923) IDLA, IMLA, SLA, IDLO, IMLO, SLO
       WRITE (LU,924) IDLA2, IMLA2, SLA2, IDLO2, IMLO2, SLO2
       IF (KEY .EQ. 1) THEN
         WRITE (LU,925) DLAS, DLOS
         WRITE (LU,927) DLAM, DLOM
       ELSE
         WRITE (LU,926) -DLAS, -DLOS
         WRITE (LU,927) -DLAM, -DLOM
       ENDIF
      ELSE
       WRITE (LU,933) IDLA, IMLA, SLA, IDLO, IMLO, SLO
       WRITE (LU,934) IDLA2, IMLA2, SLA2, IDLO2, IMLO2, SLO2
       IF (KEY .EQ. 1) THEN
         WRITE (LU,935) DLAS, DLOS
         WRITE (LU,927) DLAM, DLOM
       ELSE
         WRITE (LU,936) -DLAS, -DLOS
         WRITE (LU,927) -DLAM, -DLOM
       ENDIF
      END IF
       AMAG = DSQRT(DLAM**2 + DLOM**2)
       WRITE (LU,928) AMAG
c 930's values are for HPGN
  921 FORMAT (/, 27X, 'Transformation #: ', I4, 8X, 'Region: ', A15,/)
  922 FORMAT (2X, 'Station name:  ', A80, /)
  900 FORMAT (36X, 'Latitude', 17X, 'Longitude')
  933 FORMAT (2X, 'NAD 83 datum values:         ',
     +       (2x, I2, 1x, I2.2, F9.5, 10X, I3, 1X, I2.2, F9.5) )
  923 FORMAT (2X, 'NAD 27 datum values:         ',
     +       (2X, I2, 1X, I2.2, F9.5, 10X, I3, 1X, I2.2, F9.5) )
  934 FORMAT (2X, 'HPGN datum values:           ',
     +       (2X, I2, 1X, I2.2, F9.5, 10X, I3, 1X, I2.2, F9.5) )
  924 FORMAT (2X, 'NAD 83 datum values:         ',
     +       (2X, I2, 1X, I2.2, F9.5, 10X, I3, 1X, I2.2, F9.5) )
  925 FORMAT (2X, 'NAD 83 - NAD 27 shift values: ',
     +        6X, F9.5, 16X, F9.5, '(secs.)')
  935 FORMAT (2X, 'HPGN - NAD 83 shift values: ',
     +        6X, F9.5, 16X, F9.5, '(secs.)')
  926 FORMAT (2X, 'NAD 27 - NAD 83 shift values: ',
     +        6X, F9.5, 16X, F9.5, '(secs.)')
  936 FORMAT (2X, 'NAD 83 - HPGN shift values: ',
     +        6X, F9.5, 16X, F9.5, '(secs.)')
  927 FORMAT (37X, F8.3, 17X, F8.3, '  (meters)')
  928 FORMAT (2X, 'Magnitude of total shift:    ',
     +        19X, F8.3, '(meters)', /)

      RETURN
      END
      SUBROUTINE PRINT2 (LU, NCONV, NAME, VRSION, IDLA, IMLA, SLA,
     +                   IDLO, IMLO, SLO, IDLA2, IMLA2, SLA2, IDLO2,
     +                   IMLO2, SLO2, KEY, IFMT,dsel)

* This subroutine prints out the actual transformation results using
* a free format - the same as the input file format.  This is used
* for type 2 format.

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION DDLA, DDLO, DMLA, DMLO
      DOUBLE PRECISION DDLA2, DDLO2, DMLA2, DMLO2
      DOUBLE PRECISION VRSION
      DOUBLE PRECISION SLA, SLO, SLA2, SLO2
      INTEGER LU, NCONV, KEY, IFMT
      INTEGER IDLA, IMLA, IDLO, IMLO
      INTEGER IDLA2, IMLA2, IDLO2, IMLO2
      CHARACTER*80 NAME
      LOGICAL      dsel

* Write header record to identify source of coordinates and datum

      IF (NCONV .EQ. 1) THEN
       if(dsel) then
c nad 27, nad 83
        IF (KEY .EQ. 1) THEN
          WRITE (LU, 10) VRSION
   10     FORMAT (' NADCON Version', F5.2,
     +      ' - NAD 83 datum values converted from NAD 27 datum values')
        ELSE
          WRITE (LU, 20) VRSION
   20     FORMAT (' NADCON Version', F5.2,
     +      ' - NAD 27 datum values converted from NAD 83 datum values')
        ENDIF
       else
c nad 83, hpgn
        IF (KEY .EQ. 1) THEN
          WRITE (LU, 11) VRSION
   11     FORMAT (' NADCON Version', F5.2,
     +      ' - HPGN datum values converted from NAD 83 datum values')
        ELSE
          WRITE (LU, 21) VRSION
   21     FORMAT (' NADCON Version', F5.2,
     +      ' - NAD 83 datum values converted from HPGN datum values')
        ENDIF
       end if
      ENDIF

* Write transformed coordinates

      IF (IFMT .EQ. 1) THEN
        IF (KEY .EQ. 1) THEN
          WRITE (LU, 110) IDLA2, IMLA2, SLA2, IDLO2, IMLO2, SLO2, NAME
  110     FORMAT (I4, I3, F9.5, I4, I3, F9.5, 8X, A40)
        ELSE
          WRITE (LU, 110) IDLA, IMLA, SLA, IDLO, IMLO, SLO, NAME
        ENDIF
      ELSEIF (IFMT .EQ. 2) THEN
        IF (KEY .EQ. 1) THEN
          DMLA2 = DBLE(IMLA2) + SLA2/60.D0
          DMLO2 = DBLE(IMLO2) + SLO2/60.D0
          WRITE (LU, 120) IDLA2, DMLA2, IDLO2, DMLO2, NAME
  120     FORMAT (I4, F11.7, 1X, I4, F11.7, 1X, 8X, A40)
        ELSE
          DMLA = DBLE(IMLA) + SLA/60.D0
          DMLO = DBLE(IMLO) + SLO/60.D0
          WRITE (LU, 120) IDLA, DMLA, IDLO, DMLO, NAME
        ENDIF
      ELSEIF (IFMT .EQ. 3) THEN
        IF (KEY .EQ. 1) THEN
          DDLA2 = DBLE(IDLA2) + DBLE(IMLA2)/60.D0 + SLA2/3600.D0
          DDLO2 = DBLE(IDLO2) + DBLE(IMLO2)/60.D0 + SLO2/3600.D0
          WRITE (LU, 130) DDLA2, DDLO2, NAME
  130     FORMAT (F14.9, 2X, F14.9, 2X, 8X, A40)
        ELSE
          DDLA = DBLE(IDLA) + DBLE(IMLA)/60.D0 + SLA/3600.D0
          DDLO = DBLE(IDLO) + DBLE(IMLO)/60.D0 + SLO/3600.D0
          WRITE (LU, 130) DDLA, DDLO, NAME
        ENDIF
      ENDIF

      RETURN
      END
      SUBROUTINE PRINT3 (LU, IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +                   IDLA2, IMLA2, SLA2, IDLO2, IMLO2, SLO2,
     +                   KEY, FIRST, LAST, IPREC)

* This subroutine prints out the actual transformation results using
* the Blue Book (type 3) format.
* The precision is indicated by the number of blanks in the seconds
* field.  The output precision will match the precision of the
* input seconds of arc of latitude (the precision of the seconds of
* arc of the longitude is ignored).

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION SLA, SLO, SLA2, SLO2
      INTEGER LU, KEY, IPREC
      INTEGER IDLA, IMLA, IDLO, IMLO
      INTEGER IDLA2, IMLA2, IDLO2, IMLO2
      INTEGER ISLA, ISLO, ISLA2, ISLO2
      CHARACTER*44 FIRST
      CHARACTER*30 LAST

      IF (IPREC .LT. 0  .OR.  IPREC .GT. 5) THEN
        WRITE (6, 666) IPREC
  666   FORMAT (/, ' ******** PROGRAMMING ERROR **********',
     +          /, ' ILLEGAL PRECISION VALUE IN SUBROUTINE PRINT3', I5,
     +          /, ' TRANSFORMED COORDINATES MAY BE INCORRECT!!')
      ENDIF

      IF (KEY .EQ. -1) THEN

**********************
* FOR NAD 27 TO NAD 83
c or  NAD 83 TO HPGN
**********************

        ISLA = IDINT( SLA*10**IPREC )
        ISLO = IDINT( SLO*10**IPREC )

        IF (IPREC .EQ. 0) THEN
          WRITE (LU,6000) FIRST, IDLA, IMLA, ISLA, 'N',
     +                           IDLO, IMLO, ISLO, 'W', LAST
        ELSEIF (IPREC .EQ. 1) THEN
          WRITE (LU,6001) FIRST, IDLA, IMLA, ISLA, 'N',
     +                           IDLO, IMLO, ISLO, 'W', LAST
        ELSEIF (IPREC .EQ. 2) THEN
          WRITE (LU,6002) FIRST, IDLA, IMLA, ISLA, 'N',
     +                           IDLO, IMLO, ISLO, 'W', LAST
        ELSEIF (IPREC .EQ. 3) THEN
          WRITE (LU,6003) FIRST, IDLA, IMLA, ISLA, 'N',
     +                           IDLO, IMLO, ISLO, 'W', LAST
        ELSEIF (IPREC .EQ. 4) THEN
          WRITE (LU,6004) FIRST, IDLA, IMLA, ISLA, 'N',
     +                           IDLO, IMLO, ISLO, 'W', LAST
        ELSEIF (IPREC .EQ. 5) THEN
          WRITE (LU,6005) FIRST, IDLA, IMLA, ISLA, 'N',
     +                           IDLO, IMLO, ISLO, 'W', LAST
        ENDIF

      ELSE

**********************
* FOR NAD 83 TO NAD 27
c or  HPGN   TO NAD 83
**********************

        ISLA2 = IDINT( SLA2*10**IPREC )
        ISLO2 = IDINT( SLO2*10**IPREC )

        IF (IPREC .EQ. 0) THEN
          WRITE (LU,6000) FIRST, IDLA2, IMLA2, ISLA2, 'N',
     +                           IDLO2, IMLO2, ISLO2, 'W', LAST
        ELSEIF (IPREC .EQ. 1) THEN
          WRITE (LU,6001) FIRST, IDLA2, IMLA2, ISLA2, 'N',
     +                           IDLO2, IMLO2, ISLO2, 'W', LAST
        ELSEIF (IPREC .EQ. 2) THEN
          WRITE (LU,6002) FIRST, IDLA2, IMLA2, ISLA2, 'N',
     +                           IDLO2, IMLO2, ISLO2, 'W', LAST
        ELSEIF (IPREC .EQ. 3) THEN
          WRITE (LU,6003) FIRST, IDLA2, IMLA2, ISLA2, 'N',
     +                           IDLO2, IMLO2, ISLO2, 'W', LAST
        ELSEIF (IPREC .EQ. 4) THEN
          WRITE (LU,6004) FIRST, IDLA2, IMLA2, ISLA2, 'N',
     +                           IDLO2, IMLO2, ISLO2, 'W', LAST
        ELSEIF (IPREC .EQ. 5) THEN
          WRITE (LU,6005) FIRST, IDLA2, IMLA2, ISLA2, 'N',
     +                           IDLO2, IMLO2, ISLO2, 'W', LAST
        ENDIF

      ENDIF

      RETURN
 6000 FORMAT (A44, I2.2, I2.2, I2.2, 5X, A1,
     +             I3.3, I2.2, I2.2, 5X, A1, A11)
 6001 FORMAT (A44, I2.2, I2.2, I3.3, 4X, A1,
     +             I3.3, I2.2, I3.3, 4X, A1, A11)
 6002 FORMAT (A44, I2.2, I2.2, I4.4, 3X, A1,
     +             I3.3, I2.2, I4.4, 3X, A1, A11)
 6003 FORMAT (A44, I2.2, I2.2, I5.5, 2X, A1,
     +             I3.3, I2.2, I5.5, 2X, A1, A11)
 6004 FORMAT (A44, I2.2, I2.2, I6.6, 1X, A1,
     +             I3.3, I2.2, I6.6, 1X, A1, A11)
 6005 FORMAT (A44, I2.2, I2.2, I7.7, A1,
     +             I3.3, I2.2, I7.7, A1, A11)
      END
      REAL FUNCTION RCARD (CHLINE, LENG, IERR)

*** Read a real number from a line of card image.
*** LENG is the length of the card
*** blanks are the delimiters of the REAL*4 variable

      IMPLICIT REAL (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      REAL VAR
      INTEGER LENG, IERR, I, J, ILENG
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

* ILENG is the length of the real*4 string, it cannot be greater
* than 15 characters

      ILENG = J - I + 1

      IF (ILENG .GT. 15) THEN
        STOP 'RCARD'
      ENDIF

* Read the real*4 variable from the line, and set the return VAR to it

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
      SUBROUTINE REPORT (LU, SMDLAM, BGDLAM, SMDLOM, BGDLOM,
     +                   SMDLAS, BGDLAS, SMDLOS, BGDLOS,
     +                   ADLAM, VDLAM, SDLAM, ADLOM, VDLOM, SDLOM,
     +                   ADLAS, VDLAS, SDLAS, ADLOS, VDLOS, SDLOS,
     +                   IPAGE, PAGE, KEY,dsel)

* This subroutine prints out the statistics for the transformations

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION ADLAM, VDLAM, ADLOM, VDLOM, SDLAM, SDLOM
      DOUBLE PRECISION ADLAS, VDLAS, ADLOS, VDLOS, SDLAS, SDLOS
      DOUBLE PRECISION SMDLAM, BGDLAM, SMDLOM, BGDLOM
      DOUBLE PRECISION SMDLAS, BGDLAS, SMDLOS, BGDLOS
      INTEGER LU, IPAGE, KEY
      LOGICAL PAGE,dsel

************
* NEW PAGE
************

      WRITE (LU,2)
*   2 FORMAT ('1')
    2 FORMAT ('')

      IF (PAGE) THEN

******************
* NUMBER THIS PAGE
******************

        WRITE (LU,15)  IPAGE
   15   FORMAT (70(' '), 'Page ', I4, /)
      ENDIF

* Print out the statistics. Note that the statistics are all gathered
* in terms of NAD 27 to NAD 83 conversions.  Thus, the signs
* for the range and mean values must be changed for the
* NAD 83 to NAD 27 conversions.

      IF (KEY .EQ. 1) THEN
	if(dsel) then
           WRITE (LU,90)
   90      FORMAT (28X, 'NAD 27 to NAD 83 Conversion')
	else
           WRITE (LU,92)
   92      FORMAT (28X, 'NAD 83 to HPGN Conversion')
	end if
        WRITE (LU,100)
  100   FORMAT (//, 30X, 'Statistics for Region', /, 1X, 79('='), /)
        WRITE (LU,900)
  900   FORMAT (36X, 'Latitude', 17X, 'Longitude')
	if(dsel) then
          WRITE (LU,910)
  910     FORMAT ('  NAD 83 - NAD 27 shifts',
     +           8X, 'MIN', 6X, 'MAX', 14X, 'MIN', 6X, 'MAX')
	else
          WRITE (LU,920)
  920     FORMAT ('  HPGN    - NAD 83 shifts',
     +           8X, 'MIN', 6X, 'MAX', 14X, 'MIN', 6X, 'MAX')
	end if
        WRITE (LU,110) SMDLAM, BGDLAM, SMDLOM, BGDLOM
  110   FORMAT ('  Range of shift (meters)   ', 2F9.3, 8X, 2F9.3)
        WRITE (LU,120) SMDLAS, BGDLAS, SMDLOS, BGDLOS
  120   FORMAT ('  Range of shift (seconds)  ', 2F9.3, 8X, 2F9.3)
        WRITE (LU,130) ADLAM, ADLOM
  130   FORMAT (/, 10X, 'Mean shift (meters)     ', F9.3, 17X, F9.3)
        WRITE (LU,131) VDLAM, VDLOM
  131   FORMAT (10X, 'Variance of mean shift  ', F9.3, 17X, F9.3)
        WRITE (LU,132) SDLAM, SDLOM
  132   FORMAT (10X, 'Std. Dev. of mean shift ', F9.3, 17X, F9.3)
        WRITE (LU,133) ADLAS, ADLOS
  133   FORMAT (/, 10X, 'Mean shift (seconds)    ', F9.3, 17X, F9.3)
        WRITE (LU,134) VDLAS, VDLOS
  134   FORMAT (10X, 'Variance of mean shift  ', F9.3, 17X, F9.3)
        WRITE (LU,135) SDLAS, SDLOS
  135   FORMAT (10X, 'Std. Dev. of mean shift ', F9.3, 17X, F9.3)
      ELSE
	if(dsel) then
          WRITE (LU,91)
   91     FORMAT (28X, 'NAD 83 to NAD 27 Conversion')
	else
          WRITE (LU,191)
  191     FORMAT (28X, 'HPGN   to NAD 83 Conversion')
	end if
        WRITE (LU,100)
        WRITE (LU,900)
	if(dsel) then
          WRITE (LU,911)
  911     FORMAT ('  NAD 27 - NAD 83 shifts',
     +           8X, 'MIN', 6X, 'MAX', 14X, 'MIN', 6X, 'MAX')
	else
          WRITE (LU,921)
  921     FORMAT ('  NAD 83 - HPGN   shifts',
     +           8X, 'MIN', 6X, 'MAX', 14X, 'MIN', 6X, 'MAX')
	end if
          WRITE (LU,110) -BGDLAM, -SMDLAM, -BGDLOM, -SMDLOM
        WRITE (LU,120) -BGDLAS, -SMDLAS, -BGDLOS, -SMDLOS
        WRITE (LU,130) -ADLAM, -ADLOM
        WRITE (LU,131) VDLAM, VDLOM
        WRITE (LU,132) SDLAM, SDLOM
        WRITE (LU,133) -ADLAS, -ADLOS
        WRITE (LU,134) VDLAS, VDLOS
        WRITE (LU,135) SDLAS, SDLOS
      ENDIF

      RETURN
      END
      SUBROUTINE SGRIDS(VRSION)

* SGRIDS is DFILES subroutine revised for state hpgn files

* This subroutine opens the NADCON grids using the state HPGN
* grid files. Only 1 state hpgn file can be open at any one time
* the program loop will take care of using other states in the same
* run - jmb 1/16/92

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA, MXDEF
      PARAMETER (MXAREA = 8, MXDEF = MXAREA)
      CHARACTER*80 B80
      CHARACTER*65 B65
      CHARACTER*20 B20
      CHARACTER*2  state
      PARAMETER (B20 = '                   ', B80 = B20//B20//B20//B20)
      PARAMETER (B65 = B20//B20//B20//'     ')

      DOUBLE PRECISION XMAX1, XMIN1, YMAX1, YMIN1
      DOUBLE PRECISION DX1, DY1
      INTEGER  ITEMP, NC1
      CHARACTER*80 DUM
      CHARACTER*65 AFILE 
c     CHARACTER*15 DAREAS(MXDEF)
      LOGICAL NOGO, GFLAG

      CHARACTER*15 AREAS
      COMMON /AREAS/ AREAS(MXAREA)

      DOUBLE PRECISION DX, DY, XMAX, XMIN, YMAX, YMIN
      DOUBLE PRECISION VRSION
      INTEGER NC, NAREA
      COMMON /GDINFO/ DX(MXAREA), DY(MXAREA), XMAX(MXAREA),
     +                XMIN(MXAREA), YMAX(MXAREA), YMIN(MXAREA),
     +                NC(MXAREA), NAREA

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      DATA DUM / B80 /
c the following does not pertain to state grid files

* DFILES contains the default locations (pathname) of the grid files
* without the .las and .los extensions. (For example 'conus' would
* indicate that the conus.las and conus.los grid files are in the
* current working directory.)  The length of each entry in DFILES may
* be up to 65 characters.  DAREAS contains the default names of these
* areas.  The names are used internally in the program and in the
* program output.  They may be no longer than 15 characters.  They
* must correspond on a one-to-one basis with the file locations in
* the DFILES array.  That is, the first area name in DAREAS must
* be the name that you wish for the first data file set in the
* DFILES array.  You may, of course, have the arrays the same if
* the location of the data file is no longer than 15 characters.
* The locations of the grid files may be differ for each
* installation.  If the pathnames are not correct DFILES (and, possibly,
* DAREAS) may be changed and the program recompiled.


      GFLAG = .FALSE.

c  pick up the state file if no file is in area.par.

        write(LUOUT,90) VRSION
  90    FORMAT(//,' "README.210" file on the program disk contains ',
     + 'the names of the states',/,
     + ' for which you have High Precision grids.',/, 
     + ' Please refer to that file before running NADCON, version ',
     + f5.2,///, ' Enter the two-letter name for the state or state ',
     + 'group you choose')
	  READ(LUIN,95) state
  95       FORMAT(A2)
	  WRITE(LUOUT,'(/)')
	AFILE = B65
	AFILE(1:2) = state
	AFILE(3:6) = 'hpgn'

* Do not print error messages for non-existing files.

        ITEMP = NAREA + 1
        CALL OPENFL (AFILE, ITEMP, GFLAG, NOGO, DX1, DY1,
     +               XMAX1, XMIN1, YMAX1, YMIN1, NC1, DUM)

        IF (.NOT. NOGO) THEN

* Set of files opened OK and variables read

          NAREA = ITEMP
c         AREAS(NAREA) = DAREAS(IDEF)
          DX(NAREA) = DX1
          DY(NAREA) = DY1
          XMAX(NAREA) = XMAX1
          XMIN(NAREA) = XMIN1
          YMAX(NAREA) = YMAX1
          YMIN(NAREA) = YMIN1
          NC(NAREA) = NC1

c         WRITE (LUOUT,120) NAREA, AREAS(NAREA)
c 120     FORMAT (2X, I2, 2X, A15)
	  write(LUOUT,121) NAREA, state
  121     FORMAT (2X,I2,2X,A2)
        ENDIF

  140 CONTINUE

  999 RETURN
      END
      SUBROUTINE SURF (XGRID, YGRID, ZEE, AY, BEE, CEE, DEE, IROW, JCOL)

**********************************************************************
** SUBROUTINE SURF: INTERPOLATES THE Z VALUE                         *
**********************************************************************

* Calculated the value of the grid at the point XPT, YPT.  The
* interpolation is done in the index coordinate system for convenience.

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      DOUBLE PRECISION XGRID, YGRID
      DOUBLE PRECISION AY, BEE, CEE, DEE
      DOUBLE PRECISION ZEE, ZEE1, ZEE2, ZEE3, ZEE4
      INTEGER IROW, JCOL

      ZEE1 = AY
      ZEE2 = BEE*(XGRID - DBLE(JCOL) )
      ZEE3 = CEE*(YGRID - DBLE(IROW) )
      ZEE4 = DEE*(XGRID - DBLE(JCOL) )*(YGRID - DBLE(IROW) )
      ZEE  = ZEE1 + ZEE2 + ZEE3 + ZEE4

      RETURN
      END
      SUBROUTINE TO83 (NOGO, RESP, XPT, YPT, XPT2, YPT2,
     +                 DLAM, DLOM, DLAS, DLOS, ITYPE)

* This subroutine predicts the NAD 83 latitude and longitude values
* given the NAD 27 latitude and longitude values in degree decimal
* format.  In addition, the program returns the shift values between
* The datums in both arc secs and meters.

* All of the predictions are based upon a straight-forward interpolation
* of a gridded data set of datum shifts.  The datum shifts are assumed
* to be provided in the files opened in the NGRIDS subroutine.  The
* common AREAS contains the names of the valid areas while the common
* GDINFO contains the grid variables.  NAREA is the number of areas
* which had data files opened.  A total of two files are necessary for
* each area: one latitude and one longitude shift table (gridded data
* set) expressed in arc seconds.

* For this subroutine, it is important to remember that the
* input longitude is assumed to be positive east and the
* output longitude will be positive east.

*       Author:     Warren T. Dewhurst, PH. D.
*                   National Geodetic Survey
*                   November 1, 1989

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)

      DOUBLE PRECISION XPT, YPT, XPT2, YPT2
      DOUBLE PRECISION XGRID, YGRID
      DOUBLE PRECISION DLAM, DLOM, DLAS, DLOS
      DOUBLE PRECISION DX0, DY0, XMAX0, XMIN0, YMAX0, YMIN0
      INTEGER IROW, JCOL, IAREA, I, NC0, ITYPE
      INTEGER IFLAG1, IFLAG2, N1, N2
      CHARACTER*15 RESP
      LOGICAL NOGO, FLAG

      CHARACTER*15 AREAS
      COMMON /AREAS/ AREAS(MXAREA)

      DOUBLE PRECISION DX, DY, XMAX, XMIN, YMAX, YMIN
      INTEGER NC, NAREA
      COMMON /GDINFO/ DX(MXAREA), DY(MXAREA), XMAX(MXAREA),
     +                XMIN(MXAREA), YMAX(MXAREA), YMIN(MXAREA),
     +                NC(MXAREA), NAREA

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      CHARACTER*80 CARD
      COMMON /CURNT/ CARD

      SAVE FLAG

      DATA IFLAG1 /1/, IFLAG2 /2/, FLAG /.FALSE./

******************************************************************
*                             INITIALIZE
******************************************************************

      NOGO  =  .FALSE.

****************************************************
* READ WHERE TO GET THE DATA AND HOW IT IS ORGANIZED
****************************************************

* Check to see which set of gridded files XPT,YPT is in.

      DO 100 IAREA = 1, NAREA

        DX0 = DX(IAREA)
        DY0 = DY(IAREA)
        XMAX0 = XMAX(IAREA)
        XMIN0 = XMIN(IAREA)
        YMAX0 = YMAX(IAREA)
        YMIN0 = YMIN(IAREA)
        NC0 = NC(IAREA)
        CALL FGRID (XPT, YPT, DX0, DY0, XMAX0, XMIN0,
     +              YMAX0, YMIN0, XGRID, YGRID, IROW, JCOL, NOGO)
        IF (.NOT. NOGO) GOTO 200

  100 CONTINUE

* Not in any of the grid areas

      NOGO = .TRUE.
      GOTO 950

  200 CONTINUE

* Point in area number IAREA and named AREAS(IAREA)

        RESP = AREAS(IAREA)
        CALL INTRP (IAREA, IROW, NC0, JCOL, XGRID, YGRID,
     +              XPT, YPT, XPT2, YPT2, DLOS, DLAS, DLAM, DLOM)
9999    RETURN

* Error Messages

  950 CONTINUE
      IF (ITYPE .NE. 0) THEN
        CALL NBLANK (CARD, IFLAG1, N1)
        CALL NBLANK (CARD, IFLAG2, N2)
        WRITE (LUOUT,955) CARD(N1:N2)
  955   FORMAT (' *** THIS POINT IS OUT OF BOUNDS ***', /,
     +          1X, '''', A, '''')
      ELSE
        WRITE (LUOUT,960)
  960   FORMAT (' *** THE POINT IS OUT OF BOUNDS ***')
      ENDIF

* Write out grid areas for the first out-of-bounds error message

      IF (.NOT.FLAG  .OR.  ITYPE .EQ. 0) THEN
        WRITE (LUOUT,*) ' It must be within one of the following grid',
     +                  ' areas;'
        WRITE (LUOUT,975)
  975   FORMAT (18X, 7X, 'Latitude', 7X, 'Longitude', /,
     +          5X, 'Area Name', 5X, 2(5X, 'MIN', 4X, 'MAX', 1X),
     +          '(degrees)' )
        DO 970 I = 1, NAREA
          WRITE (LUOUT,965) AREAS(I),
     +                      IDNINT(  YMIN(I) ), IDNINT(  YMAX(I) ),
     +                      IDNINT( -XMAX(I) ), IDNINT( -XMIN(I) )
  965     FORMAT (1X, '''', A15, '''', 2(2X, 2I7) )
  970   CONTINUE
        FLAG = .TRUE.
      ENDIF

      WRITE (LUOUT,*) ' '
      GOTO 9999
      END
      SUBROUTINE TRANSF (NOGO, RESP, XPT, YPT, XPT2, YPT2,
     +                   DLAM, DLOM, DLAS, DLOS, KEY, ITYPE)

* This subroutine computes either the forward or inverse coordinate
* transformation depending upon the value of the integer variable 'key'
c 1/20/92 - IF the HPGN option is chosen, statements in this subroutine
c which refer to NAD 27 apply to NAD 83; 
c statements which refer to NAD 83 apply to HPGN -jmb

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA, ITMAX
      DOUBLE PRECISION SMALL
      PARAMETER (MXAREA = 8, ITMAX = 10, SMALL = 1.0D-9 )

      DOUBLE PRECISION XPT, YPT, XPT2, YPT2
      DOUBLE PRECISION XTEMP, YTEMP, XDIF, YDIF
      DOUBLE PRECISION DLAM, DLOM, DLAS, DLOS
      DOUBLE PRECISION DXLAST, DYLAST
      INTEGER KEY, NUM, ITYPE
      CHARACTER*15 RESP
      LOGICAL NOGO

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      IF (KEY .EQ. 1) THEN

**********************
* FOR NAD 27 TO NAD 83
**********************

        CALL TO83 (NOGO, RESP, XPT, YPT, XPT2, YPT2,
     +             DLAM, DLOM, DLAS, DLOS, ITYPE)

      ELSEIF (KEY .EQ. -1) THEN

***************************
* FOR NAD 83 TO NAD 27)
* THIS IS DONE BY ITERATION
***************************

        NUM = 0

**************************************************
* SET THE XPT,YPT TO TEMPORARY VALUES
* (REMEMBER, XPT AND YPT ARE REALLY NAD 83 VALUES)
**************************************************

        XTEMP = XPT
        YTEMP = YPT

**************************************************************
* PRETEND THAT THESE TEMPORARY VALUES ARE REALLY NAD 27 VALUES
* FOR A FIRST GUESS AND COMPUTE PSEUDO-NAD 83 COORDINATES
**************************************************************

  200   CONTINUE
          NUM = NUM + 1

********************************
* CHECK THE NUMBER OF ITERATIONS
********************************

          IF (NUM .GE. ITMAX) THEN
            WRITE (LUOUT,*) ' *** MAXIMUM ITERATIONS EXCEEDED!! ***'
            WRITE (LUOUT,*) ' *** CALL PROGRAMMER FOR HELP ***'
            WRITE (LUOUT,*) ' LATITUDE =', YTEMP, ' LONGITUDE =', XTEMP
            WRITE (LUOUT,*) ' GRID AREA =', RESP
            NOGO = .TRUE.
            GOTO 1000
          ENDIF

          CALL TO83 (NOGO, RESP, XTEMP, YTEMP, XPT2, YPT2,
     +               DLAM, DLOM, DLAS, DLOS, ITYPE)
          DXLAST = DLOS
          DYLAST = DLAS

**************************************
* COMPARE TO ACTUAL NAD 83 COORDINATES
**************************************

          XDIF = XPT - XPT2
          YDIF = YPT - YPT2

****************************************************************
* COMPUTE A NEW GUESS UNLESS THE DIFFERENCES ARE LESS THAN SMALL
* WHERE SMALL IS DEFINED (ABOVE) TO BE;  SMALL = 1.0D-9
****************************************************************

          IF (NUM .EQ. 1) THEN
            IF (DABS(XDIF) .GT. SMALL) THEN
              XTEMP = XPT - DLOS/3600.D0
            ENDIF
            IF (DABS(YDIF) .GT. SMALL) THEN
              YTEMP = YPT - DLAS/3600.D0
            ENDIF
          ELSE
            IF (DABS(XDIF) .GT. SMALL) THEN
              XTEMP = XTEMP - (XPT2 - XPT)
            ENDIF
            IF (DABS(YDIF) .GT. SMALL) THEN
              YTEMP = YTEMP - (YPT2 - YPT)
            ENDIF

          ENDIF

          IF (DABS(YDIF) .LE. SMALL  .AND.  DABS(XDIF) .LE. SMALL) THEN

******************************
* IF CONVERGED THEN LEAVE LOOP
******************************

            XPT = XTEMP
            YPT = YTEMP
            GOTO 1000
          ENDIF

*******************************
* IF NOT CONVERGED THEN ITERATE
*******************************

        GOTO 200

      ENDIF
 1000 RETURN
      END
      SUBROUTINE TYPE1 (NAME, IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +                  XPT, YPT, EOF, NOPT)

* Read a record from a file of type 1. In this type there is a station
* name (or blanks) in columns 1-40, and free-format latitude and
* longitude values in columns 41-80.  By free format we mean that the
* numbers making up the degrees, minutes and seconds of latitude,
* degrees, minutes, seconds of longitude must appear in that order in
* columns 41 through 80 but are not restricted to any specific columns.
* The latitude and longitude may be either (1) integer degrees, integer
* minutes, decimal seconds, or (2) integer degrees, decimal minutes, or
* (3) decimal degrees.

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)
      CHARACTER*1 DOT, BLK
      PARAMETER ( DOT = '.', BLK = ' ' )
      CHARACTER*20 B20
      CHARACTER*80 B80
      PARAMETER (B20 = '                   ', B80 = B20//B20//B20//B20)

      DOUBLE PRECISION XPT, YPT, RDLA, RDLO, DCARD
      DOUBLE PRECISION RMLA, RMLO, SLA, SLO
      INTEGER  IDLA, IMLA, IDLO, IMLO
      INTEGER IDOT, IBLK, LENG, IERR
      INTEGER IFLAG1, IFLAG2, N1, N2
      CHARACTER*80 NAME
      CHARACTER*40 DUMLA, DUMLO
      LOGICAL EOF, NOPT

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      CHARACTER*80 CARD
      COMMON /CURNT/ CARD

      DATA IFLAG1 /1/, IFLAG2 /2/

***********************************
* FOR INPUT FILE OF ITYPE = 1
***********************************

    1 READ (NIN,'(A80)',END=9999) CARD
      READ (CARD(1:40), '(A40)') NAME

* Check for blank line

      IF (CARD .EQ. B80) GOTO 1

* Find position of the first decimal point (to indicate the last
* number in the latitude)

      IDOT = INDEX(CARD(41:80), DOT)

* Error - no decimal point

      IF (IDOT .EQ. 0) GOTO 9980

* find position of the first blank after the first decimal point (to
* indicate the blank after the last number in the latitude)

      IDOT = IDOT + 40
      IBLK = INDEX(CARD(IDOT+1:80), BLK)
      IBLK = IBLK + IDOT

      DUMLA = CARD(41:IBLK)
      LENG = IBLK - 41
      RDLA = DCARD( DUMLA, LENG, IERR )
      IF (IERR .NE. 0) GOTO 9950
      IF (LENG .GT. 0) THEN

        RMLA = DCARD( DUMLA, LENG, IERR )
        IF (IERR .NE. 0) GOTO 9950

        IF (LENG .GT. 0) THEN
          SLA  = DCARD( DUMLA, LENG, IERR )
          IF (IERR .NE. 0) GOTO 9950
        ELSE
          SLA = 0.D0
        ENDIF

      ELSE
        RMLA = 0.D0
        SLA = 0.D0
      ENDIF

* Check for illogical values

      IF (RDLA .LT.   0.D0) GOTO 9940
      IF (RDLA .GT.  90.D0) GOTO 9950
      IF (RMLA .LT. 0.D0  .OR.  RMLA .GT. 60.D0) GOTO 9950
      IF ( SLA .LT. 0.D0  .OR.   SLA .GT. 60.D0) GOTO 9950

***********
* LONGITUDE
***********

      DUMLO = CARD(IBLK+1:80)
      CALL NBLANK (DUMLO, IFLAG2, N2)
      LENG = N2
      RDLO = DCARD( DUMLO, LENG, IERR )
      IF (IERR .NE. 0) GOTO 9960
      IF (LENG .GT. 0) THEN

        RMLO = DCARD( DUMLO, LENG, IERR )
        IF (IERR .NE. 0) GOTO 9960

        IF (LENG .GT. 0) THEN
          SLO  = DCARD( DUMLO, LENG, IERR )
          IF (IERR .NE. 0) GOTO 9960
        ELSE
          SLO = 0.D0
        ENDIF

      ELSE
        RMLO = 0.D0
        SLO = 0.D0
      ENDIF

* Check for illogical values

      IF (RDLO .LT.   0.D0) GOTO 9940
      IF (RDLO .GT. 360.D0) GOTO 9960
      IF (RMLO .LT. 0.D0  .OR.  RMLO .GT. 60.D0) GOTO 9960
      IF ( SLO .LT. 0.D0  .OR.   SLO .GT. 60.D0) GOTO 9960

* Calculate decimal degrees

      YPT = RDLA + RMLA/60.D0 + SLA/3600.D0
      XPT = RDLO + RMLO/60.D0 + SLO/3600.D0

* Get degrees, minutes, seconds

      CALL HMS (YPT, IDLA, IMLA, SLA)
      CALL HMS (XPT, IDLO, IMLO, SLO)

 9000 RETURN

* Error messages

 9940 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9945) CARD(N1:N2)
 9945 FORMAT (' ERROR - in the following record:', /,
     +        9X, '''', A, '''', /,
     +        '         Latitude and Longitudes must be positive!', /,
     +        '         Longitude is positive west.', /)
      NOPT = .TRUE.
      GOTO 9000

 9950 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9955) CARD(N1:N2)
 9955 FORMAT (' ERROR - Illogical values for latitude',
     +        ' in the following record:', /,
     +        9X, '''', A, '''', /,
     +        '         Latitude must be between 0 and 90 degrees.', /,
     +        '         Minutes and seconds must be between 0',
     +                                                    ' and 60.', /)
      NOPT = .TRUE.
      GOTO 9000

 9960 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9965) CARD(N1:N2)
 9965 FORMAT (' ERROR - Illogical values for longitude',
     +        ' in the following record:', /,
     +        9X, '''', A, '''', /,
     +        '         Longitude must be between 0 and 360 degrees.',/,
     +        '         Minutes and seconds must be between 0',
     +                                                    ' and 60.', /)
      NOPT = .TRUE.
      GOTO 9000

 9980 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9985) CARD(N1:N2)
 9985 FORMAT (' ERROR - The following record does not have a decimal',
     +        ' point in the latitude.', /,
     +        9X, '''', A, '''', /,
     +        '         In the free format a decimal point is used',
     +        ' to determine what is', /,
     +        '         the last number in the latitude.  Please',
     +        ' correct this record', /,
     +        '         and check all of the data in this file to',
     +        ' ensure that it follows', /,
     +        '         the correct format.', /)
      NOPT = .TRUE.
      GOTO 9000

 9999 CONTINUE
      EOF = .TRUE.
      GOTO 9000
      END
      SUBROUTINE TYPE2 (NAME, IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +                  XPT, YPT, EOF, NOPT, IFMT)

* Read a record from a file of type 2. In this type there is free-format
* latitude and longitude values in columns 1-40, and a station name
* (or blanks) in columns 41-80.
* By free format we mean that the numbers making up the degrees,
* minutes and seconds of latitude, degrees, minutes, seconds of
* longitude must appear in that order in columns 1 through 40 but are
* not restricted to any specific columns.  The latitude and longitude
* may be either (1) integer degrees, integer minutes, decimal seconds,
* or (2) integer degrees, decimal minutes, or (3) decimal degrees.

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)
      CHARACTER*1 DOT, BLK
      PARAMETER ( DOT = '.', BLK = ' ' )
      CHARACTER*20 B20
      CHARACTER*80 B80
      PARAMETER (B20 = '                   ', B80 = B20//B20//B20//B20)

      DOUBLE PRECISION XPT, YPT, RDLA, RDLO, DCARD
      DOUBLE PRECISION RMLA, RMLO, SLA, SLO
      INTEGER  IDLA, IMLA, IDLO, IMLO
      INTEGER IDOT, IBLK, LENG, IERR, IFMT
      INTEGER IFLAG1, IFLAG2, N1, N2
      CHARACTER*80 NAME
      CHARACTER*40 DUMLA, DUMLO
      LOGICAL EOF, NOPT

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      CHARACTER*80 CARD
      COMMON /CURNT/ CARD

      DATA IFLAG1 /1/, IFLAG2 /2/

***********************************
* FOR INPUT FILE OF ITYPE = 2
***********************************

    1 READ (NIN,'(A80)',END=9999) CARD
      NAME = CARD(41:80)

* Check for blank line

      IF (CARD .EQ. B80) GOTO 1

* Find position of the first decimal point (to indicate the last
* number in the latitude)

      IDOT = INDEX(CARD(1:40), DOT)

* Error - no decimal point

      IF (IDOT .EQ. 0) GOTO 9980

* find position of the first blank after the first decimal point (to
* indicate the blank after the last number in the latitude)

* The variable IFMT indicates whether the input latitude in in:
* 1 - integer degrees, integer minutes, decimal seconds;
* 2 - integer degrees, decimal minutes; 3 - decimal degrees

      IBLK = INDEX(CARD(IDOT+1:40), BLK)
      IBLK = IBLK + IDOT

      DUMLA = CARD(1:IBLK)
      LENG = IBLK - 1
      RDLA = DCARD( DUMLA, LENG, IERR )
      IF (IERR .NE. 0) GOTO 9950
      IF (LENG .GT. 0) THEN

        RMLA = DCARD( DUMLA, LENG, IERR )
        IF (IERR .NE. 0) GOTO 9950

        IF (LENG .GT. 0) THEN
          SLA  = DCARD( DUMLA, LENG, IERR )
          IF (IERR .NE. 0) GOTO 9950
          IFMT = 1
        ELSE
          SLA = 0.D0
          IFMT = 2
        ENDIF

      ELSE
        RMLA = 0.D0
        SLA = 0.D0
        IFMT = 3
      ENDIF

* Check for illogical values

      IF (RDLA .LT.   0.D0) GOTO 9940
      IF (RDLA .GT.  90.D0) GOTO 9950
      IF (RMLA .LT. 0.D0  .OR.  RMLA .GT. 60.D0) GOTO 9950
      IF ( SLA .LT. 0.D0  .OR.   SLA .GT. 60.D0) GOTO 9950

***********
* LONGITUDE
***********

      DUMLO = CARD(IBLK+1:40)
      CALL NBLANK (DUMLO, IFLAG2, N2)
      LENG = N2
      RDLO = DCARD( DUMLO, LENG, IERR )
      IF (IERR .NE. 0) GOTO 9960
      IF (LENG .GT. 0) THEN

        RMLO = DCARD( DUMLO, LENG, IERR )
        IF (IERR .NE. 0) GOTO 9960

        IF (LENG .GT. 0) THEN
          SLO  = DCARD( DUMLO, LENG, IERR )
          IF (IERR .NE. 0) GOTO 9960
        ELSE
          SLO = 0.D0
        ENDIF

      ELSE
        RMLO = 0.D0
        SLO = 0.D0
      ENDIF

* Check for illogical values

      IF (RDLO .LT.   0.D0) GOTO 9940
      IF (RDLO .GT. 360.D0) GOTO 9960
      IF (RMLO .LT. 0.D0  .OR.  RMLO .GT. 60.D0) GOTO 9960
      IF ( SLO .LT. 0.D0  .OR.   SLO .GT. 60.D0) GOTO 9960

* Calculate decimal degrees

      YPT = RDLA + RMLA/60.D0 + SLA/3600.D0
      XPT = RDLO + RMLO/60.D0 + SLO/3600.D0

* Get degrees, minutes, seconds

      CALL HMS (YPT, IDLA, IMLA, SLA)
      CALL HMS (XPT, IDLO, IMLO, SLO)

 9000 RETURN

* Error messages

 9940 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9945) CARD(N1:N2)
 9945 FORMAT (' ERROR - in the following record:', /,
     +        9X, '''', A, '''', /,
     +        '         Latitude and Longitudes must be positive!', /,
     +        '         Longitude is positive west.', /)
      NOPT = .TRUE.
      GOTO 9000

 9950 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9955) CARD(N1:N2)
 9955 FORMAT (' ERROR - Illogical values for latitude',
     +        ' in the following record:', /,
     +        9X, '''', A, '''', /,
     +        '         Latitude must be between 0 and 90 degrees.', /,
     +        '         Minutes and seconds must be between 0',
     +                                                    ' and 60.', /)
      NOPT = .TRUE.
      GOTO 9000

 9960 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9965) CARD(N1:N2)
 9965 FORMAT (' ERROR - Illogical values for longitude',
     +        ' in the following record:', /,
     +        9X, '''', A, '''', /,
     +        '         Longitude must be between 0 and 360 degrees.',/,
     +        '         Minutes and seconds must be between 0',
     +                                                    ' and 60.', /)
      NOPT = .TRUE.
      GOTO 9000

 9980 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9985) CARD(N1:N2)
 9985 FORMAT (' ERROR - The following record does not have a decimal',
     +        ' point in the latitude.', /,
     +        9X, '''', A, '''', /,
     +        '         In the free format a decimal point is used',
     +        ' to determine what is', /,
     +        '         the last number in the latitude.  Please',
     +        ' correct this record', /,
     +        '         and check all of the data in this file to',
     +        ' ensure that it follows', /,
     +        '         the correct format.', /)
      NOPT = .TRUE.
      GOTO 9000

 9999 CONTINUE
      EOF = .TRUE.
      GOTO 9000
      END
      SUBROUTINE TYPE3 (IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +                  XPT, YPT, EOF, NOPT, FIRST, LAST, IPREC)

* Read a record from a file of type 3 (Blue Book)
* This format is defined in 'Input Formats and Specifications of the'
* National Geodetic Survey Data Base', Volume 1. Horizontal Control
* Data, and is available from the National Geodetic Survey for a
* fee by calling (301) 443-8631

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)
      CHARACTER*1 DOT
      PARAMETER ( DOT = '.' )

      DOUBLE PRECISION XPT, YPT
      DOUBLE PRECISION SLA, SLO
      INTEGER  IDLA, IMLA, IDLO, IMLO
      INTEGER IDOT, IPREC, IP1
      INTEGER IFLAG1, IFLAG2, N1, N2
      CHARACTER*44 FIRST
      CHARACTER*30 LAST
      CHARACTER*7 ASEC
      CHARACTER*1 DIRLAT, DIRLON
      LOGICAL EOF, NOPT

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)

      CHARACTER*80 CARD
      COMMON /CURNT/ CARD

      DATA IFLAG1 /1/, IFLAG2 /2/

***********************************
* FOR INPUT FILE OF ITYPE = 3
***********************************

      READ (NIN,6005,END=9999) CARD
 6005 FORMAT (A80)
      IF (CARD(8:9) .EQ. '80') THEN

* The station names and locations are in the *80* records

        READ (CARD,6000) FIRST, IDLA, IMLA, SLA, DIRLAT,
     +                   IDLO, IMLO, SLO, DIRLON, LAST
 6000   FORMAT (BZ, A44, I2, I2, F7.5, A1, I3, I2, F7.5, A1, A11)

* Check for illogical values

        IF (DIRLAT .NE. 'N'  .AND.  DIRLAT .NE. 'n') GOTO 9940
        IF (IDLA .LT.   0) GOTO 9940
        IF (IDLA .GT.  90) GOTO 9950
        IF (IMLA .LT. 0     .OR.  IMLA .GT. 60   ) GOTO 9950
        IF ( SLA .LT. 0.D0  .OR.   SLA .GT. 60.D0) GOTO 9950
        IF (DIRLON .NE. 'W'  .AND.  DIRLON .NE. 'w') GOTO 9940
        IF (IDLO .LT.   0) GOTO 9940
        IF (IDLO .GT. 360) GOTO 9950
        IF (IMLO .LT. 0     .OR.  IMLO .GT. 60   ) GOTO 9950
        IF ( SLO .LT. 0.D0  .OR.   SLO .GT. 60.D0) GOTO 9950

      ELSE
        WRITE (NOUT,6005) CARD
        NOPT = .TRUE.
        GOTO 9000
      ENDIF

      YPT = DBLE(IDLA) + DBLE(IMLA)/60.D0 + SLA/3600.D0
      XPT = DBLE(IDLO) + DBLE(IMLO)/60.D0 + SLO/3600.D0

* Get precision of seconds of latitude (i.e. the number of digits
* past the actual or implied decimal point). But since the output will
* have implied decimal points, the precision cannot be greater than 5.

      ASEC = CARD(49:55)

      IDOT = INDEX(ASEC(1:7), DOT)
   
      IF (IDOT .EQ. 0) THEN
        CALL NBLANK (ASEC(3:7), IFLAG2, N2)
        IPREC = N2
      ELSEIF (IDOT .LT. 7) THEN
        IP1 = IDOT + 1
        CALL NBLANK (ASEC(IP1:7), IFLAG2, N2)
        IPREC = N2
        IF (IDOT .EQ. 1  .AND.  IPREC .EQ. 6) IPREC = 5
      ELSEIF (IDOT .EQ. 7) THEN
        IPREC = 0
      ENDIF

 9000 RETURN

* Error messages

 9940 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9945) CARD(N1:N2)
 9945 FORMAT (' ERROR - in the following record:', /,
     +        9X, '''', A, '''', /,
     +        '         Latitude and Longitudes must be positive!', /,
     +        '         Longitude is positive west.', /)
      NOPT = .TRUE.
      GOTO 9000

 9950 CONTINUE
      CALL NBLANK (CARD, IFLAG1, N1)
      CALL NBLANK (CARD, IFLAG2, N2)
      WRITE (LUOUT,9955) CARD(N1:N2)
 9955 FORMAT (' ERROR - Illogical values for latitude or longitude',
     +        ' in the following record:', /,
     +        9X, '''', A, '''', /,
     +        '         This record will be skipped.', /)
      NOPT = .TRUE.
      GOTO 9000

 9999 CONTINUE
      EOF = .TRUE.
      GOTO 9000
      END
      SUBROUTINE WRTPT (ITYPE, KEY, NCONV, VRSION, NAME,
     +                  IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +                  IDLA2, IMLA2, SLA2, IDLO2, IMLO2, SLO2,
     +                  DLAM, DLOM, DLAS, DLOS, IFMT,
     +                  FIRST, LAST, IPREC, RESP, IPAGE, PAGE, SCREEN,
     +                  dsel)

*** Write the NAD 83, NAD 27, and shift values to output file
***(and screen).

      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      IMPLICIT INTEGER (I-N)
*     IMPLICIT UNDEFINED (A-Z)

      INTEGER MXAREA
      PARAMETER (MXAREA = 8)

      DOUBLE PRECISION VRSION
      DOUBLE PRECISION DLAM, DLOM, DLAS, DLOS
      DOUBLE PRECISION SLA, SLO, SLA2, SLO2
      INTEGER  IDLA, IMLA, IDLO, IMLO
      INTEGER  IDLA2, IMLA2, IDLO2, IMLO2
      INTEGER ITYPE, KEY, NCONV, IFMT, IPREC, IPAGE
      CHARACTER*80 NAME
      CHARACTER*44 FIRST
      CHARACTER*30 LAST
      CHARACTER*15 RESP
      LOGICAL PAGE, SCREEN,dsel

      INTEGER LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA
      COMMON /INOUT/ LUIN, LUOUT, NOUT, NIN, NAPAR, LUAREA(2*MXAREA)
*********************
* PAGE NUMBER COUNTER
*********************

* this is where you change how many on a page

        IF ( MOD(NCONV,5) .EQ. 0  .OR.  NCONV .EQ. 1) THEN
          PAGE = .TRUE.
          IPAGE = IPAGE + 1
        ENDIF

*********************************
** WRITE TO OUTPUT FILE OR SCREEN
*********************************

        IF (ITYPE .EQ. 0) THEN

**************************************
* ONLY INTERACTIVE USE - NO INPUT FILE
**************************************
          CALL PRINT1 (NOUT, NCONV, NAME, VRSION, IDLA, IMLA, SLA,
     +                 IDLO, IMLO, SLO, IDLA2, IMLA2, SLA2, IDLO2,
     +                 IMLO2, SLO2, DLAM, DLOM, DLAS, DLOS, RESP,
     +                IPAGE, PAGE, KEY,dsel)

        ELSEIF (ITYPE .EQ. 1) THEN

**************************
* FOR FREE FORMAT TYPE 1
**************************
          CALL PRINT1 (NOUT, NCONV, NAME, VRSION, IDLA, IMLA, SLA,
     +                 IDLO, IMLO, SLO, IDLA2, IMLA2, SLA2, IDLO2,
     +                 IMLO2, SLO2, DLAM, DLOM, DLAS, DLOS, RESP,
     +                 IPAGE, PAGE, KEY,dsel)
        ELSEIF (ITYPE .EQ. 2) THEN

**************************
* FOR FREE FORMAT TYPE 2
**************************

          CALL PRINT2 (NOUT, NCONV, NAME, VRSION, IDLA, IMLA, SLA,
     +                 IDLO, IMLO, SLO, IDLA2, IMLA2, SLA2, IDLO2,
     +                 IMLO2, SLO2, KEY, IFMT,dsel)

        ELSEIF (ITYPE .EQ. 3) THEN

****************************************
* FOR INPUT FILE ITYPE = 3
* THE HORIZONTAL BLUE BOOK SPECIFICATION
****************************************

          CALL PRINT3 (NOUT, IDLA, IMLA, SLA, IDLO, IMLO, SLO,
     +                 IDLA2, IMLA2, SLA2, IDLO2, IMLO2, SLO2,
     +                 KEY, FIRST, LAST, IPREC)

        ENDIF

*******************
* FOR SCREEN OUTPUT
*******************

        IF (SCREEN) THEN
          IF (ITYPE .EQ. 3) NAME = FIRST(15:44)
          CALL PRINT1 (LUOUT, NCONV, NAME, VRSION, IDLA, IMLA, SLA,
     +                 IDLO, IMLO, SLO, IDLA2, IMLA2, SLA2, IDLO2,
     +                 IMLO2, SLO2, DLAM, DLOM, DLAS, DLOS, RESP,
     +                IPAGE, PAGE, KEY,dsel)
        ENDIF

      RETURN
      END
